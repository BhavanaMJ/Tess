import pytest
from datetime import datetime, date, timedelta, timezone
from fastapi.testclient import TestClient

from app.main import app
from app.services.wardrobe.service import _SESSION_WARDROBE_STORE
from app.services.wardrobe.outfit_service import _SESSION_OUTFITS_STORE, _SESSION_OUTFIT_ITEMS_STORE, _SESSION_WEAR_HISTORY_STORE
from app.services.wardrobe.calendar_service import _SESSION_PLANS_STORE, _SESSION_CALENDAR_WEAR_STORE
from app.services.wardrobe.weather_service import _SESSION_WEATHER_CACHE

client = TestClient(app)

USER_HEADERS = {"Authorization": "Bearer dev_user_cal_1"}
OTHER_USER_HEADERS = {"Authorization": "Bearer dev_user_cal_2"}

@pytest.fixture(autouse=True)
def setup_calendar_environment():
    _SESSION_WARDROBE_STORE.clear()
    _SESSION_OUTFITS_STORE.clear()
    _SESSION_OUTFIT_ITEMS_STORE.clear()
    _SESSION_WEAR_HISTORY_STORE.clear()
    _SESSION_PLANS_STORE.clear()
    _SESSION_CALENDAR_WEAR_STORE.clear()
    _SESSION_WEATHER_CACHE.clear()

    # Prepopulate items for user 1
    client.post(
        "/api/v1/wardrobe/items",
        headers=USER_HEADERS,
        json={
            "id": "CAL-TOP-1",
            "name": "Navy Oxford Shirt",
            "main_category": "Tops",
            "primary_color": "Navy Blue",
            "laundry_status": "CLEAN",
        },
    )
    client.post(
        "/api/v1/wardrobe/items",
        headers=USER_HEADERS,
        json={
            "id": "CAL-BOT-1",
            "name": "Beige Chinos",
            "main_category": "Bottoms",
            "primary_color": "Beige",
            "laundry_status": "CLEAN",
        },
    )
    # Create saved outfit
    res = client.post(
        "/api/v1/wardrobe/outfits",
        headers=USER_HEADERS,
        json={
            "name": "Smart Casual Duo",
            "occasion": "Work",
            "garment_ids": ["CAL-TOP-1", "CAL-BOT-1"],
            "creation_source": "MANUAL",
        },
    )
    assert res.status_code == 201


def test_create_outfit_plan_never_modifies_laundry():
    """Saving an outfit plan must NEVER alter garment laundry status or increment wear count."""
    list_res = client.get("/api/v1/wardrobe/outfits", headers=USER_HEADERS)
    outfit_id = list_res.json()["outfits"][0]["id"]

    planned_date = (date.today() + timedelta(days=2)).strftime("%Y-%m-%d")
    payload = {
        "outfit_id": outfit_id,
        "planned_date": planned_date,
        "occasion": "Team Lunch",
        "notes": "Presentation morning",
    }
    res = client.post("/api/v1/wardrobe/calendar/plans", headers=USER_HEADERS, json=payload)
    assert res.status_code == 201
    data = res.json()
    assert data["outfit_id"] == outfit_id
    assert data["planned_date"] == planned_date
    assert data["is_worn"] is False
    assert data["is_available"] is True

    # Invariant check: Garments must remain CLEAN, wear_count must remain 0!
    items = client.get("/api/v1/wardrobe/items", headers=USER_HEADERS).json()
    top = next(i for i in items if i["id"] == "CAL-TOP-1")
    bot = next(i for i in items if i["id"] == "CAL-BOT-1")
    assert top["laundry_status"] == "CLEAN"
    assert top["wear_count"] == 0
    assert bot["laundry_status"] == "CLEAN"
    assert bot["wear_count"] == 0


