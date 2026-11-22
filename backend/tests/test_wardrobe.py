import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.core.auth import get_current_user

AUTH_HEADERS = {"Authorization": "Bearer dev-token"}

@pytest.fixture(autouse=True)
def auth_override():
    app.dependency_overrides[get_current_user] = lambda: {"id": "test-wardrobe-user-1", "email": "wardrobe@tess.ai"}
    yield
    app.dependency_overrides.clear()

client = TestClient(app)

def test_get_wardrobe_categories():
    response = client.get("/api/v1/wardrobe/categories", headers=AUTH_HEADERS)
    assert response.status_code == 200
    categories = response.json()
    assert isinstance(categories, list)
    assert len(categories) >= 10
    names = [c["name"] for c in categories]
    assert "Tops" in names
    assert "Ethnic wear" in names
    assert "Bottoms" in names

def test_create_and_get_garment():
    payload = {
        "id": "CLO-TEST-001",
        "name": "Emerald Silk Kurta",
        "main_category": "Ethnic wear",
        "subcategory": "Kurtas",
        "primary_color": "Emerald Green",
        "sleeve_length": "3/4 sleeves",
        "fabric_material": "Silk",
        "laundry_status": "CLEAN",
        "is_favorite": True,
        "notes": "Festive wear"
    }

    create_resp = client.post("/api/v1/wardrobe/items", json=payload, headers=AUTH_HEADERS)
    assert create_resp.status_code == 201
    created = create_resp.json()
    assert created["id"] == "CLO-TEST-001"
    assert created["name"] == "Emerald Silk Kurta"
    assert created["sleeve_length"] == "3/4 sleeves"
    assert created["laundry_status"] == "CLEAN"
    assert created["is_favorite"] is True
    assert "created_at" in created

    # Get single
    get_resp = client.get("/api/v1/wardrobe/items/CLO-TEST-001", headers=AUTH_HEADERS)
    assert get_resp.status_code == 200
    assert get_resp.json()["id"] == "CLO-TEST-001"

def test_filter_and_search_garments():
    # Create second garment
    client.post("/api/v1/wardrobe/items", json={
        "id": "CLO-TEST-002",
        "name": "Classic Indigo Denim",
        "main_category": "Bottoms",
        "primary_color": "Blue",
        "fabric_material": "Denim",
        "laundry_status": "WORN",
        "is_favorite": False
    }, headers=AUTH_HEADERS)

    # Filter by category Bottoms
    resp_bottoms = client.get("/api/v1/wardrobe/items?category=Bottoms", headers=AUTH_HEADERS)
    assert resp_bottoms.status_code == 200
    items = resp_bottoms.json()
    assert len(items) >= 1
    assert all(i["main_category"] == "Bottoms" for i in items)

    # Filter by laundry status CLEAN
    resp_clean = client.get("/api/v1/wardrobe/items?laundry_status=CLEAN", headers=AUTH_HEADERS)
    assert resp_clean.status_code == 200
    assert all(i["laundry_status"] == "CLEAN" for i in resp_clean.json())

    # Search by keyword "Indigo"
    resp_search = client.get("/api/v1/wardrobe/items?search=Indigo", headers=AUTH_HEADERS)
    assert resp_search.status_code == 200
    assert any(i["id"] == "CLO-TEST-002" for i in resp_search.json())

def test_patch_garment():
    patch_payload = {
        "laundry_status": "WASHING",
        "is_favorite": True,
        "notes": "Moved to wash cycle"
    }

    patch_resp = client.patch("/api/v1/wardrobe/items/CLO-TEST-001", json=patch_payload, headers=AUTH_HEADERS)
    assert patch_resp.status_code == 200
    patched = patch_resp.json()
    assert patched["laundry_status"] == "WASHING"
    assert patched["is_favorite"] is True
    assert patched["notes"] == "Moved to wash cycle"
    # Preserves immutable fields
    assert patched["name"] == "Emerald Silk Kurta"

def test_delete_and_archive_garment():
    # Archive garment
    del_resp = client.delete("/api/v1/wardrobe/items/CLO-TEST-002", headers=AUTH_HEADERS)
    assert del_resp.status_code == 200
    assert del_resp.json()["status"] == "success"

    # Not returned in standard active query
    list_resp = client.get("/api/v1/wardrobe/items", headers=AUTH_HEADERS)
    ids = [i["id"] for i in list_resp.json()]
    assert "CLO-TEST-002" not in ids

def test_get_wardrobe_stats():
    stats_resp = client.get("/api/v1/wardrobe/stats", headers=AUTH_HEADERS)
    assert stats_resp.status_code == 200
    stats = stats_resp.json()
    assert "total_garments" in stats
    assert "clean_count" in stats
    assert "in_laundry_count" in stats
    assert "unassigned_count" in stats

def test_import_initial_inventory_idempotency():
    batch = {
        "garments": [
            {
                "id": "CLO-001",
                "name": "Yellow Printed Top",
                "main_category": "Tops",
                "primary_color": "Yellow",
                "sleeve_length": "3/4 sleeves"
            },
            {
                "id": "CLO-002",
                "name": "Pink & Green Floral Kurta",
                "main_category": "Ethnic wear",
                "primary_color": "Pink",
                "sleeve_length": "Sleeveless"
            }
        ]
    }

    # First import
    resp1 = client.post("/api/v1/wardrobe/import-initial", json=batch, headers=AUTH_HEADERS)
    assert resp1.status_code == 200
    data1 = resp1.json()
    assert data1["imported_count"] == 2
    assert data1["skipped_count"] == 0

    # Second import with same IDs should skip duplicates
    resp2 = client.post("/api/v1/wardrobe/import-initial", json=batch, headers=AUTH_HEADERS)
    assert resp2.status_code == 200
    data2 = resp2.json()
    assert data2["imported_count"] == 0
    assert data2["skipped_count"] == 2

def test_create_garment_validation_error():
    # Empty name
    resp = client.post("/api/v1/wardrobe/items", json={"name": "", "main_category": "Tops"}, headers=AUTH_HEADERS)
    assert resp.status_code in (400, 422)

