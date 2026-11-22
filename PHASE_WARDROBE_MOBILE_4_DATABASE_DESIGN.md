# TESS Wardrobe Intelligence — Mobile Phase 4 Database Design
## Relational Schema, Indexes, Foreign Keys & Row Level Security

**Database:** PostgreSQL (Supabase)  
**Schema Migration:** `backend/migrations/003_laundry_manager.sql`  
**Master Schema Sync:** `backend/schema.sql`  

---

## 1. Table Definitions

### 1.1 Alteration: `wardrobe_items`
Added lifecycle management columns to the primary `wardrobe_items` entity:

```sql
ALTER TABLE wardrobe_items
ADD COLUMN IF NOT EXISTS wear_count INTEGER NOT NULL DEFAULT 0,
ADD COLUMN IF NOT EXISTS wash_count INTEGER NOT NULL DEFAULT 0,
ADD COLUMN IF NOT EXISTS last_worn_date TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS last_washed_date TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS active_batch_id TEXT;
```

### 1.2 Table: `laundry_batches`
Tracks grouped wash/dry cycles created by the user.

```sql
CREATE TABLE IF NOT EXISTS laundry_batches (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name VARCHAR(120) NOT NULL,
    batch_type VARCHAR(50) NOT NULL DEFAULT 'STANDARD',
    status VARCHAR(30) NOT NULL DEFAULT 'CREATED',
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);
```

### 1.3 Table: `laundry_batch_items`
Junction table associating garments with a specific laundry batch.

```sql
CREATE TABLE IF NOT EXISTS laundry_batch_items (
    id TEXT PRIMARY KEY,
    batch_id TEXT NOT NULL REFERENCES laundry_batches(id) ON DELETE CASCADE,
    garment_id TEXT NOT NULL REFERENCES wardrobe_items(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    initial_laundry_status VARCHAR(50),
    current_laundry_status VARCHAR(50),
    added_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_batch_garment UNIQUE (batch_id, garment_id)
);
```

### 1.4 Table: `wardrobe_laundry_history`
Immutable audit log recording every transition of a garment's laundry status.

```sql
CREATE TABLE IF NOT EXISTS wardrobe_laundry_history (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    garment_id TEXT NOT NULL REFERENCES wardrobe_items(id) ON DELETE CASCADE,
    previous_status VARCHAR(50),
    new_status VARCHAR(50),
    batch_id TEXT REFERENCES laundry_batches(id) ON DELETE SET NULL,
    source VARCHAR(50) NOT NULL DEFAULT 'USER_MANUAL',
    notes TEXT,
    idempotency_key VARCHAR(128),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

---

## 2. Performance Indexes

```sql
CREATE INDEX IF NOT EXISTS idx_wardrobe_items_laundry_status ON wardrobe_items(user_id, laundry_status);
CREATE INDEX IF NOT EXISTS idx_wardrobe_items_active_batch ON wardrobe_items(user_id, active_batch_id);
CREATE INDEX IF NOT EXISTS idx_laundry_batches_user ON laundry_batches(user_id, status);
CREATE INDEX IF NOT EXISTS idx_laundry_batch_items_batch ON laundry_batch_items(batch_id);
CREATE INDEX IF NOT EXISTS idx_laundry_batch_items_garment ON laundry_batch_items(garment_id);
CREATE INDEX IF NOT EXISTS idx_wardrobe_laundry_history_garment ON wardrobe_laundry_history(garment_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_wardrobe_laundry_history_idempotency ON wardrobe_laundry_history(user_id, idempotency_key);
```

---

## 3. Row Level Security (RLS) Policies

All tables strictly enforce row-level tenant isolation using `auth.uid() = user_id`:

```sql
ALTER TABLE laundry_batches ENABLE ROW LEVEL SECURITY;
ALTER TABLE laundry_batch_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE wardrobe_laundry_history ENABLE ROW LEVEL SECURITY;

-- laundry_batches policy
CREATE POLICY "Users can only access their own laundry batches"
ON laundry_batches FOR ALL
USING (auth.uid() = user_id);

-- laundry_batch_items policy
CREATE POLICY "Users can only access their own batch items"
ON laundry_batch_items FOR ALL
USING (auth.uid() = user_id);

-- wardrobe_laundry_history policy
CREATE POLICY "Users can only access their own laundry history"
ON wardrobe_laundry_history FOR ALL
USING (auth.uid() = user_id);
```

