import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:stylehub/constants/app/app_colors.dart';
import 'package:stylehub/constants/app/textstyle.dart';
import 'package:stylehub/constants/localization/locales.dart';
import 'package:stylehub/onboarding_page/onboarding_screen.dart';
import 'package:stylehub/screens/specialist_pages/model/appointment_model.dart';
import 'package:stylehub/screens/specialist_pages/provider/specialist_provider.dart';
import 'package:stylehub/services/fcm_services/firebase_msg.dart';
import 'package:stylehub/storage/appointment_repo.dart';

class AppointmentScheduler extends StatefulWidget {
  const AppointmentScheduler({super.key});

  @override
  State<AppointmentScheduler> createState() => _AppointmentSchedulerState();
}

class _AppointmentSchedulerState extends State<AppointmentScheduler> {
  late DateTime _currentWeekStart;
  final bool _is24HourFormat = false;
  List<TimeSlot> _timeSlots = [];
  bool _isExpanded = false;
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  String specialistAddress = '';

  @override
  void initState() {
    super.initState();
    _currentWeekStart = _getFirstMonday(DateTime.now());
    _initializeTimeSlots();
    _loadSavedSlots();
    getUserInfo();
  }

  void getUserInfo() {
    Provider.of<SpecialistProvider>(context, listen: false).fetchSpecialistData();
    final specialistModel = Provider.of<SpecialistProvider>(context, listen: false).specialistModel;

    setState(() {
      specialistAddress = specialistModel?.address ?? '';
    });
  }

  void _initializeTimeSlots() {
    _timeSlots = [];
    for (int day = 0; day < 7; day++) {
      for (int hour = 8; hour < 24; hour++) {
        for (int minute = 0; minute < 60; minute += 15) {
          _timeSlots.add(TimeSlot(
            day: day,
            hour: hour,
            minute: minute,
            isOpen: false,
          ));
        }
      }
    }
  }

  DateTime _getFirstMonday(DateTime date) {
    date = DateTime(date.year, date.month, date.day);
    while (date.weekday != DateTime.monday) {
      date = date.subtract(const Duration(days: 1));
    }
    return date;
  }

  List<DateTime> _getWeekDates() {
    return List.generate(7, (index) => _currentWeekStart.add(Duration(days: index)));
  }

