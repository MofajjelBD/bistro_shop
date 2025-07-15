import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> with TickerProviderStateMixin {
  final user = FirebaseAuth.instance.currentUser;
  late Future<List<CartItem>> _cartItemsFuture;
  List<CartItem> _cartItems = [];

  @override
  void initState() {
    super.initState();
    _cartItemsFuture = fetchCartItems();
  }

  Future<List<CartItem>> fetchCartItems() async {
    if (user == null || user!.email == null) return [];
    final response = await http.get(Uri.parse(
        'https://bistro-boss-server-pink-tau.vercel.app/carts?email=${user!.email}'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      _cartItems = data.map((e) => CartItem.fromJson(e)).toList();
      return _cartItems;
    } else {
      throw Exception('Failed to load cart');
    }
  }

  Future<void> deleteCartItem(String id) async {
    final response = await http.delete(
      Uri.parse('https://bistro-boss-server-pink-tau.vercel.app/carts/$id'),
    );
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item deleted')),
      );
      setState(() {
        _cartItems.removeWhere((item) => item.id == id);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete item')),
      );
    }
  }

  Future<void> clearCart() async {
    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Are you sure you want to clear the cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final response = await http.delete(Uri.parse(
      'https://bistro-boss-server-pink-tau.vercel.app/carts?email=${user!.email}',
    ));

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart cleared')),
      );
      setState(() {
        _cartItems.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to clear cart')),
      );
    }
  }

  double calculateTotal() {
    return _cartItems.fold(0, (sum, item) => sum + item.price * item.quantity);
  }

  Future<void> handlePayment(double amountInUSD) async {
    try {
      final response = await http.post(
        Uri.parse(
            'https://bistro-boss-server-pink-tau.vercel.app/create-payment-intent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'price': amountInUSD}),
      );

      final jsonResponse = jsonDecode(response.body);
      final clientSecret = jsonResponse['clientSecret'];

      await stripe.Stripe.instance.initPaymentSheet(
        paymentSheetParameters: stripe.SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Bistro Shop',
        ),
      );

      await stripe.Stripe.instance.presentPaymentSheet();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Payment successful')),
      );
      setState(() {
        _cartItems.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Payment error: $e')),
      );
    }
  }

  void increaseQuantity(int index) {
    setState(() {
      _cartItems[index].quantity++;
    });
  }

  void decreaseQuantity(int index) {
    setState(() {
      if (_cartItems[index].quantity > 1) {
        _cartItems[index].quantity--;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          '🛒 Your Cart',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft,
              color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.trashCan,
                color: Colors.white, size: 18),
            tooltip: 'Clear Cart',
            onPressed: clearCart,
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<CartItem>>(
        future: _cartItemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (_cartItems.isEmpty) {
            return const Center(
                child: Text(
              "🛒 Your cart is empty.",
              style: TextStyle(fontSize: 18),
            ));
          }

          final totalPrice = calculateTotal();

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _cartItems.length,
                  itemBuilder: (context, index) {
                    final item = _cartItems[index];
                    return AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: Card(
                        elevation: 5,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        shadowColor: Colors.deepPurple.withOpacity(0.15),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  width: 70,
                                  height: 70,
                                  child: item.image.isEmpty
                                      ? Container(
                                          color: Colors.grey.shade300,
                                        )
                                      : Image.network(
                                          item.image,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '\$${item.price.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        _quantityButton(
                                            icon: FontAwesomeIcons.minus,
                                            onPressed: () =>
                                                decreaseQuantity(index),
                                            size: 26),
                                        Container(
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 12),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEDE7F6),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '${item.quantity}',
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF6A1B9A)),
                                          ),
                                        ),
                                        _quantityButton(
                                            icon: FontAwesomeIcons.plus,
                                            onPressed: () =>
                                                increaseQuantity(index),
                                            size: 26),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const FaIcon(FontAwesomeIcons.trash,
                                    color: Colors.redAccent, size: 22),
                                onPressed: () => deleteCartItem(item.id),
                                tooltip: 'Remove item',
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, -3),
                    ),
                  ],
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '\$${totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6A1B9A)),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      icon: const FaIcon(FontAwesomeIcons.creditCard, size: 18),
                      label: const Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        child: Text(
                          'Checkout',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6A1B9A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => handlePayment(totalPrice),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _quantityButton({
    required IconData icon,
    required VoidCallback onPressed,
    double size = 32,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFF6A1B9A),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withOpacity(0.3),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: FaIcon(
            icon,
            color: Colors.white,
            size: size * 0.55,
          ),
        ),
      ),
    );
  }
}

class CartItem {
  final String id;
  final String menuID;
  final String name;
  final String image;
  final double price;
  final String email;
  int quantity;

  CartItem({
    required this.id,
    required this.menuID,
    required this.name,
    required this.image,
    required this.price,
    required this.email,
    this.quantity = 1,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['_id'],
      menuID: json['menuID'],
      name: json['name'],
      image: json['image'] ?? '',
      price: (json['price'] as num).toDouble(),
      email: json['email'],
      quantity: json['quantity'] != null ? json['quantity'] as int : 1,
    );
  }
}
