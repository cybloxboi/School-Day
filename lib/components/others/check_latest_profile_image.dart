import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> updateProfileImageUrl(User user) async {
  try {
    final prefs = await SharedPreferences.getInstance();

    final userDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(user.email)
        .get();

    final cloudVersion =
        userDoc.data()?['profileImageVersion'].toString() ?? '0';
    final localVersion = prefs.getString('profile_image_version');

    if (localVersion != cloudVersion) {
      final previousUrl = prefs.getString('cached_profile_url');

      if (previousUrl != null) {
        await CachedNetworkImage.evictFromCache(previousUrl);
      }

      final ref =
          FirebaseStorage.instance.ref('profile_images/${user.uid}.jpg');
      final url = await ref.getDownloadURL();

      await prefs.setString('cached_profile_url', url);
      await prefs.setString('profile_image_version', cloudVersion);

      await user.updatePhotoURL(url);
    }

    await user.reload();
  } catch (e) {
    return;
  }
}
