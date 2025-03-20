import 'package:flutter/material.dart';
import 'package:school_day/screens/timetables/add_timetablesets_page.dart';
import 'package:school_day/screens/timetables/edit_timetable_sets.dart';
import 'package:school_day/services/timetable_database.dart';
import 'package:school_day/styles/styles.dart';

class TimetableSets extends StatefulWidget {
  const TimetableSets({
    super.key,
    required this.timetables,
    required this.currentTimetableId,
    required this.userEmail,
    required this.onTimetableChanged,
  });

  final List<Map<String, String>> timetables;
  final String currentTimetableId;
  final String userEmail;
  final Function(String) onTimetableChanged;

  @override
  State<TimetableSets> createState() => _TimetableSetsState();
}

class _TimetableSetsState extends State<TimetableSets> {
  late String selectedTimetableId;

  @override
  void initState() {
    super.initState();
    selectedTimetableId = widget.currentTimetableId;
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        mainAxisExtent: 150,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 3 / 2,
      ),
      itemCount: widget.timetables.length + 1,
      itemBuilder: (context, index) {
        bool isAddButton = index == widget.timetables.length;
        bool isSelected = !isAddButton &&
            widget.timetables[index]['id'] == widget.currentTimetableId;

        return Card(
          clipBehavior: Clip.antiAliasWithSaveLayer,
          color: isSelected ? secondaryColor : null,
          child: InkWell(
            onTap: () async {
              if (isAddButton) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddTimetablesetsPage(),
                  ),
                );
              } else {
                if (context.mounted) {
                  Navigator.pop(context);
                }

                String newTimetableId = widget.timetables[index]['id']!;

                widget.onTimetableChanged(newTimetableId);

                setState(() {
                  selectedTimetableId = newTimetableId;
                });

                await updateCurrentTimetableID(
                  widget.userEmail,
                  newTimetableId,
                );
              }
            },
            onLongPress: () {
              if (!isAddButton) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditTimetableSets(),
                  ),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isAddButton)
                      const Column(
                        children: [
                          Icon(Icons.add_rounded),
                          Text('สร้างชุดตารางเรียนใหม่'),
                        ],
                      )
                    else
                      Text(
                        widget.timetables[index]['name']!,
                        style: textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
