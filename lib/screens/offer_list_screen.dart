import 'package:assumemate/logo/pop_up.dart';
import 'package:assumemate/service/service.dart';
import 'package:assumemate/storage/secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:assumemate/components/offer_list.dart';

class OfferListScreen extends StatefulWidget {
  const OfferListScreen({super.key});

  @override
  State<OfferListScreen> createState() => _OfferListScreenState();
}

class _OfferListScreenState extends State<OfferListScreen> {
  final SecureStorage secureStorage = SecureStorage();
  final ApiService apiService = ApiService();
  List<Map<String, dynamic>> _offers = [];

  Future<void> _getOffers() async {
    try {
      final response = await apiService.getAssumptorListOffer();

      if (response.containsKey('offers')) {
        setState(() {
          _offers = List<Map<String, dynamic>>.from(response['offers']);
        });
      }
    } catch (e) {
      popUp(context, 'Error: $e');
    }
  }

  void _removeOffer(int offerId) {
    setState(() {
      _offers.removeWhere((offer) => offer['offer_id'] == offerId);
    });
  }

  @override
  void initState() {
    super.initState();
    _getOffers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xffFFFCF1),
          leading: IconButton(
            splashColor: Colors.transparent,
            icon: const Icon(
              Icons.arrow_back_ios,
            ),
            color: Colors.black,
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: const Text('Offer Lists',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              )),
        ),
        body: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: RefreshIndicator(
            onRefresh: _getOffers,
            color: const Color(0xff4A8AF0),
            child: _offers.isEmpty
                ? const Center(
                    child: Text('No active offers'),
                  )
                : ListView.separated(
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    padding: EdgeInsets.zero,
                    itemCount: _offers.length,
                    itemBuilder: (context, index) {
                      final offer = _offers[index];
                      return OfferList(
                        offerId: offer['offer_id'],
                        offerAmnt: offer['offer_price'],
                        reservation: offer['reservation'].toString(),
                        listId: offer['list_id'],
                        listImage: offer['list_image'],
                        userId: offer['user_id'],
                        userFullname: offer['user_fullname'],
                        roomId: offer['chatroom_id'],
                        onOfferRejected: _removeOffer,
                      );
                    },
                  ),
          ),
        ));
  }
}
