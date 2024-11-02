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
        padding:
            const EdgeInsets.only(left: 15, right: 15, top: 15, bottom: 10),
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
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const Row(
                    children: [
                      Text(
                        ' ₱',
                        style: TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 4),
                      Text(
                        '1,000,000',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 15,
                        color: Colors.white,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Seoul, South Korea',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                          fontSize: 13,
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  'https://pbs.twimg.com/media/GVv-Pfla8AUr5d2?format=jpg&name=4096x4096',
                  height: 120,
                  width: 150,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
