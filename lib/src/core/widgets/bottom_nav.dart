import 'package:flutter/material.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.article), label: 'Snippets'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Accounts'),
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.schedule), label: 'Solat'),
        BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: 'Finance'),
      ],
    );
  }
}
