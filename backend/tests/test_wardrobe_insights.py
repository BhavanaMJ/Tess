import pytest
from datetime import date, datetime, timedelta, timezone
from fastapi.testclient import TestClient
from app.main import app
from app.services.wardrobe.service import _SESSION_WARDROBE_STORE
from app.services.wardrobe.outfit_service import _SESSION_OUTFITS_STORE, _SESSION_OUTFIT_ITEMS_STORE, _SESSION_WEAR_HISTORY_STORE
from app.services.wardrobe.calendar_service import _SESSION_PLANS_STORE, _SESSION_CALENDAR_WEAR_STORE
from app.services.wardrobe.insights_service import _SESSION_STYLE_PREFERENCES_STORE

client = TestClient(app)

USER_HEADERS = {"Authorization": "Bearer dev_user_insights_1"}
OTHER_USER_HEADERS = {"Authorization": "Bearer dev_user_insights_2"}


@pytest.fixture(autouse=True)
def setup_insights_data():
    """Seed sample wardrobe, outfits, plans, and wears for test user."""
    _SESSION_WARDROBE_STORE.clear()
    _SESSION_OUTFITS_STORE.clear()
    _SESSION_OUTFIT_ITEMS_STORE.clear()
    _SESSION_WEAR_HISTORY_STORE.clear()
    _SESSION_PLANS_STORE.clear()
    _SESSION_CALENDAR_WEAR_STORE.clear()
    _SESSION_STYLE_PREFERENCES_STORE.clear()

    # 1. Seed active garments with different prices, colors, categories, laundry statuses
    client.post(
        "/api/v1/wardrobe/items",
        headers=USER_HEADERS,
        json={
            "id": "INSIGHT-CLO-01",
            "name": "Classic White Oxford Shirt",
            "main_category": "Tops",
            "primary_color": "White",
            "purchase_price": 2400.0,
            "purchase_currency": "INR",
            "laundry_status": "CLEAN",
        },
    )
    client.post(
        "/api/v1/wardrobe/items",
        headers=USER_HEADERS,
        json={
            "id": "INSIGHT-CLO-02",
            "name": "Indigo Selvedge Jeans",
            "main_category": "Bottoms",
            "primary_color": "Navy Blue",
            "purchase_price": 4500.0,
            "purchase_currency": "INR",
            "laundry_status": "CLEAN",
        },
    )
    client.post(
        "/api/v1/wardrobe/items",
        headers=USER_HEADERS,
        json={
            "id": "INSIGHT-CLO-03",
            "name": "Black Blazer",
            "main_category": "Outerwear",
            "primary_color": "Black",
            "purchase_price": 6000.0,
            "purchase_currency": "INR",
            "laundry_status": "CLEAN",
        },
    )
    client.post(
        "/api/v1/wardrobe/items",
        headers=USER_HEADERS,
        json={
            "id": "INSIGHT-CLO-04",
            "name": "Old Summer Linen Tee",
            "main_category": "Tops",
            "primary_color": "Olive Green",
            "purchase_price": 1200.0,
            "purchase_currency": "INR",
            "laundry_status": "WORN",
        },
    )
    client.post(
        "/api/v1/wardrobe/items",
        headers=USER_HEADERS,
        json={
            "id": "INSIGHT-CLO-05",
            "name": "Vintage Gift Sweater",
            "main_category": "Tops",
            "primary_color": "Burgundy",
            "purchase_price": None,  # Missing price test case
            "purchase_currency": "INR",
            "laundry_status": "CLEAN",
        },
    )

    # 2. Seed an outfit
    res_outfit = client.post(
        "/api/v1/wardrobe/outfits",
        headers=USER_HEADERS,
        json={
            "name": "Smart Work Look",
            "occasion": "Work",
            "garment_ids": ["INSIGHT-CLO-01", "INSIGHT-CLO-02"],
            "creation_source": "MANUAL",
        },
    )
    assert res_outfit.status_code == 201
    created_outfit_id = res_outfit.json()["id"]

    # 3. Log wear events
    today = date.today().isoformat()
    wear_res = client.post(
        "/api/v1/wardrobe/calendar/wear",
        headers=USER_HEADERS,
        json={
            "outfit_id": created_outfit_id,
            "actual_worn_date": today,
            "notes": "Office presentation",
        },
    )
    assert wear_res.status_code == 201


def test_get_wardrobe_overview():
    res = client.get("/api/v1/wardrobe/insights/overview?period=30d", headers=USER_HEADERS)
    assert res.status_code == 200
    data = res.json()
    assert data["total_active_garments"] >= 5
    assert data["clean_garments_count"] >= 2
    assert data["in_laundry_count"] >= 3
    assert data["total_outfits_worn_in_period"] >= 1
    assert data["unique_garments_worn_in_period"] >= 2
    assert data["utilisation_percentage"] > 0.0
    assert data["total_investment"] >= 14100.0


def test_category_distribution():
    res = client.get("/api/v1/wardrobe/insights/category-distribution", headers=USER_HEADERS)
    assert res.status_code == 200
    data = res.json()
    assert data["total_garments"] >= 5
    categories = {c["category"]: c for c in data["categories"]}
    assert "Tops" in categories
    assert categories["Tops"]["count"] >= 3
    assert categories["Tops"]["percentage_of_wardrobe"] > 0


