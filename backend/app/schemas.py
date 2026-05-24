from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class HealthResponse(BaseModel):
    status: str


class ProfileRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    name: str


class ProfileUpdate(BaseModel):
    name: str = Field(min_length=1, max_length=100)


class StorefrontItemPayload(BaseModel):
    image_path: str = Field(min_length=1)
    amount: str = ""
    color: str = ""
    material: str = ""
    size: str = ""
    measurements: str = ""
    is_favorite: bool = False


class ShopCreate(BaseModel):
    name: str = Field(default="", max_length=120)
    photo: str = Field(min_length=1)
    location: str = Field(default="", max_length=255)
    latitude: float | None = None
    longitude: float | None = None
    description: str = ""
    storefront_items: list[StorefrontItemPayload] = Field(default_factory=list)
    storefront_images: list[str] = Field(default_factory=list)
    storefront_image: str = ""
    business_card_image: str = ""
    seller_wechat: str = ""
    seller_wechat_link: str = ""


class ShopUpdate(BaseModel):
    name: str = Field(default="", max_length=120)
    photo: str = Field(min_length=1)
    location: str = Field(default="", max_length=255)
    latitude: float | None = None
    longitude: float | None = None
    description: str = ""
    storefront_items: list[StorefrontItemPayload] = Field(default_factory=list)
    storefront_images: list[str] = Field(default_factory=list)
    storefront_image: str = ""
    business_card_image: str = ""
    seller_wechat: str = ""
    seller_wechat_link: str = ""


class ShopRead(BaseModel):
    id: str
    name: str
    photo: str
    location: str
    latitude: float | None
    longitude: float | None
    description: str
    storefront_items: list[StorefrontItemPayload]
    storefront_images: list[str]
    storefront_image: str
    business_card_image: str
    seller_wechat: str
    seller_wechat_link: str
    products_count: int
    created_at: datetime


class ProductCreate(BaseModel):
    shop_id: int
    images: list[str] = Field(default_factory=list)
    article: str = ""
    amount: str = ""
    quantity: int = Field(default=1, ge=1)
    supplier_share_percent: float | None = None
    color: str = ""
    material: str = ""
    size: str = ""
    measurements: str = ""
    is_favorite: bool = False


class ProductUpdate(BaseModel):
    shop_id: int
    images: list[str] = Field(default_factory=list)
    article: str = ""
    amount: str = ""
    quantity: int = Field(default=1, ge=1)
    supplier_share_percent: float | None = None
    color: str = ""
    material: str = ""
    size: str = ""
    measurements: str = ""
    is_favorite: bool = False


class ProductRead(BaseModel):
    id: str
    shop_id: str
    shop_name: str
    images: list[str]
    article: str
    amount: str
    quantity: int
    supplier_share_percent: float
    supplier_share_amount: float
    unit_price_with_share: float
    color: str
    material: str
    size: str
    measurements: str
    status: str
    is_favorite: bool
    created_at: datetime


class ExpenseCreate(BaseModel):
    title: str = Field(min_length=1, max_length=140)
    amount: str = Field(min_length=1, max_length=120)
    note: str = ""


class ExpenseUpdate(BaseModel):
    title: str = Field(min_length=1, max_length=140)
    amount: str = Field(min_length=1, max_length=120)
    note: str = ""


class ExpenseRead(BaseModel):
    id: str
    title: str
    amount: str
    note: str
    created_at: datetime
