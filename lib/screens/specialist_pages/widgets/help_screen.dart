import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:stylehub/constants/app/app_colors.dart';
import 'package:stylehub/constants/app/textstyle.dart';
import 'package:stylehub/constants/localization/locales.dart';
import 'package:stylehub/onboarding_page/onboarding_screen.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitTicket() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in to submit a ticket.')),
          );
          return;
        }

        await FirebaseFirestore.instance.collection('supportTickets').add({
          'userId': user.uid,
          'userEmail': user.email ?? 'Unknown',
          'subject': _subjectController.text.trim(),
          'message': _messageController.text.trim(),
          'status': 'open',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'responses': [],
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket submitted successfully!')),
        );
        _subjectController.clear();
        _messageController.clear();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting ticket: $e')),
        );
      } finally {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBGColor,
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: AppColors.appBGColor,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 24.h),
                Text(LocaleData.subject.getString(context), style: appTextStyle15(AppColors.mainBlackTextColor)),
                SizedBox(height: 10.h),
                TextFormField(
                  controller: _subjectController,
                  decoration: InputDecoration(
                    hintText: LocaleData.subject.getString(context),
                    labelStyle: appTextStyle12K(AppColors.appGrayTextColor),
                    hintStyle: appTextStyle12K(AppColors.appGrayTextColor),
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.dg), borderSide: BorderSide.none),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Please enter a subject' : null,
                ),
                // TextFormField(
                //   controller: _subjectController,
                //   decoration: const InputDecoration(
                //     labelText: 'Subject',
                //     border: OutlineInputBorder(),
                //   ),
                //   validator: (value) => value?.isEmpty ?? true ? 'Please enter a subject' : null,
                // ),

                SizedBox(height: 24.h),
                Text(LocaleData.message.getString(context), style: appTextStyle15(AppColors.mainBlackTextColor)),
                SizedBox(height: 10.h),
                TextFormField(
                  controller: _messageController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: LocaleData.subject.getString(context),
                    labelStyle: appTextStyle12K(AppColors.appGrayTextColor),
                    hintStyle: appTextStyle12K(AppColors.appGrayTextColor),
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.dg), borderSide: BorderSide.none),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Please enter a message' : null,
                ),
                // TextFormField(
                //   controller: _messageController,
                //   decoration: const InputDecoration(
                //     labelText: 'Message',
                //     border: OutlineInputBorder(),
                //   ),
                //   maxLines: 5,
                //   validator: (value) => value?.isEmpty ?? true ? 'Please enter a message' : null,
                // ),
                SizedBox(height: 24.h),
                Padding(
                  padding: EdgeInsets.all(60.h),
                  child: ReusableButton(
                    text: _isSubmitting
                        ? SizedBox(
                            height: 20.h,
                            width: 20.w,
                            child: CircularProgressIndicator(
                              color: AppColors.appGrayTextColor,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(LocaleData.submit.getString(context), style: mediumTextStyle25(AppColors.mainBlackTextColor)),
                    // text: LocaleData.register.getString(context),
                    color: Colors.black,
                    bgColor: AppColors.whiteColor,
                    onPressed: () => _isSubmitting ? null : _submitTicket(),
                  ),
                ),
                // ElevatedButton(
                //   onPressed: _isSubmitting ? null : _submitTicket,
                //   child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text('Submit Ticket'),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
