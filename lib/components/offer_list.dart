import 'dart:convert';

import 'package:assumemate/format.dart';
import 'package:assumemate/logo/pop_up.dart';
import 'package:assumemate/screens/assumptor_list_detail_screen.dart';
import 'package:assumemate/screens/chat_message_screen.dart';
import 'package:assumemate/service/service.dart';
import 'package:assumemate/storage/secure_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class OfferList extends StatefulWidget {
  final int offerId;
  final String offerAmnt;
  final String listId;
  final String listImage;
  final String reservation;
  final int userId;
  final String userFullname;
  final int roomId;
  final Function(int) onOfferRejected;

  // const OfferList({required this.userId, required this.offerAmnt, super.key});
  const OfferList({
    super.key,
    required this.offerId,
    required this.offerAmnt,
    required this.reservation,
    required this.listId,
    required this.listImage,
    required this.userId,
    required this.userFullname,
    required this.roomId,
    required this.onOfferRejected,
  });

  @override
  State<OfferList> createState() => _OfferListState();
}

class _OfferListState extends State<OfferList> {
  final SecureStorage secureStorage = SecureStorage();
  final ApiService apiService = ApiService();
  bool _isLoading = false;

  void _acceptOffer() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await apiService.offerAcceptReject(
          widget.offerId.toString(), 'accepted');

      print('response1212');
      print(response['error']);

      if (response.containsKey('message')) {
        final oresponse = await apiService.createOrder(
            widget.offerId.toString(), widget.reservation);

        if (oresponse.containsKey('message')) {
          widget.onOfferRejected(widget.offerId);
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ChatMessageScreen(
                        receiverId: widget.userId.toString(),
                      )),
            );
          }
        } else {
          if (mounted) {
            popUp(context, response['error'] ?? 'Error accepting offer');
          }
          return;
        }
      } else {
        if (mounted) {
          popUp(context, response['error']);
        }
        return;
      }
    } catch (e) {
      popUp(context, 'An error occured: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _rejectOffer() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await apiService.offerAcceptReject(
          widget.offerId.toString(), 'rejected');

      if (response.containsKey('message')) {
        widget.onOfferRejected(widget.offerId);
        if (mounted) {
          popUp(context, response['message']);
        }
      } else {
        if (mounted) {
          popUp(context, response['error']);
        }
        return;
      }
    } catch (e) {
      popUp(context, 'An error occured: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => AssumptorListDetailScreen(
                    listingId: widget.listId,
                  )),
        );
      },
      child: ListTile(
        tileColor: Colors.blue.withOpacity(0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
        minTileHeight: 60,
        leading: Padding(
          padding: const EdgeInsets.only(left: 5),
          child: AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CachedNetworkImage(
                imageUrl: widget.listImage,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        title: Text(
          formatCurrency(double.parse(widget.offerAmnt)),
          style: const TextStyle(fontSize: 13),
        ),
        subtitle: Text('Offered by: ${widget.userFullname}',
            style: const TextStyle(fontSize: 12)),
        trailing: _isLoading
            ? CircularProgressIndicator(
                // backgroundColor: const Color(0xff4A8AF0),
                color: const Color(0xff4A8AF0),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => ChatMessageScreen(
                                receiverId: (widget.userId).toString(),
                              )));
                    },
                    child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(FontAwesomeIcons.message)),
                  ),
                  const SizedBox(width: 2),
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      _rejectOffer();
                    },
                    child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          FontAwesomeIcons.circleXmark,
                          color: Color(0xff683131),
                        )),
                  ),
                  const SizedBox(width: 2),
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      showConfirmation(context);
                    },
                    child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          FontAwesomeIcons.circleCheck,
                          color: Color(0xff316832),
                        )),
                  ),
                ],
              ),
      ),
    );
  }

  void showConfirmation(BuildContext context) {
    showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            actionsPadding:
                const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
            contentPadding: const EdgeInsets.only(left: 18, right: 18, top: 12),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Accept and reserve offer?',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.start,
                ),
                const SizedBox(height: 8),
                Text(
                  'Do you wish to accept offer with reservation amount of ${formatCurrency(double.parse(widget.reservation))}?',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.start,
                )
              ],
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                          color: Color(0xff4A8AF0),
                          fontWeight: FontWeight.w400),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _acceptOffer();
                      Navigator.of(context).pop(context);
                    },
                    child: const Text(
                      'Confirm',
                      style: TextStyle(
                          color: Color(0xff4A8AF0),
                          fontWeight: FontWeight.w400),
                    ),
                  ),
                ],
              )
            ],
          );
        });
  }
}
