import logging

logger = logging.getLogger(__name__)

class NotificationService:
    @staticmethod
    def send_push_notification(user_id: str, title: str, message: str, payload: dict):
        # Mask sensitive user identifiers and payload contents in logs
        masked_user = f"{user_id[:6]}***" if len(user_id) > 6 else "***"
        logger.info(f"[PUSH NOTIFICATION] Dispatched to user {masked_user} | type={payload.get('type', 'alert')}")
        return True