  void _changeWeek(int delta) {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(Duration(days: delta * 7));
    });
    // Load slots for new week
    _loadSavedSlots();
  }

  String _formatTime(int hour, [int minute = 0]) {
    if (_is24HourFormat) {
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    }
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  bool _isSlotInPast(int day, int hour) {
    final now = DateTime.now();
    final slotDate = _currentWeekStart.add(Duration(days: day));
    final slotDateTime = DateTime(slotDate.year, slotDate.month, slotDate.day, hour);

    return slotDateTime.isBefore(now);
  }

  Future<void> _loadSavedSlots() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final weekKey = _currentWeekStart.toIso8601String();
    try {
      final doc = await FirebaseFirestore.instance.collection('availability').doc(user.uid).collection('weeks').doc(weekKey).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final savedSlots = (data['slots'] as List).map((slot) => TimeSlot.fromMap(slot)).toList();

        // Merge with default slots to ensure all slots exist
        _initializeTimeSlots(); // Create default slots first

        // Update with saved values where they exist
        for (final savedSlot in savedSlots) {
          final index = _timeSlots.indexWhere((s) => s.day == savedSlot.day && s.hour == savedSlot.hour && s.minute == savedSlot.minute);

          if (index != -1) {
            _timeSlots[index] = savedSlot;
          }
        }
      } else {
        _initializeTimeSlots(); // Just use defaults if no saved data
      }
    } catch (e) {
      _initializeTimeSlots(); // Fallback to defaults on error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading slots: $e')),
      );
    }
  }

  void _toggleHourlySlots(int day, int hour, bool isOpen, String firstName, String lastName) {
    setState(() {
      for (var slot in _timeSlots) {
        if (slot.day == day && slot.hour == hour) {
          slot.isOpen = isOpen;
        }
      }
    });
    _sendToBackend(firstName, lastName);
  }

  Future<void> _sendToBackend(String firstName, String lastName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final weekKey = _currentWeekStart.toIso8601String();
    final slotsData = _timeSlots.map((slot) => slot.toMap()).toList();

    try {
      await FirebaseFirestore.instance.collection('availability').doc(user.uid).collection('weeks').doc(weekKey).set({
        'specialistId': user.uid,
        'specialistAddress': specialistAddress,
        'specialistFirstName': firstName,
        'specialistLastName': lastName,
        'weekStart': _currentWeekStart,
        'slots': slotsData,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving slots: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final weekDates = _getWeekDates();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Schedule & Bookings',
          style: appTextStyle24(AppColors.newThirdGrayColor),
        ),
      ),
      body: SingleChildScrollView(
        child: SafeArea(
            child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // _buildHeader(),
              _buildWeekNavigator(),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.dg),
                  color: AppColors.appBGColor,
                ),
                padding: EdgeInsets.only(left: 0.w, right: 0.w, top: 12.h, bottom: 12.h),
                child: Container(
                  margin: EdgeInsets.only(left: 10.w, right: 0.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.dg),
                    color: AppColors.whiteColor,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 55.w,
                            ),
                            _buildCalendarHeader(weekDates),
                          ],
                        ),
                        SizedBox(
                          height: _isExpanded ? null : 240.h,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  child: _buildTimeTable(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                child: TextButton(
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                  child: Row(
                    children: [
                      Text(
                        _isExpanded ? 'Show Less' : 'Expand',
                        style: appTextStyle24500(AppColors.newThirdGrayColor),
                      ),
                      SizedBox(width: 8.w),
                      SizedBox(
                        height: 18.h,
                        width: 18.w,
                        child: Image.asset(
                          'assets/images/Decompress.png',
                        ),
                      )
                    ],
                  ),
                ),
              ),
              SizedBox(height: 14.h),
              Padding(
                padding: EdgeInsets.only(left: 16.w),
                child: Text(
                  'Upcoming',
                  style: appTextStyle24(AppColors.newThirdGrayColor),
                ),
              ),
              // buildUpcomingAppointments(context),

              SizedBox(height: 400.h, child: AppointmentListScreen(isSpecialist: true)),
              SizedBox(
                height: 80.h,
              )
            ],
          ),
        )),
      ),
    );
  }

  // Widget _buildHeader() {
  //   return Padding(
  //     padding: EdgeInsets.only(top: 20.h, left: 12.w),
  //     child: Text(
  //       'Schedule & Bookings',
  //       style: appTextStyle24(AppColors.newThirdGrayColor),
  //     ),
  //   );
  // }

  Widget _buildWeekNavigator() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            height: 42.h,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15.dg),
              border: Border.all(color: AppColors.appBGColor, width: 2.h),
            ),
            child: Center(
              child: Text(
                DateFormat('MMM y').format(_currentWeekStart),
                style: appTextStyle16500(AppColors.newThirdGrayColor),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 44.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.dg),
                  border: Border.all(color: AppColors.appBGColor, width: 2.h),
                ),
                child: IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _changeWeek(-1),
                ),
              ),
              SizedBox(
                width: 4.w,
              ),
              Container(
                width: 44.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.dg),
                  border: Border.all(color: AppColors.appBGColor, width: 2.h),
                ),
                child: IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _changeWeek(1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader(List<DateTime> weekDates) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(7, (index) {
        final date = weekDates[index];
        final isCurrentMonth = date.month == _currentWeekStart.month;

        return Padding(
          padding: EdgeInsets.only(left: 4.w),
          child: Container(
            width: 79.w,
            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
            child: Column(
              children: [
                Text(
                  _days[index],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isCurrentMonth ? Colors.black : Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  date.day.toString(),
                  style: TextStyle(
                    color: isCurrentMonth ? Colors.black : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTimeTable() {
    final user = Provider.of<SpecialistProvider>(context).specialistModel;
    return SizedBox(
      width: 80.w * 7.5,
      child: ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: 16,
        itemBuilder: (context, index) {
          final hour = 8 + index;
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 2.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 60.w,
                  child: Text(
                    _formatTime(hour, 0),
                    style: TextStyle(fontSize: 10.sp),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: 7,
                    itemBuilder: (context, dayIndex) {
                      // Get all 15-minute slots for this hour and day
                      final slots = _timeSlots.where((s) => s.day == dayIndex && s.hour == hour).toList();
                      bool isHourOpen = slots.isNotEmpty && slots.every((s) => s.isOpen);
                      bool isPast = slots.any((s) => _isSlotInPast(s.day, s.hour));

                      return Consumer<SpecialistProvider>(
                        builder: (context, provider, child) {
                          return GestureDetector(
                            onTap: isPast
                                ? null
                                : () => _toggleHourlySlots(
                                      dayIndex,
                                      hour,
                                      !isHourOpen,
                                      user!.firstName,
                                      user.lastName,
                                    ),
                            child: Container(
                              margin: EdgeInsets.all(1.w),
                              decoration: BoxDecoration(
                                color: isPast
                                    ? Colors.grey.shade400
                                    : isHourOpen
                                        ? Colors.green.shade100
                                        : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(2.w),
                                border: Border.all(
                                  color: isPast
                                      ? Colors.grey
                                      : isHourOpen
                                          ? Colors.green
                                          : Colors.grey,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  isPast ? 'Unavailable' : (isHourOpen ? 'Opened' : 'Open'),
                                  style: TextStyle(
                                    color: isPast
                                        ? Colors.grey
                                        : isHourOpen
                                            ? Colors.green
                                            : Colors.black,
                                    fontSize: 10.sp,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class TimeSlot {
  final int day;
  final int hour;
  final int minute; // Added minute field
  bool isOpen;

  TimeSlot({
    required this.day,
    required this.hour,
    required this.minute,
    required this.isOpen,
  });

  Map<String, dynamic> toMap() {
    return {
      'day': day,
      'hour': hour,
      'minute': minute,
      'isOpen': isOpen,
    };
  }

  factory TimeSlot.fromMap(Map<String, dynamic> map) {
    return TimeSlot(
      day: map['day'],
      hour: map['hour'],
      minute: map['minute'] ?? 0, // Default to 0 for backward compatibility
      isOpen: map['isOpen'],
    );
  }

  TimeSlot copyWith({bool? isOpen}) {
    return TimeSlot(
      day: day,
      hour: hour,
      minute: minute,
      isOpen: isOpen ?? this.isOpen,
    );
  }
}

/// Widget design for upcoming appointments
Widget buildUpcomingAppointments(context) {
  return Container(
    width: double.infinity,
    margin: EdgeInsets.only(left: 18.w, right: 18.w, top: 23.h),
    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 19.h),
    decoration: BoxDecoration(color: AppColors.appBGColor, borderRadius: BorderRadius.circular(15.dg)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.topRight,
          child: Icon(
            Icons.notifications_on_sharp,
          ),
        ),
        Text(
          'Specialist name',
          style: appTextStyle16400(AppColors.mainBlackTextColor),
        ),
        Text(
          'Date',
          style: appTextStyle16400(AppColors.mainBlackTextColor),
        ),
        Text(
          'Time',
          style: appTextStyle16400(AppColors.mainBlackTextColor),
        ),
        Text(
          'Agreed address of meeting',
          style: appTextStyle16400(AppColors.mainBlackTextColor),
        ),
        SizedBox(
          height: 10.h,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: () => showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.dg),
                        ),
                        contentPadding: EdgeInsets.zero,
                        titlePadding: EdgeInsets.zero,
                        actionsPadding: EdgeInsets.only(top: 10.h, bottom: 20.h),
                        title: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                    onPressed: () => Navigator.pop(context),
                                    icon: Icon(
                                      Icons.close,
                                      color: AppColors.appBGColor,
                                    )),
                              ],
                            ),
                            SizedBox(
                              height: 6.h,
                            ),
                            SizedBox(
                              width: 211.w,
                              child: Text(
                                'Before canceling your booking you have to inform the client first , if you have done this , you can proceed to cancel , if not please inform client first',
                                style: appTextStyle16400(AppColors.mainBlackTextColor),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                  height: 32.h,
                                  width: 120.w,
                                  child: ReusableButton(
                                      color: AppColors.appBGColor,
                                      text: Text(
                                        LocaleData.cancel.getString(context),
                                        style: appTextStyle16400(AppColors.mainBlackTextColor),
                                      ),
                                      onPressed: () {})),
                            ],
                          ),
                        ],
                      )),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.whiteColor,
                minimumSize: Size(3.w, 25.h),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: AppColors.newGrayColor, width: 2.w),
                  borderRadius: BorderRadius.circular(5.dg),
                ),
              ),
              child: Center(
                child: Text(
                  LocaleData.cancel.getString(context),
                  style: appTextStyle12K(AppColors.mainBlackTextColor),
                ),
              ),
            ),
          ],
        )
      ],
    ),
  );
}

// class AppointmentListScreen extends StatefulWidget {
//   final bool isSpecialist;
//   const AppointmentListScreen({super.key, required this.isSpecialist});

//   @override
//   State<AppointmentListScreen> createState() => _AppointmentListScreenState();
// }

// class _AppointmentListScreenState extends State<AppointmentListScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final AppointmentRepository _repo = AppointmentRepository();
//   List<AppointmentModel> _appointments = [];
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadAppointments();
//   }

//   /// Loads appointments for the current user and updates status if past due.
//   ///
//   /// Fetches appointments using [AppointmentRepository], checks if any
//   /// 'booked' appointments have passed their end time (date + duration),
//   /// and updates their status to 'completed' in Firestore if so.
//   /// Updates the [_appointments] list and [_isLoading] flag accordingly.
//   Future<void> _loadAppointments() async {
//     final userId = FirebaseAuth.instance.currentUser!.uid;
//     final appointments = await _repo.fetchAppointments(
//       userId: userId,
//       isSpecialist: widget.isSpecialist,
//     );

//     final now = DateTime.now().toUtc().add(Duration(hours: 1)); // Current time in WAT (UTC+1)

//     // Prepare batch for Firestore updates
//     final batch = _firestore.batch();
//     List<AppointmentModel> updatedAppointments = List.from(appointments);

//     for (int i = 0; i < updatedAppointments.length; i++) {
//       final appointment = updatedAppointments[i];
//       if (appointment.status == 'booked') {
//         // Assume appointment.date is in UTC; convert to WAT for comparison
//         final appointmentDateWAT = appointment.date.toUtc().add(Duration(hours: 1));
//         final appointmentEndWAT = appointmentDateWAT.add(Duration(minutes: appointment.totalDuration));

//         if (now.isAfter(appointmentEndWAT)) {
//           // Update Firestore
//           final docRef = _firestore.collection('appointments').doc(appointment.appointmentId);
//           batch.update(docRef, {
//             'status': 'completed',
//             'completedAt': FieldValue.serverTimestamp(),
//           });
//           // Update local appointment
//           updatedAppointments[i] = appointment.copyWith(status: 'completed');
//         }
//       }
//     }

//     // Commit batch updates
//     await batch.commit();

//     setState(() {
//       _appointments = updatedAppointments;
//       _isLoading = false;
//     });
//   }

//   Future<void> _cancelAppointment(String appointmentId) async {
//     setState(() => _isLoading = true);
//     FirebaseNotificationService firebasePushNotificationService = FirebaseNotificationService();
//     try {
//       // Fetch appointment details
//       final appointmentDoc = await _firestore.collection('appointments').doc(appointmentId).get();
//       final appointment = appointmentDoc.data() as Map<String, dynamic>;
//       final specialistId = appointment['specialistId'] as String;
//       final date = (appointment['date'] as Timestamp).toDate();
//       final totalDuration = appointment['totalDuration'] as int;

//       // Calculate time range affected by the appointment
//       final appointmentStart = date;
//       final appointmentEnd = appointmentStart.add(Duration(minutes: totalDuration));
//       final breakEnd = appointmentEnd.add(Duration(minutes: 15));

//       // Get specialist's details
//       final specialistDoc = await _firestore.collection('users').doc(specialistId).get();
//       final specialistToken = specialistDoc['fcmToken'] as String?;

//       // Update appointment status
//       await _firestore.collection('appointments').doc(appointmentId).update({
//         'status': 'cancelled',
//         'cancelledAt': FieldValue.serverTimestamp(),
//       });

//       // Calculate the week of the appointment
//       DateTime getFirstMonday(DateTime date) {
//         date = DateTime(date.year, date.month, date.day);
//         while (date.weekday != DateTime.monday) {
//           date = date.subtract(Duration(days: 1));
//         }
//         return date;
//       }

//       final weekStart = getFirstMonday(date);
//       final availabilityRef = _firestore.collection('availability').doc(specialistId).collection('weeks').doc(weekStart.toIso8601String());

//       // Reopen slots in availability for the specific day
//       final availabilityDoc = await availabilityRef.get();
//       if (availabilityDoc.exists) {
//         List<TimeSlot> slots = (availabilityDoc.data()!['slots'] as List).map((s) => TimeSlot.fromMap(s)).toList();

//         // Calculate the appointment's day offset from weekStart
//         final appointmentDayOffset = date.difference(weekStart).inDays;

//         // Reopen slots affected by this appointment only on the same day
//         for (int i = 0; i < slots.length; i++) {
//           final slot = slots[i];
//           final slotDate = weekStart.add(Duration(days: slot.day));
//           final slotTime = DateTime(
//             slotDate.year,
//             slotDate.month,
//             slotDate.day,
//             slot.hour,
//             slot.minute,
//           );

//           if (slot.day == appointmentDayOffset && slotTime.isAfter(appointmentStart.subtract(Duration(minutes: 1))) && slotTime.isBefore(breakEnd)) {
//             slots[i] = slot.copyWith(isOpen: true);
//           }
//         }

//         // Re-block slots based on other active appointments
//         final weekEnd = weekStart.add(Duration(days: 7));
//         final activeAppointments = await _firestore
//             .collection('appointments')
//             .where('specialistId', isEqualTo: specialistId)
//             .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
//             .where('date', isLessThan: Timestamp.fromDate(weekEnd))
//             .where('status', whereIn: ['booked', 'completed']).get();

//         for (final apptDoc in activeAppointments.docs) {
//           final appt = apptDoc.data();
//           final apptDate = (appt['date'] as Timestamp).toDate();
//           final apptDuration = appt['totalDuration'] as int;
//           final apptStart = apptDate;
//           final apptEnd = apptStart.add(Duration(minutes: apptDuration));
//           final apptBreakEnd = apptEnd.add(Duration(minutes: 15));

//           // Calculate the active appointment's day offset from weekStart
//           final apptDayOffset = apptDate.difference(weekStart).inDays;

//           for (int i = 0; i < slots.length; i++) {
//             final slot = slots[i];
//             final slotDate = weekStart.add(Duration(days: slot.day));
//             final slotTime = DateTime(
//               slotDate.year,
//               slotDate.month,
//               slotDate.day,
//               slot.hour,
//               slot.minute,
//             );

//             if (slot.day == apptDayOffset && slotTime.isAfter(apptStart.subtract(Duration(minutes: 1))) && slotTime.isBefore(apptBreakEnd)) {
//               slots[i] = slot.copyWith(isOpen: false);
//             }
//           }
//         }

//         await availabilityRef.update({
//           'slots': slots.map((s) => s.toMap()).toList(),
//         });
//       }

//       // Send notification
//       if (specialistToken != null) {
//         final formattedDate = DateFormat('EEE, MMM d, y').format(date);
//         final formattedTime = DateFormat('h:mm a').format(date);
//         firebasePushNotificationService.cancelPushNotification(
//           'Appointment Cancelled',
//           'Your appointment on $formattedDate at $formattedTime has been cancelled',
//           specialistToken,
//         );
//       }

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Appointment cancelled successfully')),
//       );
//       setState(() => _isLoading = false);
//       Navigator.pop(context);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to cancel appointment: an error occurred')),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _scheduleReminder(AppointmentModel appointment) async {
//     final now = DateTime.now().toUtc().add(Duration(hours: 1)); // Current time in WAT
//     final appointmentTime = appointment.date.toUtc().add(Duration(hours: 1)); // Convert to WAT
//     final oneHourBefore = appointmentTime.subtract(Duration(hours: 1));

//     if (oneHourBefore.isBefore(now)) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Cannot set reminder for past appointments.')),
//       );
//       return;
//     }

//     try {
//       await FirebaseNotificationService().schedulePushNotification(
//         title: 'Appointment Reminder',
//         body: 'Your appointment with ${appointment.clientFirstName} ${appointment.clientLastName} is in 1 hour.',
//         scheduledTime: oneHourBefore,
//       );

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Reminder set for 1 hour before the appointment.')),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to set reminder: an error occurred')),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return _isLoading
//         ? Center(child: CircularProgressIndicator())
//         : _appointments.isEmpty
//             ? Center(child: Text('No appointments found'))
//             : Column(
//                 children: [
//                   Expanded(
//                     child: Padding(
//                       padding: const EdgeInsets.only(bottom: 0),
//                       child: ListView.builder(
//                         itemCount: _appointments.length,
//                         shrinkWrap: true,
//                         itemBuilder: (context, index) {
//                           final appointment = _appointments[index];
//                           return Column(
//                             children: [
//                               Container(
//                                 width: double.infinity,
//                                 margin: EdgeInsets.only(left: 18.w, right: 18.w, top: 23.h),
//                                 padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
//                                 decoration: BoxDecoration(
//                                   color: AppColors.appBGColor,
//                                   borderRadius: BorderRadius.circular(15.dg),
//                                 ),
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Row(
//                                       mainAxisAlignment: MainAxisAlignment.end,
//                                       children: [
//                                         IconButton(
//                                           icon: Row(
//                                             children: [
//                                               Container(
//                                                 padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
//                                                 decoration: BoxDecoration(
//                                                   color: _getStatusColor(appointment.status),
//                                                   borderRadius: BorderRadius.circular(4.dg),
//                                                 ),
//                                                 child: Text(
//                                                   appointment.status.toUpperCase(),
//                                                   style: appTextStyle10(AppColors.whiteColor),
//                                                 ),
//                                               ),
//                                               SizedBox(width: 10.w),
//                                               if (appointment.status == 'cancelled' || appointment.status == 'completed')
//                                                 GestureDetector(
//                                                   onTap: () => showDialog(
//                                                     context: context,
//                                                     builder: (context) => AlertDialog(
//                                                       title: Text('Delete Appointment'),
//                                                       content: Text(
//                                                         'Are you sure you want to delete this appointment?',
//                                                         style: appTextStyle14(AppColors.mainBlackTextColor),
//                                                       ),
//                                                       actions: [
//                                                         InkWell(
//                                                           onTap: () => Navigator.pop(context),
//                                                           child: Container(
//                                                             padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 40.w),
//                                                             decoration: BoxDecoration(
//                                                               color: AppColors.appBGColor,
//                                                               borderRadius: BorderRadius.circular(12.dg),
//                                                             ),
//                                                             child: Text('No'),
//                                                           ),
//                                                         ),
//                                                         InkWell(
//                                                           onTap: () async {
//                                                             await _repo.deleteAppointment(context, appointment.appointmentId);
//                                                             setState(() {
//                                                               _appointments.removeWhere((apt) => apt.appointmentId == appointment.appointmentId);
//                                                             });
//                                                           },
//                                                           child: Container(
//                                                             padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 40.w),
//                                                             decoration: BoxDecoration(
//                                                               color: AppColors.appBGColor,
//                                                               borderRadius: BorderRadius.circular(12.dg),
//                                                             ),
//                                                             child: Text('Yes'),
//                                                           ),
//                                                         ),
//                                                       ],
//                                                     ),
//                                                   ),
//                                                   child: Icon(Icons.delete),
//                                                 ),
//                                             ],
//                                           ),
//                                           onPressed: () => _scheduleReminder(appointment),
//                                         ),
//                                       ],
//                                     ),
//                                     Text(
//                                       widget.isSpecialist ? '${appointment.clientFirstName} ${appointment.clientLastName}' : 'Specialist: ${appointment.specialistId}',
//                                       style: appTextStyle16500(AppColors.mainBlackTextColor),
//                                     ),
//                                     SizedBox(height: 8.h),
//                                     Text(
//                                       'Details',
//                                       style: appTextStyle16500(AppColors.mainBlackTextColor),
//                                     ),
//                                     SizedBox(height: 8.h),
//                                     Row(
//                                       children: [
//                                         Icon(Icons.calendar_today, size: 16.dg, color: AppColors.newThirdGrayColor),
//                                         SizedBox(width: 8.w),
//                                         Text(
//                                           DateFormat('EEE, MMM d, y').format(appointment.date),
//                                           style: appTextStyle14(AppColors.newThirdGrayColor),
//                                         ),
//                                       ],
//                                     ),
//                                     SizedBox(height: 4.h),
//                                     Row(
//                                       children: [
//                                         Icon(Icons.access_time, size: 16.dg, color: AppColors.newThirdGrayColor),
//                                         SizedBox(width: 8.w),
//                                         Text(
//                                           DateFormat('h:mm a').format(appointment.date),
//                                           style: appTextStyle14(AppColors.newThirdGrayColor),
//                                         ),
//                                       ],
//                                     ),
//                                     Text(
//                                       appointment.address,
//                                       style: appTextStyle16400(AppColors.mainBlackTextColor),
//                                     ),
//                                     if (appointment.status == 'booked')
//                                       Row(
//                                         mainAxisAlignment: MainAxisAlignment.end,
//                                         children: [
//                                           ElevatedButton(
//                                             onPressed: () => showDialog(
//                                               context: context,
//                                               builder: (context) => AlertDialog(
//                                                 shape: RoundedRectangleBorder(
//                                                   borderRadius: BorderRadius.circular(15.dg),
//                                                 ),
//                                                 contentPadding: EdgeInsets.zero,
//                                                 titlePadding: EdgeInsets.zero,
//                                                 actionsPadding: EdgeInsets.only(top: 10.h, bottom: 20.h),
//                                                 title: Column(
//                                                   children: [
//                                                     Row(
//                                                       mainAxisAlignment: MainAxisAlignment.end,
//                                                       children: [
//                                                         IconButton(
//                                                           onPressed: () => Navigator.pop(context),
//                                                           icon: Icon(
//                                                             Icons.close,
//                                                             color: AppColors.appBGColor,
//                                                           ),
//                                                         ),
//                                                       ],
//                                                     ),
//                                                     SizedBox(height: 6.h),
//                                                     SizedBox(
//                                                       width: 211.w,
//                                                       child: Text(
//                                                         'Before canceling your booking you have to inform the client first, if you have done this, you can proceed to cancel, if not please inform client first',
//                                                         style: appTextStyle16400(AppColors.mainBlackTextColor),
//                                                         textAlign: TextAlign.center,
//                                                       ),
//                                                     ),
//                                                   ],
//                                                 ),
//                                                 actions: [
//                                                   Row(
//                                                     mainAxisAlignment: MainAxisAlignment.center,
//                                                     children: [
//                                                       SizedBox(
//                                                         height: 32.h,
//                                                         width: 120.w,
//                                                         child: ReusableButton(
//                                                           color: AppColors.appBGColor,
//                                                           text: Text(
//                                                             LocaleData.cancel.getString(context),
//                                                             style: appTextStyle16400(AppColors.mainBlackTextColor),
//                                                           ),
//                                                           onPressed: () {
//                                                             _cancelAppointment(appointment.appointmentId);
//                                                           },
//                                                         ),
//                                                       ),
//                                                     ],
//                                                   ),
//                                                 ],
//                                               ),
//                                             ),
//                                             style: ElevatedButton.styleFrom(
//                                               backgroundColor: AppColors.whiteColor,
//                                               minimumSize: Size(3.w, 25.h),
//                                               shape: RoundedRectangleBorder(
//                                                 side: BorderSide(color: AppColors.newGrayColor, width: 2.w),
//                                                 borderRadius: BorderRadius.circular(5.dg),
//                                               ),
//                                             ),
//                                             child: Center(
//                                               child: Text(
//                                                 LocaleData.cancel.getString(context),
//                                                 style: appTextStyle12K(AppColors.mainBlackTextColor),
//                                               ),
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           );
//                         },
//                       ),
//                     ),
//                   ),
//                 ],
//               );
//   }

//   Color _getStatusColor(String status) {
//     switch (status) {
//       case 'booked':
//         return AppColors.greenColor;
//       case 'cancelled':
//         return AppColors.primaryRedColor;
//       case 'completed':
//         return AppColors.mainColor;
//       default:
//         return AppColors.grayColor;
//     }
//   }
// }

class AppointmentListScreen extends StatefulWidget {
  final bool isSpecialist;
  const AppointmentListScreen({super.key, required this.isSpecialist});

  @override
  State<AppointmentListScreen> createState() => _AppointmentListScreenState();
}

class _AppointmentListScreenState extends State<AppointmentListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AppointmentRepository _repo = AppointmentRepository();
  List<AppointmentModel> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }


  Future<void> _loadAppointments() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final appointments = await _repo.fetchAppointments(
      userId: userId,
      isSpecialist: widget.isSpecialist,
    );

    final now = DateTime.now().toUtc().add(Duration(hours: 1)); // Current time in WAT (UTC+1)

    // Prepare batch for Firestore updates
    final batch = _firestore.batch();
    List<AppointmentModel> updatedAppointments = List.from(appointments);

    for (int i = 0; i < updatedAppointments.length; i++) {
      final appointment = updatedAppointments[i];
      if (appointment.status == 'booked') {
        final appointmentDateWAT = appointment.date.toUtc().add(Duration(hours: 1));
        final appointmentEndWAT = appointmentDateWAT.add(Duration(minutes: appointment.totalDuration));

        if (now.isAfter(appointmentEndWAT)) {
          final docRef = _firestore.collection('appointments').doc(appointment.appointmentId);
          batch.update(docRef, {
            'status': 'completed',
            'completedAt': FieldValue.serverTimestamp(),
          });
          updatedAppointments[i] = appointment.copyWith(status: 'completed');
        }
      }
    }

    // Commit batch updates
    await batch.commit();

    // Sort appointments by createdAt in descending order (newest first)
    updatedAppointments.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    setState(() {
      _appointments = updatedAppointments;
      _isLoading = false;
    });
  }
 

  Future<void> _cancelAppointment(String appointmentId) async {
    setState(() => _isLoading = true);
    FirebaseNotificationService firebasePushNotificationService = FirebaseNotificationService();
    try {
      // Fetch appointment details
      final appointmentDoc = await _firestore.collection('appointments').doc(appointmentId).get();
      final appointment = appointmentDoc.data() as Map<String, dynamic>;
      final specialistId = appointment['specialistId'] as String;
      final date = (appointment['date'] as Timestamp).toDate();
      final totalDuration = appointment['totalDuration'] as int;

      // Calculate time range
      final appointmentStart = date;
      final appointmentEnd = appointmentStart.add(Duration(minutes: totalDuration));
      final breakEnd = appointmentEnd.add(Duration(minutes: 15));

      // Get specialist details
      final specialistDoc = await _firestore.collection('users').doc(specialistId).get();
      final specialistToken = specialistDoc['fcmToken'] as String?;

      // Update appointment status in Firestore
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      // Handle slot reopening
      DateTime getFirstMonday(DateTime date) {
        date = DateTime(date.year, date.month, date.day);
        while (date.weekday != DateTime.monday) {
          date = date.subtract(Duration(days: 1));
        }
        return date;
      }

      final weekStart = getFirstMonday(date);
      final availabilityRef = _firestore.collection('availability').doc(specialistId).collection('weeks').doc(weekStart.toIso8601String());

      final availabilityDoc = await availabilityRef.get();
      if (availabilityDoc.exists) {
        List<TimeSlot> slots = (availabilityDoc.data()!['slots'] as List).map((s) => TimeSlot.fromMap(s)).toList();
        final appointmentDayOffset = date.difference(weekStart).inDays;

        for (int i = 0; i < slots.length; i++) {
          final slot = slots[i];
          final slotDate = weekStart.add(Duration(days: slot.day));
          final slotTime = DateTime(slotDate.year, slotDate.month, slotDate.day, slot.hour, slot.minute);

          if (slot.day == appointmentDayOffset && slotTime.isAfter(appointmentStart.subtract(Duration(minutes: 1))) && slotTime.isBefore(breakEnd)) {
            slots[i] = slot.copyWith(isOpen: true);
          }
        }

        final weekEnd = weekStart.add(Duration(days: 7));
        final activeAppointments = await _firestore
            .collection('appointments')
            .where('specialistId', isEqualTo: specialistId)
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
            .where('date', isLessThan: Timestamp.fromDate(weekEnd))
            .where('status', whereIn: ['booked', 'completed']).get();

        for (final apptDoc in activeAppointments.docs) {
          final appt = apptDoc.data();
          final apptDate = (appt['date'] as Timestamp).toDate();
          final apptDuration = appt['totalDuration'] as int;
          final apptStart = apptDate;
          final apptEnd = apptStart.add(Duration(minutes: apptDuration));
          final apptBreakEnd = apptEnd.add(Duration(minutes: 15));
          final apptDayOffset = apptDate.difference(weekStart).inDays;

          for (int i = 0; i < slots.length; i++) {
            final slot = slots[i];
            final slotDate = weekStart.add(Duration(days: slot.day));
            final slotTime = DateTime(slotDate.year, slotDate.month, slotDate.day, slot.hour, slot.minute);

            if (slot.day == apptDayOffset && slotTime.isAfter(apptStart.subtract(Duration(minutes: 1))) && slotTime.isBefore(apptBreakEnd)) {
              slots[i] = slot.copyWith(isOpen: false);
            }
          }
        }

        await availabilityRef.update({
          'slots': slots.map((s) => s.toMap()).toList(),
        });
      }

      // Update local appointment status
      final index = _appointments.indexWhere((apt) => apt.appointmentId == appointmentId);
      if (index != -1) {
        setState(() {
          _appointments[index] = _appointments[index].copyWith(status: 'cancelled');
        });
      }

      // Send notification
      if (specialistToken != null) {
        final formattedDate = DateFormat('EEE, MMM d, y').format(date);
        final formattedTime = DateFormat('h:mm a').format(date);
        firebasePushNotificationService.cancelPushNotification(
          'Appointment Cancelled',
          'Your appointment on $formattedDate at $formattedTime has been cancelled',
          specialistToken,
        );
      }
      // Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment cancelled successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel appointment: an error occurred')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _scheduleReminder(AppointmentModel appointment) async {
    final now = DateTime.now().toUtc().add(Duration(hours: 1));
    final appointmentTime = appointment.date.toUtc().add(Duration(hours: 1));
    final oneHourBefore = appointmentTime.subtract(Duration(hours: 1));

    if (oneHourBefore.isBefore(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot set reminder for past appointments.')),
      );
      return;
    }

    try {
      await FirebaseNotificationService().schedulePushNotification(
        title: 'Appointment Reminder',
        body: 'Your appointment with ${appointment.clientFirstName} ${appointment.clientLastName} is in 1 hour.',
        scheduledTime: oneHourBefore,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reminder set for 1 hour before the appointment.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to set reminder: an error occurred')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Center(child: CircularProgressIndicator())
        : _appointments.isEmpty
            ? Center(child: Text('No appointments found'))
            : Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 0),
                      child: ListView.builder(
                        itemCount: _appointments.length,
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          final appointment = _appointments[index];
                          return Column(
                            children: [
                              Container(
                                width: double.infinity,
                                margin: EdgeInsets.only(left: 18.w, right: 18.w, top: 23.h),
                                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
                                decoration: BoxDecoration(
                                  color: AppColors.appBGColor,
                                  borderRadius: BorderRadius.circular(15.dg),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          icon: Row(
                                            children: [
                                              Container(
                                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                                decoration: BoxDecoration(
                                                  color: _getStatusColor(appointment.status),
                                                  borderRadius: BorderRadius.circular(4.dg),
                                                ),
                                                child: Text(
                                                  appointment.status.toUpperCase(),
                                                  style: appTextStyle10(AppColors.whiteColor),
                                                ),
                                              ),
                                              SizedBox(width: 10.w),
                                              if (appointment.status == 'cancelled' || appointment.status == 'completed')
                                                GestureDetector(
                                                  onTap: () => showDialog(
                                                    context: context,
                                                    builder: (context) => AlertDialog(
                                                      title: Text('Delete Appointment'),
                                                      content: Text(
                                                        'Are you sure you want to delete this appointment?',
                                                        style: appTextStyle14(AppColors.mainBlackTextColor),
                                                      ),
                                                      actions: [
                                                        InkWell(
                                                          onTap: () => Navigator.pop(context),
                                                          child: Container(
                                                            padding: EdgeInsets.symmetric(vertical: 4, horizontal: 40),
                                                            decoration: BoxDecoration(
                                                              color: AppColors.appBGColor,
                                                              borderRadius: BorderRadius.circular(12),
                                                            ),
                                                            child: Text('No'),
                                                          ),
                                                        ),
                                                        InkWell(
                                                          onTap: () async {
                                                            await _repo.deleteAppointment(context, appointment.appointmentId);
                                                            setState(() {
                                                              _appointments.removeWhere((apt) => apt.appointmentId == appointment.appointmentId);
                                                            });
                                                          },
                                                          child: Container(
                                                            padding: EdgeInsets.symmetric(vertical: 4, horizontal: 40),
                                                            decoration: BoxDecoration(
                                                              color: AppColors.appBGColor,
                                                              borderRadius: BorderRadius.circular(12),
                                                            ),
                                                            child: Text('Yes'),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  child: Icon(Icons.delete),
                                                ),
                                            ],
                                          ),
                                          onPressed: () => _scheduleReminder(appointment),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      widget.isSpecialist ? '${appointment.clientFirstName} ${appointment.clientLastName}' : 'Specialist: ${appointment.specialistId}',
                                      style: appTextStyle16500(AppColors.mainBlackTextColor),
                                    ),
                                    SizedBox(height: 8.h),
                                    Text(
                                      'Details',
                                      style: appTextStyle16500(AppColors.mainBlackTextColor),
                                    ),
                                    SizedBox(height: 8.h),
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today, size: 16.h, color: AppColors.newThirdGrayColor),
                                        SizedBox(width: 8.w),
                                        Text(
                                          DateFormat('EEE, MMM d, y').format(appointment.date),
                                          style: appTextStyle14(AppColors.newThirdGrayColor),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4.h),
                                    Row(
                                      children: [
                                        Icon(Icons.access_time, size: 16.h, color: AppColors.newThirdGrayColor),
                                        SizedBox(width: 8.w),
                                        Text(
                                          DateFormat('h:mm a').format(appointment.date),
                                          style: appTextStyle14(AppColors.newThirdGrayColor),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      appointment.address,
                                      style: appTextStyle16400(AppColors.mainBlackTextColor),
                                    ),
                                    if (appointment.status == 'booked')
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          ElevatedButton(
                                            onPressed: () => showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(15.dg),
                                                ),
                                                contentPadding: EdgeInsets.zero,
                                                titlePadding: EdgeInsets.zero,
                                                actionsPadding: EdgeInsets.only(top: 10.h, bottom: 20.w),
                                                title: Column(
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.end,
                                                      children: [
                                                        IconButton(
                                                          onPressed: () => Navigator.pop(context),
                                                          icon: Icon(
                                                            Icons.close,
                                                            color: AppColors.appBGColor,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    SizedBox(height: 6.h),
                                                    SizedBox(
                                                      width: 211,
                                                      child: Text(
                                                        'Before canceling your booking you have to inform the client first, if you have done this, you can proceed to cancel, if not please inform client first',
                                                        style: appTextStyle16400(AppColors.mainBlackTextColor),
                                                        textAlign: TextAlign.center,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                actions: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      SizedBox(
                                                        height: 32.h,
                                                        width: 120.w,
                                                        child: _isLoading
                                                            ? const Center(child: CircularProgressIndicator())
                                                            : ReusableButton(
                                                                color: AppColors.appBGColor,
                                                                text: Text(
                                                                  'Cancel', // Assuming LocaleData.cancel.getString(context) returns 'Cancel'
                                                                  style: appTextStyle16400(AppColors.mainBlackTextColor),
                                                                ),
                                                                onPressed: () {
                                                                  _cancelAppointment(appointment.appointmentId);
                                                                  Navigator.pop(context);
                                                                },
                                                              ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.whiteColor,
                                              minimumSize: Size(3.w, 25.h),
                                              shape: RoundedRectangleBorder(
                                                side: BorderSide(color: AppColors.newGrayColor, width: 2.w),
                                                borderRadius: BorderRadius.circular(5.dg),
                                              ),
                                            ),
                                            child: Center(
                                              child: Text(
                                                'Cancel', // Assuming LocaleData.cancel.getString(context) returns 'Cancel'
                                                style: appTextStyle12K(AppColors.mainBlackTextColor),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'booked':
        return AppColors.greenColor;
      case 'cancelled':
        return AppColors.primaryRedColor;
      case 'completed':
        return AppColors.mainColor;
      default:
        return AppColors.grayColor;
    }
  }
}
