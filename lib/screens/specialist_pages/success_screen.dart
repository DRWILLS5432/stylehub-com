import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:stylehub/constants/app/app_colors.dart';
import 'package:stylehub/constants/app/textstyle.dart';
import 'package:stylehub/constants/localization/locales.dart';
import 'package:stylehub/onboarding_page/onboarding_screen.dart';
import 'package:stylehub/screens/specialist_pages/provider/specialist_provider.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

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
      body: SingleChildScrollView(
        // Added SingleChildScrollView
        child: Padding(
          padding: EdgeInsets.all(16.dg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 100.h),
              Image.asset(
                'assets/images/tickbox.png',
              ),
              SizedBox(height: 50.h),
              Text(
                'Your Appointment is Booked Successfully',
                style: appTextStyle20(AppColors.mainBlackTextColor),
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: 100.h,
              ),
              SizedBox(
                width: 212.w,
                child: Consumer<SpecialistProvider>(
                  builder: (context, provider, child) {
                    final userData = provider.specialistModel;
                    return ReusableButton(
                      text: Text(LocaleData.goBack.getString(context), style: mediumTextStyle25(AppColors.mainBlackTextColor)),
                      // text: LocaleData.register.getString(context),
                      color: Colors.black,
                      bgColor: AppColors.whiteColor,
                      onPressed: () {
                        if (userData!.role == 'Stylist') {
                          Navigator.pushNamedAndRemoveUntil(context, '/specialist_page', (arguments) => false);
                        } else {
                          Navigator.pushNamedAndRemoveUntil(context, '/customer_page', (arguments) => false);
                        }
                      },
                    );
                  },
                ),
              ),
              SizedBox(height: 60.h),
            ],
          ),
        ),
      ),
    );
  }
}
