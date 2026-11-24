from typing import List, Optional, Dict, Any, Union
from datetime import date, datetime
from pydantic import BaseModel, Field, field_validator, model_validator

VALID_CATEGORIES = [
    "Tops", "Bottoms", "Ethnic wear", "Dresses", "Outerwear",
    "Activewear", "Innerwear", "Sleepwear", "Footwear", "Accessories"
]

class IdentitySection(BaseModel):
    garment_name: Optional[str] = None
    category: Optional[str] = None
    subcategory: Optional[str] = None
    garment_type: Optional[str] = None
    description: Optional[str] = None
    gender_section: Optional[str] = None
    custom_category: Optional[str] = None

class AppearanceSection(BaseModel):
    primary_colour: Optional[str] = None
    secondary_colours: List[str] = Field(default_factory=list)
    accent_colours: List[str] = Field(default_factory=list)
    colour_family: Optional[str] = None
    colour_temperature: Optional[str] = None
    colour_distribution: Optional[str] = None
    pattern: Optional[str] = None
    pattern_scale: Optional[str] = None
    pattern_density: Optional[str] = None
    pattern_placement: Optional[str] = None
    print_technique: Optional[str] = None
    visual_texture: Optional[str] = None
    surface_finish: Optional[str] = None

class ConstructionSection(BaseModel):
    neckline: Optional[str] = None
    collar_type: Optional[str] = None
    sleeve_length: Optional[str] = None
    sleeve_style: Optional[str] = None
    sleeve_finish: Optional[str] = None
    shoulder_style: Optional[str] = None
    silhouette: Optional[str] = None
    fit: Optional[str] = None
    garment_length: Optional[str] = None
    hemline: Optional[str] = None
    waist_design: Optional[str] = None
    closure_type: Optional[str] = None
    closure_position: Optional[str] = None
    pocket_details: List[str] = Field(default_factory=list)
    lining: Optional[str] = None
    embroidery: Optional[str] = None
    embellishments: List[str] = Field(default_factory=list)
    slit_details: Optional[str] = None
    border_details: Optional[str] = None
    decorative_details: List[str] = Field(default_factory=list)
    stitching_details: Optional[str] = None
    back_design: Optional[str] = None

class MaterialSection(BaseModel):
    fabric_appearance: Optional[str] = None
    primary_material: Optional[str] = None
    secondary_material: Optional[str] = None
    fabric_composition: Optional[str] = None
    weave_type: Optional[str] = None
    fabric_weight: Optional[str] = None
    stretch: Optional[str] = None
    transparency: Optional[str] = None
    thickness: Optional[str] = None
    drape: Optional[str] = None
    texture: Optional[str] = None
    surface_finish: Optional[str] = None

class MeasurementsSubSection(BaseModel):
    chest: Optional[Union[float, str]] = None
    waist: Optional[Union[float, str]] = None
    hip: Optional[Union[float, str]] = None
    shoulder_width: Optional[Union[float, str]] = None
    sleeve_length: Optional[Union[float, str]] = None
    garment_length: Optional[Union[float, str]] = None
    inseam: Optional[Union[float, str]] = None
    outseam: Optional[Union[float, str]] = None

class SizingSection(BaseModel):
    labelled_size: Optional[str] = None
    size_system: Optional[str] = None
    fit_type: Optional[str] = None
    measurements: MeasurementsSubSection = Field(default_factory=MeasurementsSubSection)
    alteration_details: Optional[str] = None

class UsageSection(BaseModel):
    occasions: List[str] = Field(default_factory=list)
    seasons: List[str] = Field(default_factory=list)
    weather_suitability: List[str] = Field(default_factory=list)
    dress_code: Optional[str] = None
    style_aesthetic: List[str] = Field(default_factory=list)
    formality_level: Optional[str] = None
    comfort_rating: Optional[Union[int, float]] = None
    activity_suitability: List[str] = Field(default_factory=list)
    compatible_accessories: List[str] = Field(default_factory=list)

