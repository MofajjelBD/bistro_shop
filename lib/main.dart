import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

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
  await Firebase.initializeApp();

  // Set your Stripe publishable key here (replace with your actual key)
  Stripe.publishableKey =
      'pk_test_51RUKu4IDHiKdAOQ6yHmb7b70UWILHsnQp3kWLfR5DT8xCkeFLDw3XOnD4zo0yDsimI2i50Sm0p1wzEYzivHtXRnh005hITfUFc';

  Stripe.merchantIdentifier = 'merchant.flutter.stripe.test';
  Stripe.urlScheme = 'flutterstripe';
  await Stripe.instance.applySettings();
  // try {
  //   // Your Stripe initialization code here
  //   await Stripe.instance.applySettings(); // or whatever your init call is
  //   print('Stripe initialized successfully');
  // } catch (e, stacktrace) {
  //   print('⚠️ Stripe initialization failed: $e');
  //   print('Stack trace: $stacktrace');
  // }

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
