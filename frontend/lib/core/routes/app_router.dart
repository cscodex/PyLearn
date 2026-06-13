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
import '../../features/profile/presentation/pages/profile_screen.dart';
import '../../features/profile/presentation/pages/badges_achievements_screen.dart';
import '../../features/profile/presentation/pages/learning_history_screen.dart';
import '../../features/creator/presentation/pages/group_management_screen.dart';
import '../../features/creator/presentation/pages/quiz_builder_screen.dart';
import '../../features/creator/presentation/pages/creator_enrollment_tracking_screen.dart';
import '../../features/creator/presentation/pages/curriculum_builder_screen.dart';
import '../../features/creator/presentation/pages/course_editor_screen.dart';
import '../../features/creator/presentation/pages/code_challenge_builder_screen.dart';
import '../../features/creator/presentation/pages/student_programs_screen.dart';
import '../../features/course/presentation/providers/saved_programs_provider.dart';
import '../../features/profile/presentation/pages/certificates_screen.dart';
import '../../features/creator/presentation/pages/student_certificates_screen.dart';
import '../../features/creator/presentation/pages/creator_student_programs_screen.dart';

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
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/ide',
        builder: (context, state) {
          final program = state.extra as SavedProgram?;
          return IdeScreen(initialSavedProgram: program);
        },
      ),
      GoRoute(
        path: '/profile/badges',
        builder: (context, state) => const BadgesAchievementsScreen(),
      ),
      GoRoute(
        path: '/profile/history',
        builder: (context, state) => const LearningHistoryScreen(),
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
          return QuizBuilderScreen(key: ValueKey('quiz_$id'), lessonId: id);
        },
      ),
      GoRoute(
        path: '/creator/code_builder/:lessonId',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['lessonId']!);
          return CodeChallengeBuilderScreen(key: ValueKey('code_$id'), lessonId: id);
        },
      ),
      GoRoute(
        path: '/creator/enrollments',
        builder: (context, state) => const CreatorEnrollmentTrackingScreen(),
      ),
      GoRoute(
        path: '/profile/certificates',
        builder: (context, state) => const CertificatesScreen(),
      ),
      GoRoute(
        path: '/creator/student-certificates',
        builder: (context, state) => const StudentCertificatesScreen(),
      ),
      GoRoute(
        path: '/creator/student-programs',
        builder: (context, state) => const CreatorStudentProgramsScreen(),
      ),
    ],
  );
});
