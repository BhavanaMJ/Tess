import pytest
import os
import tempfile
import base64
from fastapi.testclient import TestClient
from app.main import app
from app.services.tools.registry import ToolRegistry
from app.services.tools.router import ToolRouter
from app.services.agent.planner import AgentPlanner
from app.services.voice.service import VoiceService
from app.services.screen.service import ScreenService
from app.core.auth import get_current_user

@pytest.fixture(autouse=True)
def auth_override():
    app.dependency_overrides[get_current_user] = lambda: {"id": "test-phase8-user-id", "email": "test@tess.ai"}
    yield
    app.dependency_overrides.clear()

AUTH_HEADERS = {"Authorization": "Bearer test-phase8-token"}
client = TestClient(app)

def test_voice_synthesis_and_transcription():
    # Test TTS synthesis produces valid WAV audio
    wav_bytes = VoiceService.synthesize_speech("Hello, I am TESS.")
    assert len(wav_bytes) > 44  # Valid WAV header + PCM data
    assert wav_bytes[:4] == b"RIFF"
    assert wav_bytes[8:12] == b"WAVE"

    # Test transcription with audio data
    transcript = VoiceService.transcribe_audio(wav_bytes)
    assert isinstance(transcript, str)
    assert len(transcript) > 0

def test_voice_api_endpoints():
    # Synthesize endpoint
    synth_resp = client.post("/api/v1/voice/synthesize", json={"text": "Voice test successful."}, headers=AUTH_HEADERS)
    assert synth_resp.status_code == 200
    assert synth_resp.headers["content-type"] == "audio/wav"
    assert len(synth_resp.content) > 44

    # Empty text validation
    empty_resp = client.post("/api/v1/voice/synthesize", json={"text": ""}, headers=AUTH_HEADERS)
    assert empty_resp.status_code == 400

    # Transcribe endpoint with WAV file
    wav_bytes = synth_resp.content
    files = {"file": ("test.wav", wav_bytes, "audio/wav")}
    trans_resp = client.post("/api/v1/voice/transcribe", files=files, headers=AUTH_HEADERS)
    assert trans_resp.status_code == 200
    assert "transcript" in trans_resp.json()

def test_screen_service_validation_and_analysis():
    from PIL import Image
    import io

    # Generate test image
    img = Image.new("RGB", (320, 240), color=(124, 58, 237))
    buf = io.BytesIO()
    img.save(buf, format="JPEG")
    img_bytes = buf.getvalue()

    # Image validation
    processed_img, b64_str = ScreenService.validate_and_process_image(img_bytes)
    assert processed_img.size == (320, 240)
    assert len(b64_str) > 0

    # Screen API endpoint
    files = {"file": ("screen.jpg", img_bytes, "image/jpeg")}
    data = {"query": "What is visible on the screen?"}
    resp = client.post("/api/v1/screen/analyze", files=files, data=data, headers=AUTH_HEADERS)
    assert resp.status_code == 200
    res_data = resp.json()
    assert "analysis" in res_data
    assert res_data["dimensions"]["width"] == 320
    assert res_data["dimensions"]["height"] == 240

def test_browser_tools():
    # Browser Navigate (Low Risk)
    nav_tool = ToolRegistry.get_tool("browser_navigate")
    assert nav_tool.risk_level == "LOW"

    # URL Validation
    with pytest.raises(ValueError):
        nav_tool.validate({"url": "ftp://invalid-url.com"})

    # SSRF Protection: Loopback, private ranges, link-local, cloud metadata blocked
    for forbidden_url in [
        "http://localhost:8000/api",
        "http://127.0.0.1:8000",
        "http://169.254.169.254/latest/meta-data/",
        "http://10.0.0.1/admin",
        "http://192.168.1.1/router",
        "http://metadata.google.internal/computeMetadata/v1/",
    ]:
        with pytest.raises(ValueError):
            nav_tool.validate({"url": forbidden_url})

    # Browser Fill Form (High Risk requires confirmation)
    form_tool = ToolRegistry.get_tool("browser_fill_form")
    assert form_tool.risk_level == "HIGH"

    # Unconfirmed execution blocked by ToolRouter
    with pytest.raises(PermissionError) as exc:
        ToolRouter.route_and_execute(
            user_id="user_123",
            tool_name="browser_fill_form",
            parameters={
                "url": "https://example.com/login",
                "form_selector": "#login-form",
                "field_values": {"username": "admin"}
            },
            is_confirmed=False
        )
    assert "requires explicit user confirmation" in str(exc.value)

    # Confirmed execution succeeds
    res = ToolRouter.route_and_execute(
        user_id="user_123",
        tool_name="browser_fill_form",
        parameters={
            "url": "https://example.com/login",
            "form_selector": "#login-form",
            "field_values": {"username": "admin"}
        },
        is_confirmed=True
    )
    assert res["status"] == "executed"

