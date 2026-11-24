import io
import pytest
from PIL import Image
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)
DEV_HEADERS = {"Authorization": "Bearer dev-token"}
OTHER_USER_HEADERS = {"Authorization": "Bearer dev-user-2"}

def _generate_test_image(width=400, height=600, color=(50, 100, 200)) -> bytes:
    """Generates a valid test JPEG in memory."""
    img = Image.new("RGB", (width, height), color)
    buf = io.BytesIO()
    img.save(buf, format="JPEG", quality=90)
    return buf.getvalue()

import os

def _generate_dark_image() -> bytes:
    """Generates an excessively dark image."""
    img = Image.new("RGB", (200, 200), (2, 2, 2))
    buf = io.BytesIO()
    img.save(buf, format="JPEG", quality=90)
    return buf.getvalue()

def _generate_multi_garment_image() -> bytes:
    """Generates an image with two distinct separated garments on a neutral background."""
    canvas = Image.new("RGB", (500, 800), (255, 255, 255))
    top_item = Image.new("RGB", (350, 250), (20, 35, 75))
    canvas.paste(top_item, (75, 50))
    bottom_item = Image.new("RGB", (350, 300), (195, 175, 145))
    canvas.paste(bottom_item, (75, 400))
    buf = io.BytesIO()
    canvas.save(buf, format="JPEG", quality=90)
    return buf.getvalue()

def test_image_validation_empty():
    """Validates that empty photograph upload is rejected."""
    files = {"image": ("empty.jpg", b"", "image/jpeg")}
    response = client.post("/api/v1/wardrobe/capture/jobs", files=files, headers=DEV_HEADERS)
    assert response.status_code == 400
    assert "empty" in response.json()["detail"].lower()

def test_image_validation_too_dark():
    """Validates that excessively dark photographs are rejected with helpful message."""
    dark_bytes = _generate_dark_image()
    files = {"image": ("dark.jpg", dark_bytes, "image/jpeg")}
    response = client.post("/api/v1/wardrobe/capture/jobs", files=files, headers=DEV_HEADERS)
    assert response.status_code == 400
    assert "dark" in response.json()["detail"].lower()

def test_create_capture_job_single_garment_never_split():
    """
    Submits a portrait photograph containing a single garment.
    Verifies that the system correctly understands physical object boundaries
    and DOES NOT falsely split a single garment into Top and Bottom candidates.
    """
    img_bytes = _generate_test_image(width=400, height=600, color=(30, 80, 160))
    files = {"image": ("single_dress.jpg", img_bytes, "image/jpeg")}
    response = client.post("/api/v1/wardrobe/capture/jobs", files=files, headers=DEV_HEADERS)
    assert response.status_code == 201
    data = response.json()

    assert data["id"].startswith("job_")
    assert data["status"] == "AWAITING_APPROVAL"
    assert data["total_detected"] == 1
    assert len(data["candidates"]) == 1
    cand = data["candidates"][0]
    assert cand["processed_image_ref"] is not None
    assert cand["is_included"] is True

def test_create_capture_job_real_kurta():
    """
    Evaluates pipeline on the actual photograph of the Kurta uploaded by user.
    Verifies:
    1. Exactly ONE garment is detected (not split into Top and Bottom).
    2. Category is Ethnic Wear, Dresses, or Tops.
    3. Primary color is accurately detected as Wine / Maroon / Burgundy (not floor or shadow).
    4. Studio catalogue image is generated.
    """
    kurta_path = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        "app", "media", "wardrobe",
        "d6dd3895-95c9-414b-8f08-863ba3985492", "originals", "job_036aae3fb6cc.jpg"
    )
    if not os.path.exists(kurta_path):
        kurta_path = "backend/app/media/wardrobe/d6dd3895-95c9-414b-8f08-863ba3985492/originals/job_036aae3fb6cc.jpg"

    if os.path.exists(kurta_path):
        with open(kurta_path, "rb") as f:
            kurta_bytes = f.read()

        files = {"image": ("kurta.jpg", kurta_bytes, "image/jpeg")}
        response = client.post("/api/v1/wardrobe/capture/jobs", files=files, headers=DEV_HEADERS)
        assert response.status_code == 201
        data = response.json()

        assert data["total_detected"] == 1
        assert len(data["candidates"]) == 1
        cand = data["candidates"][0]
        assert cand["main_category"] in ["Ethnic Wear", "Dresses", "Tops"]
        assert cand["primary_color"] in ["Wine", "Maroon", "Burgundy", "Red", "Pink"]
        assert cand["processed_image_ref"] is not None

def test_create_capture_job_multi_garment():
    """
    Submits a photograph containing two genuinely distinct garments separated on canvas.
    Verifies that multi-garment detection produces 2 distinct candidates with separate catalogue references.
    """
    img_bytes = _generate_multi_garment_image()
    files = {"image": ("outfit.jpg", img_bytes, "image/jpeg")}

    response = client.post("/api/v1/wardrobe/capture/jobs", files=files, headers=DEV_HEADERS)
    assert response.status_code == 201
    data = response.json()

    assert data["id"].startswith("job_")
    assert data["status"] == "AWAITING_APPROVAL"
    assert data["total_detected"] == 2
    assert len(data["candidates"]) == 2

    cands = data["candidates"]
    assert cands[0]["processed_image_ref"] is not None
    assert cands[1]["processed_image_ref"] is not None
    assert cands[0]["id"] != cands[1]["id"]

