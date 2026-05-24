import re
from contextlib import asynccontextmanager
from pathlib import Path
from shutil import copyfileobj
from uuid import uuid4

SUPPLIER_SHARE_PERCENT = 10.0

from fastapi import Depends, FastAPI, File, HTTPException, Request, UploadFile, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from sqlalchemy import func, inspect, select, text
from sqlalchemy.orm import Session

from .database import Base, SessionLocal, engine, get_db
from .models import Expense, Product, Profile, Shop
from .schemas import (
    ExpenseCreate,
    ExpenseRead,
    ExpenseUpdate,
    HealthResponse,
    ProductCreate,
    ProductRead,
    ProductUpdate,
    ProfileRead,
    ProfileUpdate,
    ShopCreate,
    ShopRead,
    StorefrontItemPayload,
    ShopUpdate,
)

BASE_DIR = Path(__file__).resolve().parent.parent
UPLOADS_DIR = BASE_DIR / "uploads"
FRONTEND_DIR = BASE_DIR / "webapp"
FRONTEND_INDEX = FRONTEND_DIR / "index.html"
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

        if "quantity" not in columns:
            connection.execute(
                text("ALTER TABLE products ADD COLUMN quantity INTEGER DEFAULT 1 NOT NULL")
            )

        if "color" not in columns:
            connection.execute(
                text("ALTER TABLE products ADD COLUMN color VARCHAR(80) DEFAULT '' NOT NULL")
            )

        if "article" not in columns:
            connection.execute(
                text("ALTER TABLE products ADD COLUMN article VARCHAR(120) DEFAULT '' NOT NULL")
            )

        if "measurements" not in columns:
            connection.execute(
                text(
                    "ALTER TABLE products ADD COLUMN measurements VARCHAR(160) DEFAULT '' NOT NULL"
                )
            )

        if "supplier_share_percent" not in columns:
            connection.execute(
                text(
                    "ALTER TABLE products ADD COLUMN supplier_share_percent FLOAT DEFAULT 10.0 NOT NULL"
                )
            )

        if "supplier_share_amount" not in columns:
            connection.execute(
                text(
                    "ALTER TABLE products ADD COLUMN supplier_share_amount FLOAT DEFAULT 0.0 NOT NULL"
                )
            )

        if "unit_price_with_share" not in columns:
            connection.execute(
                text(
                    "ALTER TABLE products ADD COLUMN unit_price_with_share FLOAT DEFAULT 0.0 NOT NULL"
                )
            )


def ensure_shop_columns() -> None:
    inspector = inspect(engine)

    if "shops" not in inspector.get_table_names():
        return

    columns = {column["name"] for column in inspector.get_columns("shops")}

    with engine.begin() as connection:
        if "latitude" not in columns:
            connection.execute(text("ALTER TABLE shops ADD COLUMN latitude FLOAT"))

        if "longitude" not in columns:
            connection.execute(text("ALTER TABLE shops ADD COLUMN longitude FLOAT"))

        if "storefront_image" not in columns:
            connection.execute(text("ALTER TABLE shops ADD COLUMN storefront_image VARCHAR(255) DEFAULT '' NOT NULL"))

        if "storefront_images" not in columns:
            connection.execute(
                text("ALTER TABLE shops ADD COLUMN storefront_images JSON DEFAULT '[]' NOT NULL")
            )

        if "storefront_items" not in columns:
            connection.execute(
                text("ALTER TABLE shops ADD COLUMN storefront_items JSON DEFAULT '[]' NOT NULL")
            )

        if "seller_wechat" not in columns:
            connection.execute(
                text("ALTER TABLE shops ADD COLUMN seller_wechat VARCHAR(255) DEFAULT '' NOT NULL")
            )

        if "seller_wechat_link" not in columns:
            connection.execute(
                text(
                    "ALTER TABLE shops ADD COLUMN seller_wechat_link VARCHAR(1024) DEFAULT '' NOT NULL"
                )
            )

        if "storefront_image" in columns:
            connection.execute(
                text(
                    """
                    UPDATE shops
                    SET storefront_images = '["' || storefront_image || '"]'
                    WHERE storefront_image <> ''
                      AND (storefront_images IS NULL OR storefront_images = '[]')
                    """
                )
            )


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
        forwarded_proto = request.headers.get("x-forwarded-proto", "")
        forwarded_host = request.headers.get("x-forwarded-host", "")
        scheme = (forwarded_proto.split(",")[0].strip() if forwarded_proto else request.url.scheme)
        host = (forwarded_host.split(",")[0].strip() if forwarded_host else request.headers.get("host", request.url.netloc))
        return f"{scheme}://{host}{image_path}"

    return image_path


