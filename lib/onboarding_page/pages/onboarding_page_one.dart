import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:stylehub/constants/app/app_colors.dart';
import 'package:stylehub/constants/app/textstyle.dart';
import 'package:stylehub/constants/localization/locales.dart';

class OnboardingPageOne extends StatelessWidget {
  const OnboardingPageOne({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              SizedBox(width: 60.w),
              _buildStylistRow('assets/master1.png', LocaleData.find.getString(context), true, 80.dg),
            ],
          ),
          SizedBox(height: 10.h),
          _buildStylistRow('assets/master2.png', LocaleData.stylists.getString(context), false, 60.dg),
          SizedBox(height: 10.h),
          _buildStylistRow('assets/master3.png', LocaleData.nearYou.getString(context), true, 70.dg),
        ],
      ),
    );
  }

  Widget _buildStylistRow(String imagePath, String text, bool isImageFirst, double avatarRadius) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isImageFirst)
          Container(
            padding: EdgeInsets.all(4.dg),
            decoration: BoxDecoration(
              color: AppColors.whiteColor,
              borderRadius: BorderRadius.circular(100.dg),
            ),
            child: CircleAvatar(
              radius: avatarRadius,
              backgroundImage: AssetImage(imagePath),
            ),
          ),
        if (isImageFirst) SizedBox(width: 30.w),
        Text(text, style: bigTextStyle()),
        if (!isImageFirst) SizedBox(width: 30.w),
        if (!isImageFirst)
          Container(
            padding: EdgeInsets.all(4.dg),
            decoration: BoxDecoration(
              color: AppColors.whiteColor,
              borderRadius: BorderRadius.circular(100.dg),
            ),
            child: CircleAvatar(
              radius: avatarRadius,
              backgroundImage: AssetImage(imagePath),
            ),
          ),
      ],
    );
  }
}
