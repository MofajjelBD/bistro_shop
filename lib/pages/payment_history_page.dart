import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PaymentHistoryPage extends StatefulWidget {
  const PaymentHistoryPage({super.key});

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  late Future<List<Payment>> _paymentsFuture;

  @override
  void initState() {
    super.initState();
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email != null) {
      _paymentsFuture = fetchPayments(email);
    }
  }

  Future<List<Payment>> fetchPayments(String email) async {
    final response = await http.get(
      Uri.parse(
          'https://bistro-boss-server-pink-tau.vercel.app/paymentHistory/$email'),
    );

    if (response.statusCode == 200 || response.statusCode == 403) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => Payment.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load payment history');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          '💳 Payment History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const FaIcon(
            FontAwesomeIcons.arrowLeft,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () => Navigator.of(context).pop(),
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
      body: FutureBuilder<List<Payment>>(
        future: _paymentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final payments = snapshot.data ?? [];

          if (payments.isEmpty) {
            return const Center(
              child: Text(
                'No payment history found.',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                color: const Color(0xFFEDE7F6),
                child: Text(
                  'Total Transactions: ${payments.length}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    final p = payments[index];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      shadowColor: Colors.deepPurple.withOpacity(0.3),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(8),
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFFD1C4E9),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6A1B9A),
                            ),
                          ),
                        ),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const FaIcon(FontAwesomeIcons.moneyCheckDollar,
                                    size: 14, color: Colors.green),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${p.transactionId}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const FaIcon(FontAwesomeIcons.envelope,
                                    size: 14, color: Colors.grey),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    p.email,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const FaIcon(FontAwesomeIcons.calendar,
                                    size: 14, color: Colors.grey),
                                const SizedBox(width: 6),
                                Text(
                                  'Date: ${p.date.split('T').first}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const FaIcon(FontAwesomeIcons.dollarSign,
                                color: Colors.green, size: 14),
                            Text(
                              '\$${p.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 14,
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
          );
        },
      ),
    );
  }
}

class Payment {
  final String id;
  final String email;
  final String transactionId;
  final double price;
  final String date;

  Payment({
    required this.id,
    required this.email,
    required this.transactionId,
    required this.price,
    required this.date,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['_id'],
      email: json['email'] ?? '',
      transactionId: json['transactionId'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      date: json['date'] ?? '',
    );
  }
}
