import 'package:flutter/material.dart';
import 'package:school_day/data/destination.dart';
import 'package:school_day/screens/home/home_page.dart';
import 'package:school_day/screens/timetables/timetable_page.dart';
import 'package:school_day/screens/todos/todo_page.dart';

class NavigationMenu extends StatefulWidget {
  const NavigationMenu({
    super.key,
    this.screenIndex,
    this.dateIndex,
  });

  final int? screenIndex;
  final int? dateIndex;

  @override
  State<NavigationMenu> createState() => _NavigationMenuState();
}

class _NavigationMenuState extends State<NavigationMenu> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();

    if (widget.screenIndex != null) {
      _selectedIndex = widget.screenIndex!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWideScreen = constraints.maxWidth >= 600;

        return Scaffold(
          body: Row(
            children: [
              if (isWideScreen)
                Row(
                  children: [
                    NavigationRail(
                      minWidth: 120,
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: _onItemTapped,
                      labelType: NavigationRailLabelType.all,
                      useIndicator: true,
                      groupAlignment: -0.6,
                      destinations: destinations.map(
                        (Destination destination) {
                          return NavigationRailDestination(
                            icon: destination.icon,
                            selectedIcon: destination.selectedIcon,
                            label: Text(destination.label),
                          );
                        },
                      ).toList(),
                    ),
                    const VerticalDivider(thickness: 1, width: 1),
                  ],
                ),
              Expanded(
                child: [
                  const HomePage(),
                  TimetablePage(
                    dateIndex: widget.dateIndex,
                  ),
                  const TodoPage(),
                ][_selectedIndex],
              ),
            ],
          ),
          bottomNavigationBar: isWideScreen
              ? null
              : NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onItemTapped,
                  destinations: destinations.map(
                    (Destination destination) {
                      return NavigationDestination(
                        icon: destination.icon,
                        label: destination.label,
                        selectedIcon: destination.selectedIcon,
                        tooltip: destination.label,
                      );
                    },
                  ).toList(),
                ),
        );
      },
    );
  }
}
