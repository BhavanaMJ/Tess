from datetime import datetime
from typing import List, Optional, Dict, Any
from enum import Enum
from pydantic import BaseModel, Field

class LaundryStatusEnum(str, Enum):
    CLEAN = "CLEAN"
    WORN = "WORN"
    WASHING = "WASHING"
    DRYING = "DRYING"
    STORED = "STORED"

class BatchStatusEnum(str, Enum):
    CREATED = "CREATED"
    WASHING = "WASHING"
    DRYING = "DRYING"
    COMPLETED = "COMPLETED"
    CANCELLED = "CANCELLED"

class LaundryEventTypeEnum(str, Enum):
    STATUS_CHANGE = "STATUS_CHANGE"
    WEAR = "WEAR"
    WASH_CYCLE_STARTED = "WASH_CYCLE_STARTED"
    WASH_CYCLE_COMPLETED = "WASH_CYCLE_COMPLETED"
    STORED = "STORED"
    BATCH_ASSIGNED = "BATCH_ASSIGNED"
    BATCH_REMOVED = "BATCH_REMOVED"
    MANUAL_OVERRIDE = "MANUAL_OVERRIDE"

class LaundryStatsResponse(BaseModel):
    total_garments: int
    clean_count: int
    worn_count: int
    washing_count: int
    drying_count: int
    stored_count: int
    unassigned_count: int
    active_batches_count: int = 0

class GarmentLaundryStatusUpdate(BaseModel):
    laundry_status: Optional[LaundryStatusEnum] = None
    source: Optional[str] = "MANUAL"
    notes: Optional[str] = None
    idempotency_key: Optional[str] = None

class LaundryHistoryEntryResponse(BaseModel):
    id: str
    user_id: str
    garment_id: str
    batch_id: Optional[str] = None
    event_type: str
    previous_status: Optional[str] = None
    new_status: Optional[str] = None
    source: Optional[str] = "MANUAL"
    notes: Optional[str] = None
    created_at: datetime

class LaundryBatchCreate(BaseModel):
    name: Optional[str] = None
    garment_ids: List[str]
    initial_status: BatchStatusEnum = BatchStatusEnum.WASHING
    notes: Optional[str] = None
    idempotency_key: Optional[str] = None

class LaundryBatchItemResponse(BaseModel):
    id: str
    batch_id: str
    garment_id: str
    garment_name: Optional[str] = None
    garment_category: Optional[str] = None
    current_laundry_status: Optional[str] = None
    thumbnail_ref: Optional[str] = None
    status: str = "ACTIVE"
    added_at: datetime

class LaundryBatchResponse(BaseModel):
    id: str
    user_id: str
    batch_number: str
    name: str
    status: str
    notes: Optional[str] = None
    items_count: int = 0
    items: List[LaundryBatchItemResponse] = []
    created_at: datetime
    updated_at: datetime
    completed_at: Optional[datetime] = None

class LaundryBatchStatusUpdate(BaseModel):
    status: BatchStatusEnum
    notes: Optional[str] = None
    idempotency_key: Optional[str] = None

class LaundryBatchItemAdd(BaseModel):
    garment_ids: List[str]

class BatchTransitionResponse(BaseModel):
    batch_id: str
    new_batch_status: str
    updated_garment_ids: List[str]
    skipped_garment_ids: List[str]
    message: str
