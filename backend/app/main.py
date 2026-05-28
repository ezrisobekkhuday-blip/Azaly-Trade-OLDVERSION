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
from .models import Batch, Expense, Product, Profile, Shop
from .schemas import (
    BatchAddProducts,
    BatchCreate,
    BatchRead,
    BatchUpdate,
    ExpenseBatchAssignmentUpdate,
    ExpenseCreate,
    ExpenseRead,
    ExpenseUpdate,
    HealthResponse,
    ProductBatchItemTypeUpdate,
    ProductBatchMembershipUpdate,
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


def ensure_expense_columns() -> None:
    inspector = inspect(engine)

    if "expenses" not in inspector.get_table_names():
        return

    columns = {column["name"] for column in inspector.get_columns("expenses")}

    with engine.begin() as connection:
        if "amount_cny" not in columns:
            connection.execute(
                text("ALTER TABLE expenses ADD COLUMN amount_cny FLOAT DEFAULT 0.0 NOT NULL")
            )

        if "amount_usd" not in columns:
            connection.execute(
                text("ALTER TABLE expenses ADD COLUMN amount_usd FLOAT DEFAULT 0.0 NOT NULL")
            )

        if "amount_uzs" not in columns:
            connection.execute(
                text("ALTER TABLE expenses ADD COLUMN amount_uzs FLOAT DEFAULT 0.0 NOT NULL")
            )

        if "cny_to_usd_rate" not in columns:
            connection.execute(
                text(
                    "ALTER TABLE expenses ADD COLUMN cny_to_usd_rate FLOAT DEFAULT 0.0 NOT NULL"
                )
            )

        if "usd_to_cny_rate" not in columns:
            connection.execute(
                text(
                    "ALTER TABLE expenses ADD COLUMN usd_to_cny_rate FLOAT DEFAULT 0.0 NOT NULL"
                )
            )

        if "cny_to_usd_rate" in columns:
            connection.execute(
                text(
                    """
                    UPDATE expenses
                    SET usd_to_cny_rate = CASE
                        WHEN usd_to_cny_rate > 0 THEN usd_to_cny_rate
                        WHEN cny_to_usd_rate > 0 AND cny_to_usd_rate < 2 THEN 1.0 / cny_to_usd_rate
                        WHEN cny_to_usd_rate >= 2 THEN cny_to_usd_rate
                        ELSE 0
                    END
                    """
                )
            )

        if "usd_to_uzs_rate" not in columns:
            connection.execute(
                text(
                    "ALTER TABLE expenses ADD COLUMN usd_to_uzs_rate FLOAT DEFAULT 0.0 NOT NULL"
                )
            )

        if "accounting_type" not in columns:
            connection.execute(
                text(
                    "ALTER TABLE expenses ADD COLUMN accounting_type "
                    "VARCHAR(32) DEFAULT 'not_selected' NOT NULL"
                )
            )

        if "accounting_channel" not in columns:
            connection.execute(
                text(
                    "ALTER TABLE expenses ADD COLUMN accounting_channel "
                    "VARCHAR(32) DEFAULT 'not_selected' NOT NULL"
                )
            )

        if "currency" not in columns:
            connection.execute(
                text(
                    "ALTER TABLE expenses ADD COLUMN currency "
                    "VARCHAR(8) DEFAULT 'CNY' NOT NULL"
                )
            )

        if "batch_id" not in columns:
            connection.execute(text("ALTER TABLE expenses ADD COLUMN batch_id INTEGER"))


def normalize_expense_accounting_type(value: str | None) -> str:
    normalized = (value or "").strip().lower()
    if normalized in {"product", "personal", "not_selected"}:
        return normalized
    return "not_selected"


def normalize_expense_accounting_channel(value: str | None) -> str:
    normalized = (value or "").strip().lower()
    if normalized in {"dk", "pocket", "not_selected"}:
        return normalized
    return "not_selected"


def normalize_expense_currency(value: str | None) -> str:
    normalized = (value or "CNY").strip().upper()
    if normalized in {"CNY", "USD", "UZS"}:
        return normalized
    return "CNY"


def ensure_profile_columns() -> None:
    inspector = inspect(engine)

    if "profiles" not in inspector.get_table_names():
        return

    columns = {column["name"] for column in inspector.get_columns("profiles")}

    with engine.begin() as connection:
        if "cny_to_usd" not in columns:
            connection.execute(
                text("ALTER TABLE profiles ADD COLUMN cny_to_usd FLOAT DEFAULT 0.0 NOT NULL")
            )

        if "usd_to_cny" not in columns:
            connection.execute(
                text("ALTER TABLE profiles ADD COLUMN usd_to_cny FLOAT DEFAULT 0.0 NOT NULL")
            )

        if "cny_to_usd" in columns:
            connection.execute(
                text(
                    """
                    UPDATE profiles
                    SET usd_to_cny = CASE
                        WHEN usd_to_cny > 0 THEN usd_to_cny
                        WHEN cny_to_usd > 0 AND cny_to_usd < 2 THEN 1.0 / cny_to_usd
                        WHEN cny_to_usd >= 2 THEN cny_to_usd
                        ELSE 0
                    END
                    """
                )
            )

        if "usd_to_uzs" not in columns:
            connection.execute(
                text("ALTER TABLE profiles ADD COLUMN usd_to_uzs FLOAT DEFAULT 0.0 NOT NULL")
            )


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

        if "batch_id" not in columns:
            connection.execute(text("ALTER TABLE products ADD COLUMN batch_id INTEGER"))

        if "batch_item_type" not in columns:
            connection.execute(
                text(
                    "ALTER TABLE products ADD COLUMN batch_item_type VARCHAR(32) DEFAULT 'regular' NOT NULL"
                )
            )
            connection.execute(
                text("UPDATE products SET batch_item_type = 'regular' WHERE batch_item_type IS NULL")
            )

        if "allocated_expense_per_unit_cny" not in columns:
            connection.execute(
                text(
                    "ALTER TABLE products ADD COLUMN allocated_expense_per_unit_cny "
                    "FLOAT DEFAULT 0.0 NOT NULL"
                )
            )

        if "final_unit_cost_cny" not in columns:
            connection.execute(
                text(
                    "ALTER TABLE products ADD COLUMN final_unit_cost_cny FLOAT DEFAULT 0.0 NOT NULL"
                )
            )

        if "final_unit_cost_usd" not in columns:
            connection.execute(
                text(
                    "ALTER TABLE products ADD COLUMN final_unit_cost_usd FLOAT DEFAULT 0.0 NOT NULL"
                )
            )

        if "final_unit_cost_uzs" not in columns:
            connection.execute(
                text(
                    "ALTER TABLE products ADD COLUMN final_unit_cost_uzs FLOAT DEFAULT 0.0 NOT NULL"
                )
            )

        added_product_rate_columns = False

        if "usd_to_cny_rate" not in columns:
            connection.execute(
                text(
                    "ALTER TABLE products ADD COLUMN usd_to_cny_rate FLOAT DEFAULT 0.0 NOT NULL"
                )
            )
            added_product_rate_columns = True

        if "usd_to_uzs_rate" not in columns:
            connection.execute(
                text(
                    "ALTER TABLE products ADD COLUMN usd_to_uzs_rate FLOAT DEFAULT 0.0 NOT NULL"
                )
            )
            added_product_rate_columns = True

        if added_product_rate_columns:
            connection.execute(
                text(
                    """
                    UPDATE products
                    SET
                        usd_to_cny_rate = (
                            SELECT usd_to_cny FROM profiles WHERE id = 1
                        ),
                        usd_to_uzs_rate = (
                            SELECT usd_to_uzs FROM profiles WHERE id = 1
                        )
                    WHERE
                        (usd_to_cny_rate <= 0 OR usd_to_uzs_rate <= 0)
                        AND EXISTS (
                            SELECT 1 FROM profiles WHERE id = 1 AND usd_to_cny > 0
                        )
                    """
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
        "batches",
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


VALID_BATCH_ITEM_TYPES = {"regular", "order"}


def read_batch_item_type(product: Product) -> str:
    normalized = (getattr(product, "batch_item_type", None) or "regular").strip().lower()

    if normalized in VALID_BATCH_ITEM_TYPES:
        return normalized

    return "regular"


def read_product_usd_to_cny_rate(product: Product) -> float:
    rate = float(getattr(product, "usd_to_cny_rate", 0.0) or 0.0)
    return rate if rate > 0 else 0.0


def read_product_usd_to_uzs_rate(product: Product) -> float:
    rate = float(getattr(product, "usd_to_uzs_rate", 0.0) or 0.0)
    return rate if rate > 0 else 0.0


def normalize_batch_item_type(value: str | None) -> str:
    normalized = (value or "regular").strip().lower()

    if normalized not in VALID_BATCH_ITEM_TYPES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="batch_item_type must be regular or order.",
        )

    return normalized


def serialize_product(request: Request, product: Product, shop_name: str = "") -> ProductRead:
    return ProductRead(
        id=str(product.id),
        shop_id=str(product.shop_id or ""),
        shop_name=shop_name,
        batch_id=str(product.batch_id) if product.batch_id is not None else None,
        batch_item_type=read_batch_item_type(product),
        images=[to_public_image_url(request, image) for image in product.images],
        article=product.article,
        amount=product.amount,
        quantity=product.quantity,
        supplier_share_percent=float(product.supplier_share_percent),
        supplier_share_amount=float(product.supplier_share_amount),
        unit_price_with_share=float(product.unit_price_with_share),
        allocated_expense_per_unit_cny=float(
            getattr(product, "allocated_expense_per_unit_cny", 0.0) or 0.0
        ),
        final_unit_cost_cny=float(
            getattr(product, "final_unit_cost_cny", 0.0) or product.unit_price_with_share
        ),
        final_unit_cost_usd=float(getattr(product, "final_unit_cost_usd", 0.0) or 0.0),
        final_unit_cost_uzs=float(getattr(product, "final_unit_cost_uzs", 0.0) or 0.0),
        usd_to_cny_rate=read_product_usd_to_cny_rate(product),
        usd_to_uzs_rate=read_product_usd_to_uzs_rate(product),
        color=product.color,
        material=product.material,
        size=product.size,
        measurements=product.measurements,
        status=product.status,
        is_favorite=product.is_favorite,
        created_at=product.created_at,
    )


def serialize_batch(
    request: Request,
    batch: Batch,
    products: list[Product],
    shop_names: dict[int, str],
) -> BatchRead:
    return BatchRead(
        id=str(batch.id),
        name=batch.name,
        note=batch.note,
        created_at=batch.created_at,
        products=[
            serialize_product(
                request,
                product,
                shop_names.get(product.shop_id or 0, ""),
            )
            for product in products
        ],
    )


def get_batch_or_404(batch_id: int, db: Session) -> Batch:
    batch = db.get(Batch, batch_id)

    if batch is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Batch not found.")

    return batch


def normalize_product_ids(product_ids: list[int]) -> list[int]:
    unique_product_ids: list[int] = []
    seen_ids: set[int] = set()

    for raw_id in product_ids:
        product_id = int(raw_id)
        if product_id in seen_ids:
            continue
        seen_ids.add(product_id)
        unique_product_ids.append(product_id)

    return unique_product_ids


def load_products_for_batch_assignment(
    product_ids: list[int],
    db: Session,
    *,
    target_batch_id: int | None = None,
) -> list[Product]:
    unique_product_ids = normalize_product_ids(product_ids)

    if not unique_product_ids:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="At least one product must be selected.",
        )

    products: list[Product] = []

    for product_id in unique_product_ids:
        product = db.get(Product, product_id)

        if product is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Product {product_id} not found.",
            )

        if product.batch_id is not None and product.batch_id != target_batch_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Товар уже находится в партии.",
            )

        products.append(product)

    return products


