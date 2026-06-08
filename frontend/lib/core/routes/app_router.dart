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
import '../../features/course/presentation/pages/course_player_screen.dart';
import '../../features/course/presentation/pages/ide_screen.dart';
import '../../features/course/presentation/pages/quiz_screen.dart';
import '../../features/profile/presentation/pages/settings_screen.dart';
import '../../features/profile/presentation/pages/security_logs_screen.dart';
import '../../features/creator/presentation/pages/group_management_screen.dart';
import '../../features/creator/presentation/pages/quiz_builder_screen.dart';
import '../../features/creator/presentation/pages/creator_enrollment_tracking_screen.dart';
import '../../features/creator/presentation/pages/curriculum_builder_screen.dart';
import '../../features/creator/presentation/pages/course_editor_screen.dart';

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
        path: '/courses/:courseId/learn/:lessonId',
        builder: (context, state) {
          final courseId = int.parse(state.pathParameters['courseId']!);
          final lessonId = int.parse(state.pathParameters['lessonId']!);
          return CoursePlayerScreen(courseId: courseId, lessonId: lessonId);
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
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/security-logs',
        builder: (context, state) => const SecurityLogsScreen(),
      ),
      GoRoute(
        path: '/creator/groups',
        builder: (context, state) => const GroupManagementScreen(),
      ),
      GoRoute(
        path: '/creator/course/new',
        builder: (context, state) => const CurriculumBuilderScreen(),
      ),
      GoRoute(
        path: '/creator/course/:id/edit',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return CourseEditorScreen(courseId: id);
        },
      ),
      GoRoute(
        path: '/creator/quiz_builder/:lessonId',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['lessonId']!);
          return QuizBuilderScreen(lessonId: id);
        },
      ),
      GoRoute(
        path: '/creator/enrollments',
        builder: (context, state) => const CreatorEnrollmentTrackingScreen(),
      ),
    ],
  );
});
