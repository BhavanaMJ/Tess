import os
import io
import csv
import re
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field, field_validator
from app.services.tools.base import BaseTool

SUPPORTED_EXTENSIONS = {".pdf", ".docx", ".txt", ".md", ".csv", ".xlsx"}
MAX_FILE_SIZE_BYTES = 25 * 1024 * 1024  # 25 MB

RESTRICTED_SYSTEM_DIRS = (
    "/etc",
    "/sys",
    "/proc",
    "/dev",
    "/boot",
    "/root",
    "/bin",
    "/sbin",
    "/usr",
    "/var/run",
    "/lib",
    "/lib64",
)

def is_safe_file_path(path: str) -> bool:
    try:
        resolved = os.path.realpath(os.path.abspath(path.strip()))
        if resolved == "/" or any(resolved == r or resolved.startswith(r + "/") for r in RESTRICTED_SYSTEM_DIRS):
            return False

        # If approved workspaces are configured, enforce workspace boundary
        allowed_workspaces = os.environ.get("TESS_ALLOWED_WORKSPACES")
        if allowed_workspaces:
            approved = [os.path.realpath(w.strip()) for w in allowed_workspaces.split(",") if w.strip()]
            if approved and not any(resolved == a or resolved.startswith(a + "/") for a in approved):
                return False

        return True
    except Exception:
        return False

class FileReadInput(BaseModel):
    file_path: str = Field(..., description="Absolute path to authorized document")
    max_chars: int = Field(default=10000, ge=100, le=50000, description="Maximum characters to extract")

    @field_validator("file_path")
    @classmethod
    def validate_path(cls, v: str) -> str:
        s = os.path.abspath(v.strip())
        if not is_safe_file_path(s):
            raise ValueError(f"Access to restricted system path is forbidden: '{v}'")
        ext = os.path.splitext(s)[1].lower()
        if ext not in SUPPORTED_EXTENSIONS:
            raise ValueError(f"Unsupported file format '{ext}'. Supported: {', '.join(sorted(SUPPORTED_EXTENSIONS))}")
        if not os.path.exists(s):
            raise ValueError(f"File not found: '{v}'")
        if not os.path.isfile(s):
            raise ValueError(f"Path is not a regular file: '{v}'")
        size = os.path.getsize(s)
        if size > MAX_FILE_SIZE_BYTES:
            raise ValueError(f"File size ({size} bytes) exceeds limit of 25MB")
        return s

class FileSearchInput(BaseModel):
    file_path: str = Field(..., description="Path to document")
    query: str = Field(..., description="Search term or phrase")

    @field_validator("file_path")
    @classmethod
    def validate_path(cls, v: str) -> str:
        s = os.path.abspath(v.strip())
        if not is_safe_file_path(s):
            raise ValueError(f"Access to restricted system path is forbidden: '{v}'")
        return s

    @field_validator("query")
    @classmethod
    def validate_query(cls, v: str) -> str:
        s = v.strip()
        if not s:
            raise ValueError("Query cannot be empty")
        return s

class FileModifyInput(BaseModel):
    action: str = Field(..., description="Modification action: 'UPDATE', 'DELETE', 'MOVE'")
    target_path: str = Field(..., description="Target file path")
    new_content_or_path: Optional[str] = Field(None, description="New text content or new file path")

    @field_validator("action")
    @classmethod
    def validate_action(cls, v: str) -> str:
        act = v.upper().strip()
        if act not in ("UPDATE", "DELETE", "MOVE"):
            raise ValueError("Action must be UPDATE, DELETE, or MOVE")
        return act

    @field_validator("target_path")
    @classmethod
    def validate_target(cls, v: str) -> str:
        s = os.path.abspath(v.strip())
        if not is_safe_file_path(s):
            raise ValueError(f"Modifications to restricted system path are forbidden: '{v}'")
        return s

    @field_validator("new_content_or_path")
    @classmethod
    def validate_destination(cls, v: Optional[str]) -> Optional[str]:
        if v and (v.startswith("/") or v.startswith("../") or v.startswith("./")):
            if not is_safe_file_path(v):
                raise ValueError(f"Target destination in restricted system path: '{v}'")
        return v