def calculate_expense_amounts(
    amount_raw: str,
    currency: str,
    usd_to_cny_rate: float,
    usd_to_uzs_rate: float,
) -> tuple[float, float, float, float, float]:
    amount_value = parse_amount_value(amount_raw) or 0.0
    safe_usd_to_cny = max(0.0, float(usd_to_cny_rate))
    safe_usd_to_uzs = max(0.0, float(usd_to_uzs_rate))
    normalized_currency = normalize_expense_currency(currency)

    if normalized_currency == "USD":
        amount_usd = amount_value
        amount_cny = amount_usd * safe_usd_to_cny
        amount_uzs = amount_usd * safe_usd_to_uzs
    elif normalized_currency == "UZS":
        amount_uzs = amount_value
        amount_usd = amount_uzs / safe_usd_to_uzs if safe_usd_to_uzs > 0 else 0.0
        amount_cny = amount_usd * safe_usd_to_cny
    else:
        amount_cny = amount_value
        amount_usd = amount_cny / safe_usd_to_cny if safe_usd_to_cny > 0 else 0.0
        amount_uzs = amount_usd * safe_usd_to_uzs

    return amount_cny, amount_usd, amount_uzs, safe_usd_to_cny, safe_usd_to_uzs


def apply_expense_fields(
    expense: Expense,
    *,
    title: str,
    amount_raw: str,
    note: str,
    accounting_type: str,
    accounting_channel: str,
    currency: str,
    usd_to_cny_rate: float,
    usd_to_uzs_rate: float,
) -> None:
    expense.title = title.strip()
    expense.note = note.strip()
    expense.accounting_type = normalize_expense_accounting_type(accounting_type)
    expense.accounting_channel = normalize_expense_accounting_channel(accounting_channel)
    expense.currency = normalize_expense_currency(currency)
    amount_cny, amount_usd, amount_uzs, cny_rate, uzs_rate = calculate_expense_amounts(
        amount_raw,
        expense.currency,
        usd_to_cny_rate,
        usd_to_uzs_rate,
    )
    expense.amount = amount_raw.strip()
    expense.amount_cny = amount_cny
    expense.amount_usd = amount_usd
    expense.amount_uzs = amount_uzs
    expense.usd_to_cny_rate = cny_rate
    expense.usd_to_uzs_rate = uzs_rate


