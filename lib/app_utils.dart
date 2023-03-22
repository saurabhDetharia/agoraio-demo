import 'package:flutter/material.dart';

void navigateTo(BuildContext context, Widget child) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (builderContext) {
        return child;
      },
    ),
  );
}