def test_most_and_least_worn():
    # Most worn
    res_most = client.get("/api/v1/wardrobe/insights/most-worn?period=all", headers=USER_HEADERS)
    assert res_most.status_code == 200
    data_most = res_most.json()
    assert "items" in data_most
    if len(data_most["items"]) > 0:
        assert data_most["items"][0]["wear_count"] >= 1

    # Least worn
    res_least = client.get("/api/v1/wardrobe/insights/least-worn?period=all", headers=USER_HEADERS)
    assert res_least.status_code == 200
    data_least = res_least.json()
    assert "items" in data_least
    # Vintage sweater or unrecorded should have wear_count == 0
    zero_wears = [it for it in data_least["items"] if it["wear_count"] == 0]
    assert len(zero_wears) >= 1
    assert zero_wears[0]["neglect_reason"] in ("NEVER_RECORDED", "RECENTLY_ADDED")


def test_wardrobe_utilisation_calculation():
    res = client.get("/api/v1/wardrobe/insights/utilisation?period=30d", headers=USER_HEADERS)
    assert res.status_code == 200
    data = res.json()
    assert data["active_garments_count"] >= 5
    assert data["unique_garments_worn_count"] >= 2
    # Verify strict math: (unique / total) * 100
    expected_pct = round((data["unique_garments_worn_count"] / data["active_garments_count"]) * 100.0, 1)
    assert abs(data["utilisation_percentage"] - expected_pct) < 0.1
    assert "actively wore" in data["summary_text"]


def test_colour_analysis():
    res = client.get("/api/v1/wardrobe/insights/colour-analysis", headers=USER_HEADERS)
    assert res.status_code == 200
    data = res.json()
    assert data["total_garments"] >= 5
    groups = {item["color_group"]: item for item in data["distribution"]}
    # "White", "Navy Blue" -> Blue, "Black", "Olive Green" -> Green, "Burgundy" -> Red / Pink
    assert "White" in groups
    assert "Blue" in groups
    assert "Black" in groups


def test_category_usage():
    res = client.get("/api/v1/wardrobe/insights/category-usage?period=30d", headers=USER_HEADERS)
    assert res.status_code == 200
    data = res.json()
    cats = {c["category"]: c for c in data["categories"]}
    assert "Tops" in cats
    assert cats["Tops"]["total_garments"] >= 3


def test_cost_per_wear():
    res = client.get("/api/v1/wardrobe/insights/cost-per-wear", headers=USER_HEADERS)
    assert res.status_code == 200
    data = res.json()
    assert data["garments_with_price_count"] >= 4
    assert data["garments_without_price_count"] >= 1  # Vintage sweater had None price

    # Find item without price
    unpriced = [it for it in data["items"] if it["garment_id"] == "INSIGHT-CLO-05"][0]
    assert unpriced["cost_per_wear"] is None
    assert unpriced["value_tier"] == "MISSING_PRICE"

    # Find worn priced item
    worn_item = [it for it in data["items"] if it["garment_id"] == "INSIGHT-CLO-01"][0]
    assert worn_item["wear_count"] >= 1
    assert worn_item["cost_per_wear"] == round(2400.0 / worn_item["wear_count"], 2)


def test_recommendations():
    res = client.get("/api/v1/wardrobe/insights/recommendations", headers=USER_HEADERS)
    assert res.status_code == 200
    data = res.json()
    assert "recommendations" in data
    assert len(data["recommendations"]) >= 1


def test_capsule_intelligence():
    res = client.get("/api/v1/wardrobe/insights/capsule-intelligence", headers=USER_HEADERS)
    assert res.status_code == 200
    data = res.json()
    assert data["total_active_garments"] >= 5
    assert data["average_versatility_score"] > 0
    assert "anchor_garments" in data


def test_style_memory_get_and_update():
    # GET initial
    res = client.get("/api/v1/wardrobe/insights/style-memory", headers=USER_HEADERS)
    assert res.status_code == 200
    data = res.json()
    assert "style_persona" in data

    # Update style preferences
    update_payload = {
        "style_persona": "Urban Minimalist",
        "preferred_colors": ["Black", "White", "Navy"],
        "preferred_categories": ["Tops", "Outerwear"],
        "notes": "Prefer sharp lines and monochrome palettes",
    }
    res_post = client.post(
        "/api/v1/wardrobe/insights/style-memory",
        headers=USER_HEADERS,
        json=update_payload,
    )
    assert res_post.status_code == 200
    updated = res_post.json()
    assert updated["style_persona"] == "Urban Minimalist"
    assert "Black" in updated["preferred_colors"]
    assert updated["notes"] == "Prefer sharp lines and monochrome palettes"


def test_multi_tenant_isolation():
    # Other user has empty wardrobe initially
    res = client.get("/api/v1/wardrobe/insights/overview", headers=OTHER_USER_HEADERS)
    assert res.status_code == 200
    data = res.json()
    assert data["total_active_garments"] == 0
    assert data["utilisation_percentage"] == 0.0
