import 'package:flutter/material.dart';
import 'package:school_day/screens/timetables/add_timetablesets_page.dart';
import 'package:school_day/services/timetable_database/timetable_set.dart';
import 'package:school_day/styles/styles.dart';

class TimetableSets extends StatefulWidget {
  const TimetableSets({
    super.key,
    required this.currentTimetableID,
    required this.timetableSets,
    required this.timetableSetDocument,
  });

  final String currentTimetableID;
  final List<TimetableSetInfo> timetableSets;
  final TimetableSetDocument timetableSetDocument;

  @override
  State<TimetableSets> createState() => _TimetableSetsState();
}

class _TimetableSetsState extends State<TimetableSets> {
  @override
  void initState() {
    super.initState();
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
      itemCount: widget.timetableSets.length + 1,
      itemBuilder: (context, index) {
        bool isAddButton = index == widget.timetableSets.length;
        bool isSelected = !isAddButton &&
            widget.timetableSets[index].id == widget.currentTimetableID;

        return Card(
          clipBehavior: Clip.antiAliasWithSaveLayer,
          color: isSelected ? secondaryColor : null,
          child: InkWell(
            onTap: () async {
              if (isAddButton) {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: SingleChildScrollView(
                        child: AddTimetablesetsPage(
                          isEdited: false,
                          isCurrent: isSelected,
                          timetableSetDocument: widget.timetableSetDocument,
                        ),
                      ),
                    );
                  },
                );
              } else {
                if (context.mounted) {
                  Navigator.pop(context);
                }

                await widget.timetableSetDocument.updateCurrentTimetableID(
                  widget.timetableSets[index].id,
                );
              }
            },
            onLongPress: () {
              if (!isAddButton) {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: SingleChildScrollView(
                        child: AddTimetablesetsPage(
                          isEdited: true,
                          isCurrent: isSelected,
                          timetableSetDocument: widget.timetableSetDocument,
                          name: widget.timetableSets[index].name,
                          timetableID: widget.timetableSets[index].id,
                        ),
                      ),
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
                              widget.timetableSets[index].name,
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
  }
}
