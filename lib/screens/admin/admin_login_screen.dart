import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:stylehub/constants/app/app_colors.dart';
import 'package:stylehub/constants/app/textstyle.dart';
import 'package:stylehub/constants/localization/locales.dart';
import 'package:stylehub/onboarding_page/onboarding_screen.dart';
import 'package:stylehub/screens/admin/admin_panel.dart';
import 'package:stylehub/services/fcm_services/firebase_msg.dart';
import 'package:stylehub/services/firebase_auth.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  String? selectedRole;
  final FirebaseService _firebaseService = FirebaseService(); // Create an instance of FirebaseService

  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  FirebaseNotificationService firebasePushNotificationService = FirebaseNotificationService();

  // Loading states

  bool _isLoggingIn = false;
  bool _isPasswordHidden = true;

  void togglePassword() {
    setState(() {
      _isPasswordHidden = !_isPasswordHidden;
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    nameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBGColor,
      body: SingleChildScrollView(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.h),
              child: Column(
                children: [
                  // SizedBox(height: 20.h),
                  SizedBox(
                    height: 120.h,
                    child: Image.asset(
                      'assets/logo.png',
                      // width: 250.h,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  _buildLoginTab(context)
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginTab(context) {
    loginAdmin() async {
      setState(() => _isLoggingIn = true);

      FirebaseFirestore.instance.collection('admin').get().then((snapshot) {
        for (var doc in snapshot.docs) {
          if (doc['name'] == nameController.text.trim() && doc['password'] == passwordController.text.trim()) {
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const AdminDashboard()), (_) => false);
            setState(() => _isLoggingIn = false);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(LocaleData.loginFailed.getString(context))),
            );
          }
        }
        setState(() => _isLoggingIn = false);
      });
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(LocaleData.loginAsAdmin.getString(context), style: bigTextStyle2()),
          SizedBox(height: 40.h),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(LocaleData.name.getString(context), style: appTextStyle15(AppColors.appGrayTextColor)),
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelStyle: appTextStyle12K(AppColors.appGrayTextColor),
                  hintStyle: appTextStyle12K(AppColors.appGrayTextColor),
                  hintText: LocaleData.enterName.getString(context),
                  // hintText: LocaleData.email.getString(context),
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return LocaleData.nameRequired.getString(context);
                  }

                  return null;
                },
              ),
            ],
          ),
          SizedBox(height: 20.h),

          // SizedBox(height: 10.h),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(LocaleData.password.getString(context), style: appTextStyle15(AppColors.appGrayTextColor)),
              TextFormField(
                controller: passwordController,
                obscureText: _isPasswordHidden,
                decoration: InputDecoration(
                  labelStyle: appTextStyle12K(AppColors.appGrayTextColor),
                  hintStyle: appTextStyle12K(AppColors.appGrayTextColor),
                  hintText: LocaleData.password.getString(context),
                  // hintText: LocaleData.password.getString(context),
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  suffixIcon: IconButton(
                      onPressed: togglePassword,
                      icon: Icon(
                        _isPasswordHidden ? Icons.visibility_off : Icons.visibility,
                        color: Colors.black,
                      )),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return LocaleData.passwordRequired.getString(context);
                  }
                  return null;
                },
              ),
            ],
          ),

          const SizedBox(height: 40),
          SizedBox(
            width: 212.w,
            height: 45.h,
            child: ReusableButton(
              text: _isLoggingIn
                  ? SizedBox(
                      height: 20.h,
                      width: 20.w,
                      child: CircularProgressIndicator(
                        color: AppColors.appGrayTextColor,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(LocaleData.login.getString(context), style: mediumTextStyle25(AppColors.mainBlackTextColor)),
              // text: LocaleData.register.getString(context),
              color: Colors.black,
              bgColor: AppColors.whiteColor,
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _isLoggingIn ? null : loginAdmin();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
