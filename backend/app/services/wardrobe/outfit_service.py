from datetime import datetime, timezone
from typing import List, Optional, Dict, Any, Set, Tuple
import uuid
import logging
from supabase import Client

from app.schemas.outfit import (
    OutfitSourceEnum,
    OutfitItemSummary,
    OutfitCreateRequest,
    OutfitUpdateRequest,
    OutfitResponse,
    OutfitListResponse,
    OutfitGenerateRequest,
    GuidedStylingRequest,
    OutfitValidateRequest,
    OutfitValidateResponse,
    OutfitWearRequest,
    OutfitWearResponse,
    OutfitRecommendationCard,
    OutfitRecommendationsResponse,
)
from app.schemas.laundry import GarmentLaundryStatusUpdate, LaundryStatusEnum

logger = logging.getLogger(__name__)

# Session store for unit test execution and fallback
_SESSION_OUTFITS_STORE: Dict[str, Dict[str, Dict[str, Any]]] = {}
_SESSION_OUTFIT_ITEMS_STORE: Dict[str, Dict[str, List[Dict[str, Any]]]] = {}
_SESSION_WEAR_HISTORY_STORE: Dict[str, List[Dict[str, Any]]] = {}

NEUTRAL_COLORS = {"black", "white", "grey", "gray", "navy", "navy blue", "beige", "charcoal", "cream", "khaki"}

def _is_color_compatible(c1: str, c2: str) -> bool:
    c1_lower = c1.lower().strip()
    c2_lower = c2.lower().strip()
    if c1_lower == c2_lower:
        return True
    if c1_lower in NEUTRAL_COLORS or c2_lower in NEUTRAL_COLORS:
        return True
    # Complementary combinations
    complementaries = [
        {"blue", "orange"},
        {"navy", "yellow"},
        {"pink", "olive"},
        {"burgundy", "beige"},
        {"teal", "brown"},
        {"red", "blue"},
    ]
    for pair in complementaries:
        if (c1_lower in pair or any(p in c1_lower for p in pair)) and \
           (c2_lower in pair or any(p in c2_lower for p in pair)):
            return True
    return False