def test_update_and_delete_plan():
    list_res = client.get("/api/v1/wardrobe/outfits", headers=USER_HEADERS)
    outfit_id = list_res.json()["outfits"][0]["id"]

    planned_date = (date.today() + timedelta(days=3)).strftime("%Y-%m-%d")
    res = client.post("/api/v1/wardrobe/calendar/plans", headers=USER_HEADERS, json={
        "outfit_id": outfit_id,
        "planned_date": planned_date,
        "occasion": "Casual",
    })
    assert res.status_code == 201
    plan_id = res.json()["id"]

    new_date = (date.today() + timedelta(days=4)).strftime("%Y-%m-%d")
    update_res = client.put(f"/api/v1/wardrobe/calendar/plans/{plan_id}", headers=USER_HEADERS, json={
        "planned_date": new_date,
        "occasion": "Formal Client Meeting",
    })
    assert update_res.status_code == 200
    assert update_res.json()["planned_date"] == new_date
    assert update_res.json()["occasion"] == "Formal Client Meeting"

    del_res = client.delete(f"/api/v1/wardrobe/calendar/plans/{plan_id}", headers=USER_HEADERS)
    assert del_res.status_code == 200
    get_res = client.get(f"/api/v1/wardrobe/calendar/plans/{plan_id}", headers=USER_HEADERS)
    assert get_res.status_code == 404


def test_record_actual_wear_workflow_a():
    """Workflow A: User wore the planned outfit on schedule."""
    list_res = client.get("/api/v1/wardrobe/outfits", headers=USER_HEADERS)
    outfit_id = list_res.json()["outfits"][0]["id"]

    today_str = date.today().strftime("%Y-%m-%d")
    # 1. Create plan
    plan_res = client.post("/api/v1/wardrobe/calendar/plans", headers=USER_HEADERS, json={
        "outfit_id": outfit_id,
        "planned_date": today_str,
        "occasion": "Work",
    })
    assert plan_res.status_code == 201
    plan_id = plan_res.json()["id"]

    # 2. Confirm actual wear
    wear_res = client.post("/api/v1/wardrobe/calendar/wear", headers=USER_HEADERS, json={
        "outfit_id": outfit_id,
        "actual_worn_date": today_str,
        "plan_id": plan_id,
        "notes": "Great combo for presentation",
    })
    assert wear_res.status_code == 201
    wear_data = wear_res.json()
    assert wear_data["outfit_id"] == outfit_id
    assert wear_data["actual_worn_date"] == today_str
    assert wear_data["plan_id"] == plan_id

    # Garments must now be WORN and wear counts incremented!
    items = client.get("/api/v1/wardrobe/items", headers=USER_HEADERS).json()
    top = next(i for i in items if i["id"] == "CAL-TOP-1")
    bot = next(i for i in items if i["id"] == "CAL-BOT-1")
    assert top["laundry_status"] == "WORN"
    assert top["wear_count"] == 1
    assert bot["laundry_status"] == "WORN"
    assert bot["wear_count"] == 1

    # Plan is_worn flag must be updated
    plan_get = client.get(f"/api/v1/wardrobe/calendar/plans/{plan_id}", headers=USER_HEADERS).json()
    assert plan_get["is_worn"] is True


def test_record_actual_wear_workflow_b_unplanned():
    """Workflow B: User records wearing an outfit without prior planning."""
    list_res = client.get("/api/v1/wardrobe/outfits", headers=USER_HEADERS)
    outfit_id = list_res.json()["outfits"][0]["id"]

    today_str = date.today().strftime("%Y-%m-%d")
    wear_res = client.post("/api/v1/wardrobe/calendar/wear", headers=USER_HEADERS, json={
        "outfit_id": outfit_id,
        "actual_worn_date": today_str,
        "notes": "Spontaneous evening dinner",
    })
    assert wear_res.status_code == 201
    data = wear_res.json()
    assert data["plan_id"] is None
    assert data["actual_worn_date"] == today_str

    items = client.get("/api/v1/wardrobe/items", headers=USER_HEADERS).json()
    top = next(i for i in items if i["id"] == "CAL-TOP-1")
    assert top["laundry_status"] == "WORN"
    assert top["wear_count"] == 1


