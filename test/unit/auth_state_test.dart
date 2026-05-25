import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_noc/core/providers/app_providers.dart';

void main() {
  group('AuthState', () {
    test('default state is not logged in', () {
      const state = AuthState();
      expect(state.isLoggedIn, false);
      expect(state.user, null);
      expect(state.isLoading, false);
    });

    test('plan defaults to free', () {
      const state = AuthState();
      expect(state.plan, 'free');
    });

    test('plan returns user plan when set', () {
      const state = AuthState(
        isLoggedIn: true,
        user: {'plan': 'pro', 'email': 'a@b.com', 'display_name': 'Test'},
      );
      expect(state.plan, 'pro');
    });

    test('displayName returns empty when not set', () {
      const state = AuthState();
      expect(state.displayName, '');
    });

    test('displayName returns value when set', () {
      const state = AuthState(
        isLoggedIn: true,
        user: {'display_name': 'Nader', 'email': 'a@b.com', 'plan': 'free'},
      );
      expect(state.displayName, 'Nader');
    });

    test('email returns empty when not logged in', () {
      const state = AuthState();
      expect(state.email, '');
    });

    test('copyWith preserves fields', () {
      const original = AuthState(
        isLoggedIn: true,
        user: {'email': 'a@b.com', 'plan': 'free', 'display_name': 'Test'},
      );
      final copy = original.copyWith(isLoading: true);
      expect(copy.isLoggedIn, true);
      expect(copy.isLoading, true);
      expect(copy.user, isNotNull);
    });

    test('copyWith can change login status', () {
      const original = AuthState(isLoggedIn: true);
      final copy = original.copyWith(isLoggedIn: false);
      expect(copy.isLoggedIn, false);
    });
  });
}
