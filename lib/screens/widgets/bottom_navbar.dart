import 'package:flutter/material.dart';

Widget buildBottomNavItem({
  required BuildContext context,
  required int index,
  required IconData icon,
  required String label,
  required String route,
  required int currentIndex,
  required Function(int) onTap,
}) {
  bool isActive = currentIndex == index;
  return MaterialButton(
    onPressed: () {
      onTap(index);
      if (route.isNotEmpty) {
        Navigator.pushNamed(context, route);
      }
    },
    minWidth: 40,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: isActive ? Colors.green : Colors.grey),
        Text(label,
            style: TextStyle(
                color: isActive ? Colors.green : Colors.grey, fontSize: 12)),
      ],
    ),
  );
}
