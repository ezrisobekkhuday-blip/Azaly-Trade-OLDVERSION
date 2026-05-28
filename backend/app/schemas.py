from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class HealthResponse(BaseModel):
    status: str


class ProfileRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    name: str
    usd_to_cny: float
    usd_to_uzs: float


class ProfileUpdate(BaseModel):
    name: str = Field(min_length=1, max_length=100)
    usd_to_cny: float | None = None
    usd_to_uzs: float | None = None


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


class ProductBatchItemTypeUpdate(BaseModel):
    batch_item_type: str


class ProductBatchMembershipUpdate(BaseModel):
    batch_id: str | None = None


class ProductRead(BaseModel):
    id: str
    shop_id: str
    shop_name: str
    batch_id: str | None = None
    batch_item_type: str = "regular"
    images: list[str]
    article: str
    amount: str
    quantity: int
    supplier_share_percent: float
    supplier_share_amount: float
    unit_price_with_share: float
    allocated_expense_per_unit_cny: float = 0.0
    final_unit_cost_cny: float = 0.0
    final_unit_cost_usd: float = 0.0
    final_unit_cost_uzs: float = 0.0
    usd_to_cny_rate: float = 0.0
    usd_to_uzs_rate: float = 0.0
    color: str
    material: str
    size: str
    measurements: str
    status: str
    is_favorite: bool
    created_at: datetime


class BatchCreate(BaseModel):
    name: str = Field(min_length=1, max_length=140)
    product_ids: list[int] = Field(min_length=1)
    note: str = ""


class BatchUpdate(BaseModel):
    name: str = Field(min_length=1, max_length=140)
    note: str = ""


class BatchAddProducts(BaseModel):
    product_ids: list[int] = Field(min_length=1)


class BatchRead(BaseModel):
    id: str
    name: str
    note: str
    created_at: datetime
    products: list[ProductRead]


class ExpenseCreate(BaseModel):
    title: str = Field(min_length=1, max_length=140)
    amount: str = Field(min_length=1, max_length=120)
    note: str = ""
    accounting_type: str = "not_selected"
    accounting_channel: str = "not_selected"
    currency: str = "CNY"


class ExpenseUpdate(BaseModel):
    title: str = Field(min_length=1, max_length=140)
    amount: str = Field(min_length=1, max_length=120)
    note: str = ""
    accounting_type: str = "not_selected"
    accounting_channel: str = "not_selected"
    currency: str = "CNY"


class ExpenseBatchAssignmentUpdate(BaseModel):
    batch_id: str | None = None


class ExpenseRead(BaseModel):
    id: str
    title: str
    accounting_type: str
    accounting_channel: str
    currency: str
    amount: str
    amount_cny: float
    amount_usd: float
    amount_uzs: float
    usd_to_cny_rate: float
    usd_to_uzs_rate: float
    note: str
    batch_id: str | None = None
    created_at: datetime
