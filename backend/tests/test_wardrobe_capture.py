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

def _generate_dark_image() -> bytes:
    """Generates an excessively dark image."""
    img = Image.new("RGB", (200, 200), (2, 2, 2))
    buf = io.BytesIO()
    img.save(buf, format="JPEG", quality=90)
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

def test_create_capture_job_multi_garment():
    """
    Submits a portrait photograph containing outfit/multiple garments.
    Verifies that multi-garment detection produces at least two distinct candidates
    (e.g., Top and Bottom) with separate processed catalogue references.
    """
    img_bytes = _generate_test_image(width=400, height=600, color=(30, 80, 160))
    files = {"image": ("outfit.jpg", img_bytes, "image/jpeg")}

    response = client.post("/api/v1/wardrobe/capture/jobs", files=files, headers=DEV_HEADERS)
    assert response.status_code == 201
    data = response.json()

    assert data["id"].startswith("job_")
    assert data["status"] == "AWAITING_APPROVAL"
    assert data["total_detected"] >= 2
    assert len(data["candidates"]) >= 2

    # Verify first candidate is Top and second is Bottom
    top_cand = next(c for c in data["candidates"] if c["main_category"] == "Tops")
    bot_cand = next(c for c in data["candidates"] if c["main_category"] == "Bottoms")

    assert top_cand["processed_image_ref"] is not None
    assert bot_cand["processed_image_ref"] is not None
    assert top_cand["id"] != bot_cand["id"]
    assert top_cand["confidence_scores"]["category"] == "HIGH"
    assert top_cand["is_included"] is True

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
