import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:stylehub/constants/Helpers/app_storage.dart';
import 'package:stylehub/constants/app/app_colors.dart';
import 'package:stylehub/constants/app/textstyle.dart';
import 'package:stylehub/constants/localization/locales.dart';
import 'package:stylehub/screens/specialist_pages/provider/specialist_provider.dart';

class PersonalDetailScreen extends StatefulWidget {
  const PersonalDetailScreen({super.key});

  @override
  State<PersonalDetailScreen> createState() => _PersonalDetailScreenState();
}

class _PersonalDetailScreenState extends State<PersonalDetailScreen> {
  final emailController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final passwordController = TextEditingController();

  bool isHidePassword = true;

  void togglePassword() {
    setState(() {
      isHidePassword = !isHidePassword;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadPassword();
  }

  /// Loads the saved password from SharedPreferences and updates the
  /// `_password` field.
  ///
  /// This method is called when the widget is initialized.
  ///
  /// If the password is not found in SharedPreferences, the `_password` field
  /// will be set to null.
  ///
  /// This method is asynchronous, as it waits for the SharedPreferences to
  /// load the password.

  String? _password;
  Future<void> _loadPassword() async {
    String? password = await SharedPreferencesHelper.getPassword();
    setState(() {
      _password = password;
    });
  }

  @override
  Widget build(BuildContext context) {
    // print(_password.toString());
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: AppBar(
        backgroundColor: AppColors.whiteColor,
      ),
      body: SafeArea(
        child: Consumer<SpecialistProvider>(builder: (context, provider, _) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 33.w),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Row(
                    children: [
                      SizedBox(height: 50.h, width: 50.w, child: Image.asset('assets/images/User.png')),
                      SizedBox(width: 5.w),
                      Text(
                        LocaleData.personalDetails.getString(context),
                        style: appTextStyle205(AppColors.newThirdGrayColor),
                      ),
                    ],
                  ),
                  SizedBox(height: 44.h),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PersonalDetailText(
                        text: LocaleData.firstName.getString(context),
                      ),
                      SizedBox(height: 15.h),
                      PersonalDetailForm(
                        controller: firstNameController,
                        hintText: provider.specialistModel?.firstName,
                      ),
                      SizedBox(
                        height: 25.h,
                      ),
                      PersonalDetailText(
                        text: LocaleData.lastName.getString(context),
                      ),
                      SizedBox(height: 15.h),
                      PersonalDetailForm(
                        controller: lastNameController,
                        hintText: provider.specialistModel!.lastName,
                      ),
                      SizedBox(
                        height: 25.h,
                      ),
                      PersonalDetailText(
                        text: LocaleData.email.getString(context),
                      ),
                      SizedBox(height: 15.h),
                      PersonalDetailForm(
                        controller: emailController,
                        hintText: provider.specialistModel!.email,
                      ),
                      SizedBox(
                        height: 25.h,
                      ),
                      PersonalDetailText(
                        text: LocaleData.password.getString(context),
                      ),
                      SizedBox(height: 15.h),
                      PersonalDetailForm(
                        isPassword: isHidePassword,
                        controller: passwordController,
                        hintText: !isHidePassword ? _password.toString() : '**********',
                        suffixIcon: IconButton(
                            onPressed: togglePassword,
                            icon: Icon(
                              isHidePassword ? Icons.visibility_off : Icons.visibility,
                              color: Colors.black,
                            )),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pushNamed(context, '/send_otp_screen'),
                            child: Text(
                              LocaleData.changePassword.getString(context),
                              style: appTextStyle16(AppColors.newThirdGrayColor),
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class PersonalDetailText extends StatelessWidget {
  const PersonalDetailText({
    super.key,
    required this.text,
  });
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: appTextStyle15(AppColors.appGrayTextColor));
  }
}

class PersonalDetailForm extends StatelessWidget {
  const PersonalDetailForm({
    super.key,
    required this.controller,
    this.hintText,
    this.validator,
    this.suffixIcon,
    this.isPassword = false,
    this.initialValue,
    this.enabled,
  });
  final String? hintText;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final bool isPassword;
  final bool? enabled;
  final String? initialValue;

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      initialValue: initialValue,
      decoration: InputDecoration(
        labelStyle: appTextStyle12K(AppColors.appGrayTextColor),
        hintStyle: appTextStyle16400(AppColors.appGrayTextColor),
        hintText: hintText,
        fillColor: AppColors.grayColor,
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.h), borderSide: BorderSide.none),
        suffixIcon: suffixIcon,
      ),
      validator: validator,
      enabled: enabled,

      // (value) {
      //   if (value == null || value.isEmpty) {
      //     return LocaleData.emailRequired.getString(context);
      //   }
      //   if (!validateEmail(value)) {
      //     // Use one of the validation methods above
      //     return LocaleData.emailInvalid.getString(context);
      //   }
      //   return null;
      // },
    );
  }
}
