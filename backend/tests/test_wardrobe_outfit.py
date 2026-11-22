import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

USER_HEADERS = {"Authorization": "Bearer dev_user_outfit_1"}
OTHER_USER_HEADERS = {"Authorization": "Bearer dev_user_outfit_2"}

@pytest.fixture(autouse=True)
def setup_outfit_garments():
    """Seed comprehensive wardrobe garments for Outfit Studio testing."""
    # User 1 Clean Top
    client.post(
        "/api/v1/wardrobe/items",
        headers=USER_HEADERS,
        json={
            "id": "CLO-TOP-1",
            "name": "Navy Oxford Shirt",
            "main_category": "Tops",
            "primary_color": "Navy Blue",
            "laundry_status": "CLEAN",
        },
    )
    # User 1 Clean Bottom
    client.post(
        "/api/v1/wardrobe/items",
        headers=USER_HEADERS,
        json={
            "id": "CLO-BOT-1",
            "name": "Beige Chinos",
            "main_category": "Bottoms",
            "primary_color": "Beige",
            "laundry_status": "CLEAN",
        },
    )
    # User 1 Clean Kurta (Ethnic)
    client.post(
        "/api/v1/wardrobe/items",
        headers=USER_HEADERS,
        json={
            "id": "CLO-ETH-1",
            "name": "Pink Floral Kurta",
            "main_category": "Ethnic wear",
            "primary_color": "Pink",
            "laundry_status": "CLEAN",
        },
    )
    # User 1 Clean Leggings (Ethnic bottom)
    client.post(
        "/api/v1/wardrobe/items",
        headers=USER_HEADERS,
        json={
            "id": "CLO-ETH-BOT-1",
            "name": "White Churidar Leggings",
            "main_category": "Bottoms",
            "primary_color": "White",
            "laundry_status": "CLEAN",
        },
    )
    # User 1 Clean Dress
    client.post(
        "/api/v1/wardrobe/items",
        headers=USER_HEADERS,
        json={
            "id": "CLO-DRS-1",
            "name": "Emerald Midi Dress",
            "main_category": "Dresses",
            "primary_color": "Olive Green",
            "laundry_status": "CLEAN",
        },
    )
    # User 1 Ineligible Garments: Washing, Drying, Unassigned, Worn
    client.post(
        "/api/v1/wardrobe/items",
        headers=USER_HEADERS,
        json={
            "id": "CLO-WASHING-1",
            "name": "Soaked Gym Shorts",
            "main_category": "Bottoms",
            "primary_color": "Black",
            "laundry_status": "WASHING",
        },
    )
    client.post(
        "/api/v1/wardrobe/items",
        headers=USER_HEADERS,
        json={
            "id": "CLO-DRYING-1",
            "name": "Drying Wool Sweater",
            "main_category": "Outerwear",
            "primary_color": "Grey",
            "laundry_status": "DRYING",
        },
    )
    client.post(
        "/api/v1/wardrobe/items",
        headers=USER_HEADERS,
        json={
            "id": "CLO-UNASSIGNED-1",
            "name": "Unchecked Silk Scarf",
            "main_category": "Accessories",
            "primary_color": "Red",
            "laundry_status": None,
        },
    )
    client.post(
        "/api/v1/wardrobe/items",
        headers=USER_HEADERS,
        json={
            "id": "CLO-WORN-1",
            "name": "Yesterday Graphic Tee",
            "main_category": "Tops",
            "primary_color": "Yellow",
            "laundry_status": "WORN",
        },
    )

    # User 2 Garment (Tenant Isolation)
    client.post(
        "/api/v1/wardrobe/items",
        headers=OTHER_USER_HEADERS,
        json={
            "id": "CLO-USER2-TOP",
            "name": "User 2 Blazer",
            "main_category": "Outerwear",
            "primary_color": "Black",
            "laundry_status": "CLEAN",
        },
    )

def test_outfit_automatic_generation_uses_actual_garments():
    """Mode A: Automatic outfit suggestions using only real user garments."""
    res = client.post(
        "/api/v1/wardrobe/outfits/generate",
        headers=USER_HEADERS,
        json={"occasion": "Casual", "exclude_worn": True, "limit": 5},
    )
    assert res.status_code == 200
    data = res.json()
    assert "recommendations" in data
    assert data["total"] > 0

    valid_ids = {"CLO-TOP-1", "CLO-BOT-1", "CLO-ETH-1", "CLO-ETH-BOT-1", "CLO-DRS-1"}
    for rec in data["recommendations"]:
        assert rec["name"] is not None
        assert rec["explanation"] is not None
        assert len(rec["explanation"]) > 5
        assert rec["combination_fingerprint"] is not None
        # Must only contain user's registered eligible garments
        for gid in rec["garment_ids"]:
            assert gid in valid_ids
            # Never include washing, drying, or unassigned!
            assert gid not in {"CLO-WASHING-1", "CLO-DRYING-1", "CLO-UNASSIGNED-1", "CLO-WORN-1"}

