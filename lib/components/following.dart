import 'package:flutter/material.dart';
import 'package:assumemate/provider/favorite_provider.dart';
import 'package:assumemate/screens/chat_message_screen.dart';
import 'package:provider/provider.dart';

class Following extends StatefulWidget {
  const Following({super.key});

  @override
  State<Following> createState() => _FollowingState();
}

class _FollowingState extends State<Following> {
  late bool isFav = false;

  @override
  void initState() {
    super.initState();
    isFav = false;
  }

  @override
  Widget build(BuildContext context) {
    final favoriteProvider = Provider.of<FavoriteProvider>(context);

    return InkWell(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        margin: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color(0xffFFFFFF),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 5,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(left: 15, right: 15, bottom: 4),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(
                        'https://pbs.twimg.com/media/GV_AI3pawAA-fU3?format=jpg&name=4096x4096'),
                  ),
                  SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: Text(
                      'Yushi Tokuno',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Image.network(
                'https://pbs.twimg.com/media/GUOaPRVXEAA0LpV?format=jpg&name=4096x4096',
                height: 160,
                width: 270,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 10, top: 5),
              child: Row(
                children: [
                  const SizedBox(
                    width: 8,
                  ),
                  const Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Wishville',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Yushi',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        // Text(
                        //   'Yushi',
                        //   style: TextStyle(
                        //       fontSize: 12, fontWeight: FontWeight.bold),
                        // ),
                      ],
                    ),
                  ),
                  // IconButton(
                  //   onPressed: () {
                  //     favoriteProvider.toggleFavorite();
                  //   },
                  //   icon: favoriteProvider.isFav
                  //       ? const Icon(
                  //           Icons.favorite,
                  //           color: Color(0xffFF0000),
                  //         )
                  //       : const Icon(Icons.favorite_outline,
                  //           color: Colors.black),
                  // )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
