import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:school_day/components/profile/profile_image.dart';
import 'package:school_day/data/destination.dart';
import 'package:school_day/screens/home/home_page.dart';
import 'package:school_day/screens/timetables/timetable_page.dart';
import 'package:school_day/screens/todos/chat_page.dart';
import 'package:school_day/screens/todos/todo_page.dart';
import 'package:school_day/services/database/user/user_document.dart';
import 'package:school_day/services/notification/notification_service.dart';

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
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  late final UserDocument userDocument;
  late final Stream<DocumentSnapshot> _userStream;

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

    userDocument = UserDocument(FirebaseAuth.instance.currentUser!.email!);
    _userStream = userDocument.getUserDocumentSnapshots();

    final email = FirebaseAuth.instance.currentUser!.email!;
    NotificationService().ensurePermissionAndInit(email);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWideScreen = constraints.maxWidth >= 750;

        return Scaffold(
          key: scaffoldKey,
          drawer: const Drawer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(color: Colors.pink),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
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
                  HomePage(
                    scaffoldKey: scaffoldKey,
                  ),
                  TimetablePage(
                    dateIndex: widget.dateIndex,
                    userStream: _userStream,
                  ),
                  const TodoPage(),
                  const ChatPage(),
                  const ProfileImage(),
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
