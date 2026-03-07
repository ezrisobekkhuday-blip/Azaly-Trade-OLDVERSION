from contextlib import asynccontextmanager
from pathlib import Path
from shutil import copyfileobj
from uuid import uuid4

from fastapi import Depends, FastAPI, File, HTTPException, Request, UploadFile, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy import func, inspect, select, text
from sqlalchemy.orm import Session

from .database import Base, SessionLocal, engine, get_db
from .models import Product, Profile, Shop
from .schemas import (
    HealthResponse,
    ProductCreate,
    ProductRead,
    ProductUpdate,
    ProfileRead,
    ProfileUpdate,
    ShopCreate,
    ShopRead,
    ShopUpdate,
)

BASE_DIR = Path(__file__).resolve().parent.parent
UPLOADS_DIR = BASE_DIR / "uploads"
UPLOADS_DIR.mkdir(parents=True, exist_ok=True)


def ensure_profile(db: Session) -> Profile:
    profile = db.get(Profile, 1)

    if profile is None:
        profile = Profile(id=1, name="Azaly Trade")
        db.add(profile)
        db.commit()
        db.refresh(profile)

    return profile


def ensure_product_columns() -> None:
    inspector = inspect(engine)

    if "products" not in inspector.get_table_names():
        return

    columns = {column["name"] for column in inspector.get_columns("products")}

    with engine.begin() as connection:
        if "is_favorite" not in columns:
            connection.execute(
                text("ALTER TABLE products ADD COLUMN is_favorite BOOLEAN DEFAULT 0 NOT NULL")
            )

        if "shop_id" not in columns:
            connection.execute(text("ALTER TABLE products ADD COLUMN shop_id INTEGER"))


def ensure_existing_products_have_shop(db: Session) -> None:
    unassigned_products = list(db.scalars(select(Product).where(Product.shop_id.is_(None))).all())

    if not unassigned_products:
        return

    shop = db.scalars(select(Shop).order_by(Shop.created_at.asc())).first()

    if shop is None:
        shop = Shop(
            name="Main Shop",
            photo="",
            location="Auto-created",
            description="Created automatically for existing products.",
            business_card_image="",
        )
        db.add(shop)
        db.commit()
        db.refresh(shop)

    for product in unassigned_products:
        product.shop_id = shop.id

    db.commit()


def to_public_image_url(request: Request, image_path: str) -> str:
    if image_path.startswith("http://") or image_path.startswith("https://"):
        return image_path

    if image_path.startswith("/uploads/"):
        return f"{str(request.base_url).rstrip('/')}{image_path}"

    return image_path


def normalize_image_path(image_path: str) -> str:
    if image_path.startswith("/uploads/"):
        return image_path

    uploads_index = image_path.find("/uploads/")

    if uploads_index != -1:
        return image_path[uploads_index:]

    return image_path


def serialize_shop(request: Request, shop: Shop, products_count: int = 0) -> ShopRead:
    return ShopRead(
        id=str(shop.id),
        name=shop.name,
        photo=to_public_image_url(request, shop.photo) if shop.photo else "",
        location=shop.location,
        description=shop.description,
        business_card_image=to_public_image_url(request, shop.business_card_image)
        if shop.business_card_image
        else "",
        products_count=products_count,
        created_at=shop.created_at,
    )


def serialize_product(request: Request, product: Product, shop_name: str = "") -> ProductRead:
    return ProductRead(
        id=str(product.id),
        shop_id=str(product.shop_id or ""),
        shop_name=shop_name,
        images=[to_public_image_url(request, image) for image in product.images],
        amount=product.amount,
        material=product.material,
        size=product.size,
        status=product.status,
        is_favorite=product.is_favorite,
        created_at=product.created_at,
    )


def delete_uploaded_image(image_path: str) -> None:
    normalized_path = normalize_image_path(image_path)

    if not normalized_path.startswith("/uploads/"):
        return

    file_path = BASE_DIR / normalized_path.removeprefix("/")

    if file_path.exists():
        file_path.unlink()


def validate_product_images(images: list[str]) -> None:
    if not images:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="At least one image is required.",
        )


