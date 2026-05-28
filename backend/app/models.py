from datetime import datetime

from sqlalchemy import JSON, Boolean, DateTime, Float, ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from .database import Base


class Profile(Base):
    __tablename__ = "profiles"

    id: Mapped[int] = mapped_column(primary_key=True, default=1)
    name: Mapped[str] = mapped_column(String(100), default="Azaly Trade")
    usd_to_cny: Mapped[float] = mapped_column(Float, default=0.0)
    usd_to_uzs: Mapped[float] = mapped_column(Float, default=0.0)


class Shop(Base):
    __tablename__ = "shops"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(String(120), default="")
    photo: Mapped[str] = mapped_column(String(255), default="")
    location: Mapped[str] = mapped_column(String(255), default="")
    latitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    longitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    description: Mapped[str] = mapped_column(Text, default="")
    storefront_items: Mapped[list[dict[str, object]]] = mapped_column(JSON, default=list)
    storefront_images: Mapped[list[str]] = mapped_column(JSON, default=list)
    storefront_image: Mapped[str] = mapped_column(String(255), default="")
    business_card_image: Mapped[str] = mapped_column(String(255), default="")
    seller_wechat: Mapped[str] = mapped_column(String(255), default="")
    seller_wechat_link: Mapped[str] = mapped_column(String(1024), default="")
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)


class Batch(Base):
    __tablename__ = "batches"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(String(140), default="")
    note: Mapped[str] = mapped_column(Text, default="")
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)


class Product(Base):
    __tablename__ = "products"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    shop_id: Mapped[int | None] = mapped_column(ForeignKey("shops.id"), nullable=True)
    batch_id: Mapped[int | None] = mapped_column(ForeignKey("batches.id"), nullable=True)
    batch_item_type: Mapped[str] = mapped_column(String(32), default="regular")
    images: Mapped[list[str]] = mapped_column(JSON, default=list)
    article: Mapped[str] = mapped_column(String(120), default="")
    amount: Mapped[str] = mapped_column(String(120), default="")
    quantity: Mapped[int] = mapped_column(default=1)
    supplier_share_percent: Mapped[float] = mapped_column(Float, default=10.0)
    supplier_share_amount: Mapped[float] = mapped_column(Float, default=0.0)
    unit_price_with_share: Mapped[float] = mapped_column(Float, default=0.0)
    allocated_expense_per_unit_cny: Mapped[float] = mapped_column(Float, default=0.0)
    final_unit_cost_cny: Mapped[float] = mapped_column(Float, default=0.0)
    final_unit_cost_usd: Mapped[float] = mapped_column(Float, default=0.0)
    final_unit_cost_uzs: Mapped[float] = mapped_column(Float, default=0.0)
    usd_to_cny_rate: Mapped[float] = mapped_column(Float, default=0.0)
    usd_to_uzs_rate: Mapped[float] = mapped_column(Float, default=0.0)
    color: Mapped[str] = mapped_column(String(80), default="")
    material: Mapped[str] = mapped_column(String(120), default="")
    size: Mapped[str] = mapped_column(String(120), default="")
    measurements: Mapped[str] = mapped_column(String(160), default="")
    status: Mapped[str] = mapped_column(String(32), default="new")
    is_favorite: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)


class Expense(Base):
    __tablename__ = "expenses"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    title: Mapped[str] = mapped_column(String(140), default="")
    accounting_type: Mapped[str] = mapped_column(String(32), default="not_selected")
    accounting_channel: Mapped[str] = mapped_column(String(32), default="not_selected")
    currency: Mapped[str] = mapped_column(String(8), default="CNY")
    amount: Mapped[str] = mapped_column(String(120), default="")
    amount_cny: Mapped[float] = mapped_column(Float, default=0.0)
    amount_usd: Mapped[float] = mapped_column(Float, default=0.0)
    amount_uzs: Mapped[float] = mapped_column(Float, default=0.0)
    usd_to_cny_rate: Mapped[float] = mapped_column(Float, default=0.0)
    usd_to_uzs_rate: Mapped[float] = mapped_column(Float, default=0.0)
    note: Mapped[str] = mapped_column(Text, default="")
    batch_id: Mapped[int | None] = mapped_column(ForeignKey("batches.id"), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
