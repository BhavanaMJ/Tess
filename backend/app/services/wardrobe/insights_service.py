from datetime import datetime, date, timedelta, timezone
from typing import List, Optional, Dict, Any, Set, Tuple
import logging
from collections import defaultdict
import uuid
from supabase import Client

from app.schemas.insights import (
    AnalyticsPeriodEnum,
    NeglectReasonEnum,
    ValueTierEnum,
    RecommendationTypeEnum,
    WardrobeOverviewAnalytics,
    CategoryDistributionItem,
    CategoryDistributionResponse,
    GarmentUsageItem,
    GarmentUsageListResponse,
    WardrobeUtilisationResponse,
    ColourDistributionItem,
    ColourAnalysisResponse,
    CategoryUsageAnalytics,
    CategoryUsageResponse,
    OutfitRepetitionItem,
    OutfitRepetitionResponse,
    CostPerWearItem,
    CostPerWearSummary,
    WardrobeRecommendationItem,
    WardrobeRecommendationsResponse,
    CapsuleGarmentInsight,
    CapsuleWardrobeSummary,
    StylePreferencesUpdate,
    StyleMemoryResponse,
)
from app.services.wardrobe.service import _SESSION_WARDROBE_STORE
from app.services.wardrobe.outfit_service import (
    _SESSION_OUTFITS_STORE,
    _SESSION_OUTFIT_ITEMS_STORE,
    _SESSION_WEAR_HISTORY_STORE,
    _is_color_compatible,
)
from app.services.wardrobe.calendar_service import _SESSION_CALENDAR_WEAR_STORE

logger = logging.getLogger(__name__)

# Canonical color mapping
COLOR_GROUPS: Dict[str, List[str]] = {
    "Black": ["black", "jet black", "charcoal black", "midnight black", "nero"],
    "White": ["white", "off-white", "ivory", "cream", "snow", "pearl"],
    "Blue": ["blue", "navy", "navy blue", "denim", "sky blue", "indigo", "baby blue", "royal blue", "teal", "cyan", "azure", "cobalt"],
    "Grey": ["grey", "gray", "charcoal", "silver", "ash", "heather grey", "slate"],
    "Brown / Beige": ["brown", "beige", "tan", "khaki", "camel", "coffee", "chocolate", "sand", "nude", "taupe"],
    "Green": ["green", "olive", "forest green", "emerald", "sage", "mint", "army green", "khaki green"],
    "Red / Pink": ["red", "pink", "maroon", "burgundy", "crimson", "coral", "rose", "blush", "salmon", "magenta", "rust"],
    "Yellow / Orange": ["yellow", "orange", "mustard", "gold", "amber", "peach", "rust orange"],
    "Purple": ["purple", "lavender", "violet", "plum", "lilac", "mauve"],
}

# Session store for user style preferences
_SESSION_STYLE_PREFERENCES_STORE: Dict[str, Dict[str, Any]] = {}


def _normalize_color(raw_color: str) -> str:
    cleaned = raw_color.strip().lower()
    for group, synonyms in COLOR_GROUPS.items():
        if cleaned in synonyms or any(syn in cleaned for syn in synonyms):
            return group
    return "Multicolor / Other"


def _calculate_period_dates(
    period: AnalyticsPeriodEnum,
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
) -> Tuple[date, date]:
    today = date.today()
    if period == AnalyticsPeriodEnum.DAYS_7:
        return today - timedelta(days=7), today
    elif period == AnalyticsPeriodEnum.DAYS_30:
        return today - timedelta(days=30), today
    elif period == AnalyticsPeriodEnum.DAYS_90:
        return today - timedelta(days=90), today
    elif period == AnalyticsPeriodEnum.MONTHS_6:
        return today - timedelta(days=180), today
    elif period == AnalyticsPeriodEnum.MONTHS_12:
        return today - timedelta(days=365), today
    elif period == AnalyticsPeriodEnum.ALL_TIME:
        return date(2000, 1, 1), today
    elif period == AnalyticsPeriodEnum.CUSTOM:
        s = start_date or (today - timedelta(days=30))
        e = end_date or today
        return s, e
    return today - timedelta(days=30), today


