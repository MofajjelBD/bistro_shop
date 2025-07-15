import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/food_item.dart';
import 'add_item_page.dart';

class ManageItemPage extends StatefulWidget {
  const ManageItemPage({super.key});

  @override
  State<ManageItemPage> createState() => _ManageItemPageState();
}

class _ManageItemPageState extends State<ManageItemPage> {
  late Future<List<FoodItem>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _itemsFuture = fetchItems();
  }

  Future<List<FoodItem>> fetchItems() async {
    final response = await http.get(
      Uri.parse('https://bistro-boss-server-pink-tau.vercel.app/menu'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => FoodItem.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch items');
    }
  }

  Future<void> _deleteItem(String id) async {
    final response = await http.delete(
      Uri.parse('https://bistro-boss-server-pink-tau.vercel.app/menu/$id'),
    );
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item deleted')),
      );
      setState(() {
        _itemsFuture = fetchItems();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: FutureBuilder<List<FoodItem>>(
          future: _itemsFuture,
          builder: (context, snapshot) {
            final count = snapshot.data?.length ?? 0;
            return Text(
              '🍽 Manage Items ($count)',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            );
          },
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft,
              color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
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
      body: FutureBuilder<List<FoodItem>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final items = snapshot.data!;
          if (items.isEmpty) {
            return const Center(child: Text('No items found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: const Color(0xFFD1C4E9),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Color(0xFF6A1B9A),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item.image,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image_not_supported,
                                  size: 24, color: Colors.grey),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '\$${item.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const FaIcon(FontAwesomeIcons.penToSquare,
                            color: Colors.blue, size: 18),
                        onPressed: () async {
                          final updated = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddItemPage(item: item),
                            ),
                          );
                          if (updated == true) {
                            setState(() {
                              _itemsFuture = fetchItems();
                            });
                          }
                        },
                      ),
                      IconButton(
                        icon: const FaIcon(FontAwesomeIcons.trash,
                            color: Colors.red, size: 18),
                        onPressed: () => _deleteItem(item.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
