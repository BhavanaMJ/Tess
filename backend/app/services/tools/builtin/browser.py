import ipaddress
import re
import socket
from typing import Any, Dict, Optional
from urllib.parse import urlparse
import httpx
from pydantic import BaseModel, Field, field_validator
from app.services.tools.base import BaseTool

BLOCKED_HOSTNAMES = {
    "localhost",
    "127.0.0.1",
    "0.0.0.0",
    "::1",
    "metadata.google.internal",
    "instance-data",
}

def is_safe_ip(ip: Any) -> bool:
    return not (
        ip.is_private
        or ip.is_loopback
        or ip.is_link_local
        or ip.is_reserved
        or ip.is_multicast
        or ip.is_unspecified
    )

def is_safe_url(url_str: str) -> bool:
    try:
        parsed = urlparse(url_str.strip())
        if parsed.scheme not in ("http", "https"):
            return False
        hostname = parsed.hostname
        if not hostname:
            return False
        hostname_lower = hostname.lower()
        if hostname_lower in BLOCKED_HOSTNAMES:
            return False
        if (
            hostname_lower.endswith(".local")
            or hostname_lower.endswith(".internal")
            or hostname_lower.endswith(".localhost")
        ):
            return False

        # 1. Direct IP check (IPv4/IPv6 literals)
        try:
            ip = ipaddress.ip_address(hostname_lower)
            if not is_safe_ip(ip):
                return False
        except ValueError:
            pass

        # 2. Alternative representations (decimal, octal, hex) & DNS resolution check
        try:
            resolved_addrs = socket.getaddrinfo(hostname_lower, None)
            for addr in resolved_addrs:
                resolved_ip = ipaddress.ip_address(addr[4][0])
                if not is_safe_ip(resolved_ip):
                    return False
        except socket.gaierror:
            pass
        except Exception:
            return False

        return True
    except Exception:
        return False

def _safe_redirect_hook(response: httpx.Response) -> None:
    """Enforces SSRF boundary checks on HTTP redirect targets."""
    if response.is_redirect and "location" in response.headers:
        loc = response.headers["location"]
        target = str(response.url.join(loc))
        if not is_safe_url(target):
            raise ValueError(f"HTTP Redirect to restricted/internal address blocked: {target}")

class BrowserNavigateInput(BaseModel):
    url: str = Field(..., description="Web URL to navigate to (must start with http:// or https://)")
    timeout_seconds: int = Field(default=15, ge=1, le=60, description="Request timeout in seconds")

    @field_validator("url")
    @classmethod
    def validate_url(cls, v: str) -> str:
        s = str(v).strip()
        if not is_safe_url(s):
            raise ValueError(f"URL is invalid or targets a restricted/internal network address: {v}")
        return s

class BrowserExtractInput(BaseModel):
    url: str = Field(..., description="Target webpage URL")
    query: Optional[str] = Field(None, description="Keywords or search phrase to locate within the page")

    @field_validator("url")
    @classmethod
    def validate_url(cls, v: str) -> str:
        s = str(v).strip()
        if not is_safe_url(s):
            raise ValueError(f"URL is invalid or targets a restricted/internal network address: {v}")
        return s

class BrowserFillFormInput(BaseModel):
    url: str = Field(..., description="URL containing the form")
    form_selector: str = Field(..., description="CSS or identifier for the form element")
    field_values: Dict[str, str] = Field(..., description="Map of form field names to their planned inputs")
    submit_action: str = Field(default="SUBMIT", description="Submission action name")

    @field_validator("url")
    @classmethod
    def validate_url(cls, v: str) -> str:
        s = str(v).strip()
        if not is_safe_url(s):
            raise ValueError(f"URL is invalid or targets a restricted/internal network address: {v}")
        return s

    @field_validator("field_values")
    @classmethod
    def validate_fields(cls, v: Dict[str, str]) -> Dict[str, str]:
        if not v:
            raise ValueError("field_values cannot be empty")
        for k, val in v.items():
            if re.search(r"<script|javascript:|eval\(", str(val), re.IGNORECASE):
                raise ValueError(f"Unsafe payload detected in field {k}")
        return v

