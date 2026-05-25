"""Tests for the AI explanation service."""
import pytest
from app.services.ai_explain import explain_diagnostic


class TestPingExplanation:
    def test_ping_success(self):
        result = explain_diagnostic({
            "type": "ping",
            "target": "example.com",
            "result": {"success": True, "avg": "25", "packetLoss": "0"},
        })
        assert result["success"] is True
        assert "succeeded" in result["explanation"]
        assert result["severity"] == "ok"

    def test_ping_failure(self):
        result = explain_diagnostic({
            "type": "ping",
            "target": "dead.host",
            "result": {"success": False},
        })
        assert result["success"] is True
        assert "failed" in result["explanation"]
        assert result["severity"] == "critical"
        assert len(result["recommendations"]) > 0

    def test_ping_high_latency(self):
        result = explain_diagnostic({
            "type": "ping",
            "target": "slow.host",
            "result": {"success": True, "avg": "250", "packetLoss": "0"},
        })
        assert result["severity"] == "warning"
        assert "latency" in result["likelyCause"].lower()

    def test_ping_packet_loss(self):
        result = explain_diagnostic({
            "type": "ping",
            "target": "lossy.host",
            "result": {"success": True, "avg": "50", "packetLoss": "10"},
        })
        assert "Packet loss" in result["nextSteps"]


class TestDnsExplanation:
    def test_dns_success(self):
        result = explain_diagnostic({
            "type": "dns",
            "target": "example.com",
            "result": {"success": True, "records": [{"type": "A", "value": "93.184.216.34"}]},
        })
        assert result["severity"] == "ok"
        assert "1 record" in result["explanation"]

    def test_dns_failure(self):
        result = explain_diagnostic({
            "type": "dns",
            "target": "nonexistent.invalid",
            "result": {"success": False},
        })
        assert result["severity"] == "critical"
        assert "failed" in result["explanation"]


class TestPortExplanation:
    def test_port_open(self):
        result = explain_diagnostic({
            "type": "port",
            "target": "example.com",
            "result": {"open": True, "port": 443},
        })
        assert result["severity"] == "ok"
        assert "open" in result["explanation"]

    def test_port_closed(self):
        result = explain_diagnostic({
            "type": "port",
            "target": "example.com",
            "result": {"open": False, "port": 8080},
        })
        assert result["severity"] == "critical"
        assert "closed" in result["explanation"]


class TestTlsExplanation:
    def test_tls_valid(self):
        result = explain_diagnostic({
            "type": "tls",
            "target": "example.com",
            "result": {"success": True, "daysRemaining": 90},
        })
        assert result["severity"] == "ok"
        assert "90 days" in result["explanation"]

    def test_tls_expiring_soon(self):
        result = explain_diagnostic({
            "type": "tls",
            "target": "example.com",
            "result": {"success": True, "daysRemaining": 5},
        })
        assert result["severity"] == "critical"
        assert len(result["recommendations"]) > 0

    def test_tls_expiring_warning(self):
        result = explain_diagnostic({
            "type": "tls",
            "target": "example.com",
            "result": {"success": True, "daysRemaining": 20},
        })
        assert result["severity"] == "warning"

    def test_tls_failure(self):
        result = explain_diagnostic({
            "type": "tls",
            "target": "broken.host",
            "result": {"success": False},
        })
        assert result["severity"] == "critical"


class TestHttpExplanation:
    def test_http_200(self):
        result = explain_diagnostic({
            "type": "http",
            "target": "example.com",
            "result": {"statusCode": 200},
        })
        assert result["severity"] == "ok"
        assert "normally" in result["likelyCause"]

    def test_http_500(self):
        result = explain_diagnostic({
            "type": "http",
            "target": "broken.host",
            "result": {"statusCode": 500},
        })
        assert result["severity"] == "critical"
        assert "error" in result["likelyCause"].lower()

    def test_http_404(self):
        result = explain_diagnostic({
            "type": "http",
            "target": "example.com",
            "result": {"statusCode": 404},
        })
        assert result["severity"] == "warning"


class TestTracerouteExplanation:
    def test_traceroute_clean(self):
        result = explain_diagnostic({
            "type": "traceroute",
            "target": "example.com",
            "result": {"hops": [
                {"ip": "10.0.0.1"},
                {"ip": "192.168.1.1"},
                {"ip": "93.184.216.34"},
            ]},
        })
        assert result["severity"] == "ok"
        assert "3 hop" in result["explanation"]

    def test_traceroute_with_timeouts(self):
        result = explain_diagnostic({
            "type": "traceroute",
            "target": "example.com",
            "result": {"hops": [
                {"ip": "10.0.0.1"},
                {"ip": "*"},
                {"ip": "93.184.216.34"},
            ]},
        })
        assert result["severity"] == "warning"
        assert "1 hop" in result["likelyCause"]


class TestEdgeCases:
    def test_unknown_type(self):
        result = explain_diagnostic({
            "type": "unknown",
            "target": "example.com",
            "result": {},
        })
        assert result["success"] is True
        assert result["severity"] == "info"

    def test_empty_data(self):
        result = explain_diagnostic({})
        assert result["success"] is True

    def test_response_always_has_required_fields(self):
        for diag_type in ["ping", "dns", "port", "tls", "http", "traceroute", "reverseDns", "subnet"]:
            result = explain_diagnostic({
                "type": diag_type,
                "target": "test.host",
                "result": {},
            })
            assert "explanation" in result
            assert "likelyCause" in result
            assert "nextSteps" in result
            assert "severity" in result
            assert "recommendations" in result
