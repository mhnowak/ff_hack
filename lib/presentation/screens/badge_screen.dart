import 'package:ff_hack/core/utils/nullability_extensions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:friends_badge/friends_badge.dart';
import 'package:image/image.dart' as img;

class BadgeScreen extends StatefulWidget {
  const BadgeScreen({super.key});

  @override
  State<BadgeScreen> createState() => _BadgeScreenState();
}

class _BadgeScreenState extends State<BadgeScreen> {
  BadgeImage? badgeImage;

  Uint8List? get imageBytes =>
      badgeImage?.let((image) => image.getImageBytes());

  Uint8List? get ditheredImageBytes =>
      badgeImage?.let((image) => image.getImageBytes(DitherKernel.atkinson));

  @override
  void initState() {
    super.initState();

    final image = img.Image(width: 240, height: 416);
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        // Draw circles with radius 8 in a grid pattern
        final centerX = ((x ~/ 32) * 32) + 16;
        final centerY = ((y ~/ 32) * 32) + 16;
        final dx = x - centerX;
        final dy = y - centerY;
        if (dx * dx + dy * dy <= 128) {
          // radius^2 = 8*8 = 64
          image.setPixel(x, y, img.ColorRgb8(255, 255, 0));
        } else {
          image.setPixel(x, y, img.ColorRgb8(0, 0, 0));
        }
      }
    }
    badgeImage = BadgeImage(image);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (badgeImage case final image?) {
            await WaitingForNfcTap.showLoading(
              context: context,
              job: image.writeToBadge(),
            );
          }
        },
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            spacing: 24,
            children: [
              if (imageBytes case final imageBytes?)
                Image.memory(imageBytes, height: 300),
              if (ditheredImageBytes case final ditheredImageBytes?)
                Image.memory(ditheredImageBytes, height: 300),
            ],
          ),
        ),
      ),
    );
  }
}
