from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class HealthResponse(BaseModel):
    status: str


class ProfileRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    name: str


class ProfileUpdate(BaseModel):
    name: str = Field(min_length=1, max_length=100)


class ProductCreate(BaseModel):
    images: list[str] = Field(default_factory=list)
    amount: str = ""
    material: str = ""
    size: str = ""
    is_favorite: bool = False


class ProductUpdate(BaseModel):
    images: list[str] = Field(default_factory=list)
    amount: str = ""
    material: str = ""
    size: str = ""
    is_favorite: bool = False


class ProductRead(BaseModel):
    id: str
    images: list[str]
    amount: str
    material: str
    size: str
    status: str
    is_favorite: bool
    created_at: datetime
