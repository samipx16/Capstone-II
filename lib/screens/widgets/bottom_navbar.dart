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
  return Flexible(
    child: MaterialButton(
      onPressed: () {
        if (!isActive) {
          onTap(index);
          if (route.isNotEmpty) {
            Navigator.pushReplacementNamed(context, route);
          }
        }
      },
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      minWidth: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? Colors.green : Colors.grey),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.green : Colors.grey,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}


class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  // Define the list of navigation items
  final List<Map<String, dynamic>> _navItems = const [
    {"index": 0, "icon": Icons.home, "label": "Home", "route": "/dashboard"},
    {
      "index": 1,
      "icon": Icons.emoji_events,
      "label": "Challenges",
      "route": "/challenges"
    },
    {
      "index": 2,
      "icon": Icons.star,
      "label": "Milestones",
      "route": "/milestones"
    },
    {
      "index": 3,
      "icon": Icons.account_circle,
      "label": "Account",
      "route": "/accounts"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: MediaQuery.removePadding(
        context: context,
        removeBottom: true,
        child: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 6.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 0.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _navItems.map((item) {
                return buildBottomNavItem(
                  context: context,
                  index: item["index"],
                  icon: item["icon"],
                  label: item["label"],
                  route: item["route"],
                  currentIndex: currentIndex,
                  onTap: onTap,
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}