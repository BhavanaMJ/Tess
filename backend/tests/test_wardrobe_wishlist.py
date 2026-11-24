import pytest
from datetime import datetime, date, timezone
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

USER_HEADERS = {"Authorization": "Bearer dev_wishlist_user_1"}
OTHER_USER_HEADERS = {"Authorization": "Bearer dev_wishlist_user_2"}
USER_ID = "user-dev_wishlist_user_1"
OTHER_USER_ID = "user-dev_wishlist_user_2"


@pytest.fixture(autouse=True)
def setup_wishlist_test_data():
    """Populates initial sample garments in the session wardrobe store for USER_ID."""
    from app.services.wardrobe.service import _SESSION_WARDROBE_STORE
    from app.services.wardrobe.wishlist_service import _SESSION_WISHLIST_STORE

    _SESSION_WARDROBE_STORE[USER_ID] = {
        "CLO-001": {
            "id": "CLO-001",
            "user_id": USER_ID,
            "name": "Classic White Shirt",
            "main_category": "Tops",
            "subcategory": "Shirts",
            "primary_color": "White",
            "purchase_price": 2400.0,
            "purchase_currency": "INR",
            "wear_count": 10,
            "laundry_status": "CLEAN",
            "is_archived": False,
        },
        "CLO-002": {
            "id": "CLO-002",
            "user_id": USER_ID,
            "name": "Navy Blue Polo",
            "main_category": "Tops",
            "subcategory": "Polos",
            "primary_color": "Navy Blue",
            "purchase_price": 1800.0,
            "purchase_currency": "INR",
            "wear_count": 6,
            "laundry_status": "CLEAN",
            "is_archived": False,
        },
        "CLO-003": {
            "id": "CLO-003",
            "user_id": USER_ID,
            "name": "Embroidered Kurta",
            "main_category": "Ethnic wear",
            "subcategory": "Kurtas",
            "primary_color": "Yellow",
            "purchase_price": 2800.0,
            "purchase_currency": "INR",
            "wear_count": 4,
            "laundry_status": "CLEAN",
            "is_archived": False,
        },
        "CLO-004": {
            "id": "CLO-004",
            "user_id": USER_ID,
            "name": "Silk Anarkali Kurta",
            "main_category": "Ethnic wear",
            "subcategory": "Kurtas",
            "primary_color": "Maroon",
            "purchase_price": 4500.0,
            "purchase_currency": "INR",
            "wear_count": 2,
            "laundry_status": "STORED",
            "is_archived": False,
        },
        "CLO-005": {
            "id": "CLO-005",
            "user_id": USER_ID,
            "name": "Indigo Denim Jeans",
            "main_category": "Bottoms",
            "subcategory": "Jeans",
            "primary_color": "Blue",
            "purchase_price": 3200.0,
            "purchase_currency": "INR",
            "wear_count": 12,
            "laundry_status": "WORN",
            "is_archived": False,
        },
    }
    # Reset wishlist store for test users
    _SESSION_WISHLIST_STORE[USER_ID] = {}
    _SESSION_WISHLIST_STORE[OTHER_USER_ID] = {}


def test_create_and_get_wishlist_item():
    payload = {
        "name": "Black Tailored Trousers",
        "category": "Bottoms",
        "subcategory": "Trousers",
        "expected_price": 3500.0,
        "expected_currency": "INR",
        "purchase_priority": "HIGH",
        "occasion": "Work",
        "desired_colour": "Black",
        "notes": "Need for client presentations",
    }
    res = client.post("/api/v1/wardrobe/wishlist", json=payload, headers=USER_HEADERS)
    assert res.status_code == 201
    data = res.json()
    assert data["name"] == "Black Tailored Trousers"
    assert data["category"] == "Bottoms"
    assert data["purchase_priority"] == "HIGH"
    assert data["status"] == "CONSIDERING"
    assert data["expected_price"] == 3500.0
    item_id = data["id"]

    # Retrieve single
    get_res = client.get(f"/api/v1/wardrobe/wishlist/{item_id}", headers=USER_HEADERS)
    assert get_res.status_code == 200
    assert get_res.json()["id"] == item_id

    # Security: other user cannot see this item
    get_other = client.get(f"/api/v1/wardrobe/wishlist/{item_id}", headers=OTHER_USER_HEADERS)
    assert get_other.status_code == 404