class PurchaseSection(BaseModel):
    brand: Optional[str] = None
    product_name: Optional[str] = None
    purchase_date: Optional[Union[date, str]] = None
    purchase_price: Optional[float] = None
    purchase_currency: Optional[str] = "INR"
    purchase_source: Optional[str] = None
    store_name: Optional[str] = None
    product_url: Optional[str] = None
    invoice_reference: Optional[str] = None
    ownership_status: Optional[str] = None

class CareSection(BaseModel):
    washing_method: Optional[str] = None
    washing_temperature: Optional[str] = None
    bleach_allowed: Optional[bool] = None
    ironing_temperature: Optional[str] = None
    drying_method: Optional[str] = None
    dry_cleaning: Optional[bool] = None
    care_label_instructions: Optional[str] = None
    care_precautions: List[str] = Field(default_factory=list)

class PhysicalLocationSection(BaseModel):
    storage_location: Optional[str] = None
    storage_section: Optional[str] = None
    shelf: Optional[str] = None
    drawer: Optional[str] = None
    hanger_section: Optional[str] = None
    storage_container: Optional[str] = None
    location_notes: Optional[str] = None

class AiMetadataSection(BaseModel):
    detection_source: str = "user_uploaded_image"
    vision_provider: Optional[str] = None
    image_generation_provider: Optional[str] = None
    model_name: Optional[str] = None
    processing_timestamp: Optional[str] = None
    schema_version: str = "1.1"
    attribute_confidence: Dict[str, Any] = Field(default_factory=dict)
    verification_status: str = "pending_user_review"
    user_verified_fields: List[str] = Field(default_factory=list)
    user_corrected_fields: List[str] = Field(default_factory=list)
    uncertain_fields: List[str] = Field(default_factory=list)
    unknown_fields: List[str] = Field(default_factory=list)

class VisualAssetsSection(BaseModel):
    original_image_description: Optional[str] = None
    catalogue_image_description: Optional[str] = None
    catalogue_image_generated: bool = False
    original_image_preserved: bool = True

class GarmentMetadataInterchangeV1_1(BaseModel):
    schema_version: str = "1.1"
    record_type: str = "garment"
    identity: IdentitySection = Field(default_factory=IdentitySection)
    appearance: AppearanceSection = Field(default_factory=AppearanceSection)
    construction: ConstructionSection = Field(default_factory=ConstructionSection)
    material: MaterialSection = Field(default_factory=MaterialSection)
    sizing: SizingSection = Field(default_factory=SizingSection)
    usage: UsageSection = Field(default_factory=UsageSection)
    purchase: PurchaseSection = Field(default_factory=PurchaseSection)
    care: CareSection = Field(default_factory=CareSection)
    physical_location: PhysicalLocationSection = Field(default_factory=PhysicalLocationSection)
    category_specific: Dict[str, Any] = Field(default_factory=dict)
    ai_metadata: AiMetadataSection = Field(default_factory=AiMetadataSection)
    visual_assets: VisualAssetsSection = Field(default_factory=VisualAssetsSection)
    notes: List[str] = Field(default_factory=list)

    @field_validator("schema_version")
    def validate_version(cls, v: str) -> str:
        if v != "1.1":
            raise ValueError("This metadata version is not supported.")
        return v

    @field_validator("record_type")
    def validate_record_type(cls, v: str) -> str:
        if v != "garment":
            raise ValueError(f"Invalid record_type '{v}'. Expected 'garment'.")
        return v

class MetadataValidationRequest(BaseModel):
    raw_json: Optional[str] = None
    metadata: Optional[Dict[str, Any]] = None

class MetadataValidationResponse(BaseModel):
    valid: bool
    errors: List[str] = Field(default_factory=list)
    warnings: List[str] = Field(default_factory=list)
    normalized_metadata: Optional[Dict[str, Any]] = None

class GarmentImportRegisterRequest(BaseModel):
    catalogue_image_ref: str
    original_image_ref: Optional[str] = None
    metadata: Dict[str, Any]
    user_verified: bool = True

class GarmentImportRegisterResponse(BaseModel):
    success: bool
    garment_id: str
    message: str
    garment: Dict[str, Any]
