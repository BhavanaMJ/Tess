from typing import List
from app.schemas.productivity import ProductivitySummary, ProductivityTask
from app.schemas.future import FutureSignal
from datetime import datetime, date, timedelta

class SignalExtractor:
    @staticmethod
    def extract_signals(summary: ProductivitySummary, active_tasks: List[ProductivityTask]) -> List[FutureSignal]:
        signals = []
        
        # 1. Overdue signal
        if summary.overdue > 0:
            signals.append(FutureSignal(
                name="overdue_tasks_count",
                value=summary.overdue,
                description=f"{summary.overdue} tasks are currently overdue."
            ))

        # 2. Due soon (today + this week)
        due_soon = summary.due_today + summary.due_this_week
        if due_soon > 0:
            signals.append(FutureSignal(
                name="due_soon_count",
                value=due_soon,
                description=f"{due_soon} tasks are due in the near term."
            ))
            
        # 3. Completion pace
        if summary.completed_recently > 0:
            signals.append(FutureSignal(
                name="recent_completions",
                value=summary.completed_recently,
                description=f"{summary.completed_recently} tasks were completed recently."
            ))
            
        # 4. Stalled tasks (no updates in 7 days)
        today = date.today()
        stalled_count = 0
        for task in active_tasks:
            if task.updated_at:
                updated_date = task.updated_at.date()
                if (today - updated_date).days > 7:
                    stalled_count += 1
                    
        if stalled_count > 0:
            signals.append(FutureSignal(
                name="stalled_tasks_count",
                value=stalled_count,
                description=f"{stalled_count} tasks have not been updated in over 7 days."
            ))
            
        return signals