def normalize_image_path(image_path: str) -> str:
    if image_path.startswith("/uploads/"):
        return image_path

    uploads_index = image_path.find("/uploads/")

    if uploads_index != -1:
        return image_path[uploads_index:]

    return image_path


def normalize_image_list(images: list[str]) -> list[str]:
    normalized: list[str] = []
    seen: set[str] = set()

    for image in images:
        cleaned = normalize_image_path(image.strip())

        if not cleaned or cleaned in seen:
            continue

        normalized.append(cleaned)
        seen.add(cleaned)

    return normalized


def resolve_frontend_asset(path: str) -> Path | None:
    candidate = (FRONTEND_DIR / path).resolve()

    try:
        candidate.relative_to(FRONTEND_DIR.resolve())
    except ValueError:
        return None

    if candidate.is_file():
        return candidate

    return None


def frontend_file_response(path: Path) -> FileResponse:
    return FileResponse(
        path,
        headers={
            "Cache-Control": "no-store, no-cache, must-revalidate, max-age=0",
            "Pragma": "no-cache",
            "Expires": "0",
        },
    )


def is_reserved_backend_path(path: str) -> bool:
    reserved_prefixes = (
        "health",
        "profile",
        "shops",
        "products",
        "expenses",
        "media",
        "uploads",
        "docs",
        "redoc",
        "openapi.json",
    )

    return any(path == prefix or path.startswith(f"{prefix}/") for prefix in reserved_prefixes)


def resolve_storefront_images(payload: ShopCreate | ShopUpdate) -> list[str]:
    normalized_images = normalize_image_list(payload.storefront_images)

    if normalized_images:
        return normalized_images

    if payload.storefront_image.strip():
        return [normalize_image_path(payload.storefront_image.strip())]

    return []


def normalize_storefront_item(
    payload: StorefrontItemPayload | dict[str, object],
) -> dict[str, object] | None:
    if isinstance(payload, StorefrontItemPayload):
        raw_image_path = payload.image_path
        amount = payload.amount
        color = payload.color
        material = payload.material
        size = payload.size
        measurements = payload.measurements
        is_favorite = payload.is_favorite
    else:
        raw_image_path = payload.get("image_path") or payload.get("imagePath") or ""
        amount = payload.get("amount", "")
        color = payload.get("color", "")
        material = payload.get("material", "")
        size = payload.get("size", "")
        measurements = payload.get("measurements", "")
        is_favorite = payload.get("is_favorite") or payload.get("isFavorite") or False

    image_path = normalize_image_path(str(raw_image_path).strip())

    if not image_path:
        return None

    return {
        "image_path": image_path,
        "amount": str(amount).strip(),
        "color": str(color).strip(),
        "material": str(material).strip(),
        "size": str(size).strip(),
        "measurements": str(measurements).strip(),
        "is_favorite": bool(is_favorite),
    }


def resolve_storefront_items(payload: ShopCreate | ShopUpdate) -> list[dict[str, object]]:
    normalized_items: list[dict[str, object]] = []
    seen: set[str] = set()

    for item in payload.storefront_items:
        normalized_item = normalize_storefront_item(item)

        if normalized_item is None:
            continue

        image_path = normalized_item["image_path"]
        if image_path in seen:
            continue

        normalized_items.append(normalized_item)
        seen.add(image_path)

    if normalized_items:
        return normalized_items

    return [{"image_path": image} for image in resolve_storefront_images(payload)]


def get_shop_storefront_items(shop: Shop) -> list[dict[str, str]]:
    normalized_items: list[dict[str, object]] = []
    seen: set[str] = set()

    for item in shop.storefront_items or []:
        if not isinstance(item, dict):
            continue

        normalized_item = normalize_storefront_item(item)

        if normalized_item is None:
            continue

        image_path = normalized_item["image_path"]
        if image_path in seen:
            continue

        normalized_items.append(normalized_item)
        seen.add(image_path)

    if normalized_items:
        return normalized_items

    return [{"image_path": image} for image in get_shop_storefront_images(shop)]