def test_list_and_filter_wishlist_items():
    # Insert 2 items with different priorities and categories
    client.post("/api/v1/wardrobe/wishlist", json={
        "name": "Grey Wool Cardigan",
        "category": "Outerwear",
        "expected_price": 2900.0,
        "purchase_priority": "MEDIUM",
        "desired_colour": "Grey",
    }, headers=USER_HEADERS)
    client.post("/api/v1/wardrobe/wishlist", json={
        "name": "White Minimal Sneakers",
        "category": "Footwear",
        "expected_price": 4500.0,
        "purchase_priority": "HIGH",
        "desired_colour": "White",
    }, headers=USER_HEADERS)

    # List all
    res_all = client.get("/api/v1/wardrobe/wishlist", headers=USER_HEADERS)
    assert res_all.status_code == 200
    assert len(res_all.json()) >= 2

    # Filter by priority
    res_high = client.get("/api/v1/wardrobe/wishlist?priority=HIGH", headers=USER_HEADERS)
    assert res_high.status_code == 200
    assert all(i["purchase_priority"] == "HIGH" for i in res_high.json())

    # Filter by category
    res_outer = client.get("/api/v1/wardrobe/wishlist?category=Outerwear", headers=USER_HEADERS)
    assert res_outer.status_code == 200
    assert len(res_outer.json()) == 1
    assert res_outer.json()[0]["name"] == "Grey Wool Cardigan"


def test_update_and_delete_wishlist_item():
    create_res = client.post("/api/v1/wardrobe/wishlist", json={
        "name": "Beige Trench Coat",
        "category": "Outerwear",
        "expected_price": 6000.0,
        "purchase_priority": "LOW",
    }, headers=USER_HEADERS)
    item_id = create_res.json()["id"]

    # Update
    update_res = client.put(f"/api/v1/wardrobe/wishlist/{item_id}", json={
        "name": "Beige Trench Coat (Classic Fit)",
        "purchase_priority": "HIGH",
        "expected_price": 5500.0,
    }, headers=USER_HEADERS)
    assert update_res.status_code == 200
    assert update_res.json()["name"] == "Beige Trench Coat (Classic Fit)"
    assert update_res.json()["purchase_priority"] == "HIGH"
    assert update_res.json()["expected_price"] == 5500.0

    # Delete
    del_res = client.delete(f"/api/v1/wardrobe/wishlist/{item_id}", headers=USER_HEADERS)
    assert del_res.status_code == 204

    # Verify 404
    get_res = client.get(f"/api/v1/wardrobe/wishlist/{item_id}", headers=USER_HEADERS)
    assert get_res.status_code == 404


def test_wishlist_summary_and_currency_totals():
    # Item 1 with price
    client.post("/api/v1/wardrobe/wishlist", json={
        "name": "Item A",
        "category": "Tops",
        "expected_price": 2000.0,
        "expected_currency": "INR",
        "purchase_priority": "HIGH",
    }, headers=USER_HEADERS)
    # Item 2 with missing price
    client.post("/api/v1/wardrobe/wishlist", json={
        "name": "Item B",
        "category": "Bottoms",
        "expected_price": None,
        "purchase_priority": "MEDIUM",
    }, headers=USER_HEADERS)

    summary_res = client.get("/api/v1/wardrobe/wishlist/summary", headers=USER_HEADERS)
    assert summary_res.status_code == 200
    summary = summary_res.json()
    assert summary["total_items"] >= 2
    assert summary["unpriced_items_count"] >= 1
    assert "INR" in summary["estimated_wishlist_value"]
    assert summary["estimated_wishlist_value"]["INR"] >= 2000.0


def test_status_update_transitions():
    create_res = client.post("/api/v1/wardrobe/wishlist", json={
        "name": "Casual Loafers",
        "category": "Footwear",
        "expected_price": 3800.0,
    }, headers=USER_HEADERS)
    item_id = create_res.json()["id"]

    # Transition to SHORTLISTED
    res1 = client.patch(f"/api/v1/wardrobe/wishlist/{item_id}/status", json={
        "status": "SHORTLISTED",
    }, headers=USER_HEADERS)
    assert res1.status_code == 200
    assert res1.json()["status"] == "SHORTLISTED"

    # Transition to PURCHASED with actual purchase price
    res2 = client.patch(f"/api/v1/wardrobe/wishlist/{item_id}/status", json={
        "status": "PURCHASED",
        "actual_purchase_price": 3499.0,
        "actual_purchase_currency": "INR",
    }, headers=USER_HEADERS)
    assert res2.status_code == 200
    data = res2.json()
    assert data["status"] == "PURCHASED"
    assert data["actual_purchase_price"] == 3499.0
    assert data["purchased_at"] is not None


