import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:lottie/lottie.dart';
import 'package:school_day/styles/styles.dart';

class ShareViewPage extends StatefulWidget {
  const ShareViewPage({super.key, required this.shareId});
  final String shareId;

  @override
  State<ShareViewPage> createState() => _ShareViewPageState();
}

class _ShareViewPageState extends State<ShareViewPage> {
  Map<String, dynamic>? sharedData;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadSharedData();
  }

  Future<void> _loadSharedData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('SharedLinks')
          .doc(widget.shareId)
          .get();

      if (!doc.exists) {
        setState(() {
          error = 'ลิงก์นี้หมดอายุหรือไม่พบข้อมูล';
          loading = false;
        });
        return;
      }

      final data = doc.data()!;
      final expiresAt = data['expiresAt'] as Timestamp?;
      if (expiresAt != null && expiresAt.toDate().isBefore(DateTime.now())) {
        setState(() {
          error = 'ลิงก์นี้หมดอายุ';
          loading = false;
        });
        return;
      }

      setState(() {
        sharedData = data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = 'เกิดข้อผิดพลาด: $e';
        loading = false;
      });
    }
  }

  Future<void> _saveToMyData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อน')));
      return;
    }
    if (sharedData == null) return;

    final type = sharedData!['type'] as String;
    final data = Map<String, dynamic>.from(sharedData!['data'] ?? {});

    data.remove('owner');
    data.remove('createdAt');
    data.remove('expiresAt');

    try {
      final myCollection = type == 'timetable' ? 'Timetables' : 'Todos';
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.email)
          .collection(myCollection)
          .add(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('บันทึกข้อมูลเรียบร้อยแล้ว')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('บันทึกข้อมูลล้มเหลว: $e')));
      }
    }

    if (mounted) {
      context.replace('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        body: Center(
          child: LoadingAnimationWidget.fourRotatingDots(
            color: primaryColor,
            size: 80,
          ),
        ),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'แชร์ข้อมูล',
            style: textTheme.bodyMedium!.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: false,
        ),
        backgroundColor: backgroundColor,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 16,
              children: [
                LottieBuilder.asset(
                  'assets/animations/link_expired.json',
                  width: 280,
                  height: 280,
                  frameRate: const FrameRate(120),
                ),
                Text(
                  error!,
                  style: textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  softWrap: true,
                ),
                FilledButton(
                  onPressed: () {
                    context.replace('/');
                  },
                  child: const Text('กลับไปยังหน้าแรก'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'แชร์ข้อมูล',
          style: textTheme.bodyMedium!.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      backgroundColor: backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              LottieBuilder.asset(
                'assets/animations/link_expired.json',
                width: 280,
                height: 280,
                frameRate: const FrameRate(120),
              ),
              Text(
                'คุณได้คลิกลิงค์การแชร์ข้อมูล',
                style: textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              Text(
                'เจ้าของ: ${sharedData!['owner'] ?? 'ไม่ระบุ'}',
                style: textTheme.bodySmall,
              ),
              Text(
                'ประเภท: ${sharedData!['type'] == 'timetable' ? 'ตารางเรียน' : 'งาน'}',
                style: textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _saveToMyData,
                child: const Text('บันทึกข้อมูลเป็นของฉัน'),
              ),
              const SizedBox(
                height: 16,
              ),
              ElevatedButton(
                onPressed: () {
                  context.replace('/');
                },
                child: const Text('กลับไปยังหน้าแรก'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
