import pytest
import json
from datetime import date
from app.schemas.wardrobe_import import (
    GarmentMetadataInterchangeV1_1,
    MetadataValidationRequest,
    MetadataValidationResponse,
    GarmentImportRegisterRequest,
)
from app.services.wardrobe.import_service import WardrobeImportService
from app.services.wardrobe.service import WardrobeService

VALID_SAMPLE_METADATA = {
    "schema_version": "1.1",
    "record_type": "garment",
    "identity": {
        "garment_name": "Silk Embroidered Anarkali",
        "category": "Ethnic wear",
        "subcategory": "Anarkalis",
        "garment_type": "Anarkali Suit",
        "description": "Deep crimson silk anarkali with gold zari embroidery.",
        "gender_section": "Women",
        "custom_category": None
    },
    "appearance": {
        "primary_colour": "Crimson",
        "secondary_colours": ["Gold", "Maroon"],
        "accent_colours": ["Emerald"],
        "colour_family": "Red",
        "colour_temperature": "Warm",
        "colour_distribution": "Solid with border",
        "pattern": "Embroidered",
        "pattern_scale": "Medium",
        "pattern_density": "Dense",
        "pattern_placement": "Yoke and Hem",
        "print_technique": None,
        "visual_texture": "Silky",
        "surface_finish": "Lustrous"
    },
    "construction": {
        "neckline": "Round Neck",
        "collar_type": None,
        "sleeve_length": "Full Sleeves",
        "sleeve_style": "Fitted",
        "sleeve_finish": "Embroidered cuff",
        "shoulder_style": "Regular",
        "silhouette": "A-line flared",
        "fit": "Regular Fit",
        "garment_length": "Ankle-length",
        "hemline": "Flared",
        "waist_design": "Empire",
        "closure_type": "Side zip",
        "closure_position": "Left side",
        "pocket_details": [],
        "lining": "Cotton",
        "embroidery": "Zari and sequin",
        "embellishments": ["Sequins", "Beads"],
        "slit_details": None,
        "border_details": "Gold brocade border",
        "decorative_details": ["Tassels on tie"],
        "stitching_details": "Princess seam",
        "back_design": "Deep back with dori"
    },
    "material": {
        "fabric_appearance": "Raw Silk",
        "primary_material": "Silk",
        "secondary_material": "Cotton",
        "fabric_composition": "80% Silk, 20% Cotton",
        "weave_type": "Jacquard",
        "fabric_weight": "Medium",
        "stretch": "Non-stretch",
        "transparency": "Opaque",
        "thickness": "Medium",
        "drape": "Structured",
        "texture": "Smooth",
        "surface_finish": "Sheen"
    },
    "sizing": {
        "labelled_size": "M",
        "size_system": "IN",
        "fit_type": "Regular",
        "measurements": {
            "chest": "38",
            "waist": "32",
            "hip": "42",
            "shoulder_width": "15",
            "sleeve_length": "22",
            "garment_length": "52",
            "inseam": None,
            "outseam": None
        },
        "alteration_details": None
    },
    "usage": {
        "occasions": ["Wedding", "Festive", "Evening"],
        "seasons": ["Winter", "Autumn"],
        "weather_suitability": ["Mild", "Cool"],
        "dress_code": "Traditional Festive",
        "style_aesthetic": ["Royal", "Classic Ethnic"],
        "formality_level": "Formal",
        "comfort_rating": 4.5,
        "activity_suitability": ["Ceremony", "Dining"],
        "compatible_accessories": ["Gold Jhumkas", "Embroidered Juttis", "Potli Bag"]
    },
    "purchase": {
        "brand": "FabIndia",
        "product_name": "Royal Crimson Zari Anarkali",
        "purchase_date": "2024-10-15",
        "purchase_price": 8500.0,
        "purchase_currency": "INR",
        "purchase_source": "Store",
        "store_name": "FabIndia Indiranagar",
        "product_url": None,
        "invoice_reference": "INV-2024-8891",
        "ownership_status": "Owned"
    },
    "care": {
        "washing_method": "Dry Clean Only",
        "washing_temperature": None,
        "bleach_allowed": False,
        "ironing_temperature": "Low / Silk mode",
        "drying_method": "Shadow dry",
        "dry_cleaning": True,
        "care_label_instructions": "Professional dry clean only. Store wrapped in muslin cloth.",
        "care_precautions": ["Avoid direct perfume contact", "Do not wring"]
    },
    "physical_location": {
        "storage_location": "Master Bedroom Wardrobe",
        "storage_section": "Occasion Wear Wardrobe",
        "shelf": "Shelf 2",
        "drawer": None,
        "hanger_section": "Long Garment Hanger Rack",
        "storage_container": "Muslin Garment Bag",
        "location_notes": "Hung on wooden padded hanger."
    },
    "category_specific": {
        "anarkali_flare_meters": 4.5,
        "dupatta_included": True,
        "bottom_type": "Churidar"
    },
    "ai_metadata": {
        "detection_source": "user_uploaded_image",
        "vision_provider": "ChatGPT-4o",
        "image_generation_provider": "DALL-E 3",
        "model_name": "gpt-4o",
        "processing_timestamp": "2026-11-24T20:30:00Z",
        "schema_version": "1.1",
        "attribute_confidence": {"category": "HIGH", "primary_colour": "HIGH"},
        "verification_status": "pending_user_review",
        "user_verified_fields": [],
        "user_corrected_fields": [],
        "uncertain_fields": [],
        "unknown_fields": []
    },
    "visual_assets": {
        "original_image_description": "Garment laid out on bed under indoor warm light.",
        "catalogue_image_description": "Clean studio portrait on neutral off-white background.",
        "catalogue_image_generated": True,
        "original_image_preserved": True
    },
    "notes": ["Heirloom piece worn for brother's wedding.", "Dry cleaned once."]
}

