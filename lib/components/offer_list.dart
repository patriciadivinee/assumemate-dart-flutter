import 'package:assumemate/format.dart';
import 'package:assumemate/screens/chat_message_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: const Color(0xffFFFCA1),
      contentPadding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
      minTileHeight: 50,
      leading: AspectRatio(
        aspectRatio: 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: CachedNetworkImage(
            imageUrl: widget.listImage,
            height: 50,
            fit: BoxFit.cover,
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
            onTap: () {},
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
            onTap: () {},
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
    );
  }
}
