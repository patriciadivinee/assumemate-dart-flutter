import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class OfferList extends StatefulWidget {
  // final String userId;
  // final double offerAmnt;

  // const OfferList({required this.userId, required this.offerAmnt, super.key});
  const OfferList({super.key});

  @override
  State<OfferList> createState() => _OfferListState();
}

class _OfferListState extends State<OfferList> {
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.all(10),
        child: ListTile(
          tileColor: const Color(0xffFFFCA1),
          minTileHeight: 50,
          leading: const CircleAvatar(
              backgroundImage: NetworkImage(
            'https://pbs.twimg.com/media/GUOaPRVXEAA0LpV?format=jpg&name=4096x4096',
            // fit: BoxFit.cover,
          )),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {},
                child: Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(FontAwesomeIcons.commentDots)),
              ),
              const SizedBox(width: 2),
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {},
                child: Padding(
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
                child: Padding(
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
        ));
  }
}