def test_convert_purchased_wishlist_item_to_wardrobe_idempotency():
    create_res = client.post("/api/v1/wardrobe/wishlist", json={
        "name": "Tailored Navy Blazer",
        "category": "Outerwear",
        "subcategory": "Blazers",
        "expected_price": 7500.0,
        "expected_currency": "INR",
        "desired_colour": "Navy Blue",
    }, headers=USER_HEADERS)
    item_id = create_res.json()["id"]

    # Convert to wardrobe with actual purchase price 6999.0
    conv_res = client.post(f"/api/v1/wardrobe/wishlist/{item_id}/convert-to-wardrobe", json={
        "actual_purchase_price": 6999.0,
        "actual_purchase_currency": "INR",
        "purchase_date": "2026-11-23",
        # Notice laundry_status is omitted: must remain unassigned
    }, headers=USER_HEADERS)
    assert conv_res.status_code == 200
    data = conv_res.json()
    garment = data["garment"]
    wishlist_item = data["wishlist_item"]

    # Verify created garment details
    assert garment["id"].startswith("CLO-")
    assert garment["name"] == "Tailored Navy Blazer"
    assert garment["main_category"] == "Outerwear"
    assert garment["purchase_price"] == 6999.0
    assert garment["purchase_currency"] == "INR"
    assert garment["laundry_status"] is None  # Unassigned safety!
    assert garment["wear_count"] == 0

    # Verify wishlist item link
    assert wishlist_item["status"] == "PURCHASED"
    assert wishlist_item["converted_garment_id"] == garment["id"]
    assert wishlist_item["expected_price"] == 7500.0
    assert wishlist_item["actual_purchase_price"] == 6999.0

    # Test idempotency: re-converting must NOT create a second garment!
    conv_retry = client.post(f"/api/v1/wardrobe/wishlist/{item_id}/convert-to-wardrobe", json={}, headers=USER_HEADERS)
    assert conv_retry.status_code == 200
    assert conv_retry.json()["garment"]["id"] == garment["id"]


def test_wardrobe_gap_analysis():
    # User has 4 uppers (2 tops, 2 kurtas) and only 1 bottom
    res = client.get("/api/v1/wardrobe/shopping-intelligence/gaps", headers=USER_HEADERS)
    assert res.status_code == 200
    gaps = res.json()
    assert len(gaps) >= 1

    # Should detect the bottom ratio imbalance
    bottom_gap = next((g for g in gaps if g["category"] == "Bottoms"), None)
    assert bottom_gap is not None
    assert "Bottoms Imbalance" in bottom_gap["title"] or "Missing" in bottom_gap["title"]
    assert bottom_gap["potential_outfit_combinations_gained"] > 0
    assert bottom_gap["confidence_score"] > 0.7


def test_match_existing_similar_garments():
    # User owns "Classic White Shirt" (Tops, White)
    res = client.post("/api/v1/wardrobe/shopping-intelligence/match", json={
        "category": "Tops",
        "desired_colour": "White",
    }, headers=USER_HEADERS)
    assert res.status_code == 200
    matches = res.json()
    assert len(matches) >= 1
    assert any(m["garment_name"] == "Classic White Shirt" for m in matches)
    assert matches[0]["match_type"] == "EXACT_COLOR_AND_CATEGORY"


def test_purchase_assessment_strong_addition():
    # Create wishlist item that fills a genuine gap: Black Trousers (Bottoms)
    create_res = client.post("/api/v1/wardrobe/wishlist", json={
        "name": "Classic Black Trousers",
        "category": "Bottoms",
        "desired_colour": "Black",
        "purchase_priority": "HIGH",
    }, headers=USER_HEADERS)
    item_id = create_res.json()["id"]

    res = client.get(f"/api/v1/wardrobe/shopping-intelligence/assessment/{item_id}", headers=USER_HEADERS)
    assert res.status_code == 200
    data = res.json()
    assert data["outcome"] in ("STRONG_ADDITION", "POTENTIALLY_USEFUL")
    assert data["assessment_score"] is not None
    assert data["assessment_score"] >= 60.0
    assert len(data["contributing_factors"]) >= 1


def test_purchase_assessment_consider_alternatives():
    # Create wishlist item that duplicates an owned piece: White Linen Shirt (User already owns Classic White Shirt)
    create_res = client.post("/api/v1/wardrobe/wishlist", json={
        "name": "White Linen Shirt",
        "category": "Tops",
        "desired_colour": "White",
        "purchase_priority": "LOW",
    }, headers=USER_HEADERS)
    item_id = create_res.json()["id"]

    res = client.get(f"/api/v1/wardrobe/shopping-intelligence/assessment/{item_id}", headers=USER_HEADERS)
    assert res.status_code == 200
    data = res.json()
    assert data["outcome"] == "CONSIDER_ALTERNATIVES"
    assert data["has_similar_owned"] is True
    assert len(data["existing_similar_garments"]) >= 1
    assert "Classic White Shirt" in [g["garment_name"] for g in data["existing_similar_garments"]]


def test_purchase_assessment_insufficient_info():
    item_id = client.post("/api/v1/wardrobe/wishlist", json={
        "name": "Unspecified Accessory",
        "category": "Accessories",
    }, headers=USER_HEADERS).json()["id"]

    res = client.get(f"/api/v1/wardrobe/shopping-intelligence/assessment/{item_id}", headers=USER_HEADERS)
    assert res.status_code == 200
    assert res.json()["assessment_score"] is not None