def backfill_expense_metadata(db: Session) -> None:
    expenses = list(db.scalars(select(Expense)).all())
    changed = False

    for expense in expenses:
        normalized_type = normalize_expense_accounting_type(expense.accounting_type)
        normalized_channel = normalize_expense_accounting_channel(
            expense.accounting_channel
        )
        normalized_currency = normalize_expense_currency(expense.currency)

        if (
            expense.accounting_type != normalized_type
            or expense.accounting_channel != normalized_channel
            or expense.currency != normalized_currency
        ):
            expense.accounting_type = normalized_type
            expense.accounting_channel = normalized_channel
            expense.currency = normalized_currency
            changed = True

    if changed:
        db.commit()


def backfill_expense_currency_values(db: Session) -> None:
    profile = ensure_profile(db)
    expenses = list(db.scalars(select(Expense)).all())
    changed = False

    for expense in expenses:
        amount_cny, amount_usd, amount_uzs, cny_rate, uzs_rate = calculate_expense_amounts(
            expense.amount,
            expense.currency,
            float(expense.usd_to_cny_rate)
            if expense.usd_to_cny_rate is not None and float(expense.usd_to_cny_rate) > 0
            else float(profile.usd_to_cny),
            float(expense.usd_to_uzs_rate)
            if expense.usd_to_uzs_rate is not None and float(expense.usd_to_uzs_rate) > 0
            else float(profile.usd_to_uzs),
        )

        if (
            float(expense.amount_cny) != amount_cny
            or float(expense.amount_usd) != amount_usd
            or float(expense.amount_uzs) != amount_uzs
            or float(expense.usd_to_cny_rate) != cny_rate
            or float(expense.usd_to_uzs_rate) != uzs_rate
        ):
            expense.amount_cny = amount_cny
            expense.amount_usd = amount_usd
            expense.amount_uzs = amount_uzs
            expense.usd_to_cny_rate = cny_rate
            expense.usd_to_uzs_rate = uzs_rate
            changed = True

    if changed:
        db.commit()


