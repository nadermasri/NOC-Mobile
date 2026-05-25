"""Tests for the auth service pure functions.

These tests only test password hashing, token creation/decoding,
and entitlement logic. They don't require a database connection.
"""
import os
import pytest

# Set a dummy DATABASE_URL before importing anything that touches the database module
os.environ.setdefault("DATABASE_URL", "sqlite:///test.db")

from app.services.auth import (
    hash_password,
    verify_password,
    create_access_token,
    create_refresh_token,
    decode_token,
    get_plan_limits,
    check_entitlement,
    PLAN_LIMITS,
)


class TestPasswordHashing:
    def test_hash_and_verify(self):
        password = "test-password-123"
        hashed = hash_password(password)
        assert hashed != password
        assert verify_password(password, hashed) is True

    def test_wrong_password_fails(self):
        hashed = hash_password("correct-password")
        assert verify_password("wrong-password", hashed) is False

    def test_different_hashes_for_same_password(self):
        password = "test-password"
        h1 = hash_password(password)
        h2 = hash_password(password)
        assert h1 != h2  # bcrypt uses random salt


class TestTokens:
    def test_access_token_roundtrip(self):
        token = create_access_token(42)
        payload = decode_token(token)
        assert payload is not None
        assert payload["sub"] == "42"
        assert payload["type"] == "access"

    def test_refresh_token_roundtrip(self):
        token = create_refresh_token(99)
        payload = decode_token(token)
        assert payload is not None
        assert payload["sub"] == "99"
        assert payload["type"] == "refresh"

    def test_invalid_token_returns_none(self):
        assert decode_token("invalid.token.here") is None

    def test_empty_token_returns_none(self):
        assert decode_token("") is None


class TestPlanLimits:
    def test_free_plan_limits(self):
        limits = get_plan_limits("free")
        assert limits["max_targets"] == 3
        assert limits["max_monitors"] == 3
        assert limits["max_history"] == 50
        assert limits["max_ai_explains_daily"] == 5
        assert limits["pdf_export"] is False

    def test_pro_plan_limits(self):
        limits = get_plan_limits("pro")
        assert limits["max_targets"] == -1
        assert limits["max_monitors"] == -1
        assert limits["pdf_export"] is True

    def test_unknown_plan_defaults_to_free(self):
        limits = get_plan_limits("enterprise")
        assert limits == PLAN_LIMITS["free"]


class TestEntitlements:
    def test_free_under_limit(self):
        class MockUser:
            plan = "free"
        assert check_entitlement(MockUser(), "max_monitors", 2) is True

    def test_free_at_limit(self):
        class MockUser:
            plan = "free"
        assert check_entitlement(MockUser(), "max_monitors", 3) is False

    def test_pro_unlimited(self):
        class MockUser:
            plan = "pro"
        assert check_entitlement(MockUser(), "max_monitors", 999) is True

    def test_boolean_feature_free(self):
        class MockUser:
            plan = "free"
        assert check_entitlement(MockUser(), "pdf_export") is False

    def test_boolean_feature_pro(self):
        class MockUser:
            plan = "pro"
        assert check_entitlement(MockUser(), "pdf_export") is True

    def test_none_user_defaults_to_free(self):
        assert check_entitlement(None, "max_monitors", 2) is True
        assert check_entitlement(None, "max_monitors", 3) is False