def get_shop_storefront_images(shop: Shop) -> list[str]:
    images = normalize_image_list(shop.storefront_images)

    for item in shop.storefront_items or []:
        if not isinstance(item, dict):
            continue

        normalized_item = normalize_storefront_item(item)

        if normalized_item is None:
            continue

        image_path = normalized_item["image_path"]
        if image_path not in images:
            images.append(image_path)

    if shop.storefront_image and shop.storefront_image not in images:
        images.append(shop.storefront_image)

    return images


def serialize_shop(request: Request, shop: Shop, products_count: int = 0) -> ShopRead:
    storefront_items = []

    for item in get_shop_storefront_items(shop):
        storefront_items.append(
            {
                **item,
                "image_path": to_public_image_url(request, item["image_path"]),
            }
        )

    storefront_images = [item["image_path"] for item in storefront_items]

    return ShopRead(
        id=str(shop.id),
        name=shop.name,
        photo=to_public_image_url(request, shop.photo) if shop.photo else "",
        location=shop.location,
        latitude=shop.latitude,
        longitude=shop.longitude,
        description=shop.description,
        storefront_items=storefront_items,
        storefront_images=storefront_images,
        storefront_image=storefront_images[0] if storefront_images else "",
        business_card_image=to_public_image_url(request, shop.business_card_image)
        if shop.business_card_image
        else "",
        seller_wechat=shop.seller_wechat,
        seller_wechat_link=shop.seller_wechat_link,
        products_count=products_count,
        created_at=shop.created_at,
    )


def serialize_product(request: Request, product: Product, shop_name: str = "") -> ProductRead:
    return ProductRead(
        id=str(product.id),
        shop_id=str(product.shop_id or ""),
        shop_name=shop_name,
        images=[to_public_image_url(request, image) for image in product.images],
        article=product.article,
        amount=product.amount,
        quantity=product.quantity,
        supplier_share_percent=float(product.supplier_share_percent),
        supplier_share_amount=float(product.supplier_share_amount),
        unit_price_with_share=float(product.unit_price_with_share),
        color=product.color,
        material=product.material,
        size=product.size,
        measurements=product.measurements,
        status=product.status,
        is_favorite=product.is_favorite,
        created_at=product.created_at,
    )


def serialize_expense(expense: Expense) -> ExpenseRead:
    return ExpenseRead(
        id=str(expense.id),
        title=expense.title,
        amount=expense.amount,
        note=expense.note,
        created_at=expense.created_at,
    )


def delete_uploaded_image(image_path: str) -> None:
    normalized_path = normalize_image_path(image_path)

    if not normalized_path.startswith("/uploads/"):
        return

    file_path = BASE_DIR / normalized_path.removeprefix("/")

    if file_path.exists():
        file_path.unlink()


def collect_referenced_images(db: Session) -> set[str]:
    referenced_images: set[str] = set()

    for shop in db.scalars(select(Shop)).all():
        if shop.photo:
            referenced_images.add(normalize_image_path(shop.photo))

        if shop.business_card_image:
            referenced_images.add(normalize_image_path(shop.business_card_image))

        for image in get_shop_storefront_images(shop):
            referenced_images.add(normalize_image_path(image))

    for product in db.scalars(select(Product)).all():
        for image in product.images or []:
            referenced_images.add(normalize_image_path(image))

    return referenced_images


def remove_unused_uploaded_images(db: Session, image_paths: list[str]) -> None:
    pending_images = {
        normalize_image_path(image_path)
        for image_path in image_paths
        if normalize_image_path(image_path).startswith("/uploads/")
    }

    if not pending_images:
        return

    referenced_images = collect_referenced_images(db)

    for image_path in pending_images - referenced_images:
        delete_uploaded_image(image_path)


def parse_amount_value(raw_value: str) -> float | None:
    normalized = re.sub(r"[^0-9.,]", "", raw_value.strip()).replace(",", ".")

    if not normalized:
        return None

    if not re.fullmatch(r"[0-9]+(?:\.[0-9]+)?", normalized):
        return None

    return float(normalized)


