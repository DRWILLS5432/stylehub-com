import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:stylehub/auth_screens/login_page.dart';
import 'package:stylehub/constants/app/app_colors.dart';
import 'package:stylehub/constants/app/textstyle.dart';
import 'package:stylehub/constants/localization/locales.dart';
import 'package:stylehub/onboarding_page/onboarding_screen.dart';
import 'package:stylehub/services/firebase_auth.dart';

class SendOtpScreen extends StatefulWidget {
  const SendOtpScreen({super.key});

  @override
  State<SendOtpScreen> createState() => _SendOtpScreenState();
}

class _SendOtpScreenState extends State<SendOtpScreen> {
  final _emailController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();

    super.dispose();
  }

  Future<void> _sendOtp(context) async {
    setState(() => _isLoading = true);
    try {
      await _firebaseService.sendPasswordResetEmail(_emailController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent! Check your inbox.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBGColor,
      appBar: AppBar(
        backgroundColor: AppColors.appBGColor,
        title: SizedBox(
          height: 100.h,
          child: Image.asset(
            'assets/logo.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          // Added SingleChildScrollView
          child: Padding(
            padding: EdgeInsets.all(16.dg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 10.h),
                Text(
                  LocaleData.changePassword.getString(context),
                  style: appTextStyle23(AppColors.mainBlackTextColor),
                ),
                SizedBox(height: 60.h),
                Row(
                  children: [
                    Text(
                      LocaleData.enterRegisteredEmail.getString(context),
                      style: appTextStyle15(AppColors.mainBlackTextColor),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelStyle: appTextStyle12K(AppColors.appGrayTextColor),
                    hintStyle: appTextStyle12K(AppColors.appGrayTextColor),
                    hintText: LocaleData.email.getString(context),
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return LocaleData.emailRequired.getString(context);
                    }
                    if (!validateEmail(value)) {
                      return LocaleData.emailInvalid.getString(context);
                    }
                    return null;
                  },
                ),
                SizedBox(height: 50.h),
                Text(
                  LocaleData.checkEmail.getString(context),
                  style: appTextStyle14(AppColors.mainBlackTextColor),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: 180.h,
                ),
                ReusableButton(
                  text: _isLoading
                      ? SizedBox(
                          height: 20.h,
                          width: 20.w,
                          child: CircularProgressIndicator(
                            color: AppColors.appGrayTextColor,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(LocaleData.sendOTP.getString(context), style: mediumTextStyle25(AppColors.mainBlackTextColor)),
                  // text: LocaleData.register.getString(context),
                  color: Colors.black,
                  bgColor: AppColors.whiteColor,
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      if (!_isLoading) {
                        _sendOtp(context);
                      }
                    }
                  },
                ),
                SizedBox(height: 60.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
