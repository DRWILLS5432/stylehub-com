import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:stylehub/constants/app/app_colors.dart';
import 'package:stylehub/constants/app/textstyle.dart';
import 'package:stylehub/constants/localization/locales.dart';
import 'package:stylehub/screens/specialist_pages/provider/language_provider.dart';

class SettingsWidget extends StatefulWidget {
  const SettingsWidget({super.key});

  @override
  State<SettingsWidget> createState() => _SettingsWidgetState();
}

class _SettingsWidgetState extends State<SettingsWidget> {
  late FlutterLocalization _flutterLocalization;
  List<String> availableLanguages = ['en', 'ru'];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isAllowNotifications = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _flutterLocalization = FlutterLocalization.instance;
    _fetchNotificationSettings();
  }

  /// Fetches the user's notification settings from Firestore.
  Future<void> _fetchNotificationSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data();
      setState(() {
        _isAllowNotifications = data?['isNotificationsEnabled'] ?? false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching notification settings: $e')),
      );
    }
    setState(() => _isLoading = false);
  }

  /// Updates the notification settings in Firestore.
  Future<void> _updateNotifications(bool value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'isNotificationsEnabled': value,
        'notificationsUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() {
        _isAllowNotifications = value;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating notifications: $e')),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: AppBar(
        backgroundColor: AppColors.whiteColor,
      ),
      body: Container(
        margin: EdgeInsets.only(right: 33.w, left: 33.h, top: 10.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(height: 50.h, width: 50.w, child: Image.asset('assets/images/Settings.png')),
                SizedBox(width: 5.w),
                Text(
                  LocaleData.appSettings.getString(context),
                  style: appTextStyle205(AppColors.newThirdGrayColor),
                ),
              ],
            ),
            SizedBox(height: 44.h),
            Text(
              LocaleData.language.getString(context),
              style: appTextStyle15(AppColors.appGrayTextColor),
            ),
            SizedBox(height: 14.h),
            _buildDropdown(
              value: languageProvider.currentLanguage,
              onChanged: (String? newValue) {
                _setLocale(newValue, languageProvider);
              },
              items: availableLanguages,
            ),
            SizedBox(height: 45.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  LocaleData.notifications.getString(context),
                  style: appTextStyle12K(AppColors.appGrayTextColor),
                ),
                Switch(
                  activeColor: AppColors.whiteColor,
                  activeTrackColor: AppColors.greenColor,
                  value: _isAllowNotifications,
                  onChanged: _isLoading ? null : _updateNotifications,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _setLocale(String? value, LanguageProvider provider) {
    if (value == null) return;

    String languageCode = value;
    switch (languageCode) {
      case 'en':
        _flutterLocalization.translate('en');
        break;
      case 'ru':
        _flutterLocalization.translate('ru');
        break;
      default:
        return;
    }

    provider.setLanguage(value);
    Navigator.pop(context);
  }
}

Widget _buildDropdown({
  required String value,
  required ValueChanged<String?> onChanged,
  required List<String> items,
}) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 0),
    decoration: BoxDecoration(
      color: AppColors.grayColor,
      borderRadius: BorderRadius.circular(10.dg),
      border: Border.all(color: AppColors.mainBlackTextColor),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        borderRadius: BorderRadius.circular(12.dg),
        isExpanded: true,
        padding: EdgeInsets.zero,
        value: value,
        onChanged: onChanged,
        items: items.map<DropdownMenuItem<String>>((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              getLanguageName(item),
              style: appTextStyle16400(AppColors.appGrayTextColor),
            ),
          );
        }).toList(),
        dropdownColor: AppColors.whiteColor,
        style: const TextStyle(color: Colors.black),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
      ),
    ),
  );
}

String getLanguageName(String languageCode) {
  switch (languageCode) {
    case 'en':
      return 'English';
    case 'ru':
      return 'Russian';
    default:
      return 'Unknown';
  }
}
