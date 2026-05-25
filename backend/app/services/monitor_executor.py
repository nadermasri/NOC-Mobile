import ssl
import socket
import time
from datetime import datetime
from typing import Optional

import httpx
from sqlmodel import Session

from app.models.monitor import Monitor, MonitorExecution
from app.models.alert import Alert


def execute_monitor(monitor: Monitor, session: Session) -> MonitorExecution:
    start = time.time()
    status_str = "unknown"
    response_ms = None
    status_code = None
    error_msg = None
    details = {}

    for attempt in range(monitor.retry_count):
        try:
            if monitor.monitor_type == "http":
                status_str, response_ms, status_code, details = _check_http(
                    monitor.target, monitor.timeout_seconds, monitor.config
                )
            elif monitor.monitor_type == "tcp":
                status_str, response_ms, details = _check_tcp(
                    monitor.target, monitor.timeout_seconds, monitor.config
                )
            elif monitor.monitor_type == "tls":
                status_str, response_ms, details = _check_tls(
                    monitor.target, monitor.timeout_seconds
                )
            elif monitor.monitor_type == "dns":
                status_str, response_ms, details = _check_dns(
                    monitor.target, monitor.config
                )
            elif monitor.monitor_type == "ip_change":
                status_str, response_ms, details = _check_ip_change(
                    monitor.config
                )

            if status_str == "up":
                break
            error_msg = details.get("error")
        except Exception as e:
            status_str = "down"
            error_msg = str(e)
            response_ms = int((time.time() - start) * 1000)

    execution = MonitorExecution(
        monitor_id=monitor.id,
        status=status_str,
        response_ms=response_ms,
        status_code=status_code,
        error=error_msg,
        details=details,
    )
    session.add(execution)

    previous_status = monitor.last_status
    monitor.last_status = status_str
    monitor.last_checked_at = datetime.utcnow()
    monitor.last_response_ms = response_ms
    monitor.total_checks += 1
    if status_str != "up":
        monitor.total_failures += 1
    if monitor.total_checks > 0:
        monitor.uptime_percentage = round(
            (1 - monitor.total_failures / monitor.total_checks) * 100, 2
        )

    _maybe_generate_alert(monitor, previous_status, status_str, details, session)

    session.add(monitor)
    session.commit()
    return execution


def _check_http(target: str, timeout: int, config: dict):
    url = target if target.startswith("http") else f"https://{target}"
    expected_status = config.get("expected_status", 200)

    start = time.time()
    with httpx.Client(timeout=timeout, follow_redirects=True, verify=True) as client:
        resp = client.get(url)
    elapsed = int((time.time() - start) * 1000)

    is_up = resp.status_code == expected_status
    return (
        "up" if is_up else "degraded",
        elapsed,
        resp.status_code,
        {
            "status_code": resp.status_code,
            "expected_status": expected_status,
            "response_ms": elapsed,
        },
    )


def _check_tcp(target: str, timeout: int, config: dict):
    port = config.get("port", 443)
    host = target.split(":")[0] if ":" in target else target

    start = time.time()
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(timeout)
    try:
        result = sock.connect_ex((host, port))
        elapsed = int((time.time() - start) * 1000)
        is_up = result == 0
        return (
            "up" if is_up else "down",
            elapsed,
            {"port": port, "open": is_up},
        )
    finally:
        sock.close()


def _check_tls(target: str, timeout: int):
    host = target.split(":")[0] if ":" in target else target

    start = time.time()
    context = ssl.create_default_context()
    with socket.create_connection((host, 443), timeout=timeout) as sock:
        with context.wrap_socket(sock, server_hostname=host) as ssock:
            cert = ssock.getpeercert()
    elapsed = int((time.time() - start) * 1000)

    not_after = cert.get("notAfter", "")
    if not_after:
        from email.utils import parsedate_to_datetime
        expiry = parsedate_to_datetime(not_after)
        days_remaining = (expiry - datetime.now(expiry.tzinfo)).days
    else:
        days_remaining = -1

    status_str = "up"
    if days_remaining < 0:
        status_str = "down"
    elif days_remaining < 14:
        status_str = "degraded"

    return (
        status_str,
        elapsed,
        {
            "days_remaining": days_remaining,
            "not_after": not_after,
            "issuer": dict(x[0] for x in cert.get("issuer", [])),
            "subject": dict(x[0] for x in cert.get("subject", [])),
        },
    )


