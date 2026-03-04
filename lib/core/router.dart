import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:passman_frontend/features/auth/auth_provider.dart';
import 'package:passman_frontend/features/auth/login_screen.dart';
import 'package:passman_frontend/features/auth/register_screen.dart';
import 'package:passman_frontend/features/vault/vault_item_screen.dart';
import 'package:passman_frontend/features/vault/vault_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/vault';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(path: '/vault', builder: (context, state) => const VaultScreen()),
      GoRoute(
        path: '/vault/add',
        builder: (context, state) => const VaultItemScreen(),
      ),
      GoRoute(
        path: '/vault/edit/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return VaultItemScreen(itemId: id);
        },
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Page not found: ${state.error}'))),
  );
});
