import 'package:assumemate/format.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class HighlightedItemBanner extends StatefulWidget {
  const HighlightedItemBanner({super.key});

  @override
  State<HighlightedItemBanner> createState() => _HighlightedItemBannerState();
}

class _HighlightedItemBannerState extends State<HighlightedItemBanner> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(left: 3, top: 6, right: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      color: const Color(0xff4A8AF0), // Background color for the card
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Wishville',
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        ' \u20B1',
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formatCurrency(1000000, symbol: ''),
                        style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 15,
                        color: Colors.white,
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Upper Lusimba, Pardo, Cebu City',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w500),
                          softWrap: true,
                        ),
                      )
                    ],
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                          decoration: TextDecoration.underline,
                          decorationThickness: 2),
                    ),
                    child: const Text('View Details >>>'),
                  ),
                ],
              ),
            ),
            Expanded(
                child: AspectRatio(
              aspectRatio: 16 / 14,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl:
                      'https://pbs.twimg.com/media/GVv-Pfla8AUr5d2?format=jpg&name=4096x4096',
                  placeholder: (context, url) => Container(
                    color: Colors.black38,
                  ),
                  errorWidget: (context, url, error) => Container(
                      color: Colors.white60,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.warning_rounded,
                            color: Colors.white,
                          ),
                          Text(
                            'Failed to load image',
                            style: TextStyle(fontSize: 10, color: Colors.white),
                          )
                        ],
                      )),
                  fit: BoxFit.cover,
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