def test_outfit_generation_laundry_eligibility_exclusion():
    """Verify washing, drying, and unassigned garments are strictly excluded."""
    res = client.post(
        "/api/v1/wardrobe/outfits/generate",
        headers=USER_HEADERS,
        json={"exclude_worn": False, "limit": 10},
    )
    assert res.status_code == 200
    data = res.json()
    all_recommended_gids = set()
    for rec in data["recommendations"]:
        all_recommended_gids.update(rec["garment_ids"])

    # Even with exclude_worn=False, WASHING, DRYING, and UNASSIGNED are NEVER eligible!
    assert "CLO-WASHING-1" not in all_recommended_gids
    assert "CLO-DRYING-1" not in all_recommended_gids
    assert "CLO-UNASSIGNED-1" not in all_recommended_gids

def test_guided_styling_preserves_seed_garment():
    """Mode B: Guided styling retains the seed garment in all recommendations."""
    res = client.post(
        "/api/v1/wardrobe/outfits/guided",
        headers=USER_HEADERS,
        json={"seed_garment_id": "CLO-ETH-1", "occasion": "Ethnic", "limit": 3},
    )
    assert res.status_code == 200
    data = res.json()
    assert data["total"] > 0
    for rec in data["recommendations"]:
        assert "CLO-ETH-1" in rec["garment_ids"]
        assert rec["is_available"] is True
        assert "Pink Floral Kurta" in rec["name"] or "Pink Floral Kurta" in rec["explanation"]

def test_manual_outfit_validation_detects_conflicts():
    """Mode C: Validate manual selections and flag laundry or existence conflicts."""
    # 1. Valid combination
    valid_res = client.post(
        "/api/v1/wardrobe/outfits/validate",
        headers=USER_HEADERS,
        json={"garment_ids": ["CLO-TOP-1", "CLO-BOT-1"]},
    )
    assert valid_res.status_code == 200
    v_data = valid_res.json()
    assert v_data["is_valid"] is True
    assert v_data["is_wearable"] is True
    assert len(v_data["conflicts"]) == 0

    # 2. Ineligible combination (includes drying garment & unassigned garment)
    conflict_res = client.post(
        "/api/v1/wardrobe/outfits/validate",
        headers=USER_HEADERS,
        json={"garment_ids": ["CLO-TOP-1", "CLO-DRYING-1", "CLO-UNASSIGNED-1"]},
    )
    assert conflict_res.status_code == 200
    c_data = conflict_res.json()
    assert c_data["is_wearable"] is False
    assert len(c_data["conflicts"]) >= 2
    assert any("drying" in c.lower() for c in c_data["conflicts"])
    assert any("unassigned" in c.lower() for c in c_data["conflicts"])

    # 3. Nonexistent / cross-user garment
    fake_res = client.post(
        "/api/v1/wardrobe/outfits/validate",
        headers=USER_HEADERS,
        json={"garment_ids": ["CLO-USER2-TOP", "CLO-NONEXISTENT"]},
    )
    assert fake_res.status_code == 200
    f_data = fake_res.json()
    assert f_data["is_valid"] is False
    assert f_data["is_wearable"] is False

def test_outfit_crud_and_favourite():
    """Full lifecycle: create, get, list, update favourite, and delete."""
    # 1. Create outfit
    create_res = client.post(
        "/api/v1/wardrobe/outfits",
        headers=USER_HEADERS,
        json={
            "name": "Smart Office Duo",
            "description": "Navy shirt with beige chinos",
            "occasion": "Office",
            "is_favourite": False,
            "creation_source": "MANUAL",
            "garment_ids": ["CLO-TOP-1", "CLO-BOT-1"],
        },
    )
    assert create_res.status_code == 201
    created = create_res.json()
    outfit_id = created["id"]
    assert created["name"] == "Smart Office Duo"
    assert created["wear_count"] == 0

    # 2. Get single outfit
    get_res = client.get(f"/api/v1/wardrobe/outfits/{outfit_id}", headers=USER_HEADERS)
    assert get_res.status_code == 200
    assert get_res.json()["id"] == outfit_id

    # 3. List outfits
    list_res = client.get("/api/v1/wardrobe/outfits", headers=USER_HEADERS)
    assert list_res.status_code == 200
    assert any(o["id"] == outfit_id for o in list_res.json()["outfits"])

    # 4. Update favourite
    upd_res = client.put(
        f"/api/v1/wardrobe/outfits/{outfit_id}",
        headers=USER_HEADERS,
        json={"is_favourite": True, "notes": "Fabulous for Tuesday meetings"},
    )
    assert upd_res.status_code == 200
    assert upd_res.json()["is_favourite"] is True

    # 5. Delete outfit
    del_res = client.delete(f"/api/v1/wardrobe/outfits/{outfit_id}", headers=USER_HEADERS)
    assert del_res.status_code == 204

    # 6. Verify deleted
    get_after = client.get(f"/api/v1/wardrobe/outfits/{outfit_id}", headers=USER_HEADERS)
    assert get_after.status_code == 404