def serialize_expense(expense: Expense) -> ExpenseRead:
    return ExpenseRead(
        id=str(expense.id),
        title=expense.title,
        accounting_type=expense.accounting_type,
        accounting_channel=expense.accounting_channel,
        currency=expense.currency,
        amount=expense.amount,
        amount_cny=float(expense.amount_cny),
        amount_usd=float(expense.amount_usd),
        amount_uzs=float(expense.amount_uzs),
        usd_to_cny_rate=float(expense.usd_to_cny_rate),
        usd_to_uzs_rate=float(expense.usd_to_uzs_rate),
        note=expense.note,
        batch_id=str(expense.batch_id) if expense.batch_id is not None else None,
        created_at=expense.created_at,
    )


def recalculate_batch_expense_allocation(
    batch_id: int,
    db: Session,
    *,
    profile: Profile | None = None,
) -> None:
    db.flush()

    expenses = list(
        db.scalars(select(Expense).where(Expense.batch_id == batch_id)).all()
    )
    total_expenses_cny = sum(float(expense.amount_cny) for expense in expenses)

    products = list(
        db.scalars(select(Product).where(Product.batch_id == batch_id)).all()
    )

    regular_products = [
        product
        for product in products
        if read_batch_item_type(product) == "regular"
    ]
    total_regular_quantity = sum(max(1, int(product.quantity)) for product in regular_products)

    expense_per_unit_cny = (
        total_expenses_cny / total_regular_quantity if total_regular_quantity > 0 else 0.0
    )

    for product in products:
        unit_base = float(product.unit_price_with_share)

        if read_batch_item_type(product) == "regular":
            allocated = expense_per_unit_cny
            final_cny = unit_base + allocated
        else:
            allocated = 0.0
            final_cny = unit_base

        product.allocated_expense_per_unit_cny = allocated
        product.final_unit_cost_cny = final_cny
        usd_to_cny = read_product_usd_to_cny_rate(product)
        usd_to_uzs = read_product_usd_to_uzs_rate(product)
        product.final_unit_cost_usd = final_cny / usd_to_cny if usd_to_cny > 0 else 0.0
        product.final_unit_cost_uzs = (
            product.final_unit_cost_usd * usd_to_uzs if usd_to_uzs > 0 else 0.0
        )