class MockSupabaseTable:
    def __init__(self):
        self._data = []

    def select(self, *args):
        return self

    def insert(self, record):
        self._data.append(record)
        return self

    def update(self, record):
        return self

    def eq(self, *args):
        return self

    def execute(self):
        class Resp:
            data = []
        return Resp()

class MockSupabase:
    def table(self, name):
        return MockSupabaseTable()

def test_validate_valid_metadata_schema_success():
    service = WardrobeImportService(MockSupabase(), "user-test-123")
    res = service.validate_metadata(raw_json=json.dumps(VALID_SAMPLE_METADATA))
    assert res.valid is True
    assert len(res.errors) == 0
    assert res.normalized_metadata is not None
    assert res.normalized_metadata["identity"]["garment_name"] == "Silk Embroidered Anarkali"
    assert res.normalized_metadata["identity"]["category"] == "Ethnic Wear"
    assert res.normalized_metadata["category_specific"]["anarkali_flare_meters"] == 4.5

def test_validate_malformed_json_syntax_error():
    service = WardrobeImportService(MockSupabase(), "user-test-123")
    res = service.validate_metadata(raw_json='{"schema_version": "1.1", "record_type": }')
    assert res.valid is False
    assert any("Your metadata JSON is invalid" in e for e in res.errors)

def test_validate_unsupported_schema_version_rejected():
    service = WardrobeImportService(MockSupabase(), "user-test-123")
    data = dict(VALID_SAMPLE_METADATA)
    data["schema_version"] = "2.0"
    res = service.validate_metadata(metadata_dict=data)
    assert res.valid is False
    assert any("This metadata version is not supported" in e for e in res.errors)

def test_validate_invalid_record_type_rejected():
    service = WardrobeImportService(MockSupabase(), "user-test-123")
    data = dict(VALID_SAMPLE_METADATA)
    data["record_type"] = "shoes"
    res = service.validate_metadata(metadata_dict=data)
    assert res.valid is False
    assert any("Invalid record_type" in e for e in res.errors)

def test_validate_missing_garment_name_rejected():
    service = WardrobeImportService(MockSupabase(), "user-test-123")
    data = json.loads(json.dumps(VALID_SAMPLE_METADATA))
    data["identity"]["garment_name"] = "  "
    res = service.validate_metadata(metadata_dict=data)
    assert res.valid is False
    assert any("Please provide a garment name" in e for e in res.errors)

def test_validate_invalid_category_rejected():
    service = WardrobeImportService(MockSupabase(), "user-test-123")
    data = json.loads(json.dumps(VALID_SAMPLE_METADATA))
    data["identity"]["category"] = "Automotive"
    res = service.validate_metadata(metadata_dict=data)
    assert res.valid is False
    assert any("Unsupported garment category" in e or "Select a supported garment category" in e for e in res.errors)

def test_validate_preserves_null_scalars_and_empty_arrays():
    service = WardrobeImportService(MockSupabase(), "user-test-123")
    data = json.loads(json.dumps(VALID_SAMPLE_METADATA))
    data["construction"]["collar_type"] = None
    data["construction"]["pocket_details"] = []
    res = service.validate_metadata(metadata_dict=data)
    assert res.valid is True
    norm = res.normalized_metadata
    assert norm["construction"]["collar_type"] is None
    assert norm["construction"]["pocket_details"] == []

