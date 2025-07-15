import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  late Future<List<UserItem>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = fetchUsers();
  }

  Future<List<UserItem>> fetchUsers() async {
    final response = await http
        .get(Uri.parse('https://bistro-boss-server-pink-tau.vercel.app/users'));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => UserItem.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load users');
    }
  }

  Future<void> updateRole(String id, bool makeAdmin) async {
    final url = Uri.parse(
        'https://bistro-boss-server-pink-tau.vercel.app/users/admin/$id');
    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'makeAdmin': makeAdmin}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to ${makeAdmin ? 'make' : 'remove'} admin');
    }
  }

  Future<void> deleteUserAccount(String id, String email) async {
    await http.delete(Uri.parse(
        'https://bistro-boss-server-pink-tau.vercel.app/carts?email=$email'));
    final response = await http.delete(
        Uri.parse('https://bistro-boss-server-pink-tau.vercel.app/users/$id'));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete user');
    }
  }

  void _onMakeRemoveAdmin(UserItem u, bool makeAdmin) async {
    try {
      await updateRole(u.id, makeAdmin);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'User "${u.name}" is now ${makeAdmin ? 'an Admin' : 'not an Admin'}'),
      ));
      setState(() {
        _usersFuture = fetchUsers();
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _onDeleteUser(UserItem user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
            'Are you sure you want to delete "${user.name}" and their data?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await deleteUserAccount(user.id, user.email);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User "${user.name}" deleted')),
        );
        setState(() {
          _usersFuture = fetchUsers();
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft,
              color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '👥 Manage Users',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
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
      body: FutureBuilder<List<UserItem>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final users = snapshot.data!;
          return Column(
            children: [
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                color: const Color(0xFFEDE7F6),
                child: Text('Total Users: ${users.length}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final u = users[index];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      shadowColor: Colors.deepPurple.withOpacity(0.3),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: const Color(0xFFD1C4E9),
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF6A1B9A)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        u.name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        u.email,
                                        style: TextStyle(
                                            color: Colors.grey.shade700),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton.icon(
                                  icon: FaIcon(
                                    u.isAdmin
                                        ? FontAwesomeIcons.userMinus
                                        : FontAwesomeIcons.userShield,
                                    size: 14,
                                  ),
                                  label: Text(u.isAdmin
                                      ? 'Remove Admin'
                                      : 'Make Admin'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: u.isAdmin
                                        ? Colors.grey
                                        : const Color(0xFFAB47BC),
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () =>
                                      _onMakeRemoveAdmin(u, !u.isAdmin),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                  ),
                                  onPressed: () => _onDeleteUser(u),
                                  child: const FaIcon(FontAwesomeIcons.trash),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class UserItem {
  final String id, name, email;
  final bool isAdmin;

  UserItem({
    required this.id,
    required this.name,
    required this.email,
    required this.isAdmin,
  });

  factory UserItem.fromJson(Map<String, dynamic> json) {
    return UserItem(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      isAdmin: json['role'] == 'admin',
    );
  }
}