def recalculate_batches_for_expense(expense: Expense, db: Session, *, previous_batch_id: int | None = None) -> None:
    profile = ensure_profile(db)
    batch_ids: set[int] = set()

    if previous_batch_id is not None:
        batch_ids.add(previous_batch_id)

    if expense.batch_id is not None:
        batch_ids.add(int(expense.batch_id))

    for batch_id in batch_ids:
        recalculate_batch_expense_allocation(batch_id, db, profile=profile)


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
    ensure_profile_columns()
    ensure_expense_columns()
    ensure_product_columns()
    ensure_shop_columns()

    with SessionLocal() as db:
        ensure_profile(db)
        ensure_existing_products_have_shop(db)
        backfill_supplier_share_values(db)
        backfill_expense_metadata(db)
        backfill_expense_currency_values(db)

    yield


app = FastAPI(title="Azaly Trade API", version="0.8.0", lifespan=lifespan)

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

    if payload.usd_to_cny is not None:
        profile.usd_to_cny = max(0.0, float(payload.usd_to_cny))

    if payload.usd_to_uzs is not None:
        profile.usd_to_uzs = max(0.0, float(payload.usd_to_uzs))

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
    profile = ensure_profile(db)
    usd_to_cny = float(profile.usd_to_cny) if float(profile.usd_to_cny) > 0 else 0.0
    usd_to_uzs = float(profile.usd_to_uzs) if float(profile.usd_to_uzs) > 0 else 0.0

    product = Product(
        shop_id=shop.id,
        images=[normalize_image_path(image) for image in payload.images],
        article=payload.article.strip(),
        amount=payload.amount.strip(),
        quantity=max(1, payload.quantity),
        supplier_share_percent=share_percent,
        supplier_share_amount=share_amount,
        unit_price_with_share=unit_price_with_share,
        usd_to_cny_rate=usd_to_cny,
        usd_to_uzs_rate=usd_to_uzs,
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


@app.patch("/products/{product_id}/batch-item-type", response_model=ProductRead)
def update_product_batch_item_type(
    product_id: int,
    request: Request,
    payload: ProductBatchItemTypeUpdate,
    db: Session = Depends(get_db),
) -> ProductRead:
    product = db.get(Product, product_id)

    if product is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found.")

    if product.batch_id is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Product is not assigned to a batch.",
        )

    product.batch_item_type = normalize_batch_item_type(payload.batch_item_type)

    if product.batch_id is not None:
        recalculate_batch_expense_allocation(product.batch_id, db)

    db.commit()
    db.refresh(product)

    shop_name = ""
    if product.shop_id is not None:
        shop = db.get(Shop, product.shop_id)
        if shop is not None:
            shop_name = shop.name

    return serialize_product(request, product, shop_name)


