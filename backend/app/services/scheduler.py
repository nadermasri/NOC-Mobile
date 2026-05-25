from apscheduler.schedulers.background import BackgroundScheduler
from sqlmodel import Session, select

from app.database import engine
from app.models.monitor import Monitor
from app.services.monitor_executor import execute_monitor

scheduler = BackgroundScheduler()


def run_monitors():
    with Session(engine) as session:
        monitors = session.exec(
            select(Monitor).where(Monitor.enabled == True)
        ).all()

        for monitor in monitors:
            try:
                execute_monitor(monitor, session)
            except Exception:
                pass


def start_scheduler():
    scheduler.add_job(run_monitors, "interval", seconds=60, id="monitor_runner", replace_existing=True)
    scheduler.start()


def stop_scheduler():
    scheduler.shutdown(wait=False)