def calculate_product_pricing(
    amount: str,
    quantity: int,
    supplier_share_percent: float = SUPPLIER_SHARE_PERCENT,
) -> tuple[float, float, float]:
    unit_price = parse_amount_value(amount)
    if unit_price is None:
        return supplier_share_percent, 0.0, 0.0

    safe_quantity = max(1, quantity)
    gross_total = unit_price * safe_quantity
    supplier_share_amount = gross_total * (supplier_share_percent / 100.0)
    supplier_share_per_unit = supplier_share_amount / safe_quantity
    unit_price_with_share = unit_price + supplier_share_per_unit
    return supplier_share_percent, supplier_share_amount, unit_price_with_share


def resolve_product_pricing(
    amount: str,
    quantity: int,
    supplier_share_percent: float | None = None,
) -> tuple[float, float, float]:
    share_percent = (
        float(supplier_share_percent)
        if supplier_share_percent is not None
        else SUPPLIER_SHARE_PERCENT
    )
    return calculate_product_pricing(amount, quantity, share_percent)


def backfill_supplier_share_values(db: Session) -> None:
    products = list(db.scalars(select(Product)).all())
    changed = False

    for product in products:
        share_percent = (
            float(product.supplier_share_percent)
            if product.supplier_share_percent is not None
            else SUPPLIER_SHARE_PERCENT
        )
        resolved_percent, share_amount, unit_price_with_share = calculate_product_pricing(
            product.amount,
            product.quantity,
            share_percent,
        )

        if (
            float(product.supplier_share_percent) != resolved_percent
            or float(product.supplier_share_amount) != share_amount
            or float(product.unit_price_with_share) != unit_price_with_share
        ):
            product.supplier_share_percent = resolved_percent
            product.supplier_share_amount = share_amount
            product.unit_price_with_share = unit_price_with_share
            changed = True

    if changed:
        db.commit()


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
    ensure_shop_columns()

    with SessionLocal() as db:
        ensure_profile(db)
        ensure_existing_products_have_shop(db)
        backfill_supplier_share_values(db)

    yield