@app.patch("/products/{product_id}/batch-membership", response_model=ProductRead)
def update_product_batch_membership(
    product_id: int,
    request: Request,
    payload: ProductBatchMembershipUpdate,
    db: Session = Depends(get_db),
) -> ProductRead:
    product = db.get(Product, product_id)

    if product is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found.")

    if payload.batch_id is not None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Use batch assignment endpoints to add products to a batch.",
        )

    if product.batch_id is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Product is not assigned to a batch.",
        )

    previous_batch_id = product.batch_id
    product.batch_id = None
    product.batch_item_type = "regular"
    product.allocated_expense_per_unit_cny = 0.0
    unit_base = float(product.unit_price_with_share)
    product.final_unit_cost_cny = unit_base
    usd_to_cny = read_product_usd_to_cny_rate(product)
    usd_to_uzs = read_product_usd_to_uzs_rate(product)
    product.final_unit_cost_usd = unit_base / usd_to_cny if usd_to_cny > 0 else 0.0
    product.final_unit_cost_uzs = (
        product.final_unit_cost_usd * usd_to_uzs if usd_to_uzs > 0 else 0.0
    )

    recalculate_batch_expense_allocation(previous_batch_id, db)

    db.commit()
    db.refresh(product)

    shop_name = ""
    if product.shop_id is not None:
        shop = db.get(Shop, product.shop_id)
        if shop is not None:
            shop_name = shop.name

    return serialize_product(request, product, shop_name)


