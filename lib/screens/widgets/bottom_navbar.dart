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
      "label": "Accounts",
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
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 0.0),
            child: Row(
              children: [
                // Left side items
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _navItems.sublist(0, 2).map((item) {
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
                // Right side items
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _navItems.sublist(2, 4).map((item) {
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
