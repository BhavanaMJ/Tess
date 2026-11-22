from datetime import datetime, timezone
from typing import List, Optional, Dict, Any, Tuple
import uuid
import logging
from supabase import Client

from app.schemas.laundry import (
    LaundryStatusEnum,
    BatchStatusEnum,
    LaundryEventTypeEnum,
    LaundryStatsResponse,
    GarmentLaundryStatusUpdate,
    LaundryHistoryEntryResponse,
    LaundryBatchCreate,
    LaundryBatchResponse,
    LaundryBatchItemResponse,
    LaundryBatchStatusUpdate,
    BatchTransitionResponse,
)
from app.schemas.wardrobe import GarmentResponse, GarmentListResponse

logger = logging.getLogger(__name__)

# Session in-memory store for fallback & unit tests
_SESSION_BATCHES_STORE: Dict[str, Dict[str, Dict[str, Any]]] = {}
_SESSION_BATCH_ITEMS_STORE: Dict[str, Dict[str, Dict[str, Any]]] = {}
_SESSION_HISTORY_STORE: Dict[str, List[Dict[str, Any]]] = {}

class LaundryService:
    def __init__(self, supabase: Client, user_id: str, wardrobe_service=None):
        self.supabase = supabase
        self.user_id = user_id
        self.wardrobe_service = wardrobe_service

        if self.user_id not in _SESSION_BATCHES_STORE:
            _SESSION_BATCHES_STORE[self.user_id] = {}
        if self.user_id not in _SESSION_BATCH_ITEMS_STORE:
            _SESSION_BATCH_ITEMS_STORE[self.user_id] = {}
        if self.user_id not in _SESSION_HISTORY_STORE:
            _SESSION_HISTORY_STORE[self.user_id] = []

    def _get_batches_store(self) -> Dict[str, Dict[str, Any]]:
        return _SESSION_BATCHES_STORE[self.user_id]

    def _get_batch_items_store(self) -> Dict[str, Dict[str, Any]]:
        return _SESSION_BATCH_ITEMS_STORE[self.user_id]

    def _get_history_store(self) -> List[Dict[str, Any]]:
        return _SESSION_HISTORY_STORE[self.user_id]

    # 1. LAUNDRY STATS
    def get_laundry_stats(self) -> LaundryStatsResponse:
        records: List[Dict[str, Any]] = []
        try:
            res = self.supabase.table("wardrobe_items").select("*").eq("user_id", self.user_id).eq("is_archived", False).execute()
            if res.data is not None:
                records = res.data
        except Exception as e:
            logger.warning(f"[LaundryService] Remote stats query fallback: {e}")
            if self.wardrobe_service:
                local = self.wardrobe_service._get_local_store()
                records = [v for v in local.values() if not v.get("is_archived", False)]

        total = len(records)
        clean = sum(1 for r in records if r.get("laundry_status") == LaundryStatusEnum.CLEAN.value)
        worn = sum(1 for r in records if r.get("laundry_status") == LaundryStatusEnum.WORN.value)
        washing = sum(1 for r in records if r.get("laundry_status") == LaundryStatusEnum.WASHING.value)
        drying = sum(1 for r in records if r.get("laundry_status") == LaundryStatusEnum.DRYING.value)
        stored = sum(1 for r in records if r.get("laundry_status") == LaundryStatusEnum.STORED.value)
        unassigned = sum(1 for r in records if r.get("laundry_status") is None)

        # Count active batches
        active_batches = len([b for b in self.get_batches() if b.status in ("CREATED", "WASHING", "DRYING")])

        return LaundryStatsResponse(
            total_garments=total,
            clean_count=clean,
            worn_count=worn,
            washing_count=washing,
            drying_count=drying,
            stored_count=stored,
            unassigned_count=unassigned,
            active_batches_count=active_batches,
        )

    # 2. GARMENT STATUS TRANSITION
    def update_garment_laundry_status(
        self,
        garment_id: str,
        update_data: GarmentLaundryStatusUpdate,
    ) -> GarmentResponse:
        now_dt = datetime.now(timezone.utc)
        now_iso = now_dt.isoformat()

        # Check idempotency if key provided
        if update_data.idempotency_key:
            history = self._get_history_store()
            for h in history:
                if h.get("idempotency_key") == update_data.idempotency_key:
                    logger.info(f"[LaundryService] Idempotent request duplicate detected: {update_data.idempotency_key}")
                    if self.wardrobe_service:
                        existing = self.wardrobe_service.get_item(garment_id)
                        if existing:
                            return existing

        garment = None
        if self.wardrobe_service:
            garment = self.wardrobe_service.get_item(garment_id)

        if not garment:
            raise ValueError(f"Garment {garment_id} not found or does not belong to user.")

        prev_status = garment.laundry_status
        new_status = update_data.laundry_status.value if update_data.laundry_status else None

        wear_count = garment.wear_count or 0
        wash_count = garment.wash_count or 0
        last_worn = garment.last_worn_date
        last_washed = garment.last_washed_date

        event_type = LaundryEventTypeEnum.STATUS_CHANGE.value

        # Business Rule: Worn increments wear_count exactly once upon transition into WORN
        if new_status == LaundryStatusEnum.WORN.value:
            event_type = LaundryEventTypeEnum.WEAR.value
            if prev_status != LaundryStatusEnum.WORN.value:
                wear_count += 1
                last_worn = now_dt

        # Business Rule: Moving to CLEAN from WASHING or DRYING completes wash lifecycle
        elif new_status == LaundryStatusEnum.CLEAN.value:
            if prev_status in (LaundryStatusEnum.WASHING.value, LaundryStatusEnum.DRYING.value):
                event_type = LaundryEventTypeEnum.WASH_CYCLE_COMPLETED.value
                wash_count += 1
                last_washed = now_dt
            else:
                event_type = LaundryEventTypeEnum.STATUS_CHANGE.value

        elif new_status == LaundryStatusEnum.WASHING.value:
            event_type = LaundryEventTypeEnum.WASH_CYCLE_STARTED.value

        elif new_status == LaundryStatusEnum.STORED.value:
            event_type = LaundryEventTypeEnum.STORED.value

        if update_data.source == "MANUAL" and garment.active_batch_id:
            event_type = LaundryEventTypeEnum.MANUAL_OVERRIDE.value

        # Record history event
        history_id = f"hist_{uuid.uuid4().hex[:12]}"
        history_record = {
            "id": history_id,
            "user_id": self.user_id,
            "garment_id": garment_id,
            "batch_id": garment.active_batch_id,
            "event_type": event_type,
            "previous_status": prev_status,
            "new_status": new_status,
            "source": update_data.source or "MANUAL",
            "notes": update_data.notes,
            "idempotency_key": update_data.idempotency_key,
            "created_at": now_dt,
        }
        self._get_history_store().append(history_record)

        try:
            self.supabase.table("wardrobe_laundry_history").insert({
                **history_record,
                "created_at": now_iso,
            }).execute()
        except Exception as e:
            logger.warning(f"[LaundryService] Remote history insert fallback: {e}")

        # Update garment in wardrobe
        update_dict = {
            "laundry_status": new_status,
            "wear_count": wear_count,
            "wash_count": wash_count,
            "last_worn_date": last_worn.isoformat() if last_worn else None,
            "last_washed_date": last_washed.isoformat() if last_washed else None,
            "updated_at": now_iso,
        }

        if self.wardrobe_service:
            local = self.wardrobe_service._get_local_store()
            if garment_id in local:
                local[garment_id].update(update_dict)

        try:
            self.supabase.table("wardrobe_items").update(update_dict).eq("id", garment_id).eq("user_id", self.user_id).execute()
        except Exception as e:
            logger.warning(f"[LaundryService] Remote garment status update fallback: {e}")

        if self.wardrobe_service:
            return self.wardrobe_service.get_item(garment_id)
        return GarmentResponse(
            id=garment_id,
            user_id=self.user_id,
            name=garment.name,
            main_category=garment.main_category,
            primary_color=garment.primary_color,
            laundry_status=new_status,
            wear_count=wear_count,
            wash_count=wash_count,
            last_worn_date=last_worn,
            last_washed_date=last_washed,
            created_at=garment.created_at,
            updated_at=now_dt,
        )

    # 3. GARMENT LAUNDRY HISTORY
    def get_garment_laundry_history(self, garment_id: str) -> List[LaundryHistoryEntryResponse]:
        records: List[Dict[str, Any]] = []
        try:
            res = self.supabase.table("wardrobe_laundry_history").select("*").eq("user_id", self.user_id).eq("garment_id", garment_id).order("created_at", desc=True).execute()
            if res.data:
                records = res.data
        except Exception as e:
            logger.warning(f"[LaundryService] Remote history query fallback: {e}")
            local = self._get_history_store()
            records = [h for h in local if h.get("garment_id") == garment_id]

        results = []
        for r in records:
            c_at = r.get("created_at")
            if isinstance(c_at, str):
                c_at = datetime.fromisoformat(c_at.replace("Z", "+00:00"))
            results.append(LaundryHistoryEntryResponse(
                id=r["id"],
                user_id=r["user_id"],
                garment_id=r["garment_id"],
                batch_id=r.get("batch_id"),
                event_type=r["event_type"],
                previous_status=r.get("previous_status"),
                new_status=r.get("new_status"),
                source=r.get("source", "MANUAL"),
                notes=r.get("notes"),
                created_at=c_at or datetime.now(timezone.utc),
            ))
        results.sort(key=lambda x: x.created_at, reverse=True)
        return results

    # 4. LAUNDRY BATCHES
    def create_batch(self, batch_data: LaundryBatchCreate) -> LaundryBatchResponse:
        if not batch_data.garment_ids:
            raise ValueError("Laundry batch cannot be empty. Please select at least one garment.")

        # Validate unique garments in requested batch
        if len(batch_data.garment_ids) != len(set(batch_data.garment_ids)):
            raise ValueError("Duplicate garments in batch selection.")

        # Check idempotency
        if batch_data.idempotency_key:
            for b in self._get_batches_store().values():
                if b.get("idempotency_key") == batch_data.idempotency_key:
                    return self._to_batch_response(b)

        now_dt = datetime.now(timezone.utc)
        now_iso = now_dt.isoformat()

        # Validate garments belong to user and exist
        garments = []
        if self.wardrobe_service:
            for gid in batch_data.garment_ids:
                g = self.wardrobe_service.get_item(gid)
                if not g:
                    raise ValueError(f"Garment {gid} does not exist or access denied.")
                if g.is_archived:
                    raise ValueError(f"Cannot add archived garment {gid} to a laundry batch.")
                garments.append(g)

        # Generate sequential batch number: BATCH-001, BATCH-002, etc.
        existing_batches = self.get_batches()
        batch_num_int = len(existing_batches) + 1
        batch_number = f"BATCH-{batch_num_int:03d}"
        batch_id = f"batch_{uuid.uuid4().hex[:12]}"
        batch_name = batch_data.name or f"Laundry Batch #{batch_num_int:03d}"
        initial_status = batch_data.initial_status.value

        batch_dict = {
            "id": batch_id,
            "user_id": self.user_id,
            "batch_number": batch_number,
            "name": batch_name,
            "status": initial_status,
            "notes": batch_data.notes,
            "idempotency_key": batch_data.idempotency_key,
            "created_at": now_dt,
            "updated_at": now_dt,
            "completed_at": None,
        }
        self._get_batches_store()[batch_id] = batch_dict

        # Create batch items and update garment status
        items_list: List[LaundryBatchItemResponse] = []
        for g in garments:
            item_id = f"bitem_{uuid.uuid4().hex[:12]}"
            bitem_dict = {
                "id": item_id,
                "batch_id": batch_id,
                "garment_id": g.id,
                "user_id": self.user_id,
                "status": "ACTIVE",
                "added_at": now_dt,
                "removed_at": None,
            }
            self._get_batch_items_store()[item_id] = bitem_dict

            # Transition garment status to match batch initial status (default: WASHING)
            self.update_garment_laundry_status(
                garment_id=g.id,
                update_data=GarmentLaundryStatusUpdate(
                    laundry_status=LaundryStatusEnum(initial_status) if initial_status in LaundryStatusEnum.__members__ else LaundryStatusEnum.WASHING,
                    source="BATCH_ASSIGNMENT",
                    notes=f"Assigned to {batch_number}: {batch_name}",
                ),
            )

            # Set active batch ID
            if self.wardrobe_service:
                local = self.wardrobe_service._get_local_store()
                if g.id in local:
                    local[g.id]["active_batch_id"] = batch_id

            items_list.append(LaundryBatchItemResponse(
                id=item_id,
                batch_id=batch_id,
                garment_id=g.id,
                garment_name=g.name,
                garment_category=g.main_category,
                current_laundry_status=initial_status,
                thumbnail_ref=g.thumbnail_ref,
                status="ACTIVE",
                added_at=now_dt,
            ))

        try:
            self.supabase.table("laundry_batches").insert({
                **batch_dict,
                "created_at": now_iso,
                "updated_at": now_iso,
            }).execute()
        except Exception as e:
            logger.warning(f"[LaundryService] Remote batch insert fallback: {e}")

        return LaundryBatchResponse(
            id=batch_id,
            user_id=self.user_id,
            batch_number=batch_number,
            name=batch_name,
            status=initial_status,
            notes=batch_data.notes,
            items_count=len(items_list),
            items=items_list,
            created_at=now_dt,
            updated_at=now_dt,
        )

    def get_batches(self, status: Optional[str] = None) -> List[LaundryBatchResponse]:
        records: List[Dict[str, Any]] = []
        try:
            query = self.supabase.table("laundry_batches").select("*").eq("user_id", self.user_id)
            if status:
                query = query.eq("status", status)
            res = query.order("created_at", desc=True).execute()
            if res.data:
                records = res.data
        except Exception as e:
            logger.warning(f"[LaundryService] Remote get_batches fallback: {e}")
            local = self._get_batches_store()
            records = [b for b in local.values() if status is None or b.get("status") == status]

        batches = [self._to_batch_response(r) for r in records]
        batches.sort(key=lambda b: b.created_at, reverse=True)
        return batches

    def get_batch(self, batch_id: str) -> Optional[LaundryBatchResponse]:
        record = None
        try:
            res = self.supabase.table("laundry_batches").select("*").eq("id", batch_id).eq("user_id", self.user_id).execute()
            if res.data and len(res.data) > 0:
                record = res.data[0]
        except Exception as e:
            logger.warning(f"[LaundryService] Remote get_batch fallback: {e}")
            record = self._get_batches_store().get(batch_id)

        if not record:
            return None
        return self._to_batch_response(record)

    def _to_batch_response(self, record: Dict[str, Any]) -> LaundryBatchResponse:
        bid = record["id"]
        # Retrieve member batch items
        items = self._get_batch_member_items(bid)

        c_at = record.get("created_at")
        if isinstance(c_at, str):
            c_at = datetime.fromisoformat(c_at.replace("Z", "+00:00"))
        u_at = record.get("updated_at")
        if isinstance(u_at, str):
            u_at = datetime.fromisoformat(u_at.replace("Z", "+00:00"))
        comp_at = record.get("completed_at")
        if isinstance(comp_at, str):
            comp_at = datetime.fromisoformat(comp_at.replace("Z", "+00:00"))

        return LaundryBatchResponse(
            id=bid,
            user_id=record["user_id"],
            batch_number=record["batch_number"],
            name=record["name"],
            status=record["status"],
            notes=record.get("notes"),
            items_count=len(items),
            items=items,
            created_at=c_at or datetime.now(timezone.utc),
            updated_at=u_at or datetime.now(timezone.utc),
            completed_at=comp_at,
        )

    def _get_batch_member_items(self, batch_id: str) -> List[LaundryBatchItemResponse]:
        raw_items: List[Dict[str, Any]] = []
        try:
            res = self.supabase.table("laundry_batch_items").select("*").eq("batch_id", batch_id).eq("user_id", self.user_id).execute()
            if res.data:
                raw_items = res.data
        except Exception as e:
            raw_items = [item for item in self._get_batch_items_store().values() if item.get("batch_id") == batch_id]

        results = []
        for r in raw_items:
            gid = r["garment_id"]
            garment = self.wardrobe_service.get_item(gid) if self.wardrobe_service else None
            a_at = r.get("added_at")
            if isinstance(a_at, str):
                a_at = datetime.fromisoformat(a_at.replace("Z", "+00:00"))

            results.append(LaundryBatchItemResponse(
                id=r["id"],
                batch_id=batch_id,
                garment_id=gid,
                garment_name=garment.name if garment else "Garment",
                garment_category=garment.main_category if garment else None,
                current_laundry_status=garment.laundry_status if garment else None,
                thumbnail_ref=garment.thumbnail_ref if garment else None,
                status=r.get("status", "ACTIVE"),
                added_at=a_at or datetime.now(timezone.utc),
            ))
        return results

    # 5. ADVANCE BATCH STATUS (WITH INDIVIDUAL OVERRIDE PRESERVATION)
    def advance_batch_status(
        self,
        batch_id: str,
        update_data: LaundryBatchStatusUpdate,
    ) -> BatchTransitionResponse:
        batch = self.get_batch(batch_id)
        if not batch:
            raise ValueError(f"Laundry batch {batch_id} not found.")

        target_status = update_data.status.value
        now_dt = datetime.now(timezone.utc)
        now_iso = now_dt.isoformat()

        updated_gids: List[str] = []
        skipped_gids: List[str] = []

        # Inspect each member garment and apply transition rules
        for item in batch.items:
            if item.status != "ACTIVE":
                skipped_gids.append(item.garment_id)
                continue

            current_g_status = item.current_laundry_status

            # Transition Rule: Created -> Washing
            if target_status == BatchStatusEnum.WASHING.value:
                if current_g_status in (LaundryStatusEnum.WORN.value, None, "CREATED"):
                    self.update_garment_laundry_status(
                        garment_id=item.garment_id,
                        update_data=GarmentLaundryStatusUpdate(
                            laundry_status=LaundryStatusEnum.WASHING,
                            source="BATCH_TRANSITION",
                            notes=f"Batch {batch.batch_number} advanced to WASHING",
                        ),
                    )
                    updated_gids.append(item.garment_id)
                else:
                    # Individual override preserved (e.g. already DRYING or CLEAN)
                    skipped_gids.append(item.garment_id)

            # Transition Rule: Washing -> Drying
            elif target_status == BatchStatusEnum.DRYING.value:
                if current_g_status == LaundryStatusEnum.WASHING.value:
                    self.update_garment_laundry_status(
                        garment_id=item.garment_id,
                        update_data=GarmentLaundryStatusUpdate(
                            laundry_status=LaundryStatusEnum.DRYING,
                            source="BATCH_TRANSITION",
                            notes=f"Batch {batch.batch_number} advanced to DRYING",
                        ),
                    )
                    updated_gids.append(item.garment_id)
                else:
                    # Garment already moved to DRYING individually or put away; do not overwrite
                    skipped_gids.append(item.garment_id)

            # Transition Rule: Drying -> Completed (Garments become CLEAN)
            elif target_status == BatchStatusEnum.COMPLETED.value:
                if current_g_status in (LaundryStatusEnum.DRYING.value, LaundryStatusEnum.WASHING.value):
                    self.update_garment_laundry_status(
                        garment_id=item.garment_id,
                        update_data=GarmentLaundryStatusUpdate(
                            laundry_status=LaundryStatusEnum.CLEAN,
                            source="BATCH_TRANSITION",
                            notes=f"Batch {batch.batch_number} completed. Garment washed & ready.",
                        ),
                    )
                    # Unlink active batch
                    if self.wardrobe_service:
                        local = self.wardrobe_service._get_local_store()
                        if item.garment_id in local:
                            local[item.garment_id]["active_batch_id"] = None
                    updated_gids.append(item.garment_id)
                else:
                    skipped_gids.append(item.garment_id)

            elif target_status == BatchStatusEnum.CANCELLED.value:
                if self.wardrobe_service:
                    local = self.wardrobe_service._get_local_store()
                    if item.garment_id in local:
                        local[item.garment_id]["active_batch_id"] = None
                updated_gids.append(item.garment_id)

        # Update batch record
        completed_at = now_dt if target_status == BatchStatusEnum.COMPLETED.value else None
        local_batches = self._get_batches_store()
        if batch_id in local_batches:
            local_batches[batch_id]["status"] = target_status
            local_batches[batch_id]["updated_at"] = now_dt
            if completed_at:
                local_batches[batch_id]["completed_at"] = completed_at

        try:
            self.supabase.table("laundry_batches").update({
                "status": target_status,
                "updated_at": now_iso,
                "completed_at": now_iso if completed_at else None,
            }).eq("id", batch_id).eq("user_id", self.user_id).execute()
        except Exception as e:
            logger.warning(f"[LaundryService] Remote batch update fallback: {e}")

        message = (
            f"Batch {batch.batch_number} advanced to {target_status}. "
            f"Updated {len(updated_gids)} garments; {len(skipped_gids)} garments kept their individual overrides."
        )

        return BatchTransitionResponse(
            batch_id=batch_id,
            new_batch_status=target_status,
            updated_garment_ids=updated_gids,
            skipped_garment_ids=skipped_gids,
            message=message,
        )

    # 6. ADD / REMOVE ITEMS IN BATCH
    def add_items_to_batch(self, batch_id: str, garment_ids: List[str]) -> LaundryBatchResponse:
        batch = self.get_batch(batch_id)
        if not batch:
            raise ValueError(f"Batch {batch_id} not found.")

        now_dt = datetime.now(timezone.utc)
        for gid in garment_ids:
            # Check not already in batch
            existing = [item for item in batch.items if item.garment_id == gid and item.status == "ACTIVE"]
            if existing:
                continue

            item_id = f"bitem_{uuid.uuid4().hex[:12]}"
            bitem_dict = {
                "id": item_id,
                "batch_id": batch_id,
                "garment_id": gid,
                "user_id": self.user_id,
                "status": "ACTIVE",
                "added_at": now_dt,
            }
            self._get_batch_items_store()[item_id] = bitem_dict

            # Match batch status
            if batch.status in LaundryStatusEnum.__members__:
                self.update_garment_laundry_status(
                    garment_id=gid,
                    update_data=GarmentLaundryStatusUpdate(
                        laundry_status=LaundryStatusEnum(batch.status),
                        source="BATCH_ASSIGNMENT",
                        notes=f"Added to batch {batch.batch_number}",
                    ),
                )
            if self.wardrobe_service:
                local = self.wardrobe_service._get_local_store()
                if gid in local:
                    local[gid]["active_batch_id"] = batch_id

        return self.get_batch(batch_id)

    def remove_item_from_batch(self, batch_id: str, garment_id: str) -> bool:
        batch = self.get_batch(batch_id)
        if not batch:
            return False

        now_dt = datetime.now(timezone.utc)
        found = False
        for item in self._get_batch_items_store().values():
            if item.get("batch_id") == batch_id and item.get("garment_id") == garment_id and item.get("status") == "ACTIVE":
                item["status"] = "REMOVED"
                item["removed_at"] = now_dt
                found = True

        if found:
            # Log history event
            self._get_history_store().append({
                "id": f"hist_{uuid.uuid4().hex[:12]}",
                "user_id": self.user_id,
                "garment_id": garment_id,
                "batch_id": batch_id,
                "event_type": LaundryEventTypeEnum.BATCH_REMOVED.value,
                "source": "MANUAL",
                "notes": f"Removed from {batch.batch_number}",
                "created_at": now_dt,
            })
            if self.wardrobe_service:
                local = self.wardrobe_service._get_local_store()
                if garment_id in local:
                    local[garment_id]["active_batch_id"] = None

            try:
                self.supabase.table("laundry_batch_items").update({
                    "status": "REMOVED",
                    "removed_at": now_dt.isoformat(),
                }).eq("batch_id", batch_id).eq("garment_id", garment_id).execute()
            except Exception as e:
                logger.warning(f"[LaundryService] Remote batch item remove fallback: {e}")

        return found