def _check_dns(target: str, config: dict):
    import socket as _socket

    expected_ip = config.get("expected_ip")

    start = time.time()
    try:
        addresses = _socket.getaddrinfo(target, None)
        elapsed = int((time.time() - start) * 1000)
        ips = list({addr[4][0] for addr in addresses})

        if expected_ip and expected_ip not in ips:
            return "degraded", elapsed, {
                "resolved": ips,
                "expected": expected_ip,
                "error": "DNS record changed",
            }

        return "up", elapsed, {"resolved": ips}
    except _socket.gaierror as e:
        elapsed = int((time.time() - start) * 1000)
        return "down", elapsed, {"error": str(e)}


def _check_ip_change(config: dict):
    known_ip = config.get("known_ip")

    start = time.time()
    with httpx.Client(timeout=10) as client:
        resp = client.get("https://api.ipify.org?format=json")
    elapsed = int((time.time() - start) * 1000)

    current_ip = resp.json().get("ip")
    if known_ip and current_ip != known_ip:
        return "degraded", elapsed, {
            "current_ip": current_ip,
            "known_ip": known_ip,
            "changed": True,
        }

    return "up", elapsed, {"current_ip": current_ip, "changed": False}


def _maybe_generate_alert(
    monitor: Monitor,
    previous_status: str,
    current_status: str,
    details: dict,
    session: Session,
):
    if previous_status == "up" and current_status in ("down", "degraded"):
        alert = Alert(
            user_id=monitor.user_id,
            monitor_id=monitor.id,
            alert_type=f"monitor_{current_status}",
            severity="critical" if current_status == "down" else "warning",
            title=f"{monitor.name} is {current_status}",
            message=f"Monitor '{monitor.name}' ({monitor.target}) changed from {previous_status} to {current_status}.",
            details=details,
        )
        session.add(alert)

    elif previous_status in ("down", "degraded") and current_status == "up":
        alert = Alert(
            user_id=monitor.user_id,
            monitor_id=monitor.id,
            alert_type="monitor_recovered",
            severity="info",
            title=f"{monitor.name} recovered",
            message=f"Monitor '{monitor.name}' ({monitor.target}) is back up.",
            details=details,
        )
        session.add(alert)

    if monitor.monitor_type == "tls":
        days = details.get("days_remaining", 999)
        if isinstance(days, int) and 0 < days < 14:
            alert = Alert(
                user_id=monitor.user_id,
                monitor_id=monitor.id,
                alert_type="tls_expiring",
                severity="warning",
                title=f"TLS certificate expiring: {monitor.name}",
                message=f"Certificate for {monitor.target} expires in {days} days.",
                details=details,
            )
            session.add(alert)

    if monitor.monitor_type == "dns" and details.get("error") == "DNS record changed":
        alert = Alert(
            user_id=monitor.user_id,
            monitor_id=monitor.id,
            alert_type="dns_changed",
            severity="warning",
            title=f"DNS changed: {monitor.name}",
            message=f"DNS records for {monitor.target} no longer match expected value.",
            details=details,
        )
        session.add(alert)

    if monitor.monitor_type == "ip_change" and details.get("changed"):
        alert = Alert(
            user_id=monitor.user_id,
            monitor_id=monitor.id,
            alert_type="ip_changed",
            severity="info",
            title=f"Public IP changed",
            message=f"IP changed from {details.get('known_ip')} to {details.get('current_ip')}.",
            details=details,
        )
        session.add(alert)