def test_wear_outfit_updates_laundry_and_wear_counts():
    """Wearing an outfit sets garment laundry status to WORN, increments wear counts, and updates last_worn_date."""
    # 1. Create outfit with clean items
    c_res = client.post(
        "/api/v1/wardrobe/outfits",
        headers=USER_HEADERS,
        json={
            "name": "Date Night Look",
            "occasion": "Party",
            "garment_ids": ["CLO-TOP-1", "CLO-BOT-1"],
        },
    )
    outfit_id = c_res.json()["id"]

    # 2. Wear the outfit
    wear_res = client.post(
        f"/api/v1/wardrobe/outfits/{outfit_id}/wear",
        headers=USER_HEADERS,
        json={"idempotency_key": "wear-test-key-001", "notes": "Worn to dinner party"},
    )
    assert wear_res.status_code == 200
    w_data = wear_res.json()
    assert w_data["wear_count"] == 1
    assert "CLO-TOP-1" in w_data["garments_updated"]
    assert "CLO-BOT-1" in w_data["garments_updated"]

    # 3. Verify garment status is now WORN and wear_count incremented
    g1_res = client.get("/api/v1/wardrobe/items/CLO-TOP-1", headers=USER_HEADERS)
    g1 = g1_res.json()
    assert g1["laundry_status"] == "WORN"
    assert g1["wear_count"] >= 1
    assert g1["last_worn_date"] is not None

def test_wear_outfit_idempotency():
    """Duplicate wear requests with the same idempotency key are deduplicated."""
    c_res = client.post(
        "/api/v1/wardrobe/outfits",
        headers=USER_HEADERS,
        json={"name": "Duplicate Test Outfit", "garment_ids": ["CLO-DRS-1"]},
    )
    outfit_id = c_res.json()["id"]

    res1 = client.post(
        f"/api/v1/wardrobe/outfits/{outfit_id}/wear",
        headers=USER_HEADERS,
        json={"idempotency_key": "idemp-wear-dupe-999"},
    )
    assert res1.status_code == 200
    count1 = res1.json()["wear_count"]

    # Duplicate call
    res2 = client.post(
        f"/api/v1/wardrobe/outfits/{outfit_id}/wear",
        headers=USER_HEADERS,
        json={"idempotency_key": "idemp-wear-dupe-999"},
    )
    assert res2.status_code == 200
    count2 = res2.json()["wear_count"]
    # Wear count must not increment again!
    assert count1 == count2

def test_wear_outfit_blocks_on_laundry_conflict():
    """Cannot wear outfit if a garment is currently in WASHING, DRYING, or UNASSIGNED."""
    c_res = client.post(
        "/api/v1/wardrobe/outfits",
        headers=USER_HEADERS,
        json={"name": "Wet Outfit", "garment_ids": ["CLO-WASHING-1"]},
    )
    outfit_id = c_res.json()["id"]

    wear_res = client.post(
        f"/api/v1/wardrobe/outfits/{outfit_id}/wear",
        headers=USER_HEADERS,
        json={"idempotency_key": "wet-wear-key"},
    )
    assert wear_res.status_code == 400
    assert "Laundry conflicts" in wear_res.json()["detail"]

def test_multi_tenant_isolation_outfits():
    """User B cannot view or wear User A's outfits or attach User A's garments."""
    # User 1 creates outfit
    c_res = client.post(
        "/api/v1/wardrobe/outfits",
        headers=USER_HEADERS,
        json={"name": "User 1 Secret Look", "garment_ids": ["CLO-TOP-1"]},
    )
    outfit_id = c_res.json()["id"]

    # User 2 attempts to get User 1's outfit -> 404
    u2_get = client.get(f"/api/v1/wardrobe/outfits/{outfit_id}", headers=OTHER_USER_HEADERS)
    assert u2_get.status_code == 404

    # User 2 attempts to create an outfit using User 1's garment -> 400
    u2_create = client.post(
        "/api/v1/wardrobe/outfits",
        headers=OTHER_USER_HEADERS,
        json={"name": "Steolen Look", "garment_ids": ["CLO-TOP-1"]},
    )
    assert u2_create.status_code == 400