def test_calendar_day_week_month_views():
    list_res = client.get("/api/v1/wardrobe/outfits", headers=USER_HEADERS)
    outfit_id = list_res.json()["outfits"][0]["id"]

    today_str = date.today().strftime("%Y-%m-%d")
    # Create plan
    client.post("/api/v1/wardrobe/calendar/plans", headers=USER_HEADERS, json={
        "outfit_id": outfit_id,
        "planned_date": today_str,
        "occasion": "Casual",
    })

    # Day detail
    day_res = client.get(f"/api/v1/wardrobe/calendar/day/{today_str}", headers=USER_HEADERS)
    assert day_res.status_code == 200
    day_data = day_res.json()
    assert day_data["date"] == today_str
    assert day_data["has_plan"] is True
    assert len(day_data["plans"]) == 1
    assert day_data["weather"] is not None
    assert day_data["weather"]["is_forecast_available"] is True

    # Week view
    week_res = client.get(f"/api/v1/wardrobe/calendar/week?start_date={today_str}", headers=USER_HEADERS)
    assert week_res.status_code == 200
    week_data = week_res.json()
    assert len(week_data["days"]) == 7

    # Month view
    now = date.today()
    month_res = client.get(f"/api/v1/wardrobe/calendar/month?year={now.year}&month={now.month}", headers=USER_HEADERS)
    assert month_res.status_code == 200
    month_data = month_res.json()
    assert len(month_data["days"]) >= 28


def test_repetition_warning_intelligence():
    list_res = client.get("/api/v1/wardrobe/outfits", headers=USER_HEADERS)
    outfit_id = list_res.json()["outfits"][0]["id"]

    today = date.today()
    today_str = today.strftime("%Y-%m-%d")

    # Record wear today
    wear_res = client.post("/api/v1/wardrobe/calendar/wear", headers=USER_HEADERS, json={
        "outfit_id": outfit_id,
        "actual_worn_date": today_str,
    })
    assert wear_res.status_code == 201

    # Check repetition for 3 days later
    future_date = (today + timedelta(days=3)).strftime("%Y-%m-%d")
    rep_res = client.get(
        f"/api/v1/wardrobe/calendar/intelligence/repetition?outfit_id={outfit_id}&date={future_date}",
        headers=USER_HEADERS,
    )
    assert rep_res.status_code == 200
    rep_data = rep_res.json()
    assert rep_data["is_repeated"] is True
    assert rep_data["last_worn_date"] == today_str
    assert "wore this outfit" in rep_data["message"]


def test_weather_horizon_enforcement():
    # Within 14 days
    valid_date = (date.today() + timedelta(days=5)).strftime("%Y-%m-%d")
    w_res = client.get(f"/api/v1/wardrobe/weather/{valid_date}", headers=USER_HEADERS)
    assert w_res.status_code == 200
    assert w_res.json()["is_forecast_available"] is True

    # Beyond 14 days
    far_date = (date.today() + timedelta(days=20)).strftime("%Y-%m-%d")
    far_res = client.get(f"/api/v1/wardrobe/weather/{far_date}", headers=USER_HEADERS)
    assert far_res.status_code == 200
    far_data = far_res.json()
    assert far_data["is_forecast_available"] is False
    assert "Weather forecast is not available for this date" in far_data["styling_suggestion"]


def test_multi_tenant_isolation():
    """Ensure user 1 cannot view or modify user 2's plans or wear records."""
    list_res = client.get("/api/v1/wardrobe/outfits", headers=USER_HEADERS)
    outfit_id = list_res.json()["outfits"][0]["id"]

    today_str = date.today().strftime("%Y-%m-%d")
    plan_res = client.post("/api/v1/wardrobe/calendar/plans", headers=USER_HEADERS, json={
        "outfit_id": outfit_id,
        "planned_date": today_str,
        "occasion": "User 1 Private Plan",
    })
    plan_id = plan_res.json()["id"]

    # User 2 tries to access user 1's plan
    u2_res = client.get(f"/api/v1/wardrobe/calendar/plans/{plan_id}", headers=OTHER_USER_HEADERS)
    assert u2_res.status_code == 404
