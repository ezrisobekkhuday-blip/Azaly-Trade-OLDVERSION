from contextlib import asynccontextmanager
from pathlib import Path
from shutil import copyfileobj
from uuid import uuid4

from fastapi import Depends, FastAPI, File, HTTPException, Request, UploadFile, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy import inspect, select, text
from sqlalchemy.orm import Session

from .database import Base, SessionLocal, engine, get_db
from .models import Product, Profile
from .schemas import (
    HealthResponse,
    ProductCreate,
    ProductRead,
    ProductUpdate,
    ProfileRead,
    ProfileUpdate,
)

BASE_DIR = Path(__file__).resolve().parent.parent
UPLOADS_DIR = BASE_DIR / "uploads"


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


def to_public_image_url(request: Request, image_path: str) -> str:
    if image_path.startswith("http://") or image_path.startswith("https://"):
        return image_path

    if image_path.startswith("/uploads/"):
        return f"{str(request.base_url).rstrip('/')}{image_path}"

    return image_path


def serialize_product(request: Request, product: Product) -> ProductRead:
    return ProductRead(
      id=str(product.id),
      images=[to_public_image_url(request, image) for image in product.images],
      amount=product.amount,
      material=product.material,
      size=product.size,
      status=product.status,
      is_favorite=product.is_favorite,
      created_at=product.created_at,
    )


def delete_uploaded_image(image_path: str) -> None:
    if not image_path.startswith("/uploads/"):
        return

    file_path = BASE_DIR / image_path.removeprefix("/")

    if file_path.exists():
        file_path.unlink()


def validate_product_images(images: list[str]) -> None:
    if not images:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="At least one image is required.")


@asynccontextmanager
async def lifespan(_: FastAPI):
    UPLOADS_DIR.mkdir(parents=True, exist_ok=True)
    Base.metadata.create_all(bind=engine)
    ensure_product_columns()

    with SessionLocal() as db:
        ensure_profile(db)

    yield


app = FastAPI(title="Azaly Trade API", version="0.2.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount("/uploads", StaticFiles(directory=UPLOADS_DIR), name="uploads")


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


@app.get("/products", response_model=list[ProductRead])
def list_products(request: Request, db: Session = Depends(get_db)) -> list[ProductRead]:
    statement = select(Product).order_by(Product.created_at.desc())
    products = list(db.scalars(statement).all())
    return [serialize_product(request, product) for product in products]


@app.post("/products", response_model=ProductRead, status_code=status.HTTP_201_CREATED)
def create_product(
    request: Request,
    payload: ProductCreate,
    db: Session = Depends(get_db),
) -> ProductRead:
    validate_product_images(payload.images)

    product = Product(
        images=payload.images,
        amount=payload.amount.strip(),
        material=payload.material.strip(),
        size=payload.size.strip(),
        status="new",
        is_favorite=payload.is_favorite,
    )
    db.add(product)
    db.commit()
    db.refresh(product)
    return serialize_product(request, product)


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

    removed_images = [image for image in product.images if image not in payload.images]

    product.images = payload.images
    product.amount = payload.amount.strip()
    product.material = payload.material.strip()
    product.size = payload.size.strip()
    product.is_favorite = payload.is_favorite

    db.commit()
    db.refresh(product)

    for image in removed_images:
        delete_uploaded_image(image)

    return serialize_product(request, product)


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
