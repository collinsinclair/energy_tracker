import 'package:flutter/material.dart';

import 'tab_item.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: TabItem.items,
      currentIndex: selectedIndex,
      onTap: onItemTapped,
    );
  }
}