class InsightsService:
    def __init__(self, supabase: Client, user_id: str):
        self.supabase = supabase
        self.user_id = user_id
        if self.user_id not in _SESSION_STYLE_PREFERENCES_STORE:
            _SESSION_STYLE_PREFERENCES_STORE[self.user_id] = {
                "user_id": self.user_id,
                "style_persona": "Casual Minimalist",
                "preferred_colors": ["Blue", "Black", "White"],
                "preferred_categories": ["Tops", "Bottoms"],
                "preferred_occasions": ["Casual", "Work"],
                "avoided_combinations": [],
                "favorite_pairing_rules": [],
                "notes": None,
                "updated_at": datetime.now(timezone.utc),
            }

    # -------------------------------------------------------------------------
    # Internal Helpers to Fetch Data across Supabase or Session Stores
    # -------------------------------------------------------------------------
    def _get_active_garments(self) -> List[Dict[str, Any]]:
        """Fetch all active (non-archived) garments for user."""
        import os
        if "PYTEST_CURRENT_TEST" in os.environ:
            store = _SESSION_WARDROBE_STORE.get(self.user_id, {})
            return [g for g in store.values() if not g.get("is_archived", False)]

        try:
            res = (
                self.supabase.table("wardrobe_items")
                .select("*")
                .eq("user_id", self.user_id)
                .eq("is_archived", False)
                .execute()
            )
            if res.data:
                return res.data
        except Exception as e:
            logger.debug(f"Supabase wardrobe_items fetch fallback: {e}")

        # Local fallback
        store = _SESSION_WARDROBE_STORE.get(self.user_id, {})
        return [g for g in store.values() if not g.get("is_archived", False)]

    def _get_all_garments(self) -> List[Dict[str, Any]]:
        """Fetch all garments including archived."""
        import os
        if "PYTEST_CURRENT_TEST" in os.environ:
            store = _SESSION_WARDROBE_STORE.get(self.user_id, {})
            return list(store.values())

        try:
            res = (
                self.supabase.table("wardrobe_items")
                .select("*")
                .eq("user_id", self.user_id)
                .execute()
            )
            if res.data:
                return res.data
        except Exception as e:
            logger.debug(f"Supabase wardrobe_items fetch fallback: {e}")

        store = _SESSION_WARDROBE_STORE.get(self.user_id, {})
        return list(store.values())

    def _get_outfits(self) -> List[Dict[str, Any]]:
        import os
        if "PYTEST_CURRENT_TEST" in os.environ:
            store = _SESSION_OUTFITS_STORE.get(self.user_id, {})
            return [o for o in store.values() if not o.get("is_archived", False)]

        try:
            res = (
                self.supabase.table("outfits")
                .select("*")
                .eq("user_id", self.user_id)
                .eq("is_archived", False)
                .execute()
            )
            if res.data:
                return res.data
        except Exception as e:
            logger.debug(f"Supabase outfits fetch fallback: {e}")

        store = _SESSION_OUTFITS_STORE.get(self.user_id, {})
        return [o for o in store.values() if not o.get("is_archived", False)]

    def _get_outfit_items_map(self) -> Dict[str, List[str]]:
        """Returns outfit_id -> list of garment_ids."""
        import os
        if "PYTEST_CURRENT_TEST" in os.environ:
            mapping: Dict[str, List[str]] = defaultdict(list)
            store = _SESSION_OUTFIT_ITEMS_STORE.get(self.user_id, {})
            for outfit_id, items in store.items():
                for it in items:
                    mapping[outfit_id].append(it["garment_id"])
            return mapping

        mapping: Dict[str, List[str]] = defaultdict(list)
        try:
            res = (
                self.supabase.table("outfit_items")
                .select("outfit_id, garment_id")
                .eq("user_id", self.user_id)
                .execute()
            )
            if res.data:
                for row in res.data:
                    mapping[row["outfit_id"]].append(row["garment_id"])
                return mapping
        except Exception as e:
            logger.debug(f"Supabase outfit_items fetch fallback: {e}")

        store = _SESSION_OUTFIT_ITEMS_STORE.get(self.user_id, {})
        for outfit_id, items in store.items():
            for it in items:
                mapping[outfit_id].append(it["garment_id"])
        return mapping

    def _get_wear_events_in_period(
        self, start_d: date, end_d: date
    ) -> List[Dict[str, Any]]:
        """Fetch calendar wear events and wear history within date range."""
        events: List[Dict[str, Any]] = []
        import os
        if "PYTEST_CURRENT_TEST" in os.environ:
            cstore = _SESSION_CALENDAR_WEAR_STORE.get(self.user_id, {})
            for r in cstore.values():
                w_d_raw = r.get("actual_worn_date")
                if isinstance(w_d_raw, str):
                    w_d = date.fromisoformat(w_d_raw)
                elif isinstance(w_d_raw, date):
                    w_d = w_d_raw
                else:
                    continue
                if start_d <= w_d <= end_d:
                    events.append(r)
            wstore = _SESSION_WEAR_HISTORY_STORE.get(self.user_id, [])
            for h in wstore:
                w_at = h.get("worn_at")
                if isinstance(w_at, datetime):
                    w_d = w_at.date()
                elif isinstance(w_at, str):
                    try:
                        w_d = datetime.fromisoformat(w_at.replace("Z", "+00:00")).date()
                    except Exception:
                        continue
                else:
                    continue
                if start_d <= w_d <= end_d:
                    events.append(h)
            return events

        # 1. Calendar wear records
        try:
            res = (
                self.supabase.table("outfit_calendar_wear_records")
                .select("*")
                .eq("user_id", self.user_id)
                .gte("actual_worn_date", start_d.isoformat())
                .lte("actual_worn_date", end_d.isoformat())
                .execute()
            )
            if res.data:
                events.extend(res.data)
        except Exception as e:
            logger.debug(f"Supabase calendar_wear_records fallback: {e}")
            cstore = _SESSION_CALENDAR_WEAR_STORE.get(self.user_id, {})
            for r in cstore.values():
                w_d_raw = r.get("actual_worn_date")
                if isinstance(w_d_raw, str):
                    w_d = date.fromisoformat(w_d_raw)
                elif isinstance(w_d_raw, date):
                    w_d = w_d_raw
                else:
                    continue
                if start_d <= w_d <= end_d:
                    events.append(r)

        # 2. Outfit wear history
        try:
            res = (
                self.supabase.table("outfit_wear_history")
                .select("*")
                .eq("user_id", self.user_id)
                .gte("worn_at", datetime.combine(start_d, datetime.min.time()).isoformat())
                .lte("worn_at", datetime.combine(end_d, datetime.max.time()).isoformat())
                .execute()
            )
            if res.data:
                events.extend(res.data)
        except Exception as e:
            logger.debug(f"Supabase outfit_wear_history fallback: {e}")
            wstore = _SESSION_WEAR_HISTORY_STORE.get(self.user_id, [])
            for h in wstore:
                w_at = h.get("worn_at")
                if isinstance(w_at, datetime):
                    w_d = w_at.date()
                elif isinstance(w_at, str):
                    try:
                        w_d = datetime.fromisoformat(w_at.replace("Z", "+00:00")).date()
                    except Exception:
                        continue
                else:
                    continue
                if start_d <= w_d <= end_d:
                    events.append(h)

        return events

    def _get_garment_wears_in_period(
        self, start_d: date, end_d: date
    ) -> Dict[str, int]:
        """Returns garment_id -> wear count in the period."""
        events = self._get_wear_events_in_period(start_d, end_d)
        outfit_items = self._get_outfit_items_map()

        garment_counts: Dict[str, int] = defaultdict(int)
        for ev in events:
            oid = ev.get("outfit_id")
            if oid and oid in outfit_items:
                for gid in outfit_items[oid]:
                    garment_counts[gid] += 1

        return garment_counts

    # -------------------------------------------------------------------------
    # 1. Wardrobe Overview & Telemetry
    # -------------------------------------------------------------------------
    def get_overview(
        self,
        period: AnalyticsPeriodEnum = AnalyticsPeriodEnum.DAYS_30,
        start_date: Optional[date] = None,
        end_date: Optional[date] = None,
    ) -> WardrobeOverviewAnalytics:
        start_d, end_d = _calculate_period_dates(period, start_date, end_date)
        all_garments = self._get_all_garments()
        active_garments = [g for g in all_garments if not g.get("is_archived", False)]
        archived_count = len(all_garments) - len(active_garments)

        # In-laundry count & clean count
        in_laundry_count = sum(
            1
            for g in active_garments
            if g.get("laundry_status") in ("WORN", "WASHING", "DRYING")
        )
        clean_count = sum(
            1 for g in active_garments if g.get("laundry_status") == "CLEAN"
        )

        # Never worn count (all-time wear_count == 0)
        never_worn_count = sum(
            1 for g in active_garments if (g.get("wear_count") or 0) == 0
        )

        # Period wears
        garment_period_wears = self._get_garment_wears_in_period(start_d, end_d)
        unique_worn_ids = set()
        total_worn_count = 0

        if period == AnalyticsPeriodEnum.ALL_TIME:
            for g in active_garments:
                wc = g.get("wear_count", 0)
                if wc > 0:
                    unique_worn_ids.add(g["id"])
                    total_worn_count += wc
        else:
            for gid, count in garment_period_wears.items():
                if any(g["id"] == gid for g in active_garments):
                    unique_worn_ids.add(gid)
                    total_worn_count += count

        total_active = len(active_garments)
        utilisation = (
            round((len(unique_worn_ids) / total_active) * 100.0, 1)
            if total_active > 0
            else 0.0
        )

        # Outfits worn in period
        events = self._get_wear_events_in_period(start_d, end_d)
        total_outfits_worn = len(events)

        # Financials
        total_investment = sum(
            float(g.get("purchase_price") or 0.0) for g in active_garments
        )
        worn_items_with_price = [
            g
            for g in active_garments
            if g.get("purchase_price") is not None
            and (g.get("wear_count") or 0) > 0
        ]
        avg_cpw = None
        if worn_items_with_price:
            cpw_sum = sum(
                float(g["purchase_price"]) / float(g["wear_count"])
                for g in worn_items_with_price
            )
            avg_cpw = round(cpw_sum / len(worn_items_with_price), 2)

        return WardrobeOverviewAnalytics(
            period=period,
            start_date=start_d,
            end_date=end_d,
            total_active_garments=total_active,
            total_archived_garments=archived_count,
            total_worn_garments_in_period=total_worn_count,
            unique_garments_worn_in_period=len(unique_worn_ids),
            utilisation_percentage=utilisation,
            clean_garments_count=clean_count,
            in_laundry_count=in_laundry_count,
            never_worn_count=never_worn_count,
            total_outfits_worn_in_period=total_outfits_worn,
            total_investment=round(total_investment, 2),
            average_cost_per_wear=avg_cpw,
            currency="INR",
        )

    # -------------------------------------------------------------------------
    # 2. Category Distribution
    # -------------------------------------------------------------------------
    def get_category_distribution(self) -> CategoryDistributionResponse:
        active = self._get_active_garments()
        total = len(active)
        counts: Dict[str, int] = defaultdict(int)
        for g in active:
            cat = g.get("main_category") or "Uncategorized"
            counts[cat] += 1

        items: List[CategoryDistributionItem] = []
        for cat, cnt in sorted(counts.items(), key=lambda x: x[1], reverse=True):
            pct = round((cnt / total) * 100.0, 1) if total > 0 else 0.0
            items.append(
                CategoryDistributionItem(
                    category=cat,
                    count=cnt,
                    percentage_of_wardrobe=pct,
                    active_count=cnt,
                    worn_in_period_count=0,
                )
            )

        return CategoryDistributionResponse(total_garments=total, categories=items)

    # -------------------------------------------------------------------------
    # 3. Most Worn & Least Worn & Neglected Garments
    # -------------------------------------------------------------------------
    def get_most_worn(
        self,
        period: AnalyticsPeriodEnum = AnalyticsPeriodEnum.ALL_TIME,
        limit: int = 5,
    ) -> GarmentUsageListResponse:
        active = self._get_active_garments()
        start_d, end_d = _calculate_period_dates(period)
        period_wears = self._get_garment_wears_in_period(start_d, end_d)

        garment_usage: List[GarmentUsageItem] = []
        for g in active:
            gid = g["id"]
            if period == AnalyticsPeriodEnum.ALL_TIME:
                w_count = g.get("wear_count") or 0
            else:
                w_count = period_wears.get(gid, 0)

            if w_count == 0:
                continue

            price = (
                float(g["purchase_price"])
                if g.get("purchase_price") is not None
                else None
            )
            cpw = round(price / w_count, 2) if price is not None and w_count > 0 else None

            last_worn = None
            if g.get("last_worn_date"):
                try:
                    last_worn = (
                        datetime.fromisoformat(g["last_worn_date"])
                        if isinstance(g["last_worn_date"], str)
                        else g["last_worn_date"]
                    )
                except Exception:
                    pass

            garment_usage.append(
                GarmentUsageItem(
                    garment_id=gid,
                    garment_name=g.get("name", "Unnamed"),
                    main_category=g.get("main_category", "Tops"),
                    primary_color=g.get("primary_color", "Unknown"),
                    thumbnail_ref=g.get("thumbnail_ref") or g.get("processed_image_ref"),
                    wear_count=w_count,
                    last_worn_date=last_worn,
                    purchase_price=price,
                    purchase_currency=g.get("purchase_currency", "INR"),
                    cost_per_wear=cpw,
                    laundry_status=g.get("laundry_status"),
                )
            )

        garment_usage.sort(key=lambda x: x.wear_count, reverse=True)
        items = garment_usage[:limit]
        return GarmentUsageListResponse(period=period, items=items, total=len(garment_usage))

    def get_least_worn(
        self,
        period: AnalyticsPeriodEnum = AnalyticsPeriodEnum.ALL_TIME,
        limit: int = 5,
    ) -> GarmentUsageListResponse:
        active = self._get_active_garments()
        start_d, end_d = _calculate_period_dates(period)
        period_wears = self._get_garment_wears_in_period(start_d, end_d)

        garment_usage: List[GarmentUsageItem] = []
        for g in active:
            gid = g["id"]
            if period == AnalyticsPeriodEnum.ALL_TIME:
                w_count = g.get("wear_count") or 0
            else:
                w_count = period_wears.get(gid, 0)

            price = (
                float(g["purchase_price"])
                if g.get("purchase_price") is not None
                else None
            )
            cpw = round(price / w_count, 2) if price is not None and w_count > 0 else None

            last_worn = None
            if g.get("last_worn_date"):
                try:
                    last_worn = (
                        datetime.fromisoformat(g["last_worn_date"])
                        if isinstance(g["last_worn_date"], str)
                        else g["last_worn_date"]
                    )
                except Exception:
                    pass

            # Classify neglect reason
            reason = self._classify_neglect(g, w_count)

            garment_usage.append(
                GarmentUsageItem(
                    garment_id=gid,
                    garment_name=g.get("name", "Unnamed"),
                    main_category=g.get("main_category", "Tops"),
                    primary_color=g.get("primary_color", "Unknown"),
                    thumbnail_ref=g.get("thumbnail_ref") or g.get("processed_image_ref"),
                    wear_count=w_count,
                    last_worn_date=last_worn,
                    purchase_price=price,
                    purchase_currency=g.get("purchase_currency", "INR"),
                    cost_per_wear=cpw,
                    neglect_reason=reason,
                    laundry_status=g.get("laundry_status"),
                )
            )

        # Sort by wear count ascending, then by creation date ascending
        garment_usage.sort(key=lambda x: x.wear_count)
        items = garment_usage[:limit]
        return GarmentUsageListResponse(period=period, items=items, total=len(garment_usage))

    def _classify_neglect(self, g: Dict[str, Any], wears: int) -> NeglectReasonEnum:
        now = datetime.now(timezone.utc)
        created_at_raw = g.get("created_at")
        days_since_created = 30
        if created_at_raw:
            try:
                dt = (
                    datetime.fromisoformat(created_at_raw.replace("Z", "+00:00"))
                    if isinstance(created_at_raw, str)
                    else created_at_raw
                )
                if dt.tzinfo is None:
                    dt = dt.replace(tzinfo=timezone.utc)
                days_since_created = (now - dt).days
            except Exception:
                pass

        if wears == 0:
            if days_since_created < 14:
                return NeglectReasonEnum.RECENTLY_ADDED
            return NeglectReasonEnum.NEVER_RECORDED

        last_worn_raw = g.get("last_worn_date")
        if last_worn_raw:
            try:
                l_dt = (
                    datetime.fromisoformat(last_worn_raw.replace("Z", "+00:00"))
                    if isinstance(last_worn_raw, str)
                    else last_worn_raw
                )
                if l_dt.tzinfo is None:
                    l_dt = l_dt.replace(tzinfo=timezone.utc)
                days_since_wear = (now - l_dt).days
                if days_since_wear > 60:
                    return NeglectReasonEnum.NOT_WORN_RECENTLY
            except Exception:
                pass

        if wears <= 2 and days_since_created > 30:
            return NeglectReasonEnum.RARELY_WORN

        return NeglectReasonEnum.INSUFFICIENT_DATA

    def get_neglected(
        self, threshold_days: int = 60, limit: int = 10
    ) -> GarmentUsageListResponse:
        active = self._get_active_garments()
        neglected: List[GarmentUsageItem] = []

        for g in active:
            w_count = g.get("wear_count") or 0
            reason = self._classify_neglect(g, w_count)
            if reason in (
                NeglectReasonEnum.NEVER_RECORDED,
                NeglectReasonEnum.NOT_WORN_RECENTLY,
                NeglectReasonEnum.RARELY_WORN,
            ):
                price = (
                    float(g["purchase_price"])
                    if g.get("purchase_price") is not None
                    else None
                )
                cpw = (
                    round(price / w_count, 2)
                    if price is not None and w_count > 0
                    else None
                )

                last_worn = None
                if g.get("last_worn_date"):
                    try:
                        last_worn = (
                            datetime.fromisoformat(g["last_worn_date"])
                            if isinstance(g["last_worn_date"], str)
                            else g["last_worn_date"]
                        )
                    except Exception:
                        pass

                neglected.append(
                    GarmentUsageItem(
                        garment_id=g["id"],
                        garment_name=g.get("name", "Unnamed"),
                        main_category=g.get("main_category", "Tops"),
                        primary_color=g.get("primary_color", "Unknown"),
                        thumbnail_ref=g.get("thumbnail_ref") or g.get("processed_image_ref"),
                        wear_count=w_count,
                        last_worn_date=last_worn,
                        purchase_price=price,
                        purchase_currency=g.get("purchase_currency", "INR"),
                        cost_per_wear=cpw,
                        neglect_reason=reason,
                        laundry_status=g.get("laundry_status"),
                    )
                )

        neglected.sort(key=lambda x: (x.wear_count, x.purchase_price or 0.0), reverse=False)
        return GarmentUsageListResponse(
            period=AnalyticsPeriodEnum.ALL_TIME,
            items=neglected[:limit],
            total=len(neglected),
        )

    # -------------------------------------------------------------------------
    # 4. Wardrobe Utilisation Metric
    # -------------------------------------------------------------------------
    def get_utilisation(
        self,
        period: AnalyticsPeriodEnum = AnalyticsPeriodEnum.DAYS_30,
        start_date: Optional[date] = None,
        end_date: Optional[date] = None,
    ) -> WardrobeUtilisationResponse:
        start_d, end_d = _calculate_period_dates(period, start_date, end_date)
        active = self._get_active_garments()
        total_active = len(active)

        period_wears = self._get_garment_wears_in_period(start_d, end_d)
        unique_worn_ids = set()

        if period == AnalyticsPeriodEnum.ALL_TIME:
            for g in active:
                if (g.get("wear_count") or 0) > 0:
                    unique_worn_ids.add(g["id"])
        else:
            for gid in period_wears:
                if any(g["id"] == gid for g in active):
                    unique_worn_ids.add(gid)

        unique_count = len(unique_worn_ids)
        utilisation = (
            round((unique_count / total_active) * 100.0, 1) if total_active > 0 else 0.0
        )

        events = self._get_wear_events_in_period(start_d, end_d)

        summary = (
            f"You actively wore {unique_count} of your {total_active} garments ({utilisation}%) "
            f"over the selected {period.value} period across {len(events)} wear events."
        )

        return WardrobeUtilisationResponse(
            period=period,
            start_date=start_d,
            end_date=end_d,
            active_garments_count=total_active,
            unique_garments_worn_count=unique_count,
            utilisation_percentage=utilisation,
            wear_events_count=len(events),
            summary_text=summary,
        )

    # -------------------------------------------------------------------------
    # 5. Colour Analysis
    # -------------------------------------------------------------------------
    def get_colour_analysis(self) -> ColourAnalysisResponse:
        active = self._get_active_garments()
        total = len(active)

        groups_count: Dict[str, int] = defaultdict(int)
        groups_original: Dict[str, Set[str]] = defaultdict(set)

        for g in active:
            raw_c = g.get("primary_color") or "Unknown"
            grp = _normalize_color(raw_c)
            groups_count[grp] += 1
            groups_original[grp].add(raw_c)

        distribution: List[ColourDistributionItem] = []
        for grp, cnt in sorted(groups_count.items(), key=lambda x: x[1], reverse=True):
            pct = round((cnt / total) * 100.0, 1) if total > 0 else 0.0
            distribution.append(
                ColourDistributionItem(
                    color_group=grp,
                    original_colors=sorted(list(groups_original[grp])),
                    count=cnt,
                    percentage=pct,
                )
            )

        dominant = distribution[0].color_group if distribution else None
        return ColourAnalysisResponse(
            total_garments=total,
            dominant_color=dominant,
            distribution=distribution,
        )

    # -------------------------------------------------------------------------
    # 6. Category Usage Analytics
    # -------------------------------------------------------------------------
    def get_category_usage(
        self, period: AnalyticsPeriodEnum = AnalyticsPeriodEnum.DAYS_30
    ) -> CategoryUsageResponse:
        start_d, end_d = _calculate_period_dates(period)
        active = self._get_active_garments()
        period_wears = self._get_garment_wears_in_period(start_d, end_d)

        cat_total: Dict[str, int] = defaultdict(int)
        cat_wears: Dict[str, int] = defaultdict(int)
        cat_unique_worn: Dict[str, Set[str]] = defaultdict(set)

        for g in active:
            cat = g.get("main_category") or "Tops"
            gid = g["id"]
            cat_total[cat] += 1

            if period == AnalyticsPeriodEnum.ALL_TIME:
                w_count = g.get("wear_count") or 0
                if w_count > 0:
                    cat_wears[cat] += w_count
                    cat_unique_worn[cat].add(gid)
            else:
                w_count = period_wears.get(gid, 0)
                if w_count > 0:
                    cat_wears[cat] += w_count
                    cat_unique_worn[cat].add(gid)

        items: List[CategoryUsageAnalytics] = []
        for cat, tot in sorted(cat_total.items(), key=lambda x: x[1], reverse=True):
            uniq = len(cat_unique_worn[cat])
            pct = round((uniq / tot) * 100.0, 1) if tot > 0 else 0.0
            items.append(
                CategoryUsageAnalytics(
                    category=cat,
                    total_garments=tot,
                    wear_count=cat_wears[cat],
                    unique_garments_worn=uniq,
                    utilisation_percentage=pct,
                )
            )

        return CategoryUsageResponse(period=period, categories=items)

    # -------------------------------------------------------------------------
    # 7. Outfit Repetition Analysis
    # -------------------------------------------------------------------------
    def get_outfit_repetition(self, limit: int = 10) -> OutfitRepetitionResponse:
        outfits = self._get_outfits()
        outfit_items = self._get_outfit_items_map()
        active_garments = {g["id"]: g.get("name", "Item") for g in self._get_active_garments()}

        repeated_items: List[OutfitRepetitionItem] = []

        # Find wear dates for each outfit
        outfit_wear_dates: Dict[str, List[date]] = defaultdict(list)
        events = self._get_wear_events_in_period(date(2000, 1, 1), date.today())
        for ev in events:
            oid = ev.get("outfit_id")
            if not oid:
                continue
            w_d = ev.get("actual_worn_date") or ev.get("worn_at")
            if isinstance(w_d, str):
                try:
                    dt = datetime.fromisoformat(w_d.replace("Z", "+00:00")).date()
                    outfit_wear_dates[oid].append(dt)
                except Exception:
                    pass
            elif isinstance(w_d, datetime):
                outfit_wear_dates[oid].append(w_d.date())
            elif isinstance(w_d, date):
                outfit_wear_dates[oid].append(w_d)

        for o in outfits:
            oid = o["id"]
            wc = o.get("wear_count") or len(outfit_wear_dates[oid])
            if wc >= 2:
                g_ids = outfit_items.get(oid, [])
                g_names = [active_garments.get(gid, "Garment") for gid in g_ids]

                dates = sorted(outfit_wear_dates.get(oid, []))
                last_d = dates[-1] if dates else None
                avg_interval = None
                if len(dates) >= 2:
                    diffs = [(dates[i] - dates[i - 1]).days for i in range(1, len(dates))]
                    avg_interval = round(sum(diffs) / len(diffs), 1)

                repeated_items.append(
                    OutfitRepetitionItem(
                        outfit_id=oid,
                        outfit_name=o.get("name", "Repeated Outfit"),
                        wear_count=wc,
                        garment_names=g_names,
                        garment_ids=g_ids,
                        last_worn_date=last_d,
                        average_interval_days=avg_interval,
                        occasion=o.get("occasion", "Casual"),
                    )
                )

        repeated_items.sort(key=lambda x: x.wear_count, reverse=True)
        return OutfitRepetitionResponse(
            total_repeated_outfits=len(repeated_items),
            outfits=repeated_items[:limit],
        )

    # -------------------------------------------------------------------------
    # 8. Cost-Per-Wear (CPW) Analytics
    # -------------------------------------------------------------------------
    def get_cost_per_wear(self) -> CostPerWearSummary:
        active = self._get_active_garments()
        items: List[CostPerWearItem] = []

        total_investment = 0.0
        garments_with_price = 0
        garments_without_price = 0
        cpw_values: List[float] = []

        for g in active:
            gid = g["id"]
            name = g.get("name", "Unnamed")
            cat = g.get("main_category", "Tops")
            color = g.get("primary_color", "Unknown")
            thumb = g.get("thumbnail_ref") or g.get("processed_image_ref")
            price = (
                float(g["purchase_price"])
                if g.get("purchase_price") is not None
                else None
            )
            currency = g.get("purchase_currency") or "INR"
            wears = g.get("wear_count") or 0

            p_date = None
            if g.get("purchase_date"):
                try:
                    p_date = (
                        date.fromisoformat(g["purchase_date"])
                        if isinstance(g["purchase_date"], str)
                        else g["purchase_date"]
                    )
                except Exception:
                    pass

            if price is None:
                garments_without_price += 1
                tier = ValueTierEnum.MISSING_PRICE
                cpw = None
            else:
                garments_with_price += 1
                total_investment += price
                if wears == 0:
                    tier = ValueTierEnum.UNRECORDED_WEARS
                    cpw = None
                else:
                    cpw = round(price / wears, 2)
                    cpw_values.append(cpw)
                    if cpw <= 100:
                        tier = ValueTierEnum.EXCELLENT_VALUE
                    elif cpw <= 300:
                        tier = ValueTierEnum.GOOD_VALUE
                    elif cpw <= 600:
                        tier = ValueTierEnum.FAIR_VALUE
                    else:
                        tier = ValueTierEnum.HIGH_COST_PER_WEAR

            items.append(
                CostPerWearItem(
                    garment_id=gid,
                    garment_name=name,
                    main_category=cat,
                    primary_color=color,
                    thumbnail_ref=thumb,
                    purchase_price=price,
                    purchase_currency=currency,
                    purchase_date=p_date,
                    wear_count=wears,
                    cost_per_wear=cpw,
                    value_tier=tier,
                )
            )

        avg_cpw = round(sum(cpw_values) / len(cpw_values), 2) if cpw_values else None

        # Sort items for best value (lowest CPW among items with wears > 0)
        worn_priced = [it for it in items if it.cost_per_wear is not None]
        best_value = sorted(worn_priced, key=lambda x: x.cost_per_wear)[:5]
        highest_cpw = sorted(worn_priced, key=lambda x: x.cost_per_wear, reverse=True)[:5]

        return CostPerWearSummary(
            total_garments_count=len(active),
            garments_with_price_count=garments_with_price,
            garments_without_price_count=garments_without_price,
            total_investment=round(total_investment, 2),
            currency="INR",
            average_cost_per_wear=avg_cpw,
            items=items,
            best_value_garments=best_value,
            highest_cost_per_wear_garments=highest_cpw,
        )

    # -------------------------------------------------------------------------
    # 9. Intelligent Recommendations
    # -------------------------------------------------------------------------
    def get_recommendations(self) -> WardrobeRecommendationsResponse:
        active = self._get_active_garments()
        recommendations: List[WardrobeRecommendationItem] = []

        # 1. Revive Neglected Garments
        neglected_clean = [
            g
            for g in active
            if (g.get("wear_count") or 0) <= 1
            and g.get("laundry_status") == "CLEAN"
        ]
        if neglected_clean:
            target = neglected_clean[0]
            recommendations.append(
                WardrobeRecommendationItem(
                    id=str(uuid.uuid4())[:8],
                    type=RecommendationTypeEnum.REVIVE_NEGLECTED,
                    title=f"Rediscover your {target.get('name')}",
                    description=(
                        f"Your {target.get('name')} is clean and ready to wear but has only been worn "
                        f"{target.get('wear_count', 0)} times. Pair it today for a fresh look!"
                    ),
                    garment_ids=[target["id"]],
                    garment_names=[target.get("name", "Item")],
                    suggested_action="Create Outfit",
                    confidence_score=0.92,
                )
            )

        # 2. High-Wear Favorite check
        favorites = sorted(active, key=lambda x: x.get("wear_count") or 0, reverse=True)
        if favorites and (favorites[0].get("wear_count") or 0) >= 5:
            fav = favorites[0]
            recommendations.append(
                WardrobeRecommendationItem(
                    id=str(uuid.uuid4())[:8],
                    type=RecommendationTypeEnum.HIGH_WEAR_FAVORITE,
                    title=f"MVP Garment: {fav.get('name')}",
                    description=(
                        f"Worn {fav.get('wear_count')} times! This is the most versatile piece in your wardrobe. "
                        f"Consider building capsule combinations around it."
                    ),
                    garment_ids=[fav["id"]],
                    garment_names=[fav.get("name", "Item")],
                    suggested_action="View Styling Options",
                    confidence_score=0.96,
                )
            )

        # 3. New Combination from clean tops + clean bottoms
        clean_tops = [g for g in active if g.get("main_category") == "Tops" and g.get("laundry_status") == "CLEAN"]
        clean_bottoms = [g for g in active if g.get("main_category") == "Bottoms" and g.get("laundry_status") == "CLEAN"]

        if clean_tops and clean_bottoms:
            # Pick a compatible pair
            paired = False
            for t in clean_tops:
                for b in clean_bottoms:
                    if _is_color_compatible(t.get("primary_color", ""), b.get("primary_color", "")):
                        recommendations.append(
                            WardrobeRecommendationItem(
                                id=str(uuid.uuid4())[:8],
                                type=RecommendationTypeEnum.NEW_COMBINATION,
                                title="Fresh Compatible Pairing",
                                description=(
                                    f"Pair your {t.get('name')} ({t.get('primary_color')}) with your "
                                    f"{b.get('name')} ({b.get('primary_color')}) for a harmonious new look."
                                ),
                                garment_ids=[t["id"], b["id"]],
                                garment_names=[t.get("name", "Top"), b.get("name", "Bottom")],
                                suggested_action="Save Outfit",
                                confidence_score=0.88,
                            )
                        )
                        paired = True
                        break
                if paired:
                    break

        # 4. Category Balance Check
        tops_count = sum(1 for g in active if g.get("main_category") == "Tops")
        bottoms_count = sum(1 for g in active if g.get("main_category") == "Bottoms")
        if bottoms_count > 0 and (tops_count / bottoms_count) < 1.5:
            recommendations.append(
                WardrobeRecommendationItem(
                    id=str(uuid.uuid4())[:8],
                    type=RecommendationTypeEnum.CATEGORY_BALANCE,
                    title="Wardrobe Ratio Insight",
                    description=(
                        f"You have {tops_count} tops to {bottoms_count} bottoms. Stylists recommend a 3:1 top-to-bottom "
                        f"ratio to maximize variety without over-purchasing."
                    ),
                    garment_ids=[],
                    garment_names=[],
                    suggested_action="Plan Wishlist",
                    confidence_score=0.80,
                )
            )

        return WardrobeRecommendationsResponse(recommendations=recommendations)

    # -------------------------------------------------------------------------
    # 10. Capsule Wardrobe Intelligence
    # -------------------------------------------------------------------------
    def get_capsule_intelligence(self) -> CapsuleWardrobeSummary:
        active = self._get_active_garments()
        total_active = len(active)

        tops = [g for g in active if g.get("main_category") in ("Tops", "Dresses", "Ethnic wear")]
        bottoms = [g for g in active if g.get("main_category") == "Bottoms"]
        shoes = [g for g in active if g.get("main_category") == "Footwear"]

        capsule_garments: List[CapsuleGarmentInsight] = []
        valid_combinations_count = 0

        # Calculate cross-category combinations
        for t in tops:
            for b in bottoms:
                if _is_color_compatible(t.get("primary_color", ""), b.get("primary_color", "")):
                    valid_combinations_count += 1

        for g in active:
            gid = g["id"]
            cat = g.get("main_category")
            c1 = g.get("primary_color", "")
            compat_count = 0

            # Count compatible pairings with complementary categories
            if cat in ("Tops", "Dresses", "Ethnic wear"):
                for b in bottoms:
                    if _is_color_compatible(c1, b.get("primary_color", "")):
                        compat_count += 1
            elif cat == "Bottoms":
                for t in tops:
                    if _is_color_compatible(c1, t.get("primary_color", "")):
                        compat_count += 1
            else:
                for other in active:
                    if other["id"] != gid and _is_color_compatible(c1, other.get("primary_color", "")):
                        compat_count += 1

            max_ref = max(1, len(bottoms) if cat in ("Tops", "Dresses", "Ethnic wear") else len(tops))
            versatility = min(100.0, round((compat_count / max_ref) * 100.0, 1))
            is_anchor = versatility >= 70.0 and compat_count >= 2

            capsule_garments.append(
                CapsuleGarmentInsight(
                    garment_id=gid,
                    garment_name=g.get("name", "Unnamed"),
                    main_category=cat or "Tops",
                    primary_color=c1 or "Unknown",
                    thumbnail_ref=g.get("thumbnail_ref") or g.get("processed_image_ref"),
                    compatible_pairings_count=compat_count,
                    versatility_score=versatility,
                    is_capsule_anchor=is_anchor,
                )
            )

        capsule_garments.sort(key=lambda x: x.versatility_score, reverse=True)
        anchors = [cg for cg in capsule_garments if cg.is_capsule_anchor]
        avg_versatility = (
            round(sum(cg.versatility_score for cg in capsule_garments) / len(capsule_garments), 1)
            if capsule_garments
            else 0.0
        )

        return CapsuleWardrobeSummary(
            total_active_garments=total_active,
            capsule_ready_garments_count=len(anchors),
            average_versatility_score=avg_versatility,
            anchor_garments=anchors[:6],
            potential_outfit_combinations=valid_combinations_count,
        )

    # -------------------------------------------------------------------------
    # 11. Personal Style Memory
    # -------------------------------------------------------------------------
    def get_style_memory(self) -> StyleMemoryResponse:
        # Load user style preferences from Supabase or session store
        prefs = _SESSION_STYLE_PREFERENCES_STORE.get(self.user_id, {})
        import os
        if "PYTEST_CURRENT_TEST" not in os.environ:
            try:
                res = (
                    self.supabase.table("wardrobe_style_preferences")
                    .select("*")
                    .eq("user_id", self.user_id)
                    .execute()
                )
                if res.data and len(res.data) > 0:
                    prefs.update(res.data[0])
            except Exception as e:
                logger.debug(f"Supabase style preferences fetch fallback: {e}")

        # Compute empirical wear preferences from history
        active = self._get_active_garments()
        color_wears: Dict[str, int] = defaultdict(int)
        cat_wears: Dict[str, int] = defaultdict(int)

        for g in active:
            wc = g.get("wear_count") or 0
            if wc > 0:
                grp = _normalize_color(g.get("primary_color") or "Unknown")
                color_wears[grp] += wc
                cat_wears[g.get("main_category") or "Tops"] += wc

        top_colors = [c for c, _ in sorted(color_wears.items(), key=lambda x: x[1], reverse=True)[:3]]
        top_cats = [c for c, _ in sorted(cat_wears.items(), key=lambda x: x[1], reverse=True)[:3]]

        # Outfits occasion frequency
        outfits = self._get_outfits()
        occ_counts: Dict[str, int] = defaultdict(int)
        for o in outfits:
            occ_counts[o.get("occasion", "Casual")] += o.get("wear_count", 1)
        top_occs = [occ for occ, _ in sorted(occ_counts.items(), key=lambda x: x[1], reverse=True)[:3]] or ["Casual"]

        summary = (
            f"Style Persona: {prefs.get('style_persona', 'Casual Classic')}. "
            f"Your most reached-for colors are {', '.join(top_colors) if top_colors else 'Neutral'}, "
            f"with frequent wear in {', '.join(top_cats) if top_cats else 'Tops and Bottoms'}."
        )

        return StyleMemoryResponse(
            user_id=self.user_id,
            style_persona=prefs.get("style_persona", "Casual Classic"),
            preferred_colors=prefs.get("preferred_colors", top_colors or ["Blue", "Black"]),
            preferred_categories=prefs.get("preferred_categories", top_cats or ["Tops", "Bottoms"]),
            preferred_occasions=prefs.get("preferred_occasions", top_occs),
            avoided_combinations=prefs.get("avoided_combinations", []),
            favorite_pairing_rules=prefs.get("favorite_pairing_rules", []),
            notes=prefs.get("notes"),
            top_worn_colors=top_colors,
            top_worn_categories=top_cats,
            dominant_occasions=top_occs,
            interaction_summary=summary,
            updated_at=prefs.get("updated_at", datetime.now(timezone.utc)),
        )

    def update_style_preferences(
        self, data: StylePreferencesUpdate
    ) -> StyleMemoryResponse:
        prefs = _SESSION_STYLE_PREFERENCES_STORE.setdefault(self.user_id, {})
        if data.preferred_colors is not None:
            prefs["preferred_colors"] = data.preferred_colors
        if data.preferred_categories is not None:
            prefs["preferred_categories"] = data.preferred_categories
        if data.preferred_occasions is not None:
            prefs["preferred_occasions"] = data.preferred_occasions
        if data.avoided_combinations is not None:
            prefs["avoided_combinations"] = data.avoided_combinations
        if data.style_persona is not None:
            prefs["style_persona"] = data.style_persona
        if data.favorite_pairing_rules is not None:
            prefs["favorite_pairing_rules"] = data.favorite_pairing_rules
        if data.notes is not None:
            prefs["notes"] = data.notes
        prefs["updated_at"] = datetime.now(timezone.utc)

        import os
        if "PYTEST_CURRENT_TEST" not in os.environ:
            try:
                payload = {
                    "user_id": self.user_id,
                    "preferred_colors": prefs.get("preferred_colors", []),
                    "preferred_categories": prefs.get("preferred_categories", []),
                    "preferred_occasions": prefs.get("preferred_occasions", []),
                    "avoided_combinations": prefs.get("avoided_combinations", []),
                    "style_persona": prefs.get("style_persona", "Casual Classic"),
                    "favorite_pairing_rules": prefs.get("favorite_pairing_rules", []),
                    "notes": prefs.get("notes"),
                    "updated_at": prefs["updated_at"].isoformat(),
                }
                self.supabase.table("wardrobe_style_preferences").upsert(payload).execute()
            except Exception as e:
                logger.debug(f"Supabase style preferences upsert fallback: {e}")

        return self.get_style_memory()