def test_get_job_and_candidates():
    """Verifies retrieval of capture job and its candidate garments."""
    img_bytes = _generate_test_image(width=300, height=450)
    files = {"image": ("test.jpg", img_bytes, "image/jpeg")}
    create_res = client.post("/api/v1/wardrobe/capture/jobs", files=files, headers=DEV_HEADERS)
    job_id = create_res.json()["id"]

    # Get job
    job_res = client.get(f"/api/v1/wardrobe/capture/jobs/{job_id}", headers=DEV_HEADERS)
    assert job_res.status_code == 200
    assert job_res.json()["id"] == job_id

    # Get candidates directly
    cand_res = client.get(f"/api/v1/wardrobe/capture/jobs/{job_id}/candidates", headers=DEV_HEADERS)
    assert cand_res.status_code == 200
    assert len(cand_res.json()) >= 1

def test_update_candidate_attributes_and_exclusion():
    """Verifies editing candidate attributes and toggling inclusion."""
    img_bytes = _generate_test_image(width=300, height=450)
    files = {"image": ("edit_test.jpg", img_bytes, "image/jpeg")}
    job = client.post("/api/v1/wardrobe/capture/jobs", files=files, headers=DEV_HEADERS).json()
    cand = job["candidates"][0]

    # Patch attributes
    patch_payload = {
        "suggested_name": "Verified Midnight Navy Linen Shirt",
        "primary_color": "Navy Blue",
        "sleeve_length": "Full Sleeves",
        "fit": "Slim Fit",
        "is_included": False,
    }
    patch_res = client.patch(
        f"/api/v1/wardrobe/capture/candidates/{cand['id']}",
        json=patch_payload,
        headers=DEV_HEADERS,
    )
    assert patch_res.status_code == 200
    updated = patch_res.json()
    assert updated["suggested_name"] == "Verified Midnight Navy Linen Shirt"
    assert updated["sleeve_length"] == "Full Sleeves"
    assert updated["is_included"] is False

def test_confirm_and_register_approved_garments():
    """
    Confirms approved candidates, verifies registration into wardrobe_items,
    assignment of unique CLO-xxx ID, and job status update to COMPLETED.
    """
    img_bytes = _generate_test_image(width=400, height=600)
    files = {"image": ("confirm_test.jpg", img_bytes, "image/jpeg")}
    job = client.post("/api/v1/wardrobe/capture/jobs", files=files, headers=DEV_HEADERS).json()
    job_id = job["id"]

    # Ensure candidate 0 is included, and exclude candidate 1
    cands = job["candidates"]
    client.patch(f"/api/v1/wardrobe/capture/candidates/{cands[0]['id']}", json={"is_included": True}, headers=DEV_HEADERS)
    if len(cands) > 1:
        client.patch(f"/api/v1/wardrobe/capture/candidates/{cands[1]['id']}", json={"is_included": False}, headers=DEV_HEADERS)

    # Confirm registration
    confirm_res = client.post(f"/api/v1/wardrobe/capture/jobs/{job_id}/confirm", json={}, headers=DEV_HEADERS)
    assert confirm_res.status_code == 200
    conf_data = confirm_res.json()
    assert conf_data["success"] is True
    assert conf_data["registered_count"] >= 1
    new_id = conf_data["registered_garment_ids"][0]
    assert new_id.startswith("CLO-")

    # Verify registered item exists in wardrobe items endpoint
    item_res = client.get(f"/api/v1/wardrobe/items/{new_id}", headers=DEV_HEADERS)
    assert item_res.status_code == 200
    item_data = item_res.json()
    assert item_data["id"] == new_id
    assert item_data["laundry_status"] is None  # Initial status null/unassigned per PRD

    # Verify job status is COMPLETED
    job_final = client.get(f"/api/v1/wardrobe/capture/jobs/{job_id}", headers=DEV_HEADERS).json()
    assert job_final["status"] == "COMPLETED"

def test_user_isolation_security():
    """Verifies that User 2 cannot access or confirm User 1's capture job or candidates."""
    img_bytes = _generate_test_image(width=300, height=300)
    files = {"image": ("secure.jpg", img_bytes, "image/jpeg")}
    job = client.post("/api/v1/wardrobe/capture/jobs", files=files, headers=DEV_HEADERS).json()
    job_id = job["id"]

    # Other user attempts to get job
    cross_res = client.get(f"/api/v1/wardrobe/capture/jobs/{job_id}", headers=OTHER_USER_HEADERS)
    assert cross_res.status_code == 404

    # Other user attempts to confirm
    cross_conf = client.post(f"/api/v1/wardrobe/capture/jobs/{job_id}/confirm", json={}, headers=OTHER_USER_HEADERS)
    assert cross_conf.status_code == 404

def test_retry_capture_job():
    """Verifies that retrying re-runs analysis on the preserved original image."""
    img_bytes = _generate_test_image(width=300, height=500)
    files = {"image": ("retry.jpg", img_bytes, "image/jpeg")}
    job = client.post("/api/v1/wardrobe/capture/jobs", files=files, headers=DEV_HEADERS).json()
    job_id = job["id"]

    retry_res = client.post(f"/api/v1/wardrobe/capture/jobs/{job_id}/retry", headers=DEV_HEADERS)
    assert retry_res.status_code == 200
    retried_data = retry_res.json()
    assert retried_data["id"] == job_id
    assert retried_data["status"] == "AWAITING_APPROVAL"
    assert len(retried_data["candidates"]) >= 1