@app.delete("/products/{product_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_product(product_id: int, db: Session = Depends(get_db)) -> None:
    product = db.get(Product, product_id)

    if product is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found.")

    product_images = list(product.images)
    db.delete(product)
    db.commit()

    remove_unused_uploaded_images(db, product_images)


@app.get("/batches", response_model=list[BatchRead])
def list_batches(
    request: Request,
    include_products: bool = True,
    db: Session = Depends(get_db),
) -> list[BatchRead]:
    batches = list(db.scalars(select(Batch).order_by(Batch.created_at.desc())).all())
    shop_names = build_shop_name_map(db)
    response: list[BatchRead] = []

    for batch in batches:
        if include_products:
            products = list(
                db.scalars(
                    select(Product)
                    .where(Product.batch_id == batch.id)
                    .order_by(Product.created_at.desc())
                ).all()
            )
        else:
            products = []

        response.append(serialize_batch(request, batch, products, shop_names))

    return response


@app.post("/batches", response_model=BatchRead, status_code=status.HTTP_201_CREATED)
def create_batch(
    payload: BatchCreate,
    request: Request,
    db: Session = Depends(get_db),
) -> BatchRead:
    products = load_products_for_batch_assignment(payload.product_ids, db)

    batch = Batch(name=payload.name.strip(), note=payload.note.strip())
    db.add(batch)
    db.flush()

    for product in products:
        product.batch_id = batch.id

    db.commit()
    db.refresh(batch)
    shop_names = build_shop_name_map(db)
    assigned_products = list(
        db.scalars(
            select(Product)
            .where(Product.batch_id == batch.id)
            .order_by(Product.created_at.desc())
        ).all()
    )
    return serialize_batch(request, batch, assigned_products, shop_names)


@app.post("/batches/{batch_id}/products", response_model=BatchRead)
def add_products_to_batch(
    batch_id: int,
    payload: BatchAddProducts,
    request: Request,
    db: Session = Depends(get_db),
) -> BatchRead:
    batch = get_batch_or_404(batch_id, db)
    products = load_products_for_batch_assignment(
        payload.product_ids,
        db,
        target_batch_id=batch.id,
    )

    for product in products:
        product.batch_id = batch.id

    db.commit()
    db.refresh(batch)
    shop_names = build_shop_name_map(db)
    assigned_products = list(
        db.scalars(
            select(Product)
            .where(Product.batch_id == batch.id)
            .order_by(Product.created_at.desc())
        ).all()
    )
    return serialize_batch(request, batch, assigned_products, shop_names)


@app.put("/batches/{batch_id}", response_model=BatchRead)
def update_batch(
    batch_id: int,
    payload: BatchUpdate,
    request: Request,
    db: Session = Depends(get_db),
) -> BatchRead:
    batch = get_batch_or_404(batch_id, db)
    batch.name = payload.name.strip()
    batch.note = payload.note.strip()
    db.commit()
    db.refresh(batch)

    products = list(
        db.scalars(
            select(Product)
            .where(Product.batch_id == batch.id)
            .order_by(Product.created_at.desc())
        ).all()
    )
    shop_names = build_shop_name_map(db)
    return serialize_batch(request, batch, products, shop_names)


@app.get("/expenses", response_model=list[ExpenseRead])
def list_expenses(db: Session = Depends(get_db)) -> list[ExpenseRead]:
    expenses = list(db.scalars(select(Expense).order_by(Expense.created_at.desc())).all())
    return [serialize_expense(expense) for expense in expenses]


@app.post("/expenses", response_model=ExpenseRead, status_code=status.HTTP_201_CREATED)
def create_expense(payload: ExpenseCreate, db: Session = Depends(get_db)) -> ExpenseRead:
    profile = ensure_profile(db)
    expense = Expense()
    apply_expense_fields(
        expense,
        title=payload.title,
        amount_raw=payload.amount,
        note=payload.note,
        accounting_type=payload.accounting_type,
        accounting_channel=payload.accounting_channel,
        currency=payload.currency,
        usd_to_cny_rate=float(profile.usd_to_cny),
        usd_to_uzs_rate=float(profile.usd_to_uzs),
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

    profile = ensure_profile(db)
    linked_batch_id = expense.batch_id
    apply_expense_fields(
        expense,
        title=payload.title,
        amount_raw=payload.amount,
        note=payload.note,
        accounting_type=payload.accounting_type,
        accounting_channel=payload.accounting_channel,
        currency=payload.currency,
        usd_to_cny_rate=float(profile.usd_to_cny),
        usd_to_uzs_rate=float(profile.usd_to_uzs),
    )

    if linked_batch_id is not None:
        recalculate_batch_expense_allocation(linked_batch_id, db, profile=profile)

    db.commit()
    db.refresh(expense)
    return serialize_expense(expense)


@app.patch("/expenses/{expense_id}/batch-assignment", response_model=ExpenseRead)
def assign_expense_to_batch(
    expense_id: int,
    payload: ExpenseBatchAssignmentUpdate,
    db: Session = Depends(get_db),
) -> ExpenseRead:
    expense = db.get(Expense, expense_id)

    if expense is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Expense not found.")

    previous_batch_id = expense.batch_id
    batch_id_raw = (payload.batch_id or "").strip()

    if not batch_id_raw:
        expense.batch_id = None
        db.flush()

        if previous_batch_id is not None:
            recalculate_batch_expense_allocation(previous_batch_id, db)

        db.commit()
        db.refresh(expense)
        return serialize_expense(expense)

    try:
        batch_id = int(batch_id_raw)
    except ValueError as error:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid batch id.",
        ) from error

    batch = get_batch_or_404(batch_id, db)
    expense.batch_id = batch.id
    db.flush()

    recalculate_batches_for_expense(
        expense,
        db,
        previous_batch_id=previous_batch_id,
    )

    db.commit()
    db.refresh(expense)
    return serialize_expense(expense)


@app.delete("/expenses/{expense_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_expense(expense_id: int, db: Session = Depends(get_db)) -> None:
    expense = db.get(Expense, expense_id)

    if expense is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Expense not found.")

    previous_batch_id = expense.batch_id
    db.delete(expense)
    db.flush()

    if previous_batch_id is not None:
        recalculate_batch_expense_allocation(previous_batch_id, db)

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
