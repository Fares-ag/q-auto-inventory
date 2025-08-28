// lib/utils/ui_helpers.dart

import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/item_model.dart';

Widget buildItemIcon(ItemType type, {double size = 40.0}) {
  IconData iconData;
  Color color;
  switch (type) {
    case ItemType.laptop:
      iconData = Icons.laptop_mac;
      color = Colors.black87;
      break;
    case ItemType.keyboard:
      iconData = Icons.keyboard;
      color = Colors.black87;
      break;
    case ItemType.furniture:
      iconData = Icons.chair;
      color = Colors.brown;
      break;
    case ItemType.monitor:
      iconData = Icons.monitor;
      color = Colors.black87;
      break;
    case ItemType.tablet:
      iconData = Icons.tablet_android;
      color = Colors.black87;
      break;
    case ItemType.webcam:
      iconData = Icons.videocam;
      color = Colors.black87;
      break;
    default:
      iconData = Icons.inventory;
      color = Colors.grey;
      break;
  }
  return Icon(iconData, size: size, color: color);
}
