from datetime import datetime, timezone, date
from typing import List, Optional, Dict, Any
import uuid
import logging
from supabase import Client

from app.schemas.wardrobe import (
    GarmentCreate,
    GarmentUpdate,
    GarmentResponse,
    CategoryResponse,
    GarmentListResponse,
    WardrobeStatsResponse,
    InitialImportResponse,
    LaundryStatusEnum,
)

logger = logging.getLogger(__name__)

# Standard 10 built-in categories
DEFAULT_CATEGORIES = [
    CategoryResponse(id="cat_tops", name="Tops", icon_name="checkroom", order_index=1,
                     subcategories=["T-Shirts", "Shirts", "Blouses", "Tunics", "Crop Tops", "Polos", "Tanks"]),
    CategoryResponse(id="cat_bottoms", name="Bottoms", icon_name="dry_cleaning", order_index=2,
                     subcategories=["Jeans", "Trousers", "Pants", "Leggings", "Cargo Pants", "Shorts", "Skirts"]),
    CategoryResponse(id="cat_ethnic", name="Ethnic wear", icon_name="style", order_index=3,
                     subcategories=["Kurtas", "Kurta Sets", "Sarees", "Dupattas", "Lehengas", "Anarkalis"]),
    CategoryResponse(id="cat_dresses", name="Dresses", icon_name="woman", order_index=4,
                     subcategories=["Midi Dresses", "Maxi Dresses", "Mini Dresses", "Jumpsuits", "Gowns"]),
    CategoryResponse(id="cat_outerwear", name="Outerwear", icon_name="layers", order_index=5,
                     subcategories=["Jackets", "Denim Jackets", "Coats", "Cardigans", "Shrugs", "Blazers", "Hoodies"]),
    CategoryResponse(id="cat_activewear", name="Activewear", icon_name="fitness_center", order_index=6,
                     subcategories=["Sports Bras", "Gym Leggings", "Track Pants", "Athletic Tees", "Shorts"]),
    CategoryResponse(id="cat_innerwear", name="Innerwear", icon_name="favorite_border", order_index=7,
                     subcategories=["Briefs", "Bras", "Camisoles", "Shapewear", "Thermal Wear"]),
    CategoryResponse(id="cat_sleepwear", name="Sleepwear", icon_name="bedtime", order_index=8,
                     subcategories=["Pyjamas", "Nightgowns", "Lounge Pants", "Sleep Sets", "Robes"]),
    CategoryResponse(id="cat_footwear", name="Footwear", icon_name="roller_skating", order_index=9,
                     subcategories=["Sneakers", "Flats", "Heels", "Boots", "Sandals", "Loafers", "Slippers"]),
    CategoryResponse(id="cat_accessories", name="Accessories", icon_name="watch", order_index=10,
                     subcategories=["Bags", "Belts", "Scarves", "Jewelry", "Sunglasses", "Hats", "Dupattas"]),
]

# Session memory store when Supabase tables are unavailable
_SESSION_WARDROBE_STORE: Dict[str, Dict[str, Dict[str, Any]]] = {}

