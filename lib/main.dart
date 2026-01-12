import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'theme.dart';
import 'auth/login_screen.dart';
import 'auth/signup_screen.dart';
import 'home/main_navigation.dart';
import 'home/offer_ride_screen.dart';
import 'home/find_ride_screen.dart';
import 'home/ride_details_screen.dart';
import 'home/my_rides_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/payment_method_screen.dart';
import 'screens/payment_form_screen.dart';
import 'screens/chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// ✅ Init Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize security provider after Firebase
    await ensureSecurityProvider();
  } catch (e) {
    // Firebase initialization failed
  }

  runApp(const MyApp());
}

/// ✅ Security provider initialization
Future<void> ensureSecurityProvider() async {
  try {
    await FirebaseAppCheck.instance.activate();
    print("✅ Security provider initialized");
  } catch (e) {
    debugPrint('⚠️ Security provider initialization skipped: $e');
  }
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      initialRoute: "/splash",
      routes: {
        "/splash": (context) => const SplashScreen(),
        "/onboarding": (context) => const OnboardingScreen(),
        "/login": (context) => const LoginScreen(),
        "/signup": (context) => const SignupScreen(),
        "/home": (context) => const MainNavigation(),
        "/offer-ride": (context) => const OfferRideScreen(),
        "/find-ride": (context) => const FindRideScreen(),
        "/my-rides": (context) => const MyRidesScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/ride-details') {
          final rideId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => RideDetailsScreen(rideId: rideId),
          );
        } else if (settings.name == '/payment') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => PaymentScreen(
              rideId: args['rideId'],
              seatsBooked: args['seatsBooked'],
              amount: args['amount'],
              pickupLocation: args['pickupLocation'] ?? '',
            ),
          );
        } else if (settings.name == '/payment-method') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => PaymentMethodScreen(
              rideId: args['rideId'],
              seatsBooked: args['seatsBooked'],
              amount: args['amount'],
              pickupLocation: args['pickupLocation'] ?? '',
            ),
          );
        } else if (settings.name == '/payment-form') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => PaymentFormScreen(
              rideId: args['rideId'],
              seatsBooked: args['seatsBooked'],
              rideAmount: args['rideAmount'],
              appFee: args['appFee'],
              totalAmount: args['totalAmount'],
              pickupLocation: args['pickupLocation'] ?? '',
              paymentMethod: args['paymentMethod'],
            ),
          );
        } else if (settings.name == '/chat') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => ChatScreen(
              otherUserId: args['otherUserId'],
              otherUserName: args['otherUserName'],
            ),
          );
        }
        return null;
      },
    );
  }
}
