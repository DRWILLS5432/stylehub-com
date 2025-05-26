import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:stylehub/constants/app/app_colors.dart';
import 'package:stylehub/constants/app/textstyle.dart';
import 'package:stylehub/constants/localization/locales.dart';
import 'package:stylehub/onboarding_page/onboarding_screen.dart';
import 'package:stylehub/screens/specialist_pages/provider/filter_provider.dart';

class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  final List<String> cities = ['Petrozavodsk', 'Moscow', 'Saint-Petersburg', 'Omsk'];

  @override
  Widget build(BuildContext context) {
    final filterProvider = Provider.of<FilterProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: AppBar(
        backgroundColor: AppColors.whiteColor,
        actions: [
          // if (filterProvider.filtersApplied)
          TextButton(
            onPressed: () {
              filterProvider.clearFilters();
              Navigator.pop(context);
            },
            child: Text(
              'Clear',
              style: appTextStyle16(AppColors.mainBlackTextColor),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filters',
                      style: appTextStyle24(AppColors.mainBlackTextColor),
                    ),
                    if (filterProvider.filtersApplied)
                      Center(
                        child: SizedBox(
                          // width: 272.w,
                          child: TextButton(
                            onPressed: () {
                              filterProvider.clearFilters();
                              Navigator.pop(context);
                            },
                            child: Text(
                              'Clear Filters',
                              style: appTextStyle16(AppColors.primaryRedColor),
                            ),
                          ),
                        ),
                      ),
                    // Image.asset(
                    //   'assets/categ_settings.png',
                    //   width: 24,
                    //   height: 24,
                    // ),
                  ],
                ),
                SizedBox(height: 40.h),
                Text(
                  'Proximity',
                  style: appTextStyle20(AppColors.mainBlackTextColor),
                ),
                SizedBox(height: 20.h),

                // Proximity filter slider
                // Row(
                //   children: [
                //     Expanded(
                //       child: Column(
                //         crossAxisAlignment: CrossAxisAlignment.start,
                //         children: [
                //           Text(
                //             'Maximum Distance (${filterProvider.maxDistance?.toStringAsFixed(1) ?? '0'} km)',
                //             style: appTextStyle16(AppColors.newGrayColor),
                //           ),
                //           Slider(
                //             value: filterProvider.maxDistance ?? 0,
                //             min: 0,
                //             max: 100,
                //             divisions: 20,
                //             label: '${(filterProvider.maxDistance ?? 0).toStringAsFixed(1)} km',
                //             onChanged: (value) {
                //               filterProvider.setMaxDistance(value);
                //             },
                //           ),
                //         ],
                //       ),
                //     ),
                //   ],
                // ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Nearest specialists',
                      style: appTextStyle20(AppColors.newGrayColor),
                    ),
                    Checkbox(
                      // value: filterProvider.nearestSpecialists,
                      // onChanged: (bool? value) {
                      //   filterProvider.toggleNearestSpecialists(value ?? false);
                      // },

                      value: filterProvider.sortByDistance,
                      onChanged: (value) {
                        filterProvider.toggleSortByDistance(value ?? false);
                      },
                    )
                  ],
                ),
                SizedBox(height: 20.h),
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //   children: [
                //     Text(
                //       'Sort by Distance',
                //       style: appTextStyle16(AppColors.newGrayColor),
                //     ),
                //     Switch(
                //       value: filterProvider.sortByDistance,
                //       onChanged: (value) {
                //         filterProvider.toggleSortByDistance(value);
                //       },
                //       activeColor: AppColors.appBGColor,
                //     ),
                //   ],
                // ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Specialists in city',
                      style: appTextStyle20(AppColors.newGrayColor),
                    ),
                    Checkbox(
                      value: filterProvider.specialistsInCity,
                      onChanged: (bool? value) {
                        filterProvider.toggleSpecialistsInCity(value ?? false);
                      },
                    )
                  ],
                ),
                SizedBox(height: 40.h),
                Text(
                  'Rating',
                  style: appTextStyle20(AppColors.mainBlackTextColor),
                ),
                SizedBox(height: 20.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Highest Rating',
                      style: appTextStyle20(AppColors.newGrayColor),
                    ),
                    Checkbox(
                      value: filterProvider.highestRating,
                      onChanged: (bool? value) {
                        filterProvider.toggleHighestRating(value ?? false);
                      },
                    )
                  ],
                ),
                SizedBox(height: 20.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Medium Rating',
                      style: appTextStyle20(AppColors.newGrayColor),
                    ),
                    Checkbox(
                      value: filterProvider.mediumRating,
                      onChanged: (bool? value) {
                        filterProvider.toggleMediumRating(value ?? false);
                      },
                    )
                  ],
                ),
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Text(
                      LocaleData.city.getString(context),
                      style: appTextStyle20(AppColors.mainBlackTextColor),
                    ),
                    Spacer(),
                    TextButton(
                      onPressed: () => _showCityModal(context),
                      child: Container(
                        width: 190.w,
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.mainBlackTextColor),
                          borderRadius: BorderRadius.circular(50.dg),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              filterProvider.selectedCity ?? 'Select City',
                              style: appTextStyle12(),
                            ),
                            Icon(Icons.arrow_drop_down, size: 20),
                          ],
                        ),
                      ),
                    )

                    // Padding(
                    //   padding: EdgeInsets.only(right: 16.w),
                    //   child: SizedBox(
                    //     width: 190.w,
                    //     child: DropdownButtonFormField<String>(
                    //       padding: EdgeInsets.symmetric(horizontal: 16.w),
                    //       value: filterProvider.selectedCity,
                    //       decoration: InputDecoration(
                    //         enabledBorder: OutlineInputBorder(
                    //           borderRadius: BorderRadius.circular(50.dg),
                    //           borderSide: BorderSide(color: AppColors.mainBlackTextColor),
                    //         ),
                    //         focusedBorder: OutlineInputBorder(
                    //           borderRadius: BorderRadius.circular(50.dg),
                    //           borderSide: BorderSide(color: AppColors.mainBlackTextColor),
                    //         ),
                    //         border: OutlineInputBorder(
                    //           borderSide: BorderSide(color: AppColors.grayColor),
                    //         ),
                    //         contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
                    //       ),
                    //       hint: Text(
                    //         'Select City',
                    //         style: appTextStyle12(),
                    //       ),
                    //       items: cities.map((String city) {
                    //         return DropdownMenuItem<String>(
                    //           value: city,
                    //           child: Text(
                    //             city,
                    //             style: appTextStyle12(),
                    //           ),
                    //         );
                    //       }).toList(),
                    //       onChanged: (String? value) {
                    //         filterProvider.setSelectedCity(value);
                    //       },
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
                SizedBox(height: 50.h),

                // Spacer(),
                Column(
                  children: [
                    Center(
                      child: SizedBox(
                        width: 272.w,
                        child: ReusableButton(
                          height: 60.h,
                          color: AppColors.appBGColor,
                          bgColor: AppColors.grayColor,
                          text: Text(
                            'Apply Filters',
                            style: appTextStyle16(AppColors.newThirdGrayColor),
                          ),
                          onPressed: () {
                            filterProvider.applyFilters();
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                  ],
                ),
                // SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCityModal(BuildContext context) {
    final filterProvider = Provider.of<FilterProvider>(context, listen: false);

    showModalBottomSheet(
      backgroundColor: AppColors.whiteColor,
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16.w),
          height: 320.h,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select City',
                style: appTextStyle18(AppColors.mainBlackTextColor),
              ),
              SizedBox(height: 16.h),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: cities.length,
                  itemBuilder: (context, index) {
                    final city = cities[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 3.h),
                      decoration: BoxDecoration(
                        color: AppColors.appBGColor.withValues(alpha: 0.2),
                      ),
                      child: ListTile(
                        title: Text(city),
                        onTap: () {
                          filterProvider.setSelectedCity(city);
                          Navigator.pop(context);
                        },
                        trailing: filterProvider.selectedCity == city ? Icon(Icons.check, color: AppColors.mainBlackTextColor) : null,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
