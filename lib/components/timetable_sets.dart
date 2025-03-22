import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:school_day/screens/timetables/add_timetablesets_page.dart';
import 'package:school_day/services/timetable_database.dart';
import 'package:school_day/styles/styles.dart';

class TimetableSets extends StatefulWidget {
  const TimetableSets({
    super.key,
    required this.currentTimetableId,
    required this.userEmail,
    required this.onTimetableChanged,
  });

  final String currentTimetableId;
  final String userEmail;
  final Function(String) onTimetableChanged;

  @override
  State<TimetableSets> createState() => _TimetableSetsState();
}

class _TimetableSetsState extends State<TimetableSets> {
  late String selectedTimetableId;
  late Future<List<Map<String, String>>> _futureTimetableSets;

  @override
  void initState() {
    super.initState();
    selectedTimetableId = widget.currentTimetableId;
    _futureTimetableSets = getAllTimetableSets(widget.userEmail);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _futureTimetableSets,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: LoadingAnimationWidget.fourRotatingDots(
                color: primaryColor,
                size: 80,
              ),
            );
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          List<Map<String, String>> timetables = snapshot.data!;

          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 400,
              mainAxisExtent: 150,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 3 / 2,
            ),
            itemCount: timetables.length + 1,
            itemBuilder: (context, index) {
              bool isAddButton = index == timetables.length;
              bool isSelected = !isAddButton &&
                  timetables[index]['id'] == widget.currentTimetableId;

              return Card(
                clipBehavior: Clip.antiAliasWithSaveLayer,
                color: isSelected ? secondaryColor : null,
                child: InkWell(
                  onTap: () async {
                    if (isAddButton) {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) {
                          return AddTimetablesetsPage(
                            isEdited: false,
                            userEmail: widget.userEmail,
                            isCurrent: isSelected,
                            onAdd: () {
                              setState(() {
                                _futureTimetableSets =
                                    getAllTimetableSets(widget.userEmail);
                              });
                            },
                          );
                        },
                      );
                    } else {
                      if (context.mounted) {
                        Navigator.pop(context);
                      }

                      String newTimetableId = timetables[index]['id']!;

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
                      showModalBottomSheet(
                        context: context,
                        builder: (context) {
                          return AddTimetablesetsPage(
                            isEdited: true,
                            userEmail: widget.userEmail,
                            timetableSetName: timetables[index]['name']!,
                            isCurrent: isSelected,
                            timetableSetId: timetables[index]['id'],
                            onAdd: () {
                              setState(() {
                                _futureTimetableSets =
                                    getAllTimetableSets(widget.userEmail);
                              });
                            },
                          );
                        },
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
                              spacing: 8,
                              children: [
                                Icon(Icons.add_rounded),
                                Text('สร้างเซตตารางเรียนใหม่'),
                              ],
                            )
                          else
                            Center(
                              child: Column(
                                spacing: 16,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    timetables[index]['name']!,
                                    style: textTheme.bodyMedium!.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                  if (isSelected) const Icon(Icons.check_rounded),
                                ],
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
        });
  }
}
