import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Page imports
import 'pages/login_page.dart';
import 'pages/sign_up_page.dart';
import 'pages/users_page.dart';
import 'pages/home_page.dart';
import 'pages/add_item_page.dart';
import 'pages/manage_item_page.dart';
import 'pages/cart_page.dart';
import 'pages/payment_history_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp();

  // Set your Stripe publishable key here (replace with your actual key)
  Stripe.publishableKey = dotenv.env['VITE_Payment_Gateway_SK'] ?? '';

  Stripe.merchantIdentifier = 'merchant.flutter.stripe.test';
  Stripe.urlScheme = 'flutterstripe';
  await Stripe.instance.applySettings();

  runApp(const BistroBossApp());
}

class BistroBossApp extends StatelessWidget {
  const BistroBossApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bistro Shop',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal.shade600,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFDFBF9),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal.shade600,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      initialRoute: '/home', // 👈 Launch app directly to Home
      routes: {
        '/login': (context) => LoginPage(),
        '/signup': (context) => SignUpPage(),
        '/users': (context) => const UsersPage(),
        '/home': (context) => HomePage(),
        '/add-item': (context) => const AddItemPage(),
        '/manage-items': (context) => const ManageItemPage(),
        '/cart': (context) => const CartPage(),
        '/payment-history': (context) => const PaymentHistoryPage(),
      },
    );
  }
}
