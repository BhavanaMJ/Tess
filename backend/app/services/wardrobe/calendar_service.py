from datetime import datetime, date, timedelta, timezone
from typing import List, Optional, Dict, Any
import uuid
import logging
from supabase import Client

from app.schemas.calendar import (
    WeatherSummary,
    OutfitPlanCreate,
    OutfitPlanUpdate,
    OutfitPlanResponse,
    ActualWearCreate,
    ActualWearResponse,
    CalendarDayDetailResponse,
    CalendarWeekResponse,
    CalendarMonthResponse,
    RecentlyWornGarmentItem,
    UnusedGarmentItem,
    RepetitionCheckResponse,
)
from app.schemas.outfit import OutfitResponse, OutfitWearRequest
from app.services.wardrobe.outfit_service import OutfitService
from app.services.wardrobe.weather_service import WeatherService

logger = logging.getLogger(__name__)

# Session store for in-memory and fallback execution
_SESSION_PLANS_STORE: Dict[str, Dict[str, Dict[str, Any]]] = {}
_SESSION_CALENDAR_WEAR_STORE: Dict[str, Dict[str, Dict[str, Any]]] = {}

class CalendarService:
    def __init__(
        self,
        supabase: Client,
        user_id: str,
        outfit_service: OutfitService,
        weather_service: WeatherService,
    ):
        self.supabase = supabase
        self.user_id = user_id
        self.outfit_service = outfit_service
        self.weather_service = weather_service

        if self.user_id not in _SESSION_PLANS_STORE:
            _SESSION_PLANS_STORE[self.user_id] = {}
        if self.user_id not in _SESSION_CALENDAR_WEAR_STORE:
            _SESSION_CALENDAR_WEAR_STORE[self.user_id] = {}

    def _get_plans_store(self) -> Dict[str, Dict[str, Any]]:
        return _SESSION_PLANS_STORE[self.user_id]

    def _get_wear_store(self) -> Dict[str, Dict[str, Any]]:
        return _SESSION_CALENDAR_WEAR_STORE[self.user_id]

    # --- 1. OUTFIT PLANNING ---
    def create_plan(self, req: OutfitPlanCreate) -> OutfitPlanResponse:
        outfit = self.outfit_service.get_outfit(req.outfit_id)
        if not outfit:
            raise ValueError(f"Outfit {req.outfit_id} not found.")

        # Check repetition warning
        rep_check = self.check_repetition(req.outfit_id, req.planned_date)
        rep_warning = rep_check.message if rep_check.is_repeated else None

        plan_id = f"plan_{uuid.uuid4().hex[:10]}"
        now = datetime.now(timezone.utc)

        plan_data = {
            "id": plan_id,
            "user_id": self.user_id,
            "outfit_id": req.outfit_id,
            "outfit_name": outfit.name,
            "planned_date": req.planned_date,
            "occasion": req.occasion,
            "notes": req.notes,
            "is_worn": False,
            "is_available": outfit.is_available,
            "repetition_warning": rep_warning,
            "created_at": now,
            "updated_at": now,
        }

        # Save to local session store
        self._get_plans_store()[plan_id] = plan_data

        # Save to Supabase
        try:
            self.supabase.table("outfit_plans").insert(
                {
                    "id": plan_id,
                    "user_id": self.user_id,
                    "outfit_id": req.outfit_id,
                    "planned_date": req.planned_date,
                    "occasion": req.occasion,
                    "notes": req.notes,
                    "is_worn": False,
                    "created_at": now.isoformat(),
                    "updated_at": now.isoformat(),
                }
            ).execute()
        except Exception as e:
            logger.warning(f"[CalendarService] Remote plan insert fallback: {e}")

        return self._to_plan_response(plan_data, outfit)

    def update_plan(self, plan_id: str, req: OutfitPlanUpdate) -> OutfitPlanResponse:
        plans = self._get_plans_store()
        plan_data = plans.get(plan_id)
        if not plan_data:
            raise ValueError(f"Plan {plan_id} not found.")

        outfit = self.outfit_service.get_outfit(plan_data["outfit_id"])
        if not outfit:
            raise ValueError(f"Outfit {plan_data['outfit_id']} not found.")

        now = datetime.now(timezone.utc)
        if req.planned_date is not None:
            plan_data["planned_date"] = req.planned_date
            rep_check = self.check_repetition(plan_data["outfit_id"], req.planned_date)
            plan_data["repetition_warning"] = rep_check.message if rep_check.is_repeated else None
        if req.occasion is not None:
            plan_data["occasion"] = req.occasion
        if req.notes is not None:
            plan_data["notes"] = req.notes
        plan_data["updated_at"] = now

        try:
            update_payload = {"updated_at": now.isoformat()}
            if req.planned_date is not None:
                update_payload["planned_date"] = req.planned_date
            if req.occasion is not None:
                update_payload["occasion"] = req.occasion
            if req.notes is not None:
                update_payload["notes"] = req.notes

            self.supabase.table("outfit_plans").update(update_payload).eq("id", plan_id).execute()
        except Exception as e:
            logger.warning(f"[CalendarService] Remote plan update fallback: {e}")

        return self._to_plan_response(plan_data, outfit)

    def delete_plan(self, plan_id: str) -> bool:
        plans = self._get_plans_store()
        if plan_id not in plans:
            raise ValueError(f"Plan {plan_id} not found.")
        del plans[plan_id]

        try:
            self.supabase.table("outfit_plans").delete().eq("id", plan_id).execute()
        except Exception as e:
            logger.warning(f"[CalendarService] Remote plan delete fallback: {e}")
        return True

    def get_plan(self, plan_id: str) -> Optional[OutfitPlanResponse]:
        plans = self._get_plans_store()
        plan_data = plans.get(plan_id)
        if not plan_data:
            return None
        outfit = self.outfit_service.get_outfit(plan_data["outfit_id"])
        if not outfit:
            return None
        return self._to_plan_response(plan_data, outfit)

    # --- 2. ACTUAL WEAR CONFIRMATION ---
    def record_actual_wear(self, req: ActualWearCreate) -> ActualWearResponse:
        outfit = self.outfit_service.get_outfit(req.outfit_id)
        if not outfit:
            raise ValueError(f"Outfit {req.outfit_id} not found.")

        # Check idempotency in calendar wears
        wear_store = self._get_wear_store()
        if req.idempotency_key:
            for w in wear_store.values():
                if w.get("idempotency_key") == req.idempotency_key:
                    logger.info(f"[CalendarService] Idempotent calendar wear hit: {req.idempotency_key}")
                    return self._to_wear_response(w, outfit)

        # Trigger outfit wear lifecycle through OutfitService (which updates LaundryService & garment wear counts)
        wear_req = OutfitWearRequest(
            notes=req.notes,
            idempotency_key=req.idempotency_key,
        )
        wear_res = self.outfit_service.wear_outfit(req.outfit_id, wear_req)

        # If linked to a plan, mark plan as is_worn
        if req.plan_id:
            plans = self._get_plans_store()
            if req.plan_id in plans:
                plans[req.plan_id]["is_worn"] = True
                try:
                    self.supabase.table("outfit_plans").update({"is_worn": True}).eq("id", req.plan_id).execute()
                except Exception as e:
                    logger.warning(f"[CalendarService] Plan is_worn update fallback: {e}")

        record_id = f"cwear_{uuid.uuid4().hex[:10]}"
        now = datetime.now(timezone.utc)
        record_data = {
            "id": record_id,
            "user_id": self.user_id,
            "outfit_id": req.outfit_id,
            "outfit_name": outfit.name,
            "plan_id": req.plan_id,
            "actual_worn_date": req.actual_worn_date,
            "worn_at": wear_res.worn_at,
            "garments_updated": wear_res.garments_updated,
            "wear_count": wear_res.wear_count,
            "notes": req.notes,
            "idempotency_key": req.idempotency_key,
            "created_at": now,
        }
        wear_store[record_id] = record_data

        try:
            self.supabase.table("outfit_calendar_wear_records").insert(
                {
                    "id": record_id,
                    "user_id": self.user_id,
                    "outfit_id": req.outfit_id,
                    "plan_id": req.plan_id,
                    "actual_worn_date": req.actual_worn_date,
                    "worn_at": wear_res.worn_at.isoformat(),
                    "notes": req.notes,
                    "idempotency_key": req.idempotency_key,
                    "created_at": now.isoformat(),
                }
            ).execute()
        except Exception as e:
            logger.warning(f"[CalendarService] Remote calendar wear insert fallback: {e}")

        # Refresh outfit entity after wear
        refreshed_outfit = self.outfit_service.get_outfit(req.outfit_id) or outfit
        return self._to_wear_response(record_data, refreshed_outfit)

    # --- 3. CALENDAR VIEWS ---
    def get_day_detail(self, date_str: str) -> CalendarDayDetailResponse:
        plans = [
            self._to_plan_response(p, self.outfit_service.get_outfit(p["outfit_id"]))
            for p in self._get_plans_store().values()
            if p["planned_date"] == date_str
            and self.outfit_service.get_outfit(p["outfit_id"]) is not None
        ]

        actuals = [
            self._to_wear_response(w, self.outfit_service.get_outfit(w["outfit_id"]))
            for w in self._get_wear_store().values()
            if w["actual_worn_date"] == date_str
            and self.outfit_service.get_outfit(w["outfit_id"]) is not None
        ]

        weather = self.weather_service.get_weather_for_date(date_str)

        return CalendarDayDetailResponse(
            date=date_str,
            plans=plans,
            actual_wears=actuals,
            has_plan=len(plans) > 0,
            has_actual_wear=len(actuals) > 0,
            weather=weather,
        )

    def get_week_view(self, start_date_str: str) -> CalendarWeekResponse:
        try:
            start_date = datetime.strptime(start_date_str, "%Y-%m-%d").date()
        except ValueError:
            start_date = datetime.now(timezone.utc).date()

        days = []
        for i in range(7):
            d = start_date + timedelta(days=i)
            d_str = d.strftime("%Y-%m-%d")
            days.append(self.get_day_detail(d_str))

        end_date_str = (start_date + timedelta(days=6)).strftime("%Y-%m-%d")
        return CalendarWeekResponse(
            start_date=start_date_str,
            end_date=end_date_str,
            days=days,
        )

    def get_month_view(self, year: int, month: int) -> CalendarMonthResponse:
        first_day = date(year, month, 1)
        if month == 12:
            next_month = date(year + 1, 1, 1)
        else:
            next_month = date(year, month + 1, 1)
        num_days = (next_month - first_day).days

        days = []
        for d in range(1, num_days + 1):
            curr_date = date(year, month, d)
            d_str = curr_date.strftime("%Y-%m-%d")
            days.append(self.get_day_detail(d_str))

        return CalendarMonthResponse(
            year=year,
            month=month,
            days=days,
        )

    # --- 4. CALENDAR INTELLIGENCE ---
    def check_repetition(self, outfit_id: str, date_str: str, window_days: int = 14) -> RepetitionCheckResponse:
        try:
            target_date = datetime.strptime(date_str, "%Y-%m-%d").date()
        except ValueError:
            target_date = datetime.now(timezone.utc).date()

        recent_wears = []
        for w in self._get_wear_store().values():
            if w.get("outfit_id") == outfit_id:
                try:
                    w_date = datetime.strptime(w["actual_worn_date"], "%Y-%m-%d").date()
                    diff = abs((target_date - w_date).days)
                    if diff <= window_days and w_date != target_date:
                        recent_wears.append((w_date, w["actual_worn_date"]))
                except Exception:
                    continue

        if recent_wears:
            recent_wears.sort(key=lambda x: x[0], reverse=True)
            last_date_str = recent_wears[0][1]
            days_diff = abs((target_date - recent_wears[0][0]).days)
            return RepetitionCheckResponse(
                is_repeated=True,
                last_worn_date=last_date_str,
                last_planned_or_worn_date=last_date_str,
                days_since=days_diff,
                repetition_count=len(recent_wears),
                message=f"You wore this outfit on {last_date_str}. Consider styling with an alternative piece to keep your look fresh.",
            )

        return RepetitionCheckResponse(
            is_repeated=False,
            last_worn_date=None,
            last_planned_or_worn_date=None,
            days_since=None,
            repetition_count=0,
            message=None,
        )

    def get_recently_worn_garments(self, limit: int = 10) -> List[RecentlyWornGarmentItem]:
        all_garments = self.outfit_service._get_all_user_garments()
        worn = [g for g in all_garments if g.get("last_worn_date") is not None]
        # Sort descending by last_worn_date
        def _get_sort_key(g):
            lw = g.get("last_worn_date")
            if isinstance(lw, datetime):
                return lw
            if isinstance(lw, str):
                try:
                    return datetime.fromisoformat(lw.replace("Z", "+00:00"))
                except Exception:
                    pass
            return datetime.min.replace(tzinfo=timezone.utc)

        worn.sort(key=_get_sort_key, reverse=True)
        res = []
        for g in worn[:limit]:
            lw = g.get("last_worn_date")
            lw_dt = None
            if isinstance(lw, datetime):
                lw_dt = lw
            elif isinstance(lw, str):
                try:
                    lw_dt = datetime.fromisoformat(lw.replace("Z", "+00:00"))
                except Exception:
                    pass

            res.append(
                RecentlyWornGarmentItem(
                    garment_id=g["id"],
                    garment_name=g.get("name") or "Garment",
                    main_category=g.get("category") or "top",
                    primary_color=g.get("primary_color") or "Unknown",
                    thumbnail_ref=g.get("image_url"),
                    last_worn_date=lw_dt,
                    wear_count=g.get("wear_count", 0),
                )
            )
        return res

    def get_unused_garments(self, days_threshold: int = 30) -> List[UnusedGarmentItem]:
        all_garments = self.outfit_service._get_all_user_garments()
        now = datetime.now(timezone.utc)
        unused = []

        for g in all_garments:
            wear_count = g.get("wear_count", 0)
            lw = g.get("last_worn_date")
            days_since = 999
            if lw:
                try:
                    if isinstance(lw, str):
                        dt = datetime.fromisoformat(lw.replace("Z", "+00:00"))
                    else:
                        dt = lw
                    days_since = (now - dt).days
                except Exception:
                    pass

            if wear_count == 0 or days_since >= days_threshold:
                unused.append(
                    UnusedGarmentItem(
                        garment_id=g["id"],
                        garment_name=g.get("name") or "Garment",
                        main_category=g.get("category") or "top",
                        primary_color=g.get("primary_color") or "Unknown",
                        thumbnail_ref=g.get("image_url"),
                        wear_count=wear_count,
                        days_unused=days_since if wear_count > 0 else 999,
                    )
                )

        return unused

    def get_upcoming_plans(self, limit: int = 10) -> List[OutfitPlanResponse]:
        today_str = datetime.now(timezone.utc).strftime("%Y-%m-%d")
        plans = [
            self._to_plan_response(p, self.outfit_service.get_outfit(p["outfit_id"]))
            for p in self._get_plans_store().values()
            if p["planned_date"] >= today_str
            and self.outfit_service.get_outfit(p["outfit_id"]) is not None
        ]
        plans.sort(key=lambda x: x.planned_date)
        return plans[:limit]

    def get_outfit_history(self, limit: int = 50) -> List[ActualWearResponse]:
        history = [
            self._to_wear_response(w, self.outfit_service.get_outfit(w["outfit_id"]))
            for w in self._get_wear_store().values()
            if self.outfit_service.get_outfit(w["outfit_id"]) is not None
        ]
        history.sort(key=lambda x: (x.actual_worn_date, x.worn_at), reverse=True)
        return history[:limit]

    # --- HELPERS ---
    def _to_plan_response(self, plan_data: Dict[str, Any], outfit: OutfitResponse) -> OutfitPlanResponse:
        return OutfitPlanResponse(
            id=plan_data["id"],
            user_id=self.user_id,
            outfit_id=plan_data["outfit_id"],
            outfit_name=outfit.name,
            outfit=outfit,
            planned_date=plan_data["planned_date"],
            occasion=plan_data.get("occasion", "Casual"),
            notes=plan_data.get("notes"),
            is_worn=plan_data.get("is_worn", False),
            is_available=outfit.is_available,
            repetition_warning=plan_data.get("repetition_warning"),
            created_at=plan_data["created_at"],
            updated_at=plan_data["updated_at"],
        )

    def _to_wear_response(self, wear_data: Dict[str, Any], outfit: OutfitResponse) -> ActualWearResponse:
        return ActualWearResponse(
            id=wear_data["id"],
            user_id=self.user_id,
            outfit_id=wear_data["outfit_id"],
            outfit_name=outfit.name,
            outfit=outfit,
            plan_id=wear_data.get("plan_id"),
            actual_worn_date=wear_data["actual_worn_date"],
            worn_at=wear_data["worn_at"],
            garments_updated=wear_data.get("garments_updated", []),
            wear_count=wear_data.get("wear_count", 1),
            notes=wear_data.get("notes"),
            created_at=wear_data["created_at"],
        )