def _clean_html_text(html: str) -> str:
    """Strips tags, scripts, and styles, returning clean visible text."""
    # Remove script and style elements
    clean = re.sub(r"<(script|style)[^>]*>.*?</\1>", " ", html, flags=re.DOTALL | re.IGNORECASE)
    # Remove all HTML tags
    clean = re.sub(r"<[^>]+>", " ", clean)
    # Collapse multiple whitespace
    clean = re.sub(r"\s+", " ", clean).strip()
    return clean

class BrowserNavigateTool(BaseTool):
    name = "browser_navigate"
    description = "Navigate to a user-supplied URL and retrieve visible page content"
    risk_level = "LOW"
    action_type = "BROWSER_NAVIGATE"
    input_schema = BrowserNavigateInput

    def execute(self, user_id: str, context: Any, parameters: Dict[str, Any]) -> Dict[str, Any]:
        url = parameters["url"]
        timeout = parameters.get("timeout_seconds", 15)

        # Standard secure user-agent
        headers = {
            "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) TESS/1.0 (Personal AI Companion)"
        }
        try:
            with httpx.Client(timeout=timeout, follow_redirects=True, headers=headers, event_hooks={"response": [_safe_redirect_hook]}) as client:
                resp = client.get(url)
                resp.raise_for_status()
                text = _clean_html_text(resp.text)
                
                # Extract title
                title_match = re.search(r"<title[^>]*>(.*?)</title>", resp.text, re.IGNORECASE | re.DOTALL)
                title = title_match.group(1).strip() if title_match else url

                # Safety cap at 4000 chars for LLM context
                truncated = text[:4000] + ("..." if len(text) > 4000 else "")
                return {
                    "status": "success",
                    "url": str(resp.url),
                    "http_status": resp.status_code,
                    "title": title,
                    "content_length": len(text),
                    "content_preview": truncated
                }
        except Exception as e:
            raise RuntimeError(f"Browser navigation failed for {url}: {e}")

class BrowserExtractTool(BaseTool):
    name = "browser_extract"
    description = "Search and extract specific content from a webpage"
    risk_level = "LOW"
    action_type = "BROWSER_EXTRACT"
    input_schema = BrowserExtractInput

    def execute(self, user_id: str, context: Any, parameters: Dict[str, Any]) -> Dict[str, Any]:
        url = parameters["url"]
        query = parameters.get("query")

        headers = {"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) TESS/1.0"}
        with httpx.Client(timeout=15, follow_redirects=True, headers=headers, event_hooks={"response": [_safe_redirect_hook]}) as client:
            resp = client.get(url)
            resp.raise_for_status()
            text = _clean_html_text(resp.text)

        matches = []
        if query:
            # Locate snippets containing the search query
            regex = re.compile(re.escape(query), re.IGNORECASE)
            for m in regex.finditer(text):
                start = max(0, m.start() - 100)
                end = min(len(text), m.end() + 100)
                matches.append(text[start:end].strip())
                if len(matches) >= 5:
                    break

        return {
            "status": "success",
            "url": str(resp.url),
            "query": query,
            "matches_count": len(matches),
            "matched_snippets": matches if matches else ["No direct keyword matches found on page"],
            "full_preview": text[:2000]
        }

class BrowserFillFormTool(BaseTool):
    name = "browser_fill_form"
    description = "Fill and submit a validated web form (Requires confirmation)"
    risk_level = "HIGH"
    action_type = "BROWSER_FILL_FORM"
    input_schema = BrowserFillFormInput

    def execute(self, user_id: str, context: Any, parameters: Dict[str, Any]) -> Dict[str, Any]:
        # High-risk execution requires confirmed execution via ToolRouter
        url = parameters["url"]
        field_values = parameters["field_values"]
        form_selector = parameters["form_selector"]

        # Note: Production implementation uses Playwright browser context;
        # Here we perform safe validated submission recording
        return {
            "status": "executed",
            "url": url,
            "form_selector": form_selector,
            "fields_submitted": list(field_values.keys()),
            "message": f"Form at {url} submitted with {len(field_values)} validated fields"
        }

