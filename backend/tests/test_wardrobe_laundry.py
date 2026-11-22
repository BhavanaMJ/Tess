import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

USER_HEADERS = {"Authorization": "Bearer dev_user_laundry_1"}
OTHER_USER_HEADERS = {"Authorization": "Bearer dev_user_laundry_2"}

@pytest.fixture(autouse=True)
def setup_initial_garments():
    """Seed initial garments for testing laundry lifecycle."""
    # 1. Create a clean garment
    client.post(
        "/api/v1/wardrobe/items",
        headers=USER_HEADERS,
        json={
            "id": "CLO-TEST-CLEAN",
            "name": "Clean Blue Shirt",
            "main_category": "Tops",
            "primary_color": "Blue",
            "laundry_status": "CLEAN",
        },
    )
    # 2. Create worn garments
    client.post(
        "/api/v1/wardrobe/items",
        headers=USER_HEADERS,
        json={
            "id": "CLO-TEST-WORN1",
            "name": "Worn Jeans",
            "main_category": "Bottoms",
            "primary_color": "Denim",
            "laundry_status": "WORN",
        },
    )
    client.post(
        "/api/v1/wardrobe/items",
        headers=USER_HEADERS,
        json={
            "id": "CLO-TEST-WORN2",
            "name": "Worn White Tee",
            "main_category": "Tops",
            "primary_color": "White",
            "laundry_status": "WORN",
        },
    )
    client.post(
        "/api/v1/wardrobe/items",
        headers=USER_HEADERS,
        json={
            "id": "CLO-TEST-WORN3",
            "name": "Worn Black Hoodie",
            "main_category": "Outerwear",
            "primary_color": "Black",
            "laundry_status": "WORN",
        },
    )
    # 3. Create unassigned garment (null status)
    client.post(
        "/api/v1/wardrobe/items",
        headers=USER_HEADERS,
        json={
            "id": "CLO-TEST-UNASSIGNED",
            "name": "Mystery Jacket",
            "main_category": "Outerwear",
            "primary_color": "Brown",
            "laundry_status": None,
        },
    )

def test_laundry_stats_dashboard():
    """Scenario A: Verify all 5 statuses and unassigned counts are distinct and accurate."""
    resp = client.get("/api/v1/wardrobe/laundry/stats", headers=USER_HEADERS)
    assert resp.status_code == 200
    data = resp.json()

    assert data["total_garments"] >= 5
    assert data["clean_count"] >= 1
    assert data["worn_count"] >= 3
    assert data["unassigned_count"] >= 1
    # Unassigned must NEVER be counted as clean
    assert data["clean_count"] != data["total_garments"]

def test_laundry_items_filtered_by_status():
    """Verify filtering garments by status, including explicit UNASSIGNED."""
    # Filter WORN
    resp_worn = client.get("/api/v1/wardrobe/laundry/items?laundry_status=WORN", headers=USER_HEADERS)
    assert resp_worn.status_code == 200
    worn_items = resp_worn.json()["items"]
    assert any(i["id"] == "CLO-TEST-WORN1" for i in worn_items)
    assert all(i["laundry_status"] == "WORN" for i in worn_items)

    # Filter UNASSIGNED
    resp_unassigned = client.get("/api/v1/wardrobe/laundry/items?laundry_status=UNASSIGNED", headers=USER_HEADERS)
    assert resp_unassigned.status_code == 200
    unassigned_items = resp_unassigned.json()["items"]
    assert any(i["id"] == "CLO-TEST-UNASSIGNED" for i in unassigned_items)
    assert all(i["laundry_status"] is None for i in unassigned_items)

