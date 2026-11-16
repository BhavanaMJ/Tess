import os
import re
import logging
from logging.handlers import RotatingFileHandler

class SensitiveDataMasker(logging.Formatter):
    """Masks sensitive authentication tokens, passwords, and API keys from logs."""

    PATTERNS = [
        (re.compile(r"(Bearer\s+)[A-Za-z0-9\-\._~\+\/]+=*", re.IGNORECASE), r"\1[MASKED_TOKEN]"),
        (re.compile(r"('?(?:api_key|password|secret|token|credential_reference)'?\s*[:=]\s*'?)([A-Za-z0-9]{4})[^'\"\s]+('?)", re.IGNORECASE), r"\1\2****\3"),
        (re.compile(r"(apikey:)[A-Za-z0-9_-]+", re.IGNORECASE), r"\1[MASKED]"),
    ]

    def format(self, record: logging.LogRecord) -> str:
        orig = super().format(record)
        for pattern, replacement in self.PATTERNS:
            orig = pattern.sub(replacement, orig)
        return orig

def setup_logging(log_dir: str = "logs", log_filename: str = "tess_backend.log") -> None:
    os.makedirs(log_dir, exist_ok=True)
    log_path = os.path.join(log_dir, log_filename)

    formatter = SensitiveDataMasker(
        "%(asctime)s [%(levelname)s] %(name)s: %(message)s"
    )

    root_logger = logging.getLogger()
    root_logger.setLevel(logging.INFO)

    # Avoid adding duplicate handlers on re-entry
    if not any(isinstance(h, RotatingFileHandler) for h in root_logger.handlers):
        file_handler = RotatingFileHandler(
            log_path, maxBytes=10 * 1024 * 1024, backupCount=5, encoding="utf-8"
        )
        file_handler.setFormatter(formatter)
        file_handler.setLevel(logging.INFO)
        root_logger.addHandler(file_handler)

    if not any(isinstance(h, logging.StreamHandler) and not isinstance(h, RotatingFileHandler) for h in root_logger.handlers):
        console_handler = logging.StreamHandler()
        console_handler.setFormatter(formatter)
        console_handler.setLevel(logging.INFO)
        root_logger.addHandler(console_handler)

