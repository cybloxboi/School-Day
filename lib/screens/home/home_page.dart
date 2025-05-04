import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:school_day/services/database/user/user_document.dart';
import 'package:school_day/styles/styles.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.scaffoldKey,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime now = DateTime.now();
  late String today;
  late UserDocument userDocument;
  late final Stream<DocumentSnapshot> _userStream;

  final GlobalKey _flexibleSpaceKey = GlobalKey();
  double _flexibleSpaceHeight = 200;

  String greetingText = 'สวัสดี!';

  int selectedPageIndex = 0;

  Future logOut(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('fcm_token');
    final user = FirebaseAuth.instance.currentUser;

    if (token != null && user != null) {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.email!)
          .update(
        {
          'tokens': FieldValue.arrayRemove([token]),
          'platforms.$token': FieldValue.delete(),
        },
      );
    }

    await prefs.remove('fcm_token');

    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ล็อคเอาท์สำเร็จ'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _measureFlexibleSpaceHeight() {
    final ctx = _flexibleSpaceKey.currentContext;

    if (ctx != null) {
      final box = ctx.findRenderObject() as RenderBox;
      final height = box.size.height + 10;

      if (mounted) {
        setState(() {
          _flexibleSpaceHeight = height;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    userDocument = UserDocument(FirebaseAuth.instance.currentUser!.email!);
    _userStream = userDocument.getUserDocumentSnapshots();
    today = '${DateFormat('d MMM').format(now)} ${now.year + 543}';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureFlexibleSpaceHeight();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'หน้าแรก',
          style: textTheme.bodyMedium!.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            widget.scaffoldKey.currentState?.openDrawer();
          },
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton.icon(
              onPressed: () => logOut(context),
              icon: const Icon(Icons.logout_rounded),
              label: Text(
                'ล็อคเอาท์',
                style: textTheme.bodySmall!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                snap: true,
                expandedHeight: _flexibleSpaceHeight,
                backgroundColor: backgroundColor,
                elevation: 0,
                shadowColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  background: Padding(
                    key: _flexibleSpaceKey,
                    padding: const EdgeInsets.only(top: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 16,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            StreamBuilder(
                              stream: userDocument.getUsername(_userStream),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  greetingText =
                                      'สวัสดี, ${snapshot.data}! มาดูกันสิ วันนี้มีอะไรบ้าง';
                                }

                                return Expanded(
                                  child: AnimatedTextKit(
                                    key: ValueKey(snapshot.data),
                                    isRepeatingAnimation: false,
                                    totalRepeatCount: 1,
                                    animatedTexts: [
                                      TypewriterAnimatedText(
                                        greetingText,
                                        textStyle:
                                            textTheme.bodyMedium!.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        speed: const Duration(
                                          milliseconds: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(
                              width: 16,
                            ),
                            FutureBuilder(
                              future: getCurrentUser(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                        ConnectionState.waiting ||
                                    snapshot.data == null) {
                                  return Center(
                                    child: SizedBox(
                                      width: 60,
                                      height: 60,
                                      child: FittedBox(
                                        fit: BoxFit.contain,
                                        child: ClipOval(
                                          child: CircleAvatar(
                                            radius: 64,
                                            child: LoadingAnimationWidget.beat(
                                              color: primaryColor,
                                              size: 100,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                return Center(
                                  child: SizedBox(
                                    width: 60,
                                    height: 60,
                                    child: FittedBox(
                                      fit: BoxFit.contain,
                                      child: ClipOval(
                                        child: CircleAvatar(
                                          radius: 64,
                                          child: snapshot.data!.photoURL != null
                                              ? CachedNetworkImage(
                                                  imageUrl:
                                                      snapshot.data!.photoURL!,
                                                  placeholder: (context, url) {
                                                    return LoadingAnimationWidget
                                                        .beat(
                                                      color: primaryColor,
                                                      size: 100,
                                                    );
                                                  },
                                                )
                                              : Image.asset(
                                                  'assets/images/blank_profile.jpg'),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 255, 255, 255),
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: IntrinsicHeight(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'วันนี้',
                                  style: textTheme.bodyMedium!.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 4,
                                  ),
                                  child: VerticalDivider(
                                    thickness: 2,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  today,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(999),
                                    border:
                                        Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: ToggleButtons(
                                    borderWidth: 0,
                                    borderColor: Colors.transparent,
                                    selectedBorderColor: Colors.transparent,
                                    borderRadius: BorderRadius.circular(999),
                                    fillColor:
                                        Colors.pink.withValues(alpha: 0.2),
                                    selectedColor: Colors.pink,
                                    color: Colors.black,
                                    constraints: const BoxConstraints(
                                      minWidth: 60,
                                      minHeight: 36,
                                    ),
                                    isSelected: [
                                      selectedPageIndex == 0,
                                      selectedPageIndex == 1
                                    ],
                                    onPressed: (int index) {
                                      setState(() => selectedPageIndex = index);
                                    },
                                    children: const [
                                      Text('วิชา'),
                                      Text('งาน'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          height: 1,
                          width: double.infinity,
                          color: const Color.fromARGB(255, 171, 169, 169),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 600,
                    mainAxisExtent: 200,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.black),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 18.0,
                            vertical: 20.0,
                          ),
                          child: Text(
                            'วิชา',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<User?> getCurrentUser() async {
    await FirebaseAuth.instance.currentUser?.reload();
    return FirebaseAuth.instance.currentUser;
  }
}
