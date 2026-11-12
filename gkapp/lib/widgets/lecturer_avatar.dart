import 'dart:convert';

import 'package:flutter/material.dart';

class LecturerAvatar extends StatelessWidget {
  const LecturerAvatar({required this.image, this.size = 68, super.key});

  final String image;
  final double size;

  @override
  Widget build(BuildContext context) {
    Widget placeholder() => Container(
      width: size,
      height: size,
      color: Theme.of(context).colorScheme.primaryContainer,
      alignment: Alignment.center,
      child: Icon(
        Icons.person_outline_rounded,
        color: Theme.of(context).colorScheme.primary,
        size: size * 0.48,
      ),
    );

    if (image.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.28),
        child: placeholder(),
      );
    }

    final Widget picture;
    if (image.startsWith('data:image/')) {
      try {
        final separator = image.indexOf(',');
        if (separator < 0) {
          throw const FormatException('Ảnh không hợp lệ.');
        }
        picture = Image.memory(
          base64Decode(image.substring(separator + 1)),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, _, _) => placeholder(),
        );
      } on FormatException {
        return ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.28),
          child: placeholder(),
        );
      }
    } else {
      picture = Image.network(
        image,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, _, _) => placeholder(),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.28),
      child: picture,
    );
  }
}