def extract_file_content(path: str, max_chars: int = 10000) -> str:
    """Extracts clean text content from supported file types."""
    ext = os.path.splitext(path)[1].lower()
    text = ""

    if ext in (".txt", ".md"):
        with open(path, "r", encoding="utf-8", errors="ignore") as f:
            text = f.read(max_chars)

    elif ext == ".csv":
        rows = []
        with open(path, "r", encoding="utf-8", errors="ignore") as f:
            reader = csv.reader(f)
            for i, row in enumerate(reader):
                if i >= 100:  # Cap at first 100 rows
                    break
                rows.append(", ".join(row))
        text = "\n".join(rows)

    elif ext == ".pdf":
        try:
            from pypdf import PdfReader
            reader = PdfReader(path)
            extracted = []
            for page in reader.pages:
                t = page.extract_text()
                if t:
                    extracted.append(t)
                if sum(len(x) for x in extracted) >= max_chars:
                    break
            text = "\n\n".join(extracted)
        except Exception as e:
            text = f"[Error reading PDF: {e}]"

    elif ext == ".docx":
        try:
            import docx
            doc = docx.Document(path)
            paras = [p.text for p in doc.paragraphs if p.text.strip()]
            text = "\n".join(paras)
        except Exception as e:
            text = f"[Error reading DOCX: {e}]"

    elif ext == ".xlsx":
        try:
            import openpyxl
            wb = openpyxl.load_workbook(path, read_only=True, data_only=True)
            lines = []
            sheet = wb.active
            if sheet:
                for i, row in enumerate(sheet.iter_rows(values_only=True)):
                    if i >= 100:
                        break
                    lines.append(", ".join([str(c) for c in row if c is not None]))
            text = "\n".join(lines)
        except Exception as e:
            text = f"[Error reading XLSX: {e}]"

    return text[:max_chars]

class FileReadTool(BaseTool):
    name = "file_read"
    description = "Read and extract text from authorized document (PDF, DOCX, TXT, MD, CSV, XLSX)"
    risk_level = "LOW"
    action_type = "FILE_READ"
    input_schema = FileReadInput

    def execute(self, user_id: str, context: Any, parameters: Dict[str, Any]) -> Dict[str, Any]:
        path = parameters["file_path"]
        max_chars = parameters.get("max_chars", 10000)
        content = extract_file_content(path, max_chars)
        ext = os.path.splitext(path)[1].lower()

        return {
            "status": "success",
            "file_name": os.path.basename(path),
            "file_path": path,
            "format": ext,
            "size_bytes": os.path.getsize(path),
            "extracted_length": len(content),
            "content": content
        }

class FileSearchTool(BaseTool):
    name = "file_search"
    description = "Search keywords within an authorized document"
    risk_level = "LOW"
    action_type = "FILE_SEARCH"
    input_schema = FileSearchInput

    def execute(self, user_id: str, context: Any, parameters: Dict[str, Any]) -> Dict[str, Any]:
        path = parameters["file_path"]
        query = parameters["query"]
        content = extract_file_content(path, 50000)

        matches = []
        regex = re.compile(re.escape(query), re.IGNORECASE)
        for m in regex.finditer(content):
            start = max(0, m.start() - 80)
            end = min(len(content), m.end() + 80)
            matches.append(content[start:end].replace("\n", " ").strip())
            if len(matches) >= 5:
                break

        return {
            "status": "success",
            "file_name": os.path.basename(path),
            "query": query,
            "occurrences_found": len(matches),
            "snippets": matches if matches else ["No matches found"]
        }

class FileModifyTool(BaseTool):
    name = "file_modify"
    description = "Modify, delete, or reorganize a file (Requires confirmation)"
    risk_level = "HIGH"
    action_type = "FILE_MODIFY"
    input_schema = FileModifyInput

    def execute(self, user_id: str, context: Any, parameters: Dict[str, Any]) -> Dict[str, Any]:
        action = parameters["action"]
        target_path = parameters["target_path"]
        new_val = parameters.get("new_content_or_path")

        if action == "DELETE":
            # Safety check: do not delete root or system directories
            if not os.path.exists(target_path):
                raise ValueError("Target file does not exist")
            os.remove(target_path)
            return {"status": "deleted", "target": target_path}

        elif action == "UPDATE":
            if new_val is None:
                raise ValueError("New content required for UPDATE action")
            with open(target_path, "w", encoding="utf-8") as f:
                f.write(new_val)
            return {"status": "updated", "target": target_path, "bytes_written": len(new_val)}

        elif action == "MOVE":
            if not new_val:
                raise ValueError("New path required for MOVE action")
            os.rename(target_path, new_val)
            return {"status": "moved", "source": target_path, "destination": new_val}

        return {"status": "unsupported_action"}