def test_import_image_validation_file_types():
    service = WardrobeImportService(MockSupabase(), "user-test-123")
    # Valid png
    ref = service.save_import_image("catalogue", b"\x89PNG\r\n\x1a\nfakeimagebytes", "studio.png")
    assert "/api/v1/wardrobe/capture/images/user-test-123/catalogue/" in ref

    # Invalid exe
    with pytest.raises(ValueError, match="Unsupported image format"):
        service.save_import_image("catalogue", b"MZfakebinary", "malware.exe")

    # Empty file
    with pytest.raises(ValueError, match="empty"):
        service.save_import_image("catalogue", b"", "empty.jpg")

def test_register_imported_garment_success():
    mock_supabase = MockSupabase()
    user_id = "user-test-register"
    service = WardrobeImportService(mock_supabase, user_id)
    wardrobe_service = WardrobeService(mock_supabase, user_id)

    req = GarmentImportRegisterRequest(
        catalogue_image_ref="/api/v1/wardrobe/capture/images/user-test-register/catalogue/studio.jpg",
        original_image_ref="/api/v1/wardrobe/capture/images/user-test-register/originals/photo.jpg",
        metadata=VALID_SAMPLE_METADATA,
        user_verified=True,
    )

    reg_res = service.register_garment(req, wardrobe_service)
    assert reg_res.success is True
    assert reg_res.garment_id.startswith("CLO-")
    assert reg_res.garment["laundry_status"] is None  # PRD safety guarantee
    assert reg_res.garment["metadata_payload"]["schema_version"] == "1.1"
    assert reg_res.garment["import_provenance"] == "CHATGPT_IMPORT"
    assert reg_res.garment["original_image_ref"] == req.original_image_ref
    assert reg_res.garment["processed_image_ref"] == req.catalogue_image_ref

def test_register_imported_garment_missing_catalogue_fails():
    mock_supabase = MockSupabase()
    user_id = "user-test-missing-cat"
    service = WardrobeImportService(mock_supabase, user_id)
    wardrobe_service = WardrobeService(mock_supabase, user_id)

    req = GarmentImportRegisterRequest(
        catalogue_image_ref="",
        metadata=VALID_SAMPLE_METADATA,
    )

    with pytest.raises(ValueError, match="Please upload a catalogue image"):
        service.register_garment(req, wardrobe_service)

def test_category_normalization_bottoms_aliases():
    service = WardrobeImportService(MockSupabase(), "user-test-norm")
    aliases = [
        "Bottoms",
        "Bottomwear",
        "Bottom Wear",
        "Pants",
        "Trousers",
        "Lowerwear",
        "bottomwear",
        "BOTTOMWEAR",
        "   trousers   ",
        "  Bottom Wear  ",
    ]
    for alias in aliases:
        meta = {
            "schema_version": "1.1",
            "record_type": "garment",
            "identity": {
                "garment_name": f"Test {alias}",
                "category": alias,
                "subcategory": "Pants",
            }
        }
        res = service.validate_metadata(metadata_dict=meta)
        assert res.valid is True, f"Failed for alias: {alias}, errors: {res.errors}"
        assert res.normalized_metadata["identity"]["category"] == "Bottoms", f"Expected Bottoms for {alias}, got {res.normalized_metadata['identity']['category']}"

def test_category_normalization_other_canonical_aliases():
    service = WardrobeImportService(MockSupabase(), "user-test-norm")
    mappings = {
        "Tops": "Tops",
        "Topwear": "Tops",
        "Upperwear": "Tops",
        "topwear": "Tops",
        "  upperwear  ": "Tops",
        "Ethnic Wear": "Ethnic Wear",
        "Ethnicwear": "Ethnic Wear",
        "ethnic wear": "Ethnic Wear",
        "ethnicwear": "Ethnic Wear",
        "Dresses": "Dresses",
        "Dress": "Dresses",
        "dress": "Dresses",
        "Outerwear": "Outerwear",
        "Activewear": "Activewear",
        "Innerwear": "Innerwear",
        "Sleepwear": "Sleepwear",
        "Footwear": "Footwear",
        "Accessories": "Accessories",
    }
    for alias, expected in mappings.items():
        meta = {
            "schema_version": "1.1",
            "record_type": "garment",
            "identity": {
                "garment_name": f"Test {alias}",
                "category": alias,
            }
        }
        res = service.validate_metadata(metadata_dict=meta)
        assert res.valid is True, f"Failed for alias: {alias}, errors: {res.errors}"
        assert res.normalized_metadata["identity"]["category"] == expected

