from datetime import datetime
from typing import List, Optional, Dict, Any
from enum import Enum
from pydantic import BaseModel, Field

class ConfidenceLevelEnum(str, Enum):
    HIGH = "HIGH"
    MEDIUM = "MEDIUM"
    LOW = "LOW"
    UNCERTAIN = "UNCERTAIN"

class CaptureJobStatusEnum(str, Enum):
    PENDING = "PENDING"
    UPLOADING = "UPLOADING"
    VALIDATING = "VALIDATING"
    ANALYZING = "ANALYZING"
    DETECTING = "DETECTING"
    SEGMENTING = "SEGMENTING"
    EXTRACTING = "EXTRACTING"
    AWAITING_APPROVAL = "AWAITING_APPROVAL"
    COMPLETED = "COMPLETED"
    FAILED = "FAILED"

class BoundingBox(BaseModel):
    x: float = 0.0
    y: float = 0.0
    width: float = 1.0
    height: float = 1.0

class GarmentCandidateResponse(BaseModel):
    id: str
    job_id: str
    suggested_name: str
    main_category: str
    subcategory: Optional[str] = None
    primary_color: str
    secondary_colors: List[str] = Field(default_factory=list)
    pattern: Optional[str] = None
    fabric_material: Optional[str] = None
    sleeve_length: Optional[str] = None
    neckline: Optional[str] = None
    fit: Optional[str] = None
    silhouette: Optional[str] = None
    garment_length: Optional[str] = None
    size: Optional[str] = None
    brand: Optional[str] = None
    confidence_scores: Dict[str, str] = Field(default_factory=dict)
    bounding_box: Optional[Dict[str, Any]] = None
    processed_image_ref: Optional[str] = None
    original_crop_ref: Optional[str] = None
    is_included: bool = True
    is_approved: bool = False
    registered_garment_id: Optional[str] = None
    uncertainty_notes: Optional[str] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

class GarmentCandidateUpdate(BaseModel):
    suggested_name: Optional[str] = None
    main_category: Optional[str] = None
    subcategory: Optional[str] = None
    primary_color: Optional[str] = None
    secondary_colors: Optional[List[str]] = None
    pattern: Optional[str] = None
    fabric_material: Optional[str] = None
    sleeve_length: Optional[str] = None
    neckline: Optional[str] = None
    fit: Optional[str] = None
    silhouette: Optional[str] = None
    garment_length: Optional[str] = None
    size: Optional[str] = None
    brand: Optional[str] = None
    is_included: Optional[bool] = None
    is_approved: Optional[bool] = None

class CaptureJobResponse(BaseModel):
    id: str
    user_id: str
    original_image_ref: str
    status: str
    current_stage: str
    progress_percent: int = 0
    total_detected: int = 0
    provider_type: str = "DEVELOPMENT_LOCAL"
    error_message: Optional[str] = None
    candidates: List[GarmentCandidateResponse] = Field(default_factory=list)
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

class CaptureJobConfirmRequest(BaseModel):
    candidate_ids: Optional[List[str]] = None

class CaptureJobConfirmResponse(BaseModel):
    success: bool
    job_id: str
    registered_count: int
    registered_garment_ids: List[str]
    message: str

