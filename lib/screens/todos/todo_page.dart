import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
                      todoEntry: todoEntry,
                    ),
                  ),
                );
              },
              child: const Icon(Icons.add_rounded),
            )
          : null,
      body: kDebugMode
          ? StreamBuilder(
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
                    if (entrySnapshot.connectionState ==
                        ConnectionState.waiting) {
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

                        return ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: todoData.length,
                          itemBuilder: (context, index) {
                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      side: const BorderSide(
                                          color: Colors.black, width: 1),
                                    ),
                                    color: Colors.white,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                SizedBox(height: 4),
                                                Text(
                                                  todoData[index].title,
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                SizedBox(height: 10),
                                                Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Icon(Icons.assignment,
                                                        size: 16,
                                                        color: primaryColor),
                                                    SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        'รายละเอียด',
                                                        style: TextStyle(
                                                          fontSize: 14,
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
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              const Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  Icon(Icons.schedule,
                                                      size: 16,
                                                      color: primaryColor),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'วันครบกำหนด',
                                                    style:
                                                        TextStyle(fontSize: 12),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              const Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  Icon(Icons.flag,
                                                      size: 16,
                                                      color: Colors.redAccent),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'ความสำคัญ',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.edit,
                                                        size: 18,
                                                        color: Colors.blue),
                                                    onPressed: () {},
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                        Icons.delete,
                                                        size: 18,
                                                        color: primaryColor),
                                                    onPressed: () {},
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
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            )
          : Center(
              child: Text(
                'Coming Soon...',
                style: textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
                ),
              ),
            ),
    );
  }
}
