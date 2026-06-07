import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/pages/login_screen.dart';
import '../../features/auth/presentation/pages/splash_screen.dart';
import '../../features/auth/presentation/pages/register_screen.dart';
import '../../features/auth/presentation/pages/forgot_password_screen.dart';
import '../presentation/pages/main_navigation_screen.dart';
import '../../features/course/presentation/pages/dashboard_screen.dart';
import '../../features/course/presentation/pages/course_detail_screen.dart';
import '../../features/course/presentation/pages/ide_screen.dart';
import '../../features/course/presentation/pages/quiz_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const MainNavigationScreen(),
      ),
      GoRoute(
        path: '/courses/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return CourseDetailScreen(courseId: id);
        },
      ),
      GoRoute(
        path: '/ide/:lessonId',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['lessonId']!);
          return IdeScreen(lessonId: id);
        },
      ),
      GoRoute(
        path: '/quiz/:lessonId',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['lessonId']!);
          return QuizScreen(lessonId: id);
        },
      ),
    ],
  );
});
