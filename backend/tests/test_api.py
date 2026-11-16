from fastapi.testclient import TestClient

def test_health(client: TestClient):
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}

def test_create_conversation(client: TestClient):
    response = client.post("/api/v1/conversations", json={"title": "Test Chat"})
    assert response.status_code == 200
    assert response.json()["title"] == "Test Chat"

def test_chat_endpoint(client: TestClient):
    response = client.post("/api/v1/conversations/conv-1/messages", json={"message": "Hello TESS"})
    assert response.status_code == 200
    assert "Mock response to:" in response.json()["response"]

def test_create_memory(client: TestClient):
    response = client.post("/api/v1/memories", json={"category": "preference", "content": "Test memory"})
    assert response.status_code == 200
    assert response.json()["content"] == "Test memory"

def test_productivity_summary(client: TestClient):
    response = client.get("/api/v1/productivity/summary")
    assert response.status_code == 200
    data = response.json()
    assert data["total_active"] == 5
    assert data["overdue"] == 1

def test_productivity_sync(client: TestClient):
    response = client.post("/api/v1/productivity/integrations/openproject/sync")
    assert response.status_code == 200
    assert response.json()["status"] == "success"
