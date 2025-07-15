import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'cart_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<FoodItem>> _foodItemsFuture;
  final user = FirebaseAuth.instance.currentUser;
  int cartCount = 0;
  int totalUsers = 0;

  @override
  void initState() {
    super.initState();
    _foodItemsFuture = fetchFoodItems();
    fetchCartCount();
    fetchTotalUsers();
    if (user != null) {
      Fluttertoast.showToast(
        msg: "Welcome ${user!.displayName ?? 'User'}!",
        backgroundColor: Colors.deepPurple,
        textColor: Colors.white,
      );
    }
  }

  Future<void> fetchCartCount() async {
    if (user?.email == null) return;
    final response = await http.get(Uri.parse(
        'https://bistro-boss-server-pink-tau.vercel.app/carts?email=${user!.email}'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      setState(() => cartCount = data.length);
    }
  }

  Future<void> fetchTotalUsers() async {
    final response = await http.get(
      Uri.parse('https://bistro-boss-server-pink-tau.vercel.app/users'),
    );
    if (response.statusCode == 200) {
      final List users = json.decode(response.body);
      setState(() {
        totalUsers = users.length;
      });
    }
  }

  Future<List<FoodItem>> fetchFoodItems() async {
    final response = await http
        .get(Uri.parse('https://bistro-boss-server-pink-tau.vercel.app/menu'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => FoodItem.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load food items');
    }
  }

  void _showProductModal(FoodItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                item.image,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 180,
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.broken_image, size: 40),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(item.name,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(item.recipe, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text('Price: \$${item.price}',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.green)),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.deepPurple, Colors.purpleAccent],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ElevatedButton.icon(
                icon:
                    const Icon(FontAwesomeIcons.cartPlus, color: Colors.white),
                label: const Text('Add to Cart',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  if (user?.email == null) {
                    Fluttertoast.showToast(
                        msg: 'Please log in first.',
                        backgroundColor: Colors.red);
                    return;
                  }
                  final cartItem = CartItem(
                    id: UniqueKey().toString(),
                    menuID: item.id,
                    name: item.name,
                    image: item.image,
                    price: item.price,
                    email: user!.email!,
                  );
                  addToCartBackend(cartItem);
                  Navigator.pop(context);
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> addToCartBackend(CartItem item) async {
    if (user?.email == null) return;
    final url =
        Uri.parse('https://bistro-boss-server-pink-tau.vercel.app/carts');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "menuID": item.menuID,
        "name": item.name,
        "image": item.image,
        "price": item.price,
        "email": item.email,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      fetchCartCount();
      Fluttertoast.showToast(
          msg: "Added to Cart", backgroundColor: Colors.green);
    } else {
      Fluttertoast.showToast(
          msg: "Failed to add to cart", backgroundColor: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = user != null;
    return FutureBuilder<List<FoodItem>>(
      future: _foodItemsFuture,
      builder: (context, snapshot) {
        final totalItems = snapshot.data?.length ?? 0;

        return Scaffold(
          backgroundColor: const Color(0xFFFDFBF9),
          appBar: AppBar(
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
                ),
              ),
            ),
            leading: Builder(
              builder: (context) => IconButton(
                icon: const FaIcon(FontAwesomeIcons.bars, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            title:
                const Text('🍽️ Menu', style: TextStyle(color: Colors.white)),
            actions: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(user?.displayName ?? 'Guest',
                      style: const TextStyle(color: Colors.white)),
                ),
              ),
              IconButton(
                icon: FaIcon(
                    isLoggedIn
                        ? FontAwesomeIcons.rightFromBracket
                        : FontAwesomeIcons.user,
                    color: Colors.white),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            ],
          ),
          drawer: Drawer(
            child: ListView(
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Color(0xFF6A1B9A), Color(0xFFAB47BC)]),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Bistro Shop Admin',
                          style: TextStyle(color: Colors.white, fontSize: 22)),
                      const SizedBox(height: 8),
                      Text(user?.displayName ?? "Guest",
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 16)),
                    ],
                  ),
                ),
                _buildDrawerTile(
                    FontAwesomeIcons.plus, 'Add New Item', '/add-item'),
                _buildDrawerTile(
                    FontAwesomeIcons.cartShopping, 'My Cart', '/cart'),
                _buildDrawerTile(
                    FontAwesomeIcons.table, 'Manage Items', '/manage-items'),
                _buildDrawerTile(FontAwesomeIcons.creditCard, 'Payment History',
                    '/payment-history'),
                _buildDrawerTile(FontAwesomeIcons.users, 'Users', '/users'),
              ],
            ),
          ),
          body: Column(
            children: [
              Container(
                color: Color(0xFFEDE7F6),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("🍱 Total Items: $totalItems",
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: snapshot.connectionState == ConnectionState.waiting
                    ? const Center(child: CircularProgressIndicator())
                    : snapshot.hasError
                        ? Center(child: Text('Error: ${snapshot.error}'))
                        : GridView.builder(
                            padding: const EdgeInsets.all(12.0),
                            itemCount: snapshot.data!.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.70,
                            ),
                            itemBuilder: (context, index) {
                              final item = snapshot.data![index];
                              return GestureDetector(
                                onTap: () => _showProductModal(item),
                                child: Card(
                                  elevation: 6,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                                top: Radius.circular(16)),
                                        child: Image.network(
                                          item.image,
                                          height: 120,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                            height: 120,
                                            color: Colors.grey[200],
                                            child: const Center(
                                              child: Icon(Icons.broken_image),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(item.name,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold)),
                                              Text(item.recipe,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                      fontSize: 12)),
                                              const Spacer(),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text('\$${item.price}',
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.green)),
                                                  IconButton(
                                                    icon: const FaIcon(
                                                        FontAwesomeIcons
                                                            .cartPlus,
                                                        size: 16,
                                                        color:
                                                            Colors.deepOrange),
                                                    onPressed: () {
                                                      if (user?.email == null) {
                                                        Fluttertoast.showToast(
                                                            msg:
                                                                'Please log in first.',
                                                            backgroundColor:
                                                                Colors.red);
                                                        return;
                                                      }
                                                      final cartItem = CartItem(
                                                        id: UniqueKey()
                                                            .toString(),
                                                        menuID: item.id,
                                                        name: item.name,
                                                        image: item.image,
                                                        price: item.price,
                                                        email: user!.email!,
                                                      );
                                                      addToCartBackend(
                                                          cartItem);
                                                    },
                                                  ),
                                                ],
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: Colors.transparent,
            onPressed: () {
              if (user == null) {
                Fluttertoast.showToast(
                    msg: 'Please log in to view cart.',
                    backgroundColor: Colors.red);
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartPage()),
              ).then((_) => fetchCartCount());
            },
            label: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 140, // Adjust max width to your liking
              ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.deepPurple, Colors.purpleAccent],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const FaIcon(FontAwesomeIcons.cartShopping,
                        color: Colors.white),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Cart ($cartCount)',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  ListTile _buildDrawerTile(IconData icon, String label, String route) {
    return ListTile(
      leading: FaIcon(icon, color: Colors.deepPurple),
      title: Text(label),
      onTap: () async {
        Navigator.pop(context);
        await Navigator.pushNamed(context, route);
        setState(() {
          _foodItemsFuture = fetchFoodItems();
          fetchTotalUsers();
        });
      },
    );
  }
}

// Models
class FoodItem {
  final String id;
  final String name;
  final String recipe;
  final String image;
  final double price;

  FoodItem({
    required this.id,
    required this.name,
    required this.recipe,
    required this.image,
    required this.price,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      recipe: json['recipe'] ?? '',
      image: json['image'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
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

  CartItem({
    required this.id,
    required this.menuID,
    required this.name,
    required this.image,
    required this.price,
    required this.email,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['_id'] ?? '',
      menuID: json['menuID'] ?? '',
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      email: json['email'] ?? '',
    );
  }
}
