import 'package:flutter/material.dart';
import 'discover_screen.dart';
import 'home_screen.dart';
import 'play_screen.dart';
import 'profile_screen.dart';
import 'rankings_screen.dart';

class BottomNavShell extends StatefulWidget {
  const BottomNavShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<BottomNavShell> createState() => _BottomNavShellState();
}

class _BottomNavShellState extends State<BottomNavShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 4) as int;
  }

  void _onTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: _currentIndex,
      children: [
        HomeScreen(currentIndex: _currentIndex, onTabSelected: _onTap),
        PlayScreen(currentIndex: _currentIndex, onTabSelected: _onTap),
        DiscoverScreen(currentIndex: _currentIndex, onTabSelected: _onTap),
        RankingsScreen(currentIndex: _currentIndex, onTabSelected: _onTap),
        ProfileScreen(currentIndex: _currentIndex, onTabSelected: _onTap),
      ],
    );
  }
}