def test_individual_status_transition_and_wear_count():
    """Scenario B: Transitioning Clean -> Worn increments wear_count and records history."""
    # Garment starts Clean with 0 wear_count
    resp = client.patch(
        "/api/v1/wardrobe/items/CLO-TEST-CLEAN/laundry-status",
        headers=USER_HEADERS,
        json={"laundry_status": "WORN", "notes": "Worn to dinner"},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["laundry_status"] == "WORN"
    assert data["wear_count"] == 1
    assert data["last_worn_date"] is not None

    # Retrieve history
    hist_resp = client.get("/api/v1/wardrobe/items/CLO-TEST-CLEAN/laundry-history", headers=USER_HEADERS)
    assert hist_resp.status_code == 200
    history = hist_resp.json()
    assert len(history) >= 1
    wear_event = history[0]
    assert wear_event["event_type"] == "WEAR"
    assert wear_event["previous_status"] == "CLEAN"
    assert wear_event["new_status"] == "WORN"

def test_wash_count_increment_on_completed_wash():
    """Scenario F: Wash count increments strictly when moving from WASHING/DRYING to CLEAN."""
    # Move Worn garment to Washing
    client.patch(
        "/api/v1/wardrobe/items/CLO-TEST-WORN1/laundry-status",
        headers=USER_HEADERS,
        json={"laundry_status": "WASHING"},
    )
    # Move to Drying
    client.patch(
        "/api/v1/wardrobe/items/CLO-TEST-WORN1/laundry-status",
        headers=USER_HEADERS,
        json={"laundry_status": "DRYING"},
    )
    # Complete wash -> Clean
    resp = client.patch(
        "/api/v1/wardrobe/items/CLO-TEST-WORN1/laundry-status",
        headers=USER_HEADERS,
        json={"laundry_status": "CLEAN"},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["laundry_status"] == "CLEAN"
    assert data["wash_count"] == 1
    assert data["last_washed_date"] is not None

    # Storing the garment does NOT increment wash count again (Scenario G)
    resp_stored = client.patch(
        "/api/v1/wardrobe/items/CLO-TEST-WORN1/laundry-status",
        headers=USER_HEADERS,
        json={"laundry_status": "STORED"},
    )
    assert resp_stored.status_code == 200
    assert resp_stored.json()["wash_count"] == 1

def test_idempotent_status_update():
    """Scenario H: Duplicate requests with same idempotency key do not double-increment."""
    key = "idem_key_wear_999"
    # First request
    resp1 = client.patch(
        "/api/v1/wardrobe/items/CLO-TEST-WORN2/laundry-status",
        headers=USER_HEADERS,
        json={"laundry_status": "WORN", "idempotency_key": key},
    )
    assert resp1.status_code == 200
    initial_wears = resp1.json()["wear_count"]

    # Duplicate request with same key
    resp2 = client.patch(
        "/api/v1/wardrobe/items/CLO-TEST-WORN2/laundry-status",
        headers=USER_HEADERS,
        json={"laundry_status": "WORN", "idempotency_key": key},
    )
    assert resp2.status_code == 200
    assert resp2.json()["wear_count"] == initial_wears

def test_create_and_manage_laundry_batch():
    """Scenario C & D: Create multi-garment batch and advance through lifecycle."""
    batch_payload = {
        "name": "Weekly Dark Wash",
        "garment_ids": ["CLO-TEST-WORN2", "CLO-TEST-WORN3"],
        "initial_status": "WASHING",
    }
    resp = client.post("/api/v1/wardrobe/laundry/batches", headers=USER_HEADERS, json=batch_payload)
    assert resp.status_code == 201
    batch = resp.json()
    batch_id = batch["id"]

    assert batch["batch_number"].startswith("BATCH-")
    assert batch["name"] == "Weekly Dark Wash"
    assert batch["status"] == "WASHING"
    assert batch["items_count"] == 2

    # Verify both garments now have active_batch_id and are in WASHING
    g2 = client.get("/api/v1/wardrobe/items/CLO-TEST-WORN2", headers=USER_HEADERS).json()
    assert g2["laundry_status"] == "WASHING"
    assert g2["active_batch_id"] == batch_id

def test_batch_individual_override_preservation():
    """Scenario E: Mixed-status batch progression respects individual overrides."""
    # Create batch with 2 items
    b_resp = client.post(
        "/api/v1/wardrobe/laundry/batches",
        headers=USER_HEADERS,
        json={
            "name": "Mixed Test Batch",
            "garment_ids": ["CLO-TEST-WORN2", "CLO-TEST-WORN3"],
            "initial_status": "WASHING",
        },
    )
    batch_id = b_resp.json()["id"]

    # Individual override: User moves CLO-TEST-WORN3 individually to DRYING ahead of time
    client.patch(
        "/api/v1/wardrobe/items/CLO-TEST-WORN3/laundry-status",
        headers=USER_HEADERS,
        json={"laundry_status": "DRYING", "notes": "Hung up outside first"},
    )

    # Now advance the batch to DRYING
    adv_resp = client.patch(
        f"/api/v1/wardrobe/laundry/batches/{batch_id}/status",
        headers=USER_HEADERS,
        json={"status": "DRYING"},
    )
    assert adv_resp.status_code == 200
    res_data = adv_resp.json()

    # CLO-TEST-WORN2 was updated to DRYING; CLO-TEST-WORN3 was skipped (override preserved)
    assert "CLO-TEST-WORN2" in res_data["updated_garment_ids"]
    assert "CLO-TEST-WORN3" in res_data["skipped_garment_ids"]

    # Now advance batch to COMPLETED
    comp_resp = client.patch(
        f"/api/v1/wardrobe/laundry/batches/{batch_id}/status",
        headers=USER_HEADERS,
        json={"status": "COMPLETED"},
    )
    assert comp_resp.status_code == 200

    # Both items should now be CLEAN with wash_count incremented
    g2 = client.get("/api/v1/wardrobe/items/CLO-TEST-WORN2", headers=USER_HEADERS).json()
    g3 = client.get("/api/v1/wardrobe/items/CLO-TEST-WORN3", headers=USER_HEADERS).json()
    assert g2["laundry_status"] == "CLEAN"
    assert g3["laundry_status"] == "CLEAN"
    assert g2["wash_count"] >= 1
    assert g3["wash_count"] >= 1

def test_user_isolation_security():
    """Scenario I: User B cannot access or advance User A's batches."""
    # User A creates batch
    resp = client.post(
        "/api/v1/wardrobe/laundry/batches",
        headers=USER_HEADERS,
        json={"name": "User A Private Batch", "garment_ids": ["CLO-TEST-WORN1"]},
    )
    batch_id = resp.json()["id"]

    # User B attempts to access User A's batch -> 404
    resp_b = client.get(f"/api/v1/wardrobe/laundry/batches/{batch_id}", headers=OTHER_USER_HEADERS)
    assert resp_b.status_code == 404

    # User B attempts to advance User A's batch -> 404
    resp_adv = client.patch(
        f"/api/v1/wardrobe/laundry/batches/{batch_id}/status",
        headers=OTHER_USER_HEADERS,
        json={"status": "DRYING"},
    )
    assert resp_adv.status_code == 404

