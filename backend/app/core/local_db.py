import os
import json
import sqlite3
import logging
from typing import Dict, Any, List, Optional
from datetime import datetime, timezone, date

logger = logging.getLogger(__name__)

DB_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "data")
DB_PATH = os.path.join(DB_DIR, "wardrobe.sqlite3")

class LocalWardrobeDB:
    _instance: Optional["LocalWardrobeDB"] = None

    def __init__(self, db_path: str = DB_PATH):
        self.db_path = db_path
        os.makedirs(os.path.dirname(self.db_path), exist_ok=True)
        self._init_db()
        self._migrate_legacy_json()

    @classmethod
    def get_instance(cls) -> "LocalWardrobeDB":
        if cls._instance is None:
            cls._instance = LocalWardrobeDB()
        return cls._instance

    def _get_connection(self) -> sqlite3.Connection:
        conn = sqlite3.connect(self.db_path, timeout=30.0)
        conn.row_factory = sqlite3.Row
        conn.execute("PRAGMA journal_mode=WAL;")
        conn.execute("PRAGMA synchronous=NORMAL;")
        return conn

    def _init_db(self) -> None:
        with self._get_connection() as conn:
            conn.execute("""
            CREATE TABLE IF NOT EXISTS wardrobe_categories (
                id TEXT PRIMARY KEY,
                user_id TEXT,
                name TEXT NOT NULL,
                icon_name TEXT,
                parent_category_id TEXT,
                subcategories TEXT DEFAULT '[]',
                order_index INTEGER DEFAULT 0,
                created_at TEXT
            );
            """)

            conn.execute("""
            CREATE TABLE IF NOT EXISTS wardrobe_items (
                id TEXT PRIMARY KEY,
                user_id TEXT NOT NULL,
                name TEXT NOT NULL,
                main_category TEXT NOT NULL,
                subcategory TEXT,
                original_image_ref TEXT,
                processed_image_ref TEXT,
                thumbnail_ref TEXT,
                primary_color TEXT NOT NULL DEFAULT 'Unknown',
                secondary_colors TEXT DEFAULT '[]',
                pattern TEXT,
                fabric_material TEXT,
                neckline TEXT,
                sleeve_length TEXT,
                fit TEXT,
                silhouette TEXT,
                garment_length TEXT,
                size TEXT,
                brand TEXT,
                purchase_date TEXT,
                purchase_price REAL,
                purchase_currency TEXT DEFAULT 'INR',
                occasions TEXT DEFAULT '[]',
                seasons TEXT DEFAULT '[]',
                laundry_status TEXT,
                is_favorite INTEGER DEFAULT 0,
                notes TEXT,
                is_archived INTEGER DEFAULT 0,
                metadata_payload TEXT DEFAULT '{}',
                metadata_version TEXT DEFAULT '1.1',
                import_provenance TEXT DEFAULT 'CHATGPT_IMPORT',
                created_at TEXT,
                updated_at TEXT
            );
            """)

            # Indexes
            conn.execute("CREATE INDEX IF NOT EXISTS idx_wardrobe_items_user_id ON wardrobe_items(user_id);")
            conn.execute("CREATE INDEX IF NOT EXISTS idx_wardrobe_items_category ON wardrobe_items(user_id, main_category);")
            conn.execute("CREATE INDEX IF NOT EXISTS idx_wardrobe_items_laundry ON wardrobe_items(user_id, laundry_status);")
            conn.execute("CREATE INDEX IF NOT EXISTS idx_wardrobe_items_archived ON wardrobe_items(user_id, is_archived);")
            conn.commit()

    def _migrate_legacy_json(self) -> None:
        """Migrate any existing records from local_wardrobe_store.json into SQLite DB."""
        legacy_path = os.path.join(
            os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
            "media",
            "wardrobe",
            "local_wardrobe_store.json",
        )
        if not os.path.exists(legacy_path):
            return

        try:
            with open(legacy_path, "r", encoding="utf-8") as f:
                data = json.load(f)
            if isinstance(data, dict):
                count = 0
                for user_id, items in data.items():
                    if user_id.startswith("test-") or user_id.startswith("user-test-"):
                        continue  # Skip transient test fixtures
                    if isinstance(items, dict):
                        for gid, record in items.items():
                            if isinstance(record, dict):
                                self.save_item(record)
                                count += 1
                if count > 0:
                    logger.info(f"[LocalWardrobeDB] Migrated {count} records from legacy JSON to SQLite DB.")
            # Rename legacy file to avoid re-importing test fixtures
            os.rename(legacy_path, legacy_path + ".migrated")
        except Exception as e:
            logger.warning(f"[LocalWardrobeDB] Legacy JSON migration check warning: {e}")

    def save_item(self, record: Dict[str, Any]) -> None:
        rec = dict(record)
        # Serialize lists & dicts to JSON strings for SQLite
        for field in ("secondary_colors", "occasions", "seasons"):
            val = rec.get(field)
            if isinstance(val, (list, tuple)):
                rec[field] = json.dumps(list(val))
            elif val is None:
                rec[field] = "[]"

        val_meta = rec.get("metadata_payload")
        if isinstance(val_meta, dict):
            rec["metadata_payload"] = json.dumps(val_meta)
        elif val_meta is None:
            rec["metadata_payload"] = "{}"

        # Booleans
        if "is_favorite" in rec:
            rec["is_favorite"] = 1 if rec["is_favorite"] else 0
        if "is_archived" in rec:
            rec["is_archived"] = 1 if rec["is_archived"] else 0

        # Purchase date
        p_date = rec.get("purchase_date")
        if isinstance(p_date, (datetime, date)):
            rec["purchase_date"] = p_date.isoformat()

        columns = [
            "id", "user_id", "name", "main_category", "subcategory",
            "original_image_ref", "processed_image_ref", "thumbnail_ref",
            "primary_color", "secondary_colors", "pattern", "fabric_material",
            "neckline", "sleeve_length", "fit", "silhouette", "garment_length",
            "size", "brand", "purchase_date", "purchase_price", "purchase_currency",
            "occasions", "seasons", "laundry_status", "is_favorite", "notes",
            "is_archived", "metadata_payload", "metadata_version", "import_provenance",
            "created_at", "updated_at"
        ]

        values = [rec.get(col) for col in columns]
        placeholders = ", ".join(["?"] * len(columns))
        col_names = ", ".join(columns)
        update_clauses = ", ".join([f"{col} = excluded.{col}" for col in columns if col != "id"])

        sql = f"""
        INSERT INTO wardrobe_items ({col_names})
        VALUES ({placeholders})
        ON CONFLICT(id) DO UPDATE SET {update_clauses};
        """

        with self._get_connection() as conn:
            conn.execute(sql, values)
            conn.commit()

    def get_item(self, item_id: str, user_id: str) -> Optional[Dict[str, Any]]:
        with self._get_connection() as conn:
            cursor = conn.execute(
                "SELECT * FROM wardrobe_items WHERE id = ? AND user_id = ? LIMIT 1;",
                (item_id, user_id),
            )
            row = cursor.fetchone()
            if not row:
                return None
            return self._row_to_dict(row)

    def get_items(
        self,
        user_id: str,
        category: Optional[str] = None,
        laundry_status: Optional[str] = None,
        is_favorite: Optional[bool] = None,
        include_archived: bool = False,
    ) -> List[Dict[str, Any]]:
        query = "SELECT * FROM wardrobe_items WHERE user_id = ?"
        params: List[Any] = [user_id]

        if not include_archived:
            query += " AND is_archived = 0"
        if category:
            query += " AND LOWER(main_category) = LOWER(?)"
            params.append(category)
        if laundry_status is not None:
            query += " AND laundry_status = ?"
            params.append(laundry_status)
        if is_favorite is not None:
            query += " AND is_favorite = ?"
            params.append(1 if is_favorite else 0)

        query += " ORDER BY created_at DESC;"

        with self._get_connection() as conn:
            cursor = conn.execute(query, params)
            rows = cursor.fetchall()
            return [self._row_to_dict(r) for r in rows]

    def update_item_fields(self, item_id: str, user_id: str, updates: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        existing = self.get_item(item_id, user_id)
        if not existing:
            return None

        merged = dict(existing)
        merged.update(updates)
        merged["updated_at"] = datetime.now(timezone.utc).isoformat()
        self.save_item(merged)
        return self.get_item(item_id, user_id)

    def delete_item(self, item_id: str, user_id: str, hard_delete: bool = False) -> bool:
        with self._get_connection() as conn:
            if hard_delete:
                cursor = conn.execute("DELETE FROM wardrobe_items WHERE id = ? AND user_id = ?;", (item_id, user_id))
            else:
                now = datetime.now(timezone.utc).isoformat()
                cursor = conn.execute(
                    "UPDATE wardrobe_items SET is_archived = 1, is_favorite = 0, updated_at = ? WHERE id = ? AND user_id = ?;",
                    (now, item_id, user_id),
                )
            conn.commit()
            return cursor.rowcount > 0

    def get_max_clo_id(self, user_id: str) -> int:
        with self._get_connection() as conn:
            cursor = conn.execute("SELECT id FROM wardrobe_items WHERE user_id = ? AND id LIKE 'CLO-%';", (user_id,))
            rows = cursor.fetchall()
            max_num = 0
            for row in rows:
                gid = str(row["id"])
                try:
                    num = int(gid.split("-")[1])
                    if num > max_num:
                        max_num = num
                except Exception:
                    continue
            return max_num

    def _row_to_dict(self, row: sqlite3.Row) -> Dict[str, Any]:
        d = dict(row)
        # Deserialize JSON arrays
        for field in ("secondary_colors", "occasions", "seasons"):
            val = d.get(field)
            if isinstance(val, str):
                try:
                    d[field] = json.loads(val)
                except Exception:
                    d[field] = []
            elif val is None:
                d[field] = []

        # Deserialize metadata_payload
        val_meta = d.get("metadata_payload")
        if isinstance(val_meta, str):
            try:
                d[field_meta := "metadata_payload"] = json.loads(val_meta)
            except Exception:
                d["metadata_payload"] = {}
        elif val_meta is None:
            d["metadata_payload"] = {}

        # Defaults for non-nullable schema fields
        if not d.get("purchase_currency"):
            d["purchase_currency"] = "INR"
        d["wear_count"] = d.get("wear_count") if d.get("wear_count") is not None else 0
        d["wash_count"] = d.get("wash_count") if d.get("wash_count") is not None else 0

        # Booleans
        d["is_favorite"] = bool(d.get("is_favorite", 0))
        d["is_archived"] = bool(d.get("is_archived", 0))

        return d
