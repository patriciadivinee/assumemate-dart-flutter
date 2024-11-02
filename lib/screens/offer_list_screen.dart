// import 'dart:convert';

import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:assumemate/components/chat_list.dart';
import 'package:assumemate/components/offer_list.dart';
// import 'package:assumemate/logo/pop_up.dart';
// import 'package:assumemate/service/service.dart';
// import 'package:assumemate/storage/secure_storage.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';

class OfferListScreen extends StatefulWidget {
  const OfferListScreen({super.key});

  @override
  State<OfferListScreen> createState() => _OfferListScreenState();
}

class _OfferListScreenState extends State<OfferListScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xffFFFCF1),
        title: const Text('Messages',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            )),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xff4A8AF0)),
            iconSize: 26,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications icon pressed')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView.builder(
          itemCount: 10,
          itemBuilder: (context, index) {
            // final convo = _convos[index];
            return const OfferList();
          },
        ),
      ),
    );
  }
}
