import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:school_day/styles/styles.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ReportProblemPage extends StatefulWidget {
  const ReportProblemPage({super.key});

  @override
  State<ReportProblemPage> createState() => _ReportProblemPageState();
}

class _ReportProblemPageState extends State<ReportProblemPage> {
  var loadingPercentage = 0;
  late final WebViewController controller;
  bool _isMounted = true;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) {
          if (_isMounted) {
            setState(() => loadingPercentage = 0);
          }
        },
        onProgress: (progress) {
          if (_isMounted) {
            setState(() => loadingPercentage = progress);
          }
        },
        onPageFinished: (url) {
          if (_isMounted) {
            setState(() => loadingPercentage = 100);
          }
        },
      ))
      ..loadRequest(
        Uri.parse('https://forms.gle/ADrcqjmjCb5ocBr48'),
      );
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'รายงานปัญหาที่พบ',
          style: textTheme.bodyMedium!.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          WebViewWidget(
            controller: controller,
          ),
          if (loadingPercentage < 100)
            Stack(
              children: [
                LinearProgressIndicator(
                  value: loadingPercentage / 100.0,
                ),
                Center(
                  child: Column(
                    spacing: 8,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      LottieBuilder.asset(
                        'assets/animations/loading.json',
                        width: 280,
                        height: 280,
                        frameRate: const FrameRate(120),
                      ),
                      Text(
                        'กำลังดาวน์โหลดแบบฟอร์ม...',
                        style: textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
