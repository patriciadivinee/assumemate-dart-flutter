import 'package:flutter/material.dart';
import 'package:assumemate/provider/favorite_provider.dart';
import 'package:provider/provider.dart';

class HighlightedItem extends StatefulWidget {
  const HighlightedItem({super.key});

  @override
  State<HighlightedItem> createState() => _HighlightedItemState();
}

class _HighlightedItemState extends State<HighlightedItem> {
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
            ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Image.network(
                'https://pbs.twimg.com/media/GUOaPRVXEAA0LpV?format=jpg&name=4096x4096',
                height: 110,
                width: 120,
                fit: BoxFit.cover,
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 10, right: 10, top: 5),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: NetworkImage(
                        'https://pbs.twimg.com/media/GV_AI3pawAA-fU3?format=jpg&name=4096x4096'),
                  ),
                  SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Wishville',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold),
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
