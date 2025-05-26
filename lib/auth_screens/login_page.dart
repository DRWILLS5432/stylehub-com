import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:stylehub/constants/Helpers/app_storage.dart';
import 'package:stylehub/constants/app/app_colors.dart';
import 'package:stylehub/constants/app/textstyle.dart';
import 'package:stylehub/constants/localization/locales.dart';
import 'package:stylehub/onboarding_page/onboarding_screen.dart';
import 'package:stylehub/screens/customer_pages/customer_home_page.dart';
import 'package:stylehub/screens/specialist_pages/specialist_home_page.dart';
import 'package:stylehub/services/fcm_services/firebase_msg.dart';
import 'package:stylehub/services/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? selectedRole;
  final FirebaseService _firebaseService = FirebaseService(); // Create an instance of FirebaseService
  // Text Editing Controllers (Moved to State)
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController loginEmailController = TextEditingController();
  final TextEditingController loginPasswordController = TextEditingController();

  FirebaseNotificationService firebasePushNotificationService = FirebaseNotificationService();

  // Loading states
  bool _isRegistering = false;
  bool _isLoggingIn = false;
  bool _isPasswordHidden = true;

  final FocusNode _passwordFocusNode = FocusNode();
  // LayerLink and Popup Visibility
  final LayerLink _roleLayerLink = LayerLink();
  bool _isRolePopupVisible = false;

  void togglePassword() {
    setState(() {
      _isPasswordHidden = !_isPasswordHidden;
    });
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _passwordFocusNode.dispose();
    firstNameController.dispose(); // Dispose controllers
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBGColor,
      body: SafeArea(
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
                //  SizedBox(height: 20.h),
                TabBar(
                  dividerColor: Colors.transparent,
                  controller: _tabController,
                  indicatorColor: Colors.black,
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(text: LocaleData.createAccount.getString(context)),
                    Tab(text: LocaleData.login.getString(context)),
                  ],
                ),
                SizedBox(height: 40.h),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCreateAccountTab(context),
                      _buildLoginTab(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateAccountTab(context) {
    Future<void> register() async {
      if (selectedRole == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a role')),
        );
        return;
      }
      // Start loading
      setState(() => _isRegistering = true);

      try {
        User? user = await _firebaseService.registerUser(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
          firstName: firstNameController.text.trim(),
          lastName: lastNameController.text.trim(),
          role: selectedRole!,
        );

        if (user != null) {
          if (selectedRole == LocaleData.customer.getString(context)) {
            Navigator.pushNamed(context, '/customer_page');
          } else if (selectedRole == LocaleData.stylist.getString(context)) {
            Navigator.pushNamed(context, '/specialist_page');
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      } finally {
        setState(() => _isRegistering = false);
      }
    }

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CompositedTransformTarget(
              link: _roleLayerLink,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isRolePopupVisible = !_isRolePopupVisible;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.dg),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 15.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedRole ?? LocaleData.selectRole.getString(context),
                        style: selectedRole == null ? appTextStyle12K(AppColors.appGrayTextColor) : const TextStyle(color: Colors.black),
                      ),
                      const Icon(Icons.arrow_drop_down, color: Colors.black),
                    ],
                  ),
                ),
              ),
            ),
            if (_isRolePopupVisible)
              CompositedTransformFollower(
                link: _roleLayerLink,
                offset: Offset(0, 65.h), //Adjust offset to move popup below the button
                child: Material(
                  color: Colors.transparent,
                  child: SizedBox(
                    width: double.infinity,
                    // decoration: BoxDecoration(
                    //   color: Colors.white,
                    //   borderRadius: BorderRadius.circular(14.dg),
                    //   border: Border.all(color: Colors.black),
                    // ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        InkWell(
                          onTap: () {
                            setState(() {
                              selectedRole = LocaleData.customer.getString(context);
                              _isRolePopupVisible = false;
                            });
                          },
                          child: Container(
                            height: 48.h,
                            margin: EdgeInsets.only(bottom: 5.h),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10.dg), border: Border.all(color: Colors.black), color: Colors.white),
                            // alignment: Alignment.center,
                            child: Padding(
                              padding: EdgeInsets.all(10.dg),
                              child: Text(
                                LocaleData.customer.getString(context),
                                style: const TextStyle(color: Colors.black),
                                textAlign: TextAlign.start,
                              ),
                            ),
                          ),
                        ),
                        // Divider(height: 1.h, color: Colors.grey),
                        InkWell(
                          onTap: () {
                            setState(() {
                              selectedRole = LocaleData.stylist.getString(context);
                              _isRolePopupVisible = false;
                            });
                          },
                          child: Container(
                            height: 48.h,
                            margin: EdgeInsets.only(bottom: 5.h),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10.dg), border: Border.all(color: Colors.black), color: Colors.white),
                            // alignment: Alignment.center,
                            child: Padding(
                              padding: EdgeInsets.all(10.dg),
                              child: Text(
                                LocaleData.stylist.getString(context),
                                style: const TextStyle(color: Colors.black),
                                textAlign: TextAlign.start,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // DropdownButtonFormField<String>(
            //   borderRadius: BorderRadius.circular(14.dg),
            //   value: selectedRole,
            //   hint: Text(LocaleData.selectRole.getString(context), style: appTextStyle12K(AppColors.appGrayTextColor)),
            //   decoration: InputDecoration(
            //     fillColor: Colors.white,
            //     filled: true,
            //     border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.dg), borderSide: BorderSide.none),
            //     contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 15.h),
            //   ),
            //   onChanged: (String? newValue) {
            //     setState(() => selectedRole = newValue);
            //   },
            //   items: <String>[
            //     LocaleData.customer.getString(context),
            //     LocaleData.stylist.getString(context),
            //   ].map<DropdownMenuItem<String>>((String value) {
            //     return DropdownMenuItem<String>(
            //       value: value,
            //       child: Container(
            //           width: double.maxFinite,
            //           height: 40.h,
            //           decoration: BoxDecoration(
            //             borderRadius: BorderRadius.circular(14.dg),
            //             border: Border.all(color: Colors.black),
            //             color: Colors.white,
            //           ),
            //           child: Center(child: Text(value))),
            //     );
            //   }).toList(),
            //   isExpanded: true,
            //   style: const TextStyle(color: Colors.black),
            //   dropdownColor: Colors.white,
            //   icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
            // ),
            SizedBox(height: 20.h),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(LocaleData.firstName.getString(context), style: appTextStyle15(AppColors.appGrayTextColor)),
                TextFormField(
                  controller: firstNameController,
                  decoration: InputDecoration(
                    hintText: LocaleData.firstName.getString(context),
                    labelStyle: appTextStyle12K(AppColors.appGrayTextColor),
                    hintStyle: appTextStyle12K(AppColors.appGrayTextColor),
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.dg), borderSide: BorderSide.none),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return LocaleData.firstNameRequired.getString(context);
                    }
                    return null;
                  },
                ),
              ],
            ),
            SizedBox(height: 20.h),
            CustomeTextField(
              context: context,
              lastNameController: lastNameController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return LocaleData.lastNameRequired.getString(context);
                }
                return null;
              },
            ),
            SizedBox(height: 20.h),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(LocaleData.email.getString(context), style: appTextStyle15(AppColors.appGrayTextColor)),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelStyle: appTextStyle12K(AppColors.appGrayTextColor),
                    hintStyle: appTextStyle12K(AppColors.appGrayTextColor),
                    hintText: LocaleData.email.getString(context),
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.h), borderSide: BorderSide.none),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return LocaleData.emailRequired.getString(context);
                    }
                    if (!validateEmail(value)) {
                      // Use one of the validation methods above
                      return LocaleData.emailInvalid.getString(context);
                    }
                    return null;
                  },
                ),
              ],
            ),
            SizedBox(height: 20.h),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(LocaleData.password.getString(context), style: appTextStyle15(AppColors.appGrayTextColor)),
                TextFormField(
                  controller: passwordController,
                  obscureText: _isPasswordHidden,
                  // focusNode: _passwordFocusNode,
                  decoration: InputDecoration(
                      labelStyle: appTextStyle12K(AppColors.appGrayTextColor),
                      hintStyle: appTextStyle12K(AppColors.appGrayTextColor),
                      hintText: LocaleData.password.getString(context),
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.dg), borderSide: BorderSide.none),
                      suffixIcon: IconButton(
                          onPressed: togglePassword,
                          icon: Icon(
                            _isPasswordHidden ? Icons.visibility_off : Icons.visibility,
                            color: Colors.black,
                          ))),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return LocaleData.passwordRequired.getString(context);
                    } else if (value.length < 6) {
                      return LocaleData.passwordInvalid.getString(context);
                    }
                    return null;
                  },
                ),
              ],
            ),
            SizedBox(height: 40.h),
            SizedBox(
              width: 212.w,
              height: 45.h,
              child: ReusableButton(
                text: _isRegistering
                    ? SizedBox(
                        height: 20.h,
                        width: 20.w,
                        child: CircularProgressIndicator(
                          color: AppColors.appGrayTextColor,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(LocaleData.register.getString(context), style: mediumTextStyle25(AppColors.mainBlackTextColor)),
                // text: LocaleData.register.getString(context),
                color: Colors.black,
                bgColor: AppColors.whiteColor,
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    if (selectedRole != null) {
                      // Form is valid AND a role is selected
                      if (!_isRegistering) {
                        // Check if not already registering
                        register();
                      }
                    } else {
                      // Form is valid BUT NO role is selected
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(LocaleData.roleRequired.getString(context))),
                      );
                    }
                  }
                },
              ),
            ),
            SizedBox(height: 20.h),
            Text(LocaleData.termsAndConditions.getString(context), style: appTextStyle12K(AppColors.appGrayTextColor)),
            Text('StyleHub 2024', style: appTextStyle12K(AppColors.appGrayTextColor)),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginTab(context) {
    Future<void> login() async {
      setState(() => _isLoggingIn = true);

      try {
        User? user = await _firebaseService.loginUser(
          email: loginEmailController.text.trim(),
          password: loginPasswordController.text.trim(),
        );

        if (user != null) {
          // Fetch user document
          DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

          final data = userDoc.data() as Map<String, dynamic>?;

          if (data == null) {
            throw Exception("User data is null.");
          }

          // Safely check for 'suspended'
          final isSuspended = data['suspended'] == true;

          if (isSuspended) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                content: SizedBox(height: 250.h, child: SuspendedUserScreen()),
              ),
            );

            return;
          }

          // Save the password
          await SharedPreferencesHelper.savePassword(loginPasswordController.text.trim());

          // Continue as normal
          String? role = await _firebaseService.getUserRole(user.uid);

          firebasePushNotificationService.sendPushNotification(
            'Welcome to StyleHub',
            'Thank you for logging in. We hope you enjoy our services',
            user,
          );

          if (role == LocaleData.customer.getString(context)) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => CustomerPage()),
            );
          } else if (role == LocaleData.stylist.getString(context)) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => SpecialistPage()),
            );
          }
        }
      } catch (e) {
        // print(e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login details incorrect. Please try again.')),
        );
      } finally {
        setState(() => _isLoggingIn = false);
      }
    }

    // Future<void> login() async {
    //   setState(() => _isLoggingIn = true);

    //   try {
    //     User? user = await _firebaseService.loginUser(
    //       email: loginEmailController.text.trim(),
    //       password: loginPasswordController.text.trim(),
    //     );

    //     if (user != null) {
    //       // Save the password to SharedPreferences
    //       await SharedPreferencesHelper.savePassword(loginPasswordController.text.trim());

    //       String? role = await _firebaseService.getUserRole(user.uid);
    //       if (role == 'Customer') {
    //         Navigator.pushReplacement(
    //           context,
    //           MaterialPageRoute(builder: (context) => CustomerPage()),
    //         );
    //       } else if (role == 'Stylist') {
    //         Navigator.pushReplacement(
    //           context,
    //           MaterialPageRoute(builder: (context) => SpecialistPage()),
    //         );
    //       }
    //     }
    //   } catch (e) {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(content: Text(e.toString())),
    //     );
    //   } finally {
    //     setState(() => _isLoggingIn = false);
    //   }
    // }

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(LocaleData.welcomeBack.getString(context), style: bigTextStyle2()),
          SizedBox(height: 40.h),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(LocaleData.email.getString(context), style: appTextStyle15(AppColors.appGrayTextColor)),
              TextFormField(
                controller: loginEmailController,
                decoration: InputDecoration(
                  labelStyle: appTextStyle12K(AppColors.appGrayTextColor),
                  hintStyle: appTextStyle12K(AppColors.appGrayTextColor),
                  hintText: LocaleData.email.getString(context),
                  // hintText: LocaleData.email.getString(context),
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return LocaleData.emailRequired.getString(context);
                  }
                  if (!validateEmail(value)) {
                    // Use one of the validation methods above
                    return LocaleData.emailInvalid.getString(context);
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
                controller: loginPasswordController,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/send_otp_screen'),
                child: Text(
                  LocaleData.forgotPassword.getString(context),
                  style: appTextStyle16(AppColors.mainBlackTextColor),
                ),
              )
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
                  _isLoggingIn ? null : login();
                }
              },
            ),
          ),

          SizedBox(height: 40.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/admin_page'),
                child: Text(
                  LocaleData.goToAdmin.getString(context),
                  style: appTextStyle16(AppColors.mainBlackTextColor),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}

class CustomeTextField extends StatelessWidget {
  const CustomeTextField({
    super.key,
    required this.context,
    required this.lastNameController,
    this.validator,
  });

  final BuildContext context;
  final TextEditingController lastNameController;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(LocaleData.lastName.getString(context), style: appTextStyle15(AppColors.appGrayTextColor)),
        TextFormField(
            controller: lastNameController,
            decoration: InputDecoration(
              labelStyle: appTextStyle12K(AppColors.appGrayTextColor),
              hintStyle: appTextStyle12K(AppColors.appGrayTextColor),
              hintText: LocaleData.lastName.getString(context),
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.dg), borderSide: BorderSide.none),
            ),
            validator: validator),
      ],
    );
  }
}

bool validateEmail(String email) {
  String pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$';
  RegExp regex = RegExp(pattern);
  return regex.hasMatch(email);
}

class SuspendedUserScreen extends StatelessWidget {
  const SuspendedUserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              'Account Suspended',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              'Your account has been suspended.\nPlease contact customer support for more information.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