app = FastAPI(title="Azaly Trade API", version="0.7.0", lifespan=lifespan)

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
    storefront_items = resolve_storefront_items(payload)
    storefront_images = [item["image_path"] for item in storefront_items]

    shop = Shop(
        name=normalize_shop_name(payload.name),
        photo=normalize_image_path(payload.photo.strip()),
        location=payload.location.strip(),
        latitude=payload.latitude,
        longitude=payload.longitude,
        description=payload.description.strip(),
        storefront_items=storefront_items,
        storefront_images=storefront_images,
        storefront_image=storefront_images[0] if storefront_images else "",
        business_card_image=normalize_image_path(payload.business_card_image.strip())
        if payload.business_card_image.strip()
        else "",
        seller_wechat=payload.seller_wechat.strip(),
        seller_wechat_link=payload.seller_wechat_link.strip(),
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
    new_storefront_items = resolve_storefront_items(payload)
    new_storefront_images = [item["image_path"] for item in new_storefront_items]
    new_storefront = new_storefront_images[0] if new_storefront_images else ""
    new_business_card = (
        normalize_image_path(payload.business_card_image.strip())
        if payload.business_card_image.strip()
        else ""
    )
    removed_images: list[str] = []

    if shop.photo and shop.photo != new_photo:
        removed_images.append(shop.photo)

    for image in get_shop_storefront_images(shop):
        if image not in new_storefront_images:
            removed_images.append(image)

    if shop.business_card_image and shop.business_card_image != new_business_card:
        removed_images.append(shop.business_card_image)

    shop.name = normalize_shop_name(payload.name)
    shop.photo = new_photo
    shop.location = payload.location.strip()
    shop.latitude = payload.latitude
    shop.longitude = payload.longitude
    shop.description = payload.description.strip()
    shop.storefront_items = new_storefront_items
    shop.storefront_images = new_storefront_images
    shop.storefront_image = new_storefront
    shop.business_card_image = new_business_card
    shop.seller_wechat = payload.seller_wechat.strip()
    shop.seller_wechat_link = payload.seller_wechat_link.strip()

    db.commit()
    db.refresh(shop)

    remove_unused_uploaded_images(db, removed_images)

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

    images_to_delete.extend(get_shop_storefront_images(shop))

    for product in products:
        images_to_delete.extend(product.images)
        db.delete(product)

    db.delete(shop)
    db.commit()

    remove_unused_uploaded_images(db, images_to_delete)


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
    share_percent, share_amount, unit_price_with_share = resolve_product_pricing(
        payload.amount,
        payload.quantity,
        payload.supplier_share_percent,
    )

    product = Product(
        shop_id=shop.id,
        images=[normalize_image_path(image) for image in payload.images],
        article=payload.article.strip(),
        amount=payload.amount.strip(),
        quantity=max(1, payload.quantity),
        supplier_share_percent=share_percent,
        supplier_share_amount=share_amount,
        unit_price_with_share=unit_price_with_share,
        color=payload.color.strip(),
        material=payload.material.strip(),
        size=payload.size.strip(),
        measurements=payload.measurements.strip(),
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
    share_percent, share_amount, unit_price_with_share = resolve_product_pricing(
        payload.amount,
        payload.quantity,
        payload.supplier_share_percent
        if payload.supplier_share_percent is not None
        else float(product.supplier_share_percent),
    )

    product.shop_id = shop.id
    product.images = normalized_images
    product.article = payload.article.strip()
    product.amount = payload.amount.strip()
    product.quantity = max(1, payload.quantity)
    product.supplier_share_percent = share_percent
    product.supplier_share_amount = share_amount
    product.unit_price_with_share = unit_price_with_share
    product.color = payload.color.strip()
    product.material = payload.material.strip()
    product.size = payload.size.strip()
    product.measurements = payload.measurements.strip()
    product.is_favorite = payload.is_favorite

    db.commit()
    db.refresh(product)

    remove_unused_uploaded_images(db, removed_images)

    return serialize_product(request, product, shop.name)


@app.delete("/products/{product_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_product(product_id: int, db: Session = Depends(get_db)) -> None:
    product = db.get(Product, product_id)

    if product is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found.")

    product_images = list(product.images)
    db.delete(product)
    db.commit()

    remove_unused_uploaded_images(db, product_images)


@app.get("/expenses", response_model=list[ExpenseRead])
def list_expenses(db: Session = Depends(get_db)) -> list[ExpenseRead]:
    expenses = list(db.scalars(select(Expense).order_by(Expense.created_at.desc())).all())
    return [serialize_expense(expense) for expense in expenses]


@app.post("/expenses", response_model=ExpenseRead, status_code=status.HTTP_201_CREATED)
def create_expense(payload: ExpenseCreate, db: Session = Depends(get_db)) -> ExpenseRead:
    expense = Expense(
        title=payload.title.strip(),
        amount=payload.amount.strip(),
        note=payload.note.strip(),
    )
    db.add(expense)
    db.commit()
    db.refresh(expense)
    return serialize_expense(expense)


@app.put("/expenses/{expense_id}", response_model=ExpenseRead)
def update_expense(
    expense_id: int,
    payload: ExpenseUpdate,
    db: Session = Depends(get_db),
) -> ExpenseRead:
    expense = db.get(Expense, expense_id)

    if expense is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Expense not found.")

    expense.title = payload.title.strip()
    expense.amount = payload.amount.strip()
    expense.note = payload.note.strip()

    db.commit()
    db.refresh(expense)
    return serialize_expense(expense)


@app.delete("/expenses/{expense_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_expense(expense_id: int, db: Session = Depends(get_db)) -> None:
    expense = db.get(Expense, expense_id)

    if expense is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Expense not found.")

    db.delete(expense)
    db.commit()


@app.get("/", include_in_schema=False)
def serve_frontend_root() -> FileResponse:
    if not FRONTEND_INDEX.is_file():
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Frontend build not found.",
        )

    return frontend_file_response(FRONTEND_INDEX)


@app.get("/{full_path:path}", include_in_schema=False)
def serve_frontend(full_path: str) -> FileResponse:
    if not FRONTEND_INDEX.is_file():
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Frontend build not found.",
        )

    cleaned_path = full_path.strip("/")

    if cleaned_path:
        asset = resolve_frontend_asset(cleaned_path)

        if asset is not None:
            return frontend_file_response(asset)

        if is_reserved_backend_path(cleaned_path):
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Route not found.",
            )

    return frontend_file_response(FRONTEND_INDEX)