def test_file_tools():
    # Create temporary text document
    with tempfile.NamedTemporaryFile("w+", suffix=".txt", delete=False) as tmp:
        tmp.write("TESS Phase 8: Personal AI Operating System documentation.\nMilestone 8.4 File Intelligence.")
        tmp_path = tmp.name

    try:
        # File Read
        read_tool = ToolRegistry.get_tool("file_read")
        read_res = read_tool.execute("user_123", None, {"file_path": tmp_path})
        assert read_res["status"] == "success"
        assert "Personal AI Operating System" in read_res["content"]

        # File Search
        search_tool = ToolRegistry.get_tool("file_search")
        search_res = search_tool.execute("user_123", None, {"file_path": tmp_path, "query": "File Intelligence"})
        assert search_res["occurrences_found"] >= 1

        # File Modify (High risk requires confirmation)
        modify_tool = ToolRegistry.get_tool("file_modify")
        assert modify_tool.risk_level == "HIGH"

        # Protected system directory validation check
        for forbidden_path in [
            "/etc/passwd",
            "/proc/cpuinfo",
            "/sys/kernel",
            "/dev/null",
            "/root/.bashrc",
            "/",
        ]:
            with pytest.raises(ValueError):
                modify_tool.validate({"action": "DELETE", "target_path": forbidden_path})

        with pytest.raises(PermissionError):
            ToolRouter.route_and_execute(
                user_id="user_123",
                tool_name="file_modify",
                parameters={"action": "DELETE", "target_path": tmp_path},
                is_confirmed=False
            )

        # Confirmed execution deletes file
        del_res = ToolRouter.route_and_execute(
            user_id="user_123",
            tool_name="file_modify",
            parameters={"action": "DELETE", "target_path": tmp_path},
            is_confirmed=True
        )
        assert del_res["status"] == "deleted"
        assert not os.path.exists(tmp_path)
    finally:
        if os.path.exists(tmp_path):
            os.remove(tmp_path)

def test_email_and_calendar_tools():
    # Gmail Read (Low Risk)
    gmail_read = ToolRegistry.get_tool("gmail_read")
    res_mail = gmail_read.execute("user_123", None, {"query": "is:unread", "max_results": 2})
    assert res_mail["status"] == "success"
    assert len(res_mail["messages"]) > 0

    # Gmail Send (High Risk requires confirmation)
    with pytest.raises(PermissionError):
        ToolRouter.route_and_execute(
            user_id="user_123",
            tool_name="gmail_send_email",
            parameters={"to": "client@example.com", "subject": "Update", "body": "Report ready."},
            is_confirmed=False
        )

    # Confirmed send succeeds
    send_res = ToolRouter.route_and_execute(
        user_id="user_123",
        tool_name="gmail_send_email",
        parameters={"to": "client@example.com", "subject": "Update", "body": "Report ready."},
        is_confirmed=True
    )
    assert send_res["status"] == "sent"

    # Calendar List
    cal_list = ToolRegistry.get_tool("calendar_list_events")
    cal_res = cal_list.execute("user_123", None, {"days_ahead": 7})
    assert cal_res["status"] == "success"
    assert len(cal_res["events"]) > 0

    # Calendar Create (Medium Risk requires confirmation)
    with pytest.raises(PermissionError):
        ToolRouter.route_and_execute(
            user_id="user_123",
            tool_name="calendar_create_event",
            parameters={
                "title": "Quarterly Review",
                "start_time": "2026-11-15T14:00:00Z",
                "end_time": "2026-11-15T15:00:00Z",
                "attendees": ["lead@deepmind.com"]
            },
            is_confirmed=False
        )

def test_multi_step_agent_planner_workflows():
    # 1. Meeting prep multi-step workflow
    prep_plan = AgentPlanner.plan("Prepare me for tomorrow's meeting")
    assert len(prep_plan.steps) == 3
    assert prep_plan.steps[0].tool_name == "calendar_list_events"
    assert prep_plan.steps[1].tool_name == "gmail_read"
    assert prep_plan.steps[2].tool_name == "gmail_create_draft"

    # 2. Browser research workflow
    browse_plan = AgentPlanner.plan("Search web and browse https://github.com/trending")
    assert len(browse_plan.steps) == 2
    assert browse_plan.steps[0].tool_name == "browser_navigate"
    assert browse_plan.steps[1].tool_name == "browser_extract"

    # 3. Document analysis workflow
    file_plan = AgentPlanner.plan("Read document /home/user/report.pdf")
    assert len(file_plan.steps) == 2
    assert file_plan.steps[0].tool_name == "file_read"
    assert file_plan.steps[1].tool_name == "file_search"

    # 4. Phase 6 OpenProject regression preserved
    worklog_plan = AgentPlanner.plan("Log 3.5 hours on task #42 in OpenProject")
    assert len(worklog_plan.steps) == 1
    assert worklog_plan.steps[0].tool_name == "openproject_update_worklog"
    assert worklog_plan.steps[0].parameters["hours"] == 3.5
    assert worklog_plan.steps[0].parameters["task_id"] == "42"
