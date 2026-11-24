import os
import json
import uuid
import threading
import logging
from typing import Dict, Any, Optional, List, Tuple
from datetime import datetime, timezone, date

from app.schemas.wardrobe import GarmentCreate
from app.schemas.wardrobe_import import (
    GarmentMetadataInterchangeV1_1,
    MetadataValidationResponse,
    GarmentImportRegisterRequest,
    GarmentImportRegisterResponse,
    VALID_CATEGORIES,
)
from app.services.wardrobe.service import WardrobeService
from app.services.wardrobe.capture_service import MEDIA_ROOT

logger = logging.getLogger(__name__)

# Global lock for thread-safe sequential ID generation in memory / concurrency
_ID_GENERATION_LOCK = threading.Lock()

class WardrobeImportService:
    def __init__(self, supabase: Any, user_id: str):
        self.supabase = supabase
        self.user_id = user_id

    def validate_metadata(
        self,
        raw_json: Optional[str] = None,
        metadata_dict: Optional[Dict[str, Any]] = None,
    ) -> MetadataValidationResponse:
        """
        Validates raw JSON or metadata dictionary against TESS Garment Metadata Schema Version 1.1.
        Returns detailed validation errors, warnings, and normalized metadata.
        """
        errors: List[str] = []
        warnings: List[str] = []

        parsed_data: Optional[Dict[str, Any]] = metadata_dict

        if raw_json is not None:
            if not raw_json.strip():
                return MetadataValidationResponse(
                    valid=False,
                    errors=["Metadata JSON payload is empty. Please paste your garment JSON."],
                )
            try:
                parsed_data = json.loads(raw_json)
            except json.JSONDecodeError as e:
                return MetadataValidationResponse(
                    valid=False,
                    errors=[f"Your metadata JSON is invalid. Please correct the highlighted issue: {e.msg} at line {e.lineno}, column {e.colno}."],
                )

        if not isinstance(parsed_data, dict):
            return MetadataValidationResponse(
                valid=False,
                errors=["Expected a JSON object representing garment metadata."],
            )

        # 1. Check schema_version
        schema_version = parsed_data.get("schema_version")
        if schema_version != "1.1":
            return MetadataValidationResponse(
                valid=False,
                errors=[f"This metadata version is not supported. Expected '1.1', found '{schema_version}'."],
            )

        # 2. Check record_type
        record_type = parsed_data.get("record_type")
        if record_type != "garment":
            errors.append(f"Invalid record_type '{record_type}'. Expected 'garment'.")

        # 3. Pydantic Model Validation
        try:
            model = GarmentMetadataInterchangeV1_1(**parsed_data)
        except Exception as e:
            errors.append(f"Schema validation error: {str(e)}")
            return MetadataValidationResponse(valid=False, errors=errors)

        # 4. Mandatory Identity Validation
        identity = model.identity
        if not identity.garment_name or not identity.garment_name.strip():
            errors.append("Please provide a garment name.")

        category = identity.category
        if not category or not category.strip():
            errors.append("Select a supported garment category.")
        else:
            # Case-insensitive category resolution
            matched_cat = next((c for c in VALID_CATEGORIES if c.lower() == category.strip().lower()), None)
            if not matched_cat and not identity.custom_category:
                errors.append(f"Select a supported garment category. '{category}' is not recognized. Supported categories: {', '.join(VALID_CATEGORIES)}.")
            elif matched_cat:
                identity.category = matched_cat

        # 5. Purchase Date Format Validation
        purchase = model.purchase
        if purchase.purchase_date:
            if isinstance(purchase.purchase_date, str):
                try:
                    datetime.strptime(purchase.purchase_date, "%Y-%m-%d")
                except ValueError:
                    errors.append(f"Invalid purchase_date '{purchase.purchase_date}'. Expected format YYYY-MM-DD.")

        # 6. Purchase Price Validation
        if purchase.purchase_price is not None and purchase.purchase_price < 0:
            errors.append("Purchase price cannot be negative.")

        if errors:
            return MetadataValidationResponse(valid=False, errors=errors, warnings=warnings)

        # Warnings for missing optional attributes that improve wardrobe recommendations
        if not model.appearance.primary_colour:
            warnings.append("Primary colour is unspecified. Adding colour will improve outfit styling.")
        if not model.construction.sleeve_length and identity.category in ("Tops", "Dresses", "Ethnic wear", "Outerwear"):
            warnings.append("Sleeve length is unspecified.")

        return MetadataValidationResponse(
            valid=True,
            errors=[],
            warnings=warnings,
            normalized_metadata=model.model_dump(),
        )

    def save_import_image(
        self,
        image_type: str,
        file_bytes: bytes,
        filename: str,
    ) -> str:
        """
        Validates and stores uploaded catalogue or original garment photograph in user-scoped private media.
        Returns a URL reference to the stored image.
        """
        if image_type not in ("catalogue", "original", "processed", "originals"):
            raise ValueError(f"Invalid image_type '{image_type}'. Expected 'catalogue' or 'original'.")

        folder_name = "originals" if image_type in ("original", "originals") else "catalogue"

        if not file_bytes:
            raise ValueError("The uploaded image file is empty.")

        if len(file_bytes) > 15 * 1024 * 1024:
            raise ValueError("Image file exceeds the 15MB limit. Please upload a smaller image.")

        ext = os.path.splitext(filename)[1].lower().replace(".", "")
        if ext not in ("jpg", "jpeg", "png", "webp"):
            raise ValueError(f"Unsupported image format '.{ext}'. Supported formats: JPG, JPEG, PNG, WEBP.")

        user_dir = os.path.join(MEDIA_ROOT, self.user_id, folder_name)
        os.makedirs(user_dir, exist_ok=True)

        unique_name = f"import_{uuid.uuid4().hex[:12]}.{ext}"
        target_path = os.path.join(user_dir, unique_name)

        with open(target_path, "wb") as f:
            f.write(file_bytes)

        return f"/api/v1/wardrobe/capture/images/{self.user_id}/{folder_name}/{unique_name}"

    def generate_next_garment_id(self, wardrobe_service: WardrobeService) -> str:
        """
        Atomically generates the next unique sequential garment ID (e.g. 'CLO-019')
        ensuring zero collisions even under concurrent registration requests.
        """
        with _ID_GENERATION_LOCK:
            max_num = 0

            # 1. Check Supabase table directly if available
            try:
                resp = self.supabase.table("wardrobe_items").select("id").eq("user_id", self.user_id).execute()
                if resp.data:
                    for row in resp.data:
                        gid = str(row.get("id", ""))
                        if gid.startswith("CLO-"):
                            try:
                                num = int(gid.replace("CLO-", ""))
                                if num > max_num:
                                    max_num = num
                            except ValueError:
                                pass
            except Exception as e:
                logger.warning(f"[WardrobeImport] Database query for max ID failed, checking wardrobe_service: {e}")

            # 2. Check wardrobe service memory store
            items_resp = wardrobe_service.get_items(limit=1000)
            for item in items_resp.items:
                if item.id.startswith("CLO-"):
                    try:
                        num = int(item.id.replace("CLO-", ""))
                        if num > max_num:
                            max_num = num
                    except ValueError:
                        pass

            next_num = max_num + 1
            return f"CLO-{next_num:03d}"

    def register_garment(
        self,
        request: GarmentImportRegisterRequest,
        wardrobe_service: WardrobeService,
    ) -> GarmentImportRegisterResponse:
        """
        Registers an imported garment into wardrobe_items:
        - Validates metadata payload
        - Validates mandatory catalogue image
        - Allocates unique CLO-xxx ID
        - Stores core fields in SQL columns and full 1.1 tree in metadata_payload
        - Enforces laundry_status = null initially
        """
        if not request.catalogue_image_ref or not request.catalogue_image_ref.strip():
            raise ValueError("Please upload a catalogue image before continuing.")

        # Validate metadata
        val_res = self.validate_metadata(metadata_dict=request.metadata)
        if not val_res.valid:
            raise ValueError(f"Metadata validation failed: {'; '.join(val_res.errors)}")

        meta = val_res.normalized_metadata or request.metadata
        identity = meta.get("identity", {})
        appearance = meta.get("appearance", {})
        construction = meta.get("construction", {})
        material = meta.get("material", {})
        sizing = meta.get("sizing", {})
        usage = meta.get("usage", {})
        purchase = meta.get("purchase", {})

        # Parse purchase date
        p_date = None
        if purchase.get("purchase_date"):
            try:
                if isinstance(purchase["purchase_date"], str):
                    p_date = datetime.strptime(purchase["purchase_date"], "%Y-%m-%d").date()
                elif isinstance(purchase["purchase_date"], date):
                    p_date = purchase["purchase_date"]
            except Exception:
                p_date = None

        # Generate atomic ID
        garment_id = self.generate_next_garment_id(wardrobe_service)

        notes_list = meta.get("notes", [])
        combined_notes = "; ".join(notes_list) if isinstance(notes_list, list) and notes_list else None
        if not combined_notes and identity.get("description"):
            combined_notes = identity.get("description")

        # Map to GarmentCreate schema
        create_dto = GarmentCreate(
            id=garment_id,
            name=identity.get("garment_name") or "Imported Garment",
            main_category=identity.get("category") or "Tops",
            subcategory=identity.get("subcategory"),
            original_image_ref=request.original_image_ref,
            processed_image_ref=request.catalogue_image_ref,
            thumbnail_ref=request.catalogue_image_ref,
            primary_color=appearance.get("primary_colour") or "Unknown",
            secondary_colors=appearance.get("secondary_colours") or [],
            pattern=appearance.get("pattern"),
            fabric_material=material.get("fabric_appearance") or material.get("primary_material"),
            neckline=construction.get("neckline"),
            sleeve_length=construction.get("sleeve_length"),
            fit=construction.get("fit"),
            silhouette=construction.get("silhouette"),
            garment_length=construction.get("garment_length"),
            size=sizing.get("labelled_size"),
            brand=purchase.get("brand"),
            purchase_date=p_date,
            purchase_price=purchase.get("purchase_price"),
            purchase_currency=purchase.get("purchase_currency") or "INR",
            occasions=usage.get("occasions") or [],
            seasons=usage.get("seasons") or [],
            laundry_status=None,  # Strictly null on new registration per PRD
            is_favorite=False,
            notes=combined_notes,
        )

        created_garment = wardrobe_service.create_item(create_dto)

        # Attach metadata_payload and provenance to database record / local store
        record_update = {
            "metadata_payload": meta,
            "metadata_version": "1.1",
            "import_provenance": "CHATGPT_IMPORT",
        }

        # Update in-memory session store
        local_store = wardrobe_service._get_local_store()
        if garment_id in local_store:
            local_store[garment_id].update(record_update)

        # Update Supabase database table
        try:
            self.supabase.table("wardrobe_items").update(record_update).eq("id", garment_id).eq("user_id", self.user_id).execute()
        except Exception as e:
            logger.warning(f"[WardrobeImport] Updating metadata_payload in Supabase: {e}")

        garment_dict = created_garment.model_dump()
        garment_dict.update(record_update)

        return GarmentImportRegisterResponse(
            success=True,
            garment_id=garment_id,
            message=f"Successfully registered {created_garment.name} ({garment_id}) to My Wardrobe.",
            garment=garment_dict,
        )