class OutfitService:
    def __init__(self, supabase: Client, user_id: str, wardrobe_service=None, laundry_service=None):
        self.supabase = supabase
        self.user_id = user_id
        self.wardrobe_service = wardrobe_service
        self.laundry_service = laundry_service

        if self.user_id not in _SESSION_OUTFITS_STORE:
            _SESSION_OUTFITS_STORE[self.user_id] = {}
        if self.user_id not in _SESSION_OUTFIT_ITEMS_STORE:
            _SESSION_OUTFIT_ITEMS_STORE[self.user_id] = {}
        if self.user_id not in _SESSION_WEAR_HISTORY_STORE:
            _SESSION_WEAR_HISTORY_STORE[self.user_id] = []

    def _get_outfits_store(self) -> Dict[str, Dict[str, Any]]:
        return _SESSION_OUTFITS_STORE[self.user_id]

    def _get_outfit_items_store(self) -> Dict[str, List[Dict[str, Any]]]:
        return _SESSION_OUTFIT_ITEMS_STORE[self.user_id]

    def _get_wear_history_store(self) -> List[Dict[str, Any]]:
        return _SESSION_WEAR_HISTORY_STORE[self.user_id]

    # --- HELPER: Garment Retrieval & Eligibility ---
    def _get_all_user_garments(self) -> List[Dict[str, Any]]:
        garments = []
        try:
            res = self.supabase.table("wardrobe_items").select("*").eq("user_id", self.user_id).eq("is_archived", False).execute()
            if res.data is not None:
                garments = res.data
        except Exception as e:
            logger.warning(f"[OutfitService] Remote garments query fallback: {e}")
            if self.wardrobe_service:
                local = self.wardrobe_service._get_local_store()
                garments = [v for v in local.values() if not v.get("is_archived", False)]
        return garments

    def _check_garment_eligibility(self, g: Dict[str, Any], exclude_worn: bool = True) -> Tuple[bool, Optional[str]]:
        status = g.get("laundry_status")
        if status is None:
            return False, "Laundry status is unassigned; verify condition before wear"
        s = str(status).upper()
        if s == LaundryStatusEnum.WASHING.value:
            return False, "Garment is currently in the wash cycle"
        if s == LaundryStatusEnum.DRYING.value:
            return False, "Garment is currently drying"
        if s == LaundryStatusEnum.WORN.value:
            if exclude_worn:
                return False, "Garment is marked as worn"
            return True, None
        if s in (LaundryStatusEnum.CLEAN.value, LaundryStatusEnum.STORED.value):
            return True, None
        return False, f"Garment status '{s}' is not available"

    def _to_item_summary(self, g: Dict[str, Any], exclude_worn: bool = True) -> OutfitItemSummary:
        is_eligible, reason = self._check_garment_eligibility(g, exclude_worn=exclude_worn)
        return OutfitItemSummary(
            garment_id=g.get("id", ""),
            name=g.get("name", ""),
            main_category=g.get("main_category", "Tops"),
            primary_color=g.get("primary_color", "Unknown"),
            secondary_colors=g.get("secondary_colors", []) or [],
            pattern=g.get("pattern"),
            original_image_ref=g.get("original_image_ref"),
            processed_image_ref=g.get("processed_image_ref"),
            thumbnail_ref=g.get("thumbnail_ref"),
            laundry_status=g.get("laundry_status"),
            is_eligible=is_eligible,
            unavailability_reason=reason,
        )

    # --- 1. OUTFIT RECOMMENDATION ENGINE (MODE A: AUTOMATIC) ---
    def generate_recommendations(self, req: OutfitGenerateRequest) -> OutfitRecommendationsResponse:
        all_garments = self._get_all_user_garments()
        if not all_garments:
            return OutfitRecommendationsResponse(recommendations=[], total=0)

        # Separate into eligible pools
        tops = []
        bottoms = []
        dresses = []
        ethnic_tops = []
        ethnic_bottoms = []
        layers = []

        for g in all_garments:
            is_eligible, _ = self._check_garment_eligibility(g, exclude_worn=req.exclude_worn)
            if not is_eligible:
                continue

            if req.favorites_only and not g.get("is_favorite", False):
                continue

            # Check occasion if garment has specified occasions
            occasions = [o.lower() for o in (g.get("occasions") or [])]
            if req.occasion and occasions and req.occasion.lower() not in occasions:
                # If garment has explicit occasions and requested occasion doesn't match, demote or skip
                continue

            cat = (g.get("main_category") or "").lower()
            sub = (g.get("subcategory") or "").lower()
            name = (g.get("name") or "").lower()

            if "ethnic" in cat or "kurta" in cat or "kurta" in name or "kurta" in sub:
                ethnic_tops.append(g)
            elif "dress" in cat or "jumpsuit" in cat or "dress" in name or "jumpsuit" in sub:
                dresses.append(g)
            elif "top" in cat or "shirt" in cat or "t-shirt" in cat or "blouse" in cat or "top" in name:
                tops.append(g)
            elif "bottom" in cat or "pant" in cat or "jean" in cat or "trouser" in cat or "legging" in cat or "skirt" in cat:
                if "legging" in name or "salwar" in name or "palazzo" in name:
                    ethnic_bottoms.append(g)
                bottoms.append(g)
            elif "outerwear" in cat or "jacket" in cat or "blazer" in cat or "sweater" in cat:
                layers.append(g)
            else:
                tops.append(g)

        if not ethnic_bottoms:
            ethnic_bottoms = bottoms

        generated_cards: List[OutfitRecommendationCard] = []
        seen_fingerprints: Set[str] = set()

        def add_combination(items: List[Dict[str, Any]], explanation: str, name: str):
            g_ids = [it["id"] for it in items]
            fingerprint = ":".join(sorted(g_ids))
            if fingerprint in seen_fingerprints:
                return
            seen_fingerprints.add(fingerprint)

            summaries = [self._to_item_summary(it, exclude_worn=req.exclude_worn) for it in items]
            is_avail = all(s.is_eligible for s in summaries)
            card = OutfitRecommendationCard(
                id=f"rec_{uuid.uuid4().hex[:10]}",
                name=name,
                occasion=req.occasion or "Casual",
                garments=summaries,
                garment_ids=g_ids,
                explanation=explanation,
                is_available=is_avail,
                combination_fingerprint=fingerprint,
            )
            generated_cards.append(card)

        # 1. Dress-based outfits (One-piece perfection)
        for d in dresses:
            if len(generated_cards) >= req.limit:
                break
            items = [d]
            expl = f"{d.get('name')} provides an effortless single-piece {req.occasion.lower() if req.occasion else 'stylish'} look in {d.get('primary_color')}."
            add_combination(items, expl, f"{d.get('name')} Ensemble")

        # 2. Ethnic wear combinations (Kurta + Bottom)
        for k in ethnic_tops:
            if len(generated_cards) >= req.limit:
                break
            for b in ethnic_bottoms:
                if _is_color_compatible(k.get("primary_color", ""), b.get("primary_color", "")):
                    items = [k, b]
                    expl = f"The {b.get('primary_color')} {b.get('name')} harmonizes with the {k.get('primary_color')} {k.get('name')} for refined ethnic styling."
                    add_combination(items, expl, f"{k.get('name')} & {b.get('name')}")
                    break

        # 3. Top + Bottom (+ optional Layer)
        for t in tops:
            if len(generated_cards) >= req.limit:
                break
            for b in bottoms:
                if t["id"] == b["id"]:
                    continue
                if _is_color_compatible(t.get("primary_color", ""), b.get("primary_color", "")):
                    items = [t, b]
                    # Check for a matching layer if available
                    for l in layers:
                        if l["id"] not in (t["id"], b["id"]) and _is_color_compatible(l.get("primary_color", ""), t.get("primary_color", "")):
                            items.append(l)
                            break

                    expl = f"The neutral balance of {b.get('primary_color')} {b.get('name')} complements the {t.get('primary_color')} {t.get('name')}."
                    if len(items) > 2:
                        expl += f" Layered with {items[2].get('name')} for depth."
                    add_combination(items, expl, f"{t.get('name')} & {b.get('name')}")
                    break

        # If strict matching produced fewer than limit, relax color compatibility
        if len(generated_cards) < req.limit:
            for t in tops:
                if len(generated_cards) >= req.limit:
                    break
                for b in bottoms:
                    if t["id"] == b["id"]:
                        continue
                    g_ids = [t["id"], b["id"]]
                    fp = ":".join(sorted(g_ids))
                    if fp not in seen_fingerprints:
                        add_combination([t, b], f"Versatile daily pairing of {t.get('name')} with {b.get('name')}.", f"{t.get('name')} & {b.get('name')}")
                        break

        return OutfitRecommendationsResponse(
            recommendations=generated_cards[:req.limit],
            total=len(generated_cards[:req.limit]),
        )

    # --- 2. GUIDED STYLING (MODE B) ---
    def generate_guided_styling(self, req: GuidedStylingRequest) -> OutfitRecommendationsResponse:
        all_garments = self._get_all_user_garments()
        seed_garment = next((g for g in all_garments if g["id"] == req.seed_garment_id), None)
        if not seed_garment:
            raise ValueError(f"Seed garment {req.seed_garment_id} not found in user wardrobe.")

        seed_cat = (seed_garment.get("main_category") or "").lower()
        seed_sub = (seed_garment.get("subcategory") or "").lower()
        seed_name = (seed_garment.get("name") or "").lower()
        seed_color = seed_garment.get("primary_color", "")

        candidates = [g for g in all_garments if g["id"] != seed_garment["id"]]
        if req.exclude_worn:
            candidates = [g for g in candidates if self._check_garment_eligibility(g, exclude_worn=True)[0]]

        results: List[OutfitRecommendationCard] = []
        seen_fingerprints: Set[str] = set()

        def add_guided(partner_items: List[Dict[str, Any]], explanation: str):
            all_items = [seed_garment] + partner_items
            g_ids = [it["id"] for it in all_items]
            fp = ":".join(sorted(g_ids))
            if fp in seen_fingerprints:
                return
            seen_fingerprints.add(fp)
            summaries = [self._to_item_summary(it, exclude_worn=req.exclude_worn) for it in all_items]
            card = OutfitRecommendationCard(
                id=f"guided_{uuid.uuid4().hex[:10]}",
                name=f"Styled with {seed_garment.get('name')}",
                occasion=req.occasion or "Casual",
                garments=summaries,
                garment_ids=g_ids,
                explanation=explanation,
                is_available=all(s.is_eligible for s in summaries),
                combination_fingerprint=fp,
            )
            results.append(card)

        # If seed is Ethnic Kurta / Top
        if "ethnic" in seed_cat or "kurta" in seed_cat or "kurta" in seed_name or "kurta" in seed_sub:
            matching_bottoms = [g for g in candidates if "bottom" in (g.get("main_category") or "").lower() or "legging" in (g.get("name") or "").lower()]
            for b in matching_bottoms:
                if len(results) >= req.limit:
                    break
                expl = f"The {b.get('name')} in {b.get('primary_color')} anchors the ethnic silhouette of {seed_garment.get('name')}."
                add_guided([b], expl)

        # If seed is a Top
        elif "top" in seed_cat or "shirt" in seed_cat or "t-shirt" in seed_cat or "blouse" in seed_cat:
            matching_bottoms = [g for g in candidates if "bottom" in (g.get("main_category") or "").lower()]
            for b in matching_bottoms:
                if len(results) >= req.limit:
                    break
                if _is_color_compatible(seed_color, b.get("primary_color", "")):
                    expl = f"{b.get('name')} balances the {seed_color} tone of {seed_garment.get('name')} cleanly."
                    add_guided([b], expl)

        # If seed is a Bottom
        elif "bottom" in seed_cat or "pant" in seed_cat or "jean" in seed_cat or "trouser" in seed_cat or "skirt" in seed_cat:
            matching_tops = [g for g in candidates if "top" in (g.get("main_category") or "").lower() or "shirt" in (g.get("main_category") or "").lower()]
            for t in matching_tops:
                if len(results) >= req.limit:
                    break
                if _is_color_compatible(seed_color, t.get("primary_color", "")):
                    expl = f"{t.get('name')} coordinates gracefully with {seed_garment.get('name')}."
                    add_guided([t], expl)

        # If seed is a Dress
        elif "dress" in seed_cat or "jumpsuit" in seed_cat:
            layers = [g for g in candidates if "outerwear" in (g.get("main_category") or "").lower() or "jacket" in (g.get("main_category") or "").lower()]
            for l in layers:
                if len(results) >= req.limit:
                    break
                expl = f"Layering {seed_garment.get('name')} with {l.get('name')} elevates the look."
                add_guided([l], expl)
            if not results:
                add_guided([], f"{seed_garment.get('name')} stands alone as a striking one-piece statement.")

        # Fallback if specific styling produced fewer than limit
        if len(results) < req.limit:
            for c in candidates:
                if len(results) >= req.limit:
                    break
                add_guided([c], f"Creative pairing highlighting {seed_garment.get('name')} with {c.get('name')}.")

        return OutfitRecommendationsResponse(
            recommendations=results[:req.limit],
            total=len(results[:req.limit]),
        )

    # --- 3. MANUAL OUTFIT VALIDATION ---
    def validate_outfit_selection(self, req: OutfitValidateRequest) -> OutfitValidateResponse:
        all_garments = self._get_all_user_garments()
        garment_map = {g["id"]: g for g in all_garments}

        conflicts = []
        items: List[OutfitItemSummary] = []
        is_wearable = True

        if not req.garment_ids:
            return OutfitValidateResponse(is_valid=False, is_wearable=False, conflicts=["At least one garment is required."], items=[])

        seen_ids = set()
        for gid in req.garment_ids:
            if gid in seen_ids:
                conflicts.append(f"Duplicate garment detected: {gid}")
                continue
            seen_ids.add(gid)

            g = garment_map.get(gid)
            if not g:
                conflicts.append(f"Garment {gid} does not exist in your wardrobe.")
                is_wearable = False
                continue

            summary = self._to_item_summary(g, exclude_worn=False)
            items.append(summary)

            is_eligible, reason = self._check_garment_eligibility(g, exclude_worn=False)
            if not is_eligible:
                is_wearable = False
                conflicts.append(f"{g.get('name')} ({gid}): {reason}")

        is_valid = len(conflicts) == 0 or all("not exist" not in c and "Duplicate" not in c for c in conflicts)
        return OutfitValidateResponse(
            is_valid=is_valid,
            is_wearable=is_wearable and is_valid,
            conflicts=conflicts,
            items=items,
        )

    # --- 4. CRUD FOR SAVED OUTFITS ---
    def create_outfit(self, req: OutfitCreateRequest) -> OutfitResponse:
        all_garments = self._get_all_user_garments()
        garment_map = {g["id"]: g for g in all_garments}

        # Validate that all requested garments exist and belong to user
        resolved_items = []
        for gid in req.garment_ids:
            g = garment_map.get(gid)
            if not g:
                raise ValueError(f"Garment {gid} does not exist or does not belong to user.")
            resolved_items.append(g)

        now = datetime.now(timezone.utc)
        outfit_id = f"outfit_{uuid.uuid4().hex[:12]}"

        # Remote insert if possible
        try:
            record = {
                "id": outfit_id,
                "user_id": self.user_id,
                "name": req.name,
                "description": req.description,
                "occasion": req.occasion,
                "notes": req.notes,
                "is_favourite": req.is_favourite,
                "creation_source": req.creation_source.value,
                "styling_explanation": req.styling_explanation,
                "wear_count": 0,
                "created_at": now.isoformat(),
                "updated_at": now.isoformat(),
            }
            self.supabase.table("outfits").insert(record).execute()

            for pos, g in enumerate(resolved_items):
                item_record = {
                    "id": f"item_{uuid.uuid4().hex[:10]}",
                    "outfit_id": outfit_id,
                    "garment_id": g["id"],
                    "user_id": self.user_id,
                    "position": pos,
                    "created_at": now.isoformat(),
                }
                self.supabase.table("outfit_items").insert(item_record).execute()
        except Exception as e:
            logger.warning(f"[OutfitService] Remote create_outfit fallback: {e}")

        # Local cache insertion
        outfits_store = self._get_outfits_store()
        outfit_data = {
            "id": outfit_id,
            "user_id": self.user_id,
            "name": req.name,
            "description": req.description,
            "occasion": req.occasion,
            "notes": req.notes,
            "is_favourite": req.is_favourite,
            "creation_source": req.creation_source.value,
            "styling_explanation": req.styling_explanation,
            "wear_count": 0,
            "last_worn_date": None,
            "garment_ids": req.garment_ids,
            "is_archived": False,
            "created_at": now,
            "updated_at": now,
        }
        outfits_store[outfit_id] = outfit_data

        items_store = self._get_outfit_items_store()
        items_store[outfit_id] = [
            {"garment_id": g["id"], "position": pos} for pos, g in enumerate(resolved_items)
        ]

        summaries = [self._to_item_summary(g, exclude_worn=False) for g in resolved_items]
        unavail = [f"{s.name}: {s.unavailability_reason}" for s in summaries if not s.is_eligible]

        return OutfitResponse(
            id=outfit_id,
            user_id=self.user_id,
            name=req.name,
            description=req.description,
            occasion=req.occasion,
            notes=req.notes,
            is_favourite=req.is_favourite,
            creation_source=req.creation_source,
            styling_explanation=req.styling_explanation,
            wear_count=0,
            last_worn_date=None,
            items=summaries,
            garment_ids=req.garment_ids,
            is_available=len(unavail) == 0,
            unavailable_reasons=unavail,
            created_at=now,
            updated_at=now,
        )

    def get_outfits(
        self,
        occasion: Optional[str] = None,
        favourite_only: bool = False,
        search: Optional[str] = None,
    ) -> OutfitListResponse:
        outfits_store = self._get_outfits_store()
        all_garments = self._get_all_user_garments()
        garment_map = {g["id"]: g for g in all_garments}

        results: List[OutfitResponse] = []
        for out in outfits_store.values():
            if out.get("is_archived", False):
                continue
            if favourite_only and not out.get("is_favourite", False):
                continue
            if occasion and out.get("occasion", "").lower() != occasion.lower():
                continue
            if search:
                q = search.lower()
                name_match = q in out.get("name", "").lower()
                desc_match = q in (out.get("description") or "").lower()
                if not (name_match or desc_match):
                    continue

            gids = out.get("garment_ids", [])
            summaries = []
            for gid in gids:
                g = garment_map.get(gid)
                if g:
                    summaries.append(self._to_item_summary(g, exclude_worn=False))
                else:
                    summaries.append(
                        OutfitItemSummary(
                            garment_id=gid,
                            name="Archived/Missing Garment",
                            main_category="Unknown",
                            primary_color="Unknown",
                            is_eligible=False,
                            unavailability_reason="Garment has been removed from wardrobe",
                        )
                    )

            unavail = [f"{s.name}: {s.unavailability_reason}" for s in summaries if not s.is_eligible]
            created_dt = out.get("created_at")
            if isinstance(created_dt, str):
                created_dt = datetime.fromisoformat(created_dt)
            updated_dt = out.get("updated_at")
            if isinstance(updated_dt, str):
                updated_dt = datetime.fromisoformat(updated_dt)

            results.append(
                OutfitResponse(
                    id=out["id"],
                    user_id=self.user_id,
                    name=out["name"],
                    description=out.get("description"),
                    occasion=out.get("occasion", "Casual"),
                    notes=out.get("notes"),
                    is_favourite=out.get("is_favourite", False),
                    creation_source=OutfitSourceEnum(out.get("creation_source", "MANUAL")),
                    styling_explanation=out.get("styling_explanation"),
                    wear_count=out.get("wear_count", 0),
                    last_worn_date=out.get("last_worn_date"),
                    items=summaries,
                    garment_ids=gids,
                    is_available=len(unavail) == 0,
                    unavailable_reasons=unavail,
                    created_at=created_dt or datetime.now(timezone.utc),
                    updated_at=updated_dt or datetime.now(timezone.utc),
                )
            )

        return OutfitListResponse(outfits=results, total=len(results))

    def get_outfit(self, outfit_id: str) -> Optional[OutfitResponse]:
        outfits_store = self._get_outfits_store()
        out = outfits_store.get(outfit_id)
        if not out or out.get("is_archived", False):
            return None

        all_garments = self._get_all_user_garments()
        garment_map = {g["id"]: g for g in all_garments}

        gids = out.get("garment_ids", [])
        summaries = [self._to_item_summary(garment_map[gid], exclude_worn=False) for gid in gids if gid in garment_map]
        unavail = [f"{s.name}: {s.unavailability_reason}" for s in summaries if not s.is_eligible]

        created_dt = out.get("created_at")
        if isinstance(created_dt, str):
            created_dt = datetime.fromisoformat(created_dt)
        updated_dt = out.get("updated_at")
        if isinstance(updated_dt, str):
            updated_dt = datetime.fromisoformat(updated_dt)

        return OutfitResponse(
            id=out["id"],
            user_id=self.user_id,
            name=out["name"],
            description=out.get("description"),
            occasion=out.get("occasion", "Casual"),
            notes=out.get("notes"),
            is_favourite=out.get("is_favourite", False),
            creation_source=OutfitSourceEnum(out.get("creation_source", "MANUAL")),
            styling_explanation=out.get("styling_explanation"),
            wear_count=out.get("wear_count", 0),
            last_worn_date=out.get("last_worn_date"),
            items=summaries,
            garment_ids=gids,
            is_available=len(unavail) == 0,
            unavailable_reasons=unavail,
            created_at=created_dt or datetime.now(timezone.utc),
            updated_at=updated_dt or datetime.now(timezone.utc),
        )

    def update_outfit(self, outfit_id: str, req: OutfitUpdateRequest) -> OutfitResponse:
        outfits_store = self._get_outfits_store()
        out = outfits_store.get(outfit_id)
        if not out or out.get("is_archived", False):
            raise ValueError(f"Outfit {outfit_id} not found.")

        if req.name is not None:
            out["name"] = req.name
        if req.description is not None:
            out["description"] = req.description
        if req.occasion is not None:
            out["occasion"] = req.occasion
        if req.notes is not None:
            out["notes"] = req.notes
        if req.is_favourite is not None:
            out["is_favourite"] = req.is_favourite
        if req.styling_explanation is not None:
            out["styling_explanation"] = req.styling_explanation
        if req.garment_ids is not None:
            all_garments = self._get_all_user_garments()
            garment_map = {g["id"]: g for g in all_garments}
            for gid in req.garment_ids:
                if gid not in garment_map:
                    raise ValueError(f"Garment {gid} does not exist in user wardrobe.")
            out["garment_ids"] = req.garment_ids

        now = datetime.now(timezone.utc)
        out["updated_at"] = now

        try:
            update_data = {
                "name": out["name"],
                "description": out.get("description"),
                "occasion": out.get("occasion"),
                "notes": out.get("notes"),
                "is_favourite": out.get("is_favourite"),
                "styling_explanation": out.get("styling_explanation"),
                "updated_at": now.isoformat(),
            }
            self.supabase.table("outfits").update(update_data).eq("id", outfit_id).execute()
        except Exception as e:
            logger.warning(f"[OutfitService] Remote update_outfit fallback: {e}")

        return self.get_outfit(outfit_id)

    def delete_outfit(self, outfit_id: str) -> bool:
        outfits_store = self._get_outfits_store()
        out = outfits_store.get(outfit_id)
        if not out or out.get("is_archived", False):
            raise ValueError(f"Outfit {outfit_id} not found.")

        out["is_archived"] = True
        try:
            self.supabase.table("outfits").delete().eq("id", outfit_id).execute()
        except Exception as e:
            logger.warning(f"[OutfitService] Remote delete_outfit fallback: {e}")
        return True

    # --- 5. WEAR THIS OUTFIT (PHASE 4 LAUNDRY INTEGRATION) ---
    def wear_outfit(self, outfit_id: str, req: OutfitWearRequest) -> OutfitWearResponse:
        outfit = self.get_outfit(outfit_id)
        if not outfit:
            raise ValueError(f"Outfit {outfit_id} not found.")

        # Check idempotency
        wear_history = self._get_wear_history_store()
        if req.idempotency_key:
            for w in wear_history:
                if w.get("idempotency_key") == req.idempotency_key:
                    logger.info(f"[OutfitService] Idempotent wear duplicate: {req.idempotency_key}")
                    return OutfitWearResponse(
                        outfit_id=outfit_id,
                        worn_at=w["worn_at"],
                        garments_updated=w.get("garments_updated", []),
                        wear_count=outfit.wear_count,
                        idempotency_key=req.idempotency_key,
                    )

        # Validate that all garments are currently eligible
        unavail = []
        for item in outfit.items:
            if not item.is_eligible:
                unavail.append(f"{item.name} ({item.garment_id}): {item.unavailability_reason}")

        if unavail:
            raise ValueError(f"Cannot wear outfit. Laundry conflicts: {'; '.join(unavail)}")

        now = datetime.now(timezone.utc)
        updated_garments = []

        # Update each garment through LaundryService (incrementing wear_count and setting last_worn_date)
        for gid in outfit.garment_ids:
            if self.laundry_service:
                garment_idempotency = f"{req.idempotency_key}:{gid}" if req.idempotency_key else None
                status_update = GarmentLaundryStatusUpdate(
                    laundry_status=LaundryStatusEnum.WORN,
                    notes=f"Worn in outfit: {outfit.name}",
                    idempotency_key=garment_idempotency,
                    source="OUTFIT_WEAR",
                )
                self.laundry_service.update_garment_laundry_status(gid, status_update)
                updated_garments.append(gid)
            elif self.wardrobe_service:
                # Direct fallback update
                g = self.wardrobe_service.get_item(gid)
                if g:
                    new_wear = (g.wear_count or 0) + 1
                    self.wardrobe_service.update_item_field(gid, "laundry_status", "WORN")
                    self.wardrobe_service.update_item_field(gid, "wear_count", new_wear)
                    self.wardrobe_service.update_item_field(gid, "last_worn_date", now.isoformat())
                    updated_garments.append(gid)

        # Update outfit's wear count
        outfits_store = self._get_outfits_store()
        raw_outfit = outfits_store.get(outfit_id)
        if raw_outfit:
            raw_outfit["wear_count"] = raw_outfit.get("wear_count", 0) + 1
            raw_outfit["last_worn_date"] = now
            raw_outfit["updated_at"] = now

        # Record outfit wear history
        history_record = {
            "id": f"wear_{uuid.uuid4().hex[:10]}",
            "user_id": self.user_id,
            "outfit_id": outfit_id,
            "worn_at": now,
            "garments_updated": updated_garments,
            "notes": req.notes,
            "idempotency_key": req.idempotency_key,
        }
        wear_history.append(history_record)

        try:
            self.supabase.table("outfit_wear_history").insert(
                {
                    "id": history_record["id"],
                    "user_id": self.user_id,
                    "outfit_id": outfit_id,
                    "worn_at": now.isoformat(),
                    "notes": req.notes,
                    "idempotency_key": req.idempotency_key,
                }
            ).execute()
        except Exception as e:
            logger.warning(f"[OutfitService] Remote outfit_wear_history insert fallback: {e}")

        return OutfitWearResponse(
            outfit_id=outfit_id,
            worn_at=now,
            garments_updated=updated_garments,
            wear_count=raw_outfit.get("wear_count", 1) if raw_outfit else 1,
            idempotency_key=req.idempotency_key,
        )