def validate_shop_photo(photo: str) -> None:
    if not photo.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Shop photo is required.",
        )


def get_shop_or_404(shop_id: int, db: Session) -> Shop:
    shop = db.get(Shop, shop_id)

    if shop is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Shop not found.")

    return shop


def build_shop_count_map(db: Session) -> dict[int, int]:
    rows = db.execute(
        select(Product.shop_id, func.count(Product.id)).group_by(Product.shop_id)
    ).all()
    return {shop_id: count for shop_id, count in rows if shop_id is not None}


def build_shop_name_map(db: Session) -> dict[int, str]:
    shops = db.scalars(select(Shop)).all()
    return {shop.id: shop.name for shop in shops}


@asynccontextmanager
async def lifespan(_: FastAPI):
    UPLOADS_DIR.mkdir(parents=True, exist_ok=True)
    Base.metadata.create_all(bind=engine)
    ensure_product_columns()

    with SessionLocal() as db:
        ensure_profile(db)
        ensure_existing_products_have_shop(db)

    yield


app = FastAPI(title="Azaly Trade API", version="0.3.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount("/uploads", StaticFiles(directory=UPLOADS_DIR), name="uploads")


def normalize_shop_name(value: str) -> str:
    return value.strip() or "Новый магазин"


@app.get("/health", response_model=HealthResponse)
def healthcheck() -> HealthResponse:
    return HealthResponse(status="ok")


@app.get("/profile", response_model=ProfileRead)
def get_profile(db: Session = Depends(get_db)) -> Profile:
    return ensure_profile(db)


@app.put("/profile", response_model=ProfileRead)
def update_profile(payload: ProfileUpdate, db: Session = Depends(get_db)) -> Profile:
    profile = ensure_profile(db)
    profile.name = payload.name.strip() or "Azaly Trade"
    db.commit()
    db.refresh(profile)
    return profile


@app.post("/media/upload", response_model=list[str], status_code=status.HTTP_201_CREATED)
def upload_media(
    request: Request,
    files: list[UploadFile] = File(...),
) -> list[str]:
    uploaded_urls: list[str] = []

    for file in files:
        extension = Path(file.filename or "").suffix or ".jpg"
        stored_name = f"{uuid4().hex}{extension}"
        stored_path = UPLOADS_DIR / stored_name

        with stored_path.open("wb") as output_file:
            copyfileobj(file.file, output_file)

        uploaded_urls.append(to_public_image_url(request, f"/uploads/{stored_name}"))

    return uploaded_urls


@app.get("/shops", response_model=list[ShopRead])
def list_shops(request: Request, db: Session = Depends(get_db)) -> list[ShopRead]:
    shops = list(db.scalars(select(Shop).order_by(Shop.created_at.desc())).all())
    counts = build_shop_count_map(db)
    return [serialize_shop(request, shop, counts.get(shop.id, 0)) for shop in shops]


@app.post("/shops", response_model=ShopRead, status_code=status.HTTP_201_CREATED)
def create_shop(
    request: Request,
    payload: ShopCreate,
    db: Session = Depends(get_db),
) -> ShopRead:
    validate_shop_photo(payload.photo)

    shop = Shop(
        name=normalize_shop_name(payload.name),
        photo=normalize_image_path(payload.photo.strip()),
        location=payload.location.strip(),
        description=payload.description.strip(),
        business_card_image=normalize_image_path(payload.business_card_image.strip())
        if payload.business_card_image.strip()
        else "",
    )
    db.add(shop)
    db.commit()
    db.refresh(shop)
    return serialize_shop(request, shop, 0)


@app.put("/shops/{shop_id}", response_model=ShopRead)
def update_shop(
    shop_id: int,
    request: Request,
    payload: ShopUpdate,
    db: Session = Depends(get_db),
) -> ShopRead:
    validate_shop_photo(payload.photo)
    shop = get_shop_or_404(shop_id, db)

    new_photo = normalize_image_path(payload.photo.strip())
    new_business_card = (
        normalize_image_path(payload.business_card_image.strip())
        if payload.business_card_image.strip()
        else ""
    )
    removed_images: list[str] = []

    if shop.photo and shop.photo != new_photo:
        removed_images.append(shop.photo)

    if shop.business_card_image and shop.business_card_image != new_business_card:
        removed_images.append(shop.business_card_image)

    shop.name = normalize_shop_name(payload.name)
    shop.photo = new_photo
    shop.location = payload.location.strip()
    shop.description = payload.description.strip()
    shop.business_card_image = new_business_card

    db.commit()
    db.refresh(shop)

    for image in set(removed_images):
        delete_uploaded_image(image)

    counts = build_shop_count_map(db)
    return serialize_shop(request, shop, counts.get(shop.id, 0))


@app.delete("/shops/{shop_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_shop(shop_id: int, db: Session = Depends(get_db)) -> None:
    shop = get_shop_or_404(shop_id, db)
    products = list(db.scalars(select(Product).where(Product.shop_id == shop.id)).all())

    images_to_delete: list[str] = []

    if shop.photo:
        images_to_delete.append(shop.photo)

    if shop.business_card_image:
        images_to_delete.append(shop.business_card_image)

    for product in products:
        images_to_delete.extend(product.images)
        db.delete(product)

    db.delete(shop)
    db.commit()

    for image in set(images_to_delete):
        delete_uploaded_image(image)


@app.get("/shops/{shop_id}/products", response_model=list[ProductRead])
def list_shop_products(
    shop_id: int,
    request: Request,
    db: Session = Depends(get_db),
) -> list[ProductRead]:
    shop = get_shop_or_404(shop_id, db)
    statement = select(Product).where(Product.shop_id == shop.id).order_by(Product.created_at.desc())
    products = list(db.scalars(statement).all())
    return [serialize_product(request, product, shop.name) for product in products]


@app.get("/products", response_model=list[ProductRead])
def list_products(request: Request, db: Session = Depends(get_db)) -> list[ProductRead]:
    statement = select(Product).order_by(Product.created_at.desc())
    products = list(db.scalars(statement).all())
    shop_names = build_shop_name_map(db)
    return [
        serialize_product(request, product, shop_names.get(product.shop_id or 0, ""))
        for product in products
    ]


@app.post("/products", response_model=ProductRead, status_code=status.HTTP_201_CREATED)
def create_product(
    request: Request,
    payload: ProductCreate,
    db: Session = Depends(get_db),
) -> ProductRead:
    validate_product_images(payload.images)
    shop = get_shop_or_404(payload.shop_id, db)

    product = Product(
        shop_id=shop.id,
        images=[normalize_image_path(image) for image in payload.images],
        amount=payload.amount.strip(),
        material=payload.material.strip(),
        size=payload.size.strip(),
        status="new",
        is_favorite=payload.is_favorite,
    )
    db.add(product)
    db.commit()
    db.refresh(product)
    return serialize_product(request, product, shop.name)


@app.put("/products/{product_id}", response_model=ProductRead)
def update_product(
    product_id: int,
    request: Request,
    payload: ProductUpdate,
    db: Session = Depends(get_db),
) -> ProductRead:
    validate_product_images(payload.images)

    product = db.get(Product, product_id)

    if product is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found.")

    shop = get_shop_or_404(payload.shop_id, db)
    normalized_images = [normalize_image_path(image) for image in payload.images]
    removed_images = [image for image in product.images if image not in normalized_images]

    product.shop_id = shop.id
    product.images = normalized_images
    product.amount = payload.amount.strip()
    product.material = payload.material.strip()
    product.size = payload.size.strip()
    product.is_favorite = payload.is_favorite

    db.commit()
    db.refresh(product)

    for image in removed_images:
        delete_uploaded_image(image)

    return serialize_product(request, product, shop.name)


@app.delete("/products/{product_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_product(product_id: int, db: Session = Depends(get_db)) -> None:
    product = db.get(Product, product_id)

    if product is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found.")

    product_images = list(product.images)
    db.delete(product)
    db.commit()

    for image in product_images:
        delete_uploaded_image(image)