class WardrobeService:
    def __init__(self, supabase: Client, user_id: str):
        self.supabase = supabase
        self.user_id = user_id
        if self.user_id not in _SESSION_WARDROBE_STORE:
            _SESSION_WARDROBE_STORE[self.user_id] = {}

    def _get_local_store(self) -> Dict[str, Dict[str, Any]]:
        return _SESSION_WARDROBE_STORE[self.user_id]

    def get_items(
        self,
        category: Optional[str] = None,
        laundry_status: Optional[str] = None,
        is_favorite: Optional[bool] = None,
        search: Optional[str] = None,
        sort_by: str = "created_at",
        sort_order: str = "desc",
        page: int = 1,
        limit: int = 50,
        include_archived: bool = False,
    ) -> GarmentListResponse:
        records: List[Dict[str, Any]] = []

        try:
            query = self.supabase.table("wardrobe_items").select("*").eq("user_id", self.user_id)
            if not include_archived:
                query = query.eq("is_archived", False)
            if category:
                query = query.eq("main_category", category)
            if laundry_status:
                query = query.eq("laundry_status", laundry_status)
            if is_favorite is not None:
                query = query.eq("is_favorite", is_favorite)

            res = query.execute()
            if res.data is not None:
                records = res.data
        except Exception as e:
            logger.warning(f"[WardrobeService] Remote query failed, using session store: {e}")
            local = self._get_local_store()
            records = [
                item for item in local.values()
                if (include_archived or not item.get("is_archived", False))
                and (category is None or item.get("main_category", "").lower() == category.lower())
                and (laundry_status is None or item.get("laundry_status") == laundry_status)
                and (is_favorite is None or item.get("is_favorite", False) == is_favorite)
            ]

        # In-memory search filtering across multiple fields
        if search and search.strip():
            q = search.strip().lower()
            filtered = []
            for r in records:
                name_match = q in r.get("name", "").lower()
                id_match = q in r.get("id", "").lower()
                cat_match = q in r.get("main_category", "").lower()
                sub_match = q in (r.get("subcategory") or "").lower()
                color_match = q in r.get("primary_color", "").lower()
                brand_match = q in (r.get("brand") or "").lower()
                pattern_match = q in (r.get("pattern") or "").lower()
                if name_match or id_match or cat_match or sub_match or color_match or brand_match or pattern_match:
                    filtered.append(r)
            records = filtered

        # Sorting
        reverse = (sort_order.lower() == "desc")
        if sort_by == "name":
            records.sort(key=lambda x: x.get("name", "").lower(), reverse=reverse)
        elif sort_by == "updated_at":
            records.sort(key=lambda x: str(x.get("updated_at", "")), reverse=reverse)
        else:  # default created_at
            records.sort(key=lambda x: str(x.get("created_at", "")), reverse=reverse)

        total = len(records)
        start = (page - 1) * limit
        end = start + limit
        sliced = records[start:end]

        items = [GarmentResponse(**item) for item in sliced]
        return GarmentListResponse(items=items, total=total, page=page, limit=limit)

    def get_item(self, item_id: str) -> Optional[GarmentResponse]:
        try:
            res = self.supabase.table("wardrobe_items").select("*").eq("id", item_id).eq("user_id", self.user_id).execute()
            if res.data and len(res.data) > 0:
                return GarmentResponse(**res.data[0])
        except Exception as e:
            logger.warning(f"[WardrobeService] Remote get_item failed, checking session store: {e}")

        local = self._get_local_store()
        if item_id in local:
            return GarmentResponse(**local[item_id])
        return None

    def create_item(self, data: GarmentCreate) -> GarmentResponse:
        now = datetime.now(timezone.utc).isoformat()
        item_id = data.id if (data.id and data.id.strip()) else f"CLO-{str(uuid.uuid4())[:8].upper()}"

        record: Dict[str, Any] = {
            "id": item_id,
            "user_id": self.user_id,
            "name": data.name,
            "main_category": data.main_category,
            "subcategory": data.subcategory,
            "original_image_ref": data.original_image_ref,
            "processed_image_ref": data.processed_image_ref,
            "thumbnail_ref": data.thumbnail_ref,
            "primary_color": data.primary_color,
            "secondary_colors": data.secondary_colors,
            "pattern": data.pattern,
            "fabric_material": data.fabric_material,
            "neckline": data.neckline,
            "sleeve_length": data.sleeve_length,
            "fit": data.fit,
            "silhouette": data.silhouette,
            "garment_length": data.garment_length,
            "size": data.size,
            "brand": data.brand,
            "purchase_date": data.purchase_date.isoformat() if data.purchase_date else None,
            "purchase_price": data.purchase_price,
            "occasions": data.occasions,
            "seasons": data.seasons,
            "laundry_status": data.laundry_status,
            "is_favorite": data.is_favorite,
            "notes": data.notes,
            "is_archived": False,
            "created_at": now,
            "updated_at": now,
        }

        # Keep in local session store
        self._get_local_store()[item_id] = record

        try:
            self.supabase.table("wardrobe_items").insert(record).execute()
        except Exception as e:
            logger.warning(f"[WardrobeService] Remote insert failed, kept in session store: {e}")

        return GarmentResponse(**record)

    def update_item(self, item_id: str, data: GarmentUpdate) -> Optional[GarmentResponse]:
        existing = self.get_item(item_id)
        if not existing:
            return None

        now = datetime.now(timezone.utc).isoformat()
        current_dict = existing.model_dump()
        updates = data.model_dump(exclude_unset=True)

        for k, v in updates.items():
            if k in ("id", "user_id", "created_at"):
                continue  # Immutable fields
            if isinstance(v, (datetime, date)):
                current_dict[k] = v.isoformat()
            else:
                current_dict[k] = v

        current_dict["updated_at"] = now
        self._get_local_store()[item_id] = current_dict

        try:
            self.supabase.table("wardrobe_items").update(current_dict).eq("id", item_id).eq("user_id", self.user_id).execute()
        except Exception as e:
            logger.warning(f"[WardrobeService] Remote update failed, kept in session store: {e}")

        return GarmentResponse(**current_dict)

    def delete_item(self, item_id: str, hard_delete: bool = False) -> bool:
        existing = self.get_item(item_id)
        if not existing:
            return False

        if hard_delete:
            self._get_local_store().pop(item_id, None)
            try:
                self.supabase.table("wardrobe_items").delete().eq("id", item_id).eq("user_id", self.user_id).execute()
            except Exception as e:
                logger.warning(f"[WardrobeService] Remote hard delete error: {e}")
            return True
        else:
            # Soft archival to preserve wear-history integrity
            return self.update_item(item_id, GarmentUpdate(is_favorite=False)) is not None and self._archive_item(item_id)

    def _archive_item(self, item_id: str) -> bool:
        local = self._get_local_store()
        if item_id in local:
            local[item_id]["is_archived"] = True
            local[item_id]["updated_at"] = datetime.now(timezone.utc).isoformat()
        try:
            self.supabase.table("wardrobe_items").update({"is_archived": True, "updated_at": "now()"}).eq("id", item_id).eq("user_id", self.user_id).execute()
        except Exception as e:
            logger.warning(f"[WardrobeService] Remote archive error: {e}")
        return True

    def get_categories(self) -> List[CategoryResponse]:
        custom_cats: List[CategoryResponse] = []
        try:
            res = self.supabase.table("wardrobe_categories").select("*").or_(f"user_id.is.null,user_id.eq.{self.user_id}").order("order_index").execute()
            if res.data:
                custom_cats = [CategoryResponse(**item) for item in res.data]
        except Exception as e:
            logger.warning(f"[WardrobeService] Remote get_categories failed: {e}")

        if custom_cats:
            return custom_cats
        return DEFAULT_CATEGORIES

    def get_stats(self) -> WardrobeStatsResponse:
        records_resp = self.get_items(limit=1000)
        items = records_resp.items

        total = len(items)
        clean = sum(1 for i in items if i.laundry_status == LaundryStatusEnum.CLEAN.value)
        worn = sum(1 for i in items if i.laundry_status == LaundryStatusEnum.WORN.value)
        in_laundry = sum(1 for i in items if i.laundry_status in (LaundryStatusEnum.WASHING.value, LaundryStatusEnum.DRYING.value))
        stored = sum(1 for i in items if i.laundry_status == LaundryStatusEnum.STORED.value)
        unassigned = sum(1 for i in items if i.laundry_status is None)

        return WardrobeStatsResponse(
            total_garments=total,
            clean_count=clean,
            worn_count=worn,
            in_laundry_count=in_laundry,
            stored_count=stored,
            unassigned_count=unassigned,
        )

    def import_initial_inventory(self, items: List[GarmentCreate]) -> InitialImportResponse:
        imported = 0
        skipped = 0

        for item_data in items:
            if not item_data.id:
                continue
            existing = self.get_item(item_data.id)
            if existing:
                skipped += 1
            else:
                self.create_item(item_data)
                imported += 1

        total = len(self.get_items(limit=1000).items)
        return InitialImportResponse(
            imported_count=imported,
            skipped_count=skipped,
            total_garments=total,
        )
