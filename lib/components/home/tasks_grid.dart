import 'package:flutter/material.dart';
import 'package:school_day/data/todo.dart';
import 'package:school_day/styles/styles.dart';

class TasksGrid extends StatelessWidget {
  const TasksGrid({
    super.key,
    required this.todoData,
  });

  final Todo todoData;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 18.0,
          vertical: 20.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Text(
              todoData.title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                decoration: todoData.isDone
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
                color: todoData.isDone ? Colors.grey : Colors.black,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (todoData.description != null)
              Text(
                todoData.description!,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            const Divider(),
            Row(
              children: [
                Icon(Icons.date_range_rounded, size: 24, color: primaryColor),
                SizedBox(width: 10),
                Text(
                  '${todoData.selectedDate!.day}/${todoData.selectedDate!.month}/${todoData.selectedDate!.year}',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
            if (todoData.alarmTime != null)
              Row(
                children: [
                  Icon(Icons.access_time, size: 24, color: primaryColor),
                  SizedBox(width: 10),
                  Text(
                    '${todoData.alarmTime}',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            if (todoData.categoryName != null)
              Row(
                children: [
                  Icon(Icons.note, size: 24, color: primaryColor),
                  SizedBox(width: 10),
                  Text(
                    todoData.categoryName!,
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
