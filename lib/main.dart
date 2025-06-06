import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:local_loop/firebase_options.dart';
import 'package:local_loop/screens/ngo/create_event_screen.dart';
import 'package:local_loop/screens/ngo/event_details_screen.dart';
import 'package:local_loop/screens/ngo/ngo_events.dart';
import 'package:local_loop/screens/volunteer/volunteer_events.dart';
import 'package:local_loop/screens/volunteer/volunteer_profile.dart';
import 'package:local_loop/screens/volunteer/volunteer_schedule.dart';
import 'package:local_loop/services/event_service.dart';
import 'package:provider/provider.dart';

import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/verify_email_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/admin/admin_screen.dart';
import 'screens/ngo/ngo_screen.dart';
import 'screens/volunteer/volunteer_screen.dart';
import 'widgets/custom_loading_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => EventService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LocalLoop',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF4CAF50),
          primary: Color(0xFF4CAF50),
          secondary: Color(0xFF66BB6A),
        ),
        useMaterial3: true,
        fontFamily: 'Poppins',
      ),
      home: AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/verify-email': (context) => const VerifyEmailScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/admin': (context) => const AdminScreen(),
        '/ngo': (context) => const NgoScreen(),
        '/volunteer': (context) => const VolunteerScreen(),
        '/volunteer/events': (context) => const VolunteerEvents(),
        '/volunteer/schedule': (context) => const VolunteerSchedule(),
        '/volunteer/profile': (context) => const VolunteerProfile(),
        '/ngo/events': (context) => const NgoEventsScreen(),
        '/ngo/create-event': (context) => const CreateEventScreen(),
        '/ngo/event-details': (context) {
          final eventId = ModalRoute.of(context)?.settings.arguments as String?;
          if (eventId == null) {
            // navigate back
            return const NgoEventsScreen();
          }
          return EventDetailsScreen(eventId: eventId);
        },
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.initializeUser();

    setState(() {
      _isInitializing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: CustomLoadingWidget(message: 'Initializing LocalLoop...'),
      );
    }

    return Consumer<AuthService>(
      builder: (context, authService, child) {
        return StreamBuilder<User?>(
          stream: authService.authStateChanges,
          builder: (context, snapshot) {
            // Show loading while checking authentication state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                backgroundColor: Colors.white,
                body: CustomLoadingWidget(
                  message: 'Checking authentication...',
                ),
              );
            }

            final user = snapshot.data;

            // User not logged in
            if (user == null) {
              return const LoginScreen();
            }

            // User logged in but email not verified
            if (!user.emailVerified) {
              return const VerifyEmailScreen();
            }

            // User logged in and verified - route based on role
            return RoleBasedRouter(authService: authService);
          },
        );
      },
    );
  }
}

class RoleBasedRouter extends StatelessWidget {
  final AuthService authService;

  const RoleBasedRouter({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    final userModel = authService.userModel;

    // If user model is not loaded yet, show loading
    if (userModel == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: CustomLoadingWidget(message: 'Loading user profile...'),
      );
    }

    // Route based on user role
    switch (userModel.role) {
      case 'admin':
        return const AdminScreen();
      case 'ngo':
        return const NgoScreen();
      case 'volunteer':
      default:
        return const VolunteerScreen();
    }
  }
}
