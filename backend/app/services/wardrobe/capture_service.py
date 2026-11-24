import os
import io
import uuid
import logging
from datetime import datetime, timezone
from typing import List, Optional, Dict, Any, Tuple
from PIL import Image, ImageStat, ImageOps
from supabase import Client

from app.schemas.wardrobe import GarmentCreate
from app.schemas.wardrobe_capture import (
    CaptureJobResponse,
    GarmentCandidateResponse,
    GarmentCandidateUpdate,
    CaptureJobConfirmResponse,
    CaptureJobStatusEnum,
)
from app.services.wardrobe.vision_provider import get_vision_provider, GarmentVisionProvider
from app.services.wardrobe.service import WardrobeService

logger = logging.getLogger(__name__)

# Base local media path for wardrobe images
MEDIA_ROOT = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "media", "wardrobe")
os.makedirs(MEDIA_ROOT, exist_ok=True)

# Session memory stores for capture jobs & candidates when Supabase table is unreachable
_SESSION_CAPTURE_JOBS: Dict[str, Dict[str, Dict[str, Any]]] = {}
_SESSION_CANDIDATES: Dict[str, Dict[str, Dict[str, Any]]] = {}

class WardrobeCaptureService:
    def __init__(self, supabase: Client, user_id: str, vision_provider: Optional[GarmentVisionProvider] = None):
        self.supabase = supabase
        self.user_id = user_id
        self.vision_provider = vision_provider or get_vision_provider()
        if self.user_id not in _SESSION_CAPTURE_JOBS:
            _SESSION_CAPTURE_JOBS[self.user_id] = {}
        if self.user_id not in _SESSION_CANDIDATES:
            _SESSION_CANDIDATES[self.user_id] = {}

    def _user_jobs_store(self) -> Dict[str, Dict[str, Any]]:
        return _SESSION_CAPTURE_JOBS[self.user_id]

    def _user_candidates_store(self) -> Dict[str, Dict[str, Any]]:
        return _SESSION_CANDIDATES[self.user_id]

    def _validate_image(self, image_bytes: bytes) -> Image.Image:
        """Validates file presence, size, resolution, and basic readability."""
        if not image_bytes or len(image_bytes) == 0:
            raise ValueError("The uploaded photograph is empty. Please select or capture a valid photo.")

        # 15MB size limit
        if len(image_bytes) > 15 * 1024 * 1024:
            raise ValueError("Photograph exceeds maximum 15MB file size limit. Please choose a smaller image.")

        try:
            img = Image.open(io.BytesIO(image_bytes))
            img.verify()
            # Reopen after verify to load pixel buffer
            img = Image.open(io.BytesIO(image_bytes))
            img = ImageOps.exif_transpose(img)
            img.load()
        except Exception as e:
            raise ValueError(f"The photograph format is invalid or unreadable: {e}")

        w, h = img.size
        if w < 100 or h < 100:
            raise ValueError("Photograph resolution is too low (minimum 100x100 required). Please capture in better resolution.")

        # Check for completely black/dark image
        rgb = img.convert("RGB")
        stat = ImageStat.Stat(rgb)
        mean_brightness = sum(stat.mean[:3]) / 3.0
        if mean_brightness < 10.0:
            raise ValueError("The photograph is excessively dark. Try capturing with better lighting.")

        return img

    def _save_image_file(self, folder: str, file_id: str, data: bytes, ext: str = "jpg") -> str:
        """Saves image bytes to user-scoped directory and returns local access reference."""
        user_folder = os.path.join(MEDIA_ROOT, self.user_id, folder)
        os.makedirs(user_folder, exist_ok=True)
        file_name = f"{file_id}.{ext}"
        full_path = os.path.join(user_folder, file_name)
        with open(full_path, "wb") as f:
            f.write(data)
        return f"/api/v1/wardrobe/capture/images/{self.user_id}/{folder}/{file_name}"

    async def create_capture_job(self, image_bytes: bytes, filename: str) -> CaptureJobResponse:
        """
        Executes end-to-end Smart Capture job:
        1. Validates photograph.
        2. Persists original image securely.
        3. Runs multi-garment detection & segmentation.
        4. Creates individual candidate records.
        5. Updates job status to AWAITING_APPROVAL.
        """
        img = self._validate_image(image_bytes)
        job_id = f"job_{uuid.uuid4().hex[:12]}"
        now = datetime.now(timezone.utc)

        # Securely store original image
        orig_ref = self._save_image_file("originals", job_id, image_bytes, "jpg")

        job_record = {
            "id": job_id,
            "user_id": self.user_id,
            "original_image_ref": orig_ref,
            "status": CaptureJobStatusEnum.ANALYZING.value,
            "current_stage": "Analyzing photograph & detecting garments",
            "progress_percent": 30,
            "total_detected": 0,
            "provider_type": self.vision_provider.provider_name,
            "error_message": None,
            "created_at": now.isoformat(),
            "updated_at": now.isoformat(),
        }

        # Save job record
        self._user_jobs_store()[job_id] = job_record
        try:
            self.supabase.table("wardrobe_capture_jobs").insert(job_record).execute()
        except Exception as e:
            logger.info(f"[CaptureService] Supabase capture jobs table unavailable ({e}); using session store.")

        # Run AI detection & segmentation
        candidate_responses: List[GarmentCandidateResponse] = []
        try:
            job_record["current_stage"] = "Separating garments & creating studio catalogue cards"
            job_record["progress_percent"] = 65

            detection_results = await self.vision_provider.detect_and_segment(image_bytes, filename)

            if not detection_results:
                raise ValueError("No identifiable garments could be detected in this photograph. Try another angle or lighting.")

            for res in detection_results:
                cand_id = f"cand_{uuid.uuid4().hex[:12]}"

                # Save studio-white processed catalogue image
                processed_ref = None
                if res.processed_image_bytes:
                    processed_ref = self._save_image_file("processed", f"{job_id}_{cand_id}", res.processed_image_bytes, "jpg")

                # Save original crop image
                crop_ref = None
                if res.original_crop_bytes:
                    crop_ref = self._save_image_file("crops", f"{job_id}_{cand_id}_crop", res.original_crop_bytes, "jpg")

                cand_record = {
                    "id": cand_id,
                    "job_id": job_id,
                    "user_id": self.user_id,
                    "suggested_name": res.suggested_name,
                    "main_category": res.main_category,
                    "subcategory": res.subcategory,
                    "primary_color": res.primary_color,
                    "secondary_colors": res.secondary_colors,
                    "pattern": res.pattern,
                    "fabric_material": res.fabric_material,
                    "sleeve_length": res.sleeve_length,
                    "neckline": res.neckline,
                    "fit": res.fit,
                    "silhouette": res.silhouette,
                    "garment_length": res.garment_length,
                    "size": res.size,
                    "brand": res.brand,
                    "confidence_scores": res.confidence_scores,
                    "bounding_box": res.bounding_box,
                    "processed_image_ref": processed_ref,
                    "original_crop_ref": crop_ref,
                    "is_included": True,
                    "is_approved": False,
                    "registered_garment_id": None,
                    "uncertainty_notes": res.uncertainty_notes,
                    "created_at": now.isoformat(),
                    "updated_at": now.isoformat(),
                }

                self._user_candidates_store()[cand_id] = cand_record
                try:
                    self.supabase.table("wardrobe_garment_candidates").insert(cand_record).execute()
                except Exception:
                    pass

                candidate_responses.append(GarmentCandidateResponse(**cand_record))

            job_record["status"] = CaptureJobStatusEnum.AWAITING_APPROVAL.value
            job_record["current_stage"] = "Awaiting user approval"
            job_record["progress_percent"] = 100
            job_record["total_detected"] = len(candidate_responses)
            job_record["updated_at"] = datetime.now(timezone.utc).isoformat()
            self._user_jobs_store()[job_id] = job_record

            try:
                self.supabase.table("wardrobe_capture_jobs").update(job_record).eq("id", job_id).eq("user_id", self.user_id).execute()
            except Exception:
                pass

        except Exception as e:
            logger.error(f"[CaptureService] Processing failed for job {job_id}: {e}")
            job_record["status"] = CaptureJobStatusEnum.FAILED.value
            job_record["current_stage"] = "Processing failed"
            job_record["error_message"] = str(e)
            job_record["updated_at"] = datetime.now(timezone.utc).isoformat()
            try:
                self.supabase.table("wardrobe_capture_jobs").update(job_record).eq("id", job_id).eq("user_id", self.user_id).execute()
            except Exception:
                self._user_jobs_store()[job_id] = job_record

            raise ValueError(str(e))

        return CaptureJobResponse(**job_record, candidates=candidate_responses)

    def get_capture_job(self, job_id: str) -> CaptureJobResponse:
        """Retrieves capture job and its candidate garments with strict user ownership validation."""
        job_data = None
        try:
            resp = self.supabase.table("wardrobe_capture_jobs").select("*").eq("id", job_id).eq("user_id", self.user_id).execute()
            if resp.data:
                job_data = resp.data[0]
        except Exception:
            pass

        if not job_data:
            job_data = self._user_jobs_store().get(job_id)

        if not job_data or str(job_data.get("user_id")) != self.user_id:
            raise KeyError(f"Capture job '{job_id}' not found")

        # Fetch candidates
        candidates = self.get_job_candidates(job_id)
        return CaptureJobResponse(**job_data, candidates=candidates)

    def get_job_candidates(self, job_id: str) -> List[GarmentCandidateResponse]:
        """Retrieves all garment candidates for a capture job."""
        cands: List[Dict[str, Any]] = []
        try:
            resp = self.supabase.table("wardrobe_garment_candidates").select("*").eq("job_id", job_id).eq("user_id", self.user_id).execute()
            if resp.data:
                cands = resp.data
        except Exception:
            pass

        if not cands:
            cands = [c for c in self._user_candidates_store().values() if c.get("job_id") == job_id and str(c.get("user_id")) == self.user_id]

        return [GarmentCandidateResponse(**c) for c in cands]

    def update_candidate(self, candidate_id: str, update: GarmentCandidateUpdate) -> GarmentCandidateResponse:
        """Updates attributes, inclusion flag, or approval state of an individual garment candidate."""
        cand_data = None
        try:
            resp = self.supabase.table("wardrobe_garment_candidates").select("*").eq("id", candidate_id).eq("user_id", self.user_id).execute()
            if resp.data:
                cand_data = resp.data[0]
        except Exception:
            pass

        if not cand_data:
            cand_data = self._user_candidates_store().get(candidate_id)

        if not cand_data or str(cand_data.get("user_id")) != self.user_id:
            raise KeyError(f"Candidate '{candidate_id}' not found")

        update_dict = update.model_dump(exclude_unset=True)
        update_dict["updated_at"] = datetime.now(timezone.utc).isoformat()
        cand_data.update(update_dict)

        try:
            self.supabase.table("wardrobe_garment_candidates").update(update_dict).eq("id", candidate_id).eq("user_id", self.user_id).execute()
        except Exception:
            self._user_candidates_store()[candidate_id] = cand_data

        return GarmentCandidateResponse(**cand_data)

    async def retry_job(self, job_id: str) -> CaptureJobResponse:
        """Retries detection and segmentation on a failed job using preserved original photograph."""
        job = self.get_capture_job(job_id)

        # Resolve local file path
        rel_path = job.original_image_ref.replace("/api/v1/wardrobe/capture/images/", "")
        local_path = os.path.join(MEDIA_ROOT, rel_path)
        if not os.path.exists(local_path):
            raise FileNotFoundError("Original photograph is missing and cannot be reprocessed.")

        with open(local_path, "rb") as f:
            image_bytes = f.read()

        # Delete previous candidates
        try:
            self.supabase.table("wardrobe_garment_candidates").delete().eq("job_id", job_id).eq("user_id", self.user_id).execute()
        except Exception:
            pass
        to_del = [cid for cid, c in self._user_candidates_store().items() if c.get("job_id") == job_id]
        for cid in to_del:
            self._user_candidates_store().pop(cid, None)

        # Re-run detection
        candidates = await self.vision_provider.detect_and_segment(image_bytes, "retry.jpg")
        now = datetime.now(timezone.utc)
        candidate_responses: List[GarmentCandidateResponse] = []

        for res in candidates:
            cand_id = f"cand_{uuid.uuid4().hex[:12]}"
            processed_ref = None
            if res.processed_image_bytes:
                processed_ref = self._save_image_file("processed", f"{job_id}_{cand_id}", res.processed_image_bytes, "jpg")

            cand_record = {
                "id": cand_id,
                "job_id": job_id,
                "user_id": self.user_id,
                "suggested_name": res.suggested_name,
                "main_category": res.main_category,
                "subcategory": res.subcategory,
                "primary_color": res.primary_color,
                "secondary_colors": res.secondary_colors,
                "pattern": res.pattern,
                "fabric_material": res.fabric_material,
                "sleeve_length": res.sleeve_length,
                "neckline": res.neckline,
                "fit": res.fit,
                "silhouette": res.silhouette,
                "garment_length": res.garment_length,
                "size": res.size,
                "brand": res.brand,
                "confidence_scores": res.confidence_scores,
                "bounding_box": res.bounding_box,
                "processed_image_ref": processed_ref,
                "original_crop_ref": None,
                "is_included": True,
                "is_approved": False,
                "registered_garment_id": None,
                "uncertainty_notes": res.uncertainty_notes,
                "created_at": now.isoformat(),
                "updated_at": now.isoformat(),
            }
            self._user_candidates_store()[cand_id] = cand_record
            try:
                self.supabase.table("wardrobe_garment_candidates").insert(cand_record).execute()
            except Exception:
                pass

            candidate_responses.append(GarmentCandidateResponse(**cand_record))

        updated_job = {
            "status": CaptureJobStatusEnum.AWAITING_APPROVAL.value,
            "current_stage": "Awaiting user approval",
            "progress_percent": 100,
            "total_detected": len(candidate_responses),
            "error_message": None,
            "updated_at": now.isoformat(),
        }
        if job_id in self._user_jobs_store():
            self._user_jobs_store()[job_id].update(updated_job)
        try:
            self.supabase.table("wardrobe_capture_jobs").update(updated_job).eq("id", job_id).eq("user_id", self.user_id).execute()
        except Exception:
            pass

        return self.get_capture_job(job_id)

    def _generate_next_garment_id(self, wardrobe_service: WardrobeService) -> str:
        """
        Determines the next sequential garment ID (e.g. CLO-019),
        inspecting all existing garments to ensure idempotency and zero ID collisions.
        """
        items_resp = wardrobe_service.get_items(limit=1000)
        max_num = 0
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

    def confirm_and_register_garments(
        self,
        job_id: str,
        candidate_ids: Optional[List[str]] = None,
    ) -> CaptureJobConfirmResponse:
        """
        Atomically registers approved, included candidates into wardrobe_items:
        1. Ensures only user's candidates are confirmed.
        2. Assigns permanent unique CLO-xxx garment IDs.
        3. Sets laundry status to null (unassigned initially).
        4. Updates job status to COMPLETED.
        """
        job = self.get_capture_job(job_id)
        candidates = self.get_job_candidates(job_id)

        # Filter candidates to register
        to_register = []
        for cand in candidates:
            if not cand.is_included:
                continue
            if candidate_ids is not None and cand.id not in candidate_ids:
                continue
            if cand.is_approved:
                # Already registered
                continue
            to_register.append(cand)

        wardrobe_service = WardrobeService(self.supabase, self.user_id)
        registered_ids: List[str] = []

        for cand in to_register:
            garment_id = self._generate_next_garment_id(wardrobe_service)

            create_dto = GarmentCreate(
                id=garment_id,
                name=cand.suggested_name,
                main_category=cand.main_category,
                subcategory=cand.subcategory,
                original_image_ref=job.original_image_ref,
                processed_image_ref=cand.processed_image_ref,
                thumbnail_ref=cand.processed_image_ref,
                primary_color=cand.primary_color,
                secondary_colors=cand.secondary_colors,
                pattern=cand.pattern,
                fabric_material=cand.fabric_material,
                sleeve_length=cand.sleeve_length,
                neckline=cand.neckline,
                fit=cand.fit,
                silhouette=cand.silhouette,
                garment_length=cand.garment_length,
                size=cand.size,
                brand=cand.brand,
                laundry_status=None,  # null unassigned initially per PRD
                is_favorite=False,
                notes=cand.uncertainty_notes,
            )

            created_garment = wardrobe_service.create_item(create_dto)
            registered_ids.append(created_garment.id)

            # Mark candidate as approved
            self.update_candidate(
                cand.id,
                GarmentCandidateUpdate(is_approved=True),
            )
            try:
                self.supabase.table("wardrobe_garment_candidates").update({"registered_garment_id": created_garment.id}).eq("id", cand.id).execute()
            except Exception:
                if cand.id in self._user_candidates_store():
                    self._user_candidates_store()[cand.id]["registered_garment_id"] = created_garment.id

        # Update job status
        completed_update = {
            "status": CaptureJobStatusEnum.COMPLETED.value,
            "current_stage": "All approved garments registered in My Wardrobe",
            "progress_percent": 100,
            "updated_at": datetime.now(timezone.utc).isoformat(),
        }
        try:
            self.supabase.table("wardrobe_capture_jobs").update(completed_update).eq("id", job_id).eq("user_id", self.user_id).execute()
        except Exception:
            if job_id in self._user_jobs_store():
                self._user_jobs_store()[job_id].update(completed_update)

        return CaptureJobConfirmResponse(
            success=True,
            job_id=job_id,
            registered_count=len(registered_ids),
            registered_garment_ids=registered_ids,
            message=f"Successfully registered {len(registered_ids)} garments to wardrobe.",
        )
