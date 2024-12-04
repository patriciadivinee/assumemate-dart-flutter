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
  final int userId;
  final String userFullname;
  final int roomId;

  // const OfferList({required this.userId, required this.offerAmnt, super.key});
  const OfferList(
      {super.key,
      required this.offerId,
      required this.offerAmnt,
      required this.listId,
      required this.listImage,
      required this.userId,
      required this.userFullname,
      required this.roomId});

  @override
  State<OfferList> createState() => _OfferListState();
}

class _OfferListState extends State<OfferList> {
  final String? baseURL = dotenv.env['WEB_SOCKET_URL'];
  final SecureStorage secureStorage = SecureStorage();
  final ApiService apiService = ApiService();

  WebSocketChannel? _channel;
  WebSocketChannel? _inboxChannel;

  void _sendInboxUpdate(Map<String, dynamic> message, bool isRead) {
    _inboxChannel!.sink.add(jsonEncode({
      'type': 'inbox_update',
      'sender_id': secureStorage.getUserId(),
      'message': message,
      'room_id': widget.roomId,
      'receiver_id': widget.userId,
      'is_read': isRead,
    }));
  }

  void _acceptOffer(String status) async {
    // if (status == 'ACCEPTED') {
    //   final response = await apiService.createOrder(widget.offerId.toString());

    //   if (response.containsKey('message')) {
    //     if (mounted) {
    //       Navigator.push(
    //         context,
    //         MaterialPageRoute(
    //             builder: (context) => ChatMessageScreen(
    //                   receiverId: widget.userId.toString(),
    //                 )),
    //       );
    //     }
    //   } else {
    //     if (mounted) {
    //       popUp(context, 'Error accepting offer');
    //     }
    //     return;
    //   }
    // }

    if (_channel != null) {
      _channel!.sink.add(jsonEncode({
        'type': 'offer_update',
        'user_id': widget.userId,
        'offer_id': widget.offerId,
        'offer_status': status
      }));

      final updatedStatus = status.toLowerCase();
      print('sent');

      final message = {
        'message': 'Offer $updatedStatus',
        'file': null,
        'file_name': null,
        'file_type': null,
      };

      _sendInboxUpdate(message, false);
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
        tileColor: const Color(0xffFFFCA1),
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
        trailing: Row(
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
                _acceptOffer('REJECTED');
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
                _acceptOffer('ACCEPTED');
              },
              child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    FontAwesomeIcons.circleCheck,
                    color: Color(0xff316832),
                  )),
            ),
            // IconButton(
            //     onPressed: () {},
            //     icon: const Icon(FontAwesomeIcons.commentDots)),
            // IconButton(
            //     onPressed: () {},
            //     icon: const Icon(
            //       FontAwesomeIcons.circleXmark,
            //       color: Color(0xff683131),
            //     )),
            // IconButton(
            //     onPressed: () {},
            //     icon: const Icon(
            //       FontAwesomeIcons.circleCheck,
            //       color: Color(0xff316832),
            //     ))
          ],
        ),
      ),
    );
  }
}