def test_regression_fixture_orange_blue_homewear_pants():
    """
    Regression fixture required by prompt:
    {
      "schema_version": "1.1",
      "record_type": "garment",
      "identity": {
        "garment_name": "Orange and Blue Geometric Printed Homewear Pants",
        "category": "Bottomwear",
        "subcategory": "Lounge Pants",
        "garment_type": "Printed Homewear Trousers"
      }
    }
    Expected normalized category: Bottoms
    Expected preserved subcategory: Lounge Pants
    Expected preserved garment_type: Printed Homewear Trousers
    """
    mock_supabase = MockSupabase()
    user_id = "user-test-homewear"
    service = WardrobeImportService(mock_supabase, user_id)
    wardrobe_service = WardrobeService(mock_supabase, user_id)

    fixture_meta = {
        "schema_version": "1.1",
        "record_type": "garment",
        "identity": {
            "garment_name": "Orange and Blue Geometric Printed Homewear Pants",
            "category": "Bottomwear",
            "subcategory": "Lounge Pants",
            "garment_type": "Printed Homewear Trousers"
        }
    }

    # 1. Validation test
    val_res = service.validate_metadata(metadata_dict=fixture_meta)
    assert val_res.valid is True
    assert len(val_res.errors) == 0
    assert val_res.normalized_metadata["identity"]["category"] == "Bottoms"
    assert val_res.normalized_metadata["identity"]["subcategory"] == "Lounge Pants"
    assert val_res.normalized_metadata["identity"]["garment_type"] == "Printed Homewear Trousers"
    assert val_res.diagnostics.get("category_normalization", {}).get("original_category") == "Bottomwear"
    assert val_res.diagnostics.get("category_normalization", {}).get("canonical_category") == "Bottoms"

    # 2. Registration test
    reg_req = GarmentImportRegisterRequest(
        catalogue_image_ref="https://example.com/cat_homewear.jpg",
        metadata=fixture_meta,
    )
    reg_res = service.register_garment(reg_req, wardrobe_service)
    assert reg_res.success is True
    assert reg_res.garment["name"] == "Orange and Blue Geometric Printed Homewear Pants"
    assert reg_res.garment["main_category"] == "Bottoms"
    assert reg_res.garment["subcategory"] == "Lounge Pants"
    assert reg_res.garment["metadata_payload"]["identity"]["garment_type"] == "Printed Homewear Trousers"
    assert reg_res.garment["metadata_payload"]["ai_metadata"]["diagnostics"]["category_normalization"]["canonical_category"] == "Bottoms"

def test_subcategory_preservation_examples():
    """
    Other examples required by prompt:
    - Jeans -> category Bottoms, subcategory Jeans
    - Leggings -> category Bottoms, subcategory Leggings
    - Kurta -> category Ethnic Wear, subcategory Kurta
    - T-shirt -> category Tops, subcategory T-shirt
    """
    service = WardrobeImportService(MockSupabase(), "user-test-subcat")
    cases = [
        ("Bottomwear", "Jeans", "Bottoms", "Jeans"),
        ("pants", "Leggings", "Bottoms", "Leggings"),
        ("Ethnicwear", "Kurta", "Ethnic Wear", "Kurta"),
        ("Topwear", "T-shirt", "Tops", "T-shirt"),
    ]
    for in_cat, in_sub, exp_cat, exp_sub in cases:
        meta = {
            "schema_version": "1.1",
            "record_type": "garment",
            "identity": {
                "garment_name": f"Test {in_sub}",
                "category": in_cat,
                "subcategory": in_sub,
            }
        }
        res = service.validate_metadata(metadata_dict=meta)
        assert res.valid is True
        assert res.normalized_metadata["identity"]["category"] == exp_cat
        assert res.normalized_metadata["identity"]["subcategory"] == exp_sub

def test_unknown_category_rejection_helpful_error():
    service = WardrobeImportService(MockSupabase(), "user-test-err")
    meta = {
        "schema_version": "1.1",
        "record_type": "garment",
        "identity": {
            "garment_name": "Test Gadget",
            "category": "Spacesuit",
        }
    }
    res = service.validate_metadata(metadata_dict=meta)
    assert res.valid is False
    assert any("Unsupported garment category: 'Spacesuit'" in e for e in res.errors)
    assert any("Supported categories are Tops, Bottoms, Ethnic Wear, Dresses, Outerwear, Activewear, Innerwear, Sleepwear, Footwear and Accessories" in e for e in res.errors)


