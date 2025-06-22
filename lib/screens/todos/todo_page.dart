import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:lottie/lottie.dart';
import 'package:school_day/components/todos/categories.dart';
import 'package:school_day/data/todo.dart';
import 'package:school_day/screens/todos/add_new_todo_page.dart';
import 'package:school_day/services/database/todo/category.dart';
import 'package:school_day/services/database/todo/todo_entry.dart';
import 'package:school_day/services/database/user/user_document.dart';
import 'package:school_day/styles/styles.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  late final User currentUser;
  late final Stream<DocumentSnapshot> _userStream;
  late final CategoryDocument _categoryDocument;
  late final Stream<QuerySnapshot> _categoryStream;
  late String? categoryID;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser!;
    _userStream = UserDocument(currentUser.email!).getUserDocumentSnapshots();
    _categoryDocument = CategoryDocument(email: currentUser.email!);
    _categoryStream = _categoryDocument.getCategoryQuerySnapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'งาน',
          style: textTheme.bodyMedium!.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: const Icon(Icons.list_rounded),
              onPressed: () {
                if (categoryID == null) return;

                showModalBottomSheet(
                  context: context,
                  showDragHandle: !kIsWeb ? true : false,
                  isScrollControlled: true,
                  builder: (context) {
                    return SizedBox(
                      height: MediaQuery.of(context).size.height * 0.8,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 32,
                          top: 32,
                          right: 32,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (kIsWeb)
                              Column(
                                children: [
                                  Row(
                                    children: [
                                      const Spacer(),
                                      IconButton.filledTonal(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        icon: const Icon(
                                          Icons.cancel_rounded,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 16,
                                  ),
                                ],
                              ),
                            Text(
                              'หมวดหมู่งาน',
                              style: textTheme.bodyMedium!.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(),
                            const SizedBox(
                              height: 16,
                            ),
                            Expanded(
                              child: StreamBuilder(
                                stream: _categoryDocument.fetchCategories(
                                  _categoryStream,
                                ),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Center(
                                      child: LoadingAnimationWidget
                                          .fourRotatingDots(
                                        color: primaryColor,
                                        size: 80,
                                      ),
                                    );
                                  }

                                  if (snapshot.hasError) {
                                    return Text(
                                      'เกิดข้อผิดพลาด: ${snapshot.error}',
                                    );
                                  }

                                  List<CategoryInfo> categories =
                                      snapshot.data!;

                                  categories.sort((a, b) {
                                    if (a.id == categoryID) {
                                      return -1;
                                    }

                                    if (b.id == categoryID) {
                                      return 1;
                                    }

                                    return 0;
                                  });

                                  return Categories(
                                    currentCategoryID: categoryID!,
                                    categories: categories,
                                    categoryDocument: _categoryDocument,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      floatingActionButton: kDebugMode
          ? FloatingActionButton(
              onPressed: () {
                if (categoryID == null) return;

                TodoEntry todoEntry = TodoEntry(
                  email: currentUser.email!,
                  categoryID: categoryID!,
                );

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddNewTodoPage(
                      isEdited: false,
                      todoEntry: todoEntry,
                    ),
                  ),
                );
              },
              child: const Icon(Icons.add_rounded),
            )
          : null,
      body: StreamBuilder(
        stream: _categoryDocument.getCurrentTodosID(_userStream),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: LoadingAnimationWidget.fourRotatingDots(
                color: primaryColor,
                size: 80,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          categoryID = snapshot.data!;

          TodoEntry todoEntry = TodoEntry(
            email: currentUser.email!,
            categoryID: categoryID!,
          );

          return StreamBuilder(
            stream: todoEntry.fetchTodos(
              todoEntry.getUserTodoDoc(categoryID).snapshots(),
            ),
            builder: (context, entrySnapshot) {
              if (entrySnapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: LoadingAnimationWidget.fourRotatingDots(
                    color: primaryColor,
                    size: 80,
                  ),
                );
              }

              if (entrySnapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              List<Todo> todoData = entrySnapshot.data!;

              todoData.sort(
                (a, b) => a.createdTime.compareTo(b.createdTime),
              );

              return Builder(
                builder: (context) {
                  if (todoData.isEmpty) {
                    return Center(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            spacing: 8,
                            children: [
                              Text(
                                'ไม่มีงาน :>',
                                softWrap: true,
                                textAlign: TextAlign.center,
                                style: textTheme.bodyMedium!.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 30,
                                ),
                              ),
                              Text(
                                'คลิกปุ่ม + เพื่อเพิ่มงาน',
                                softWrap: true,
                                style: textTheme.bodySmall,
                              ),
                              LottieBuilder.asset(
                                'assets/animations/empty_timetable.json',
                                width: 180,
                                height: 180,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 800,
                      mainAxisExtent: 150,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: todoData.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Slidable(
                        key: ValueKey(todoData[index].id),
                        endActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (context) {
                                if (categoryID == null) return;

                                TodoEntry todoEntry = TodoEntry(
                                  email: currentUser.email!,
                                  categoryID: categoryID!,
                                );

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddNewTodoPage(
                                      todoEntry: todoEntry,
                                      isEdited: true,
                                      todoData: todoData[index],
                                    ),
                                  ),
                                );
                              },
                              backgroundColor: backgroundColor,
                              foregroundColor: Colors.blue,
                              spacing: 8,
                              icon: Icons.edit,
                              label: 'แก้ไข',
                            ),
                            SlidableAction(
                              onPressed: (context) async {
                                if (categoryID == null) return;

                                TodoEntry todoEntry = TodoEntry(
                                  email: currentUser.email!,
                                  categoryID: categoryID!,
                                );

                                await todoEntry.deleteTodo(
                                  todo: todoData[index],
                                );
                              },
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                              ),
                              icon: Icons.delete,
                              spacing: 8,
                              label: 'ลบ',
                            ),
                          ],
                        ),
                        child: Card(
                          key: ValueKey(todoData[index].id),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side:
                                const BorderSide(color: Colors.black, width: 1),
                          ),
                          color: Colors.white,
                          clipBehavior: Clip.antiAliasWithSaveLayer,
                          child: InkWell(
                            onTap: () {
                              if (categoryID == null) return;

                              TodoEntry todoEntry = TodoEntry(
                                email: currentUser.email!,
                                categoryID: categoryID!,
                              );

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddNewTodoPage(
                                    todoEntry: todoEntry,
                                    isEdited: true,
                                    todoData: todoData[index],
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Checkbox(
                                    value: todoData[index].isDone,
                                    onChanged: (bool? value) async {
                                      if (value == null) return;

                                      final todo = todoData[index];
                                      final updatedTodo = todo.copyWith(
                                        isDone: value,
                                      );

                                      setState(() {
                                        todoData = List.from(todoData);
                                        todoData[index] = updatedTodo;
                                      });

                                      await TodoEntry(
                                        email: currentUser.email!,
                                        categoryID: categoryID!,
                                      ).updateTodo(
                                        oldTodo: todo,
                                        newTodo: updatedTodo,
                                      );
                                    },
                                    activeColor: primaryColor,
                                    checkColor: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(
                                          todoData[index].title,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            decoration: todoData[index].isDone
                                                ? TextDecoration.lineThrough
                                                : TextDecoration.none,
                                            color: todoData[index].isDone
                                                ? Colors.grey
                                                : Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        if (todoData[index].description != null)
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Icon(Icons.assignment,
                                                  size: 16,
                                                  color: primaryColor),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  todoData[index].description!,
                                                  softWrap: true,
                                                  maxLines: 4,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    spacing: 8,
                                    children: [
                                      if (todoData[index].selectedDate != null)
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          spacing: 8,
                                          children: [
                                            Icon(Icons.date_range_rounded,
                                                size: 16, color: primaryColor),
                                            Text(
                                              '${todoData[index].selectedDate!.day}/${todoData[index].selectedDate!.month}/${todoData[index].selectedDate!.year + 543}',
                                            ),
                                          ],
                                        ),
                                      if (todoData[index].alarmTime != null)
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          spacing: 8,
                                          children: [
                                            Icon(Icons.schedule,
                                                size: 16, color: primaryColor),
                                            Text(
                                              todoData[index]
                                                  .alarmTime
                                                  .toString(),
                                            ),
                                          ],
                                        ),
                                      if (todoData[index].priority != null)
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          spacing: 8,
                                          children: [
                                            Icon(Icons.flag,
                                                size: 16,
                                                color: Colors.redAccent),
                                            Text(
                                              todoData[index]
                                                  .priority!
                                                  .toLocalizedString(),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
