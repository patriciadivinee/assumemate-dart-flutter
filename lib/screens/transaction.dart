import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:assumemate/storage/secure_storage.dart';
import 'package:intl/intl.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  late Future<List<Transaction>> _transactions;
  final SecureStorage secureStorage = SecureStorage();
  final String? baseUrl = dotenv.env['API_URL'];

  @override
  void initState() {
    super.initState();
    _transactions = fetchTransactions();
  }

  // Fetch the transaction data from the API
  Future<List<Transaction>> fetchTransactions() async {
    final token = await secureStorage.getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/transactions/'), // Adjust API URL as needed
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Transaction.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load transactions');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: const Color(0xff4A8AF0),
          leading: IconButton(
            splashColor: Colors.transparent,
            icon: const Icon(
              Icons.arrow_back_ios,
            ),
            color: const Color(0xffFFFEF7),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: const Text(
            "Transaction History",
            style: TextStyle(
              fontSize: 18,
              color: Color(0xffFFFEF7),
              fontWeight: FontWeight.bold,
            ),
          )),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: FutureBuilder<List<Transaction>>(
          future: _transactions,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No transactions available.'));
            }

            final transactions = snapshot.data!;

            return ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                final amountWithSign = transaction.category == 'TOPUP'
                    ? '+${transaction.amount}'
                    : '-${transaction.amount}';
                final amountColor =
                    transaction.category == 'TOPUP' ? Colors.green : Colors.red;
                final formattedDate = DateFormat('MMM dd, yyyy, h:mm a').format(
                    DateTime.parse(transaction.transactionDate).toLocal());

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // First Column (Category and Date)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction.category,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(formattedDate),
                        ],
                      ),
                      // Second Column (Amount)
                      Text(
                        amountWithSign,
                        style: TextStyle(
                          color: amountColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // // Third Column (Status)
                      // Text(transaction.transactionStatus),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class Transaction {
  final String amount;
  // final String transactionStatus;
  final String transactionDate;
  final String category;

  Transaction({
    required this.amount,
    // required this.transactionStatus,
    required this.transactionDate,
    required this.category,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      amount: json['transaction_amount'].toString(),
      // transactionStatus: json['transaction_status'],
      transactionDate: json['transaction_date'],
      category: json['transaction_type'],
    );
  }
}
