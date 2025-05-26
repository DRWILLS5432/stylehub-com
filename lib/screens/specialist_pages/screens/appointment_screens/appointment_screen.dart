import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:stylehub/constants/app/app_colors.dart';
import 'package:stylehub/constants/app/textstyle.dart';
import 'package:stylehub/constants/localization/locales.dart';
import 'package:stylehub/screens/specialist_pages/specialist_schedule_appointment_screen.dart';
import 'package:stylehub/screens/specialist_pages/widgets/write_review.dart';
import 'package:stylehub/services/fcm_services/firebase_msg.dart';
import 'package:stylehub/storage/post_review_method.dart';

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Center(child: Text('Please sign in to view appointments'));
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          LocaleData.appointments.getString(context),
          style: appTextStyle24(AppColors.newThirdGrayColor),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('appointments').where('clientId', isEqualTo: user.uid).orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: SizedBox.shrink());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No appointments booked yet',
                      style: appTextStyle16(AppColors.newThirdGrayColor),
                    ),
                  );
                }

                final appointments = snapshot.data!.docs;

                return ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final appointment = appointments[index].data() as Map<String, dynamic>;
                    final date = (appointment['date'] as Timestamp).toDate();
                    final status = appointment['status'] as String? ?? 'booked';
                    final now = DateTime.now();
                    final effectiveStatus = (status == 'booked' && date.isBefore(now)) ? 'completed' : status;

                    return AppointmentCard(
                      appointmentId: appointments[index].id,
                      specialistId: appointment['specialistId'] as String,
                      date: date,
                      status: effectiveStatus,
                      onCancel: () => _cancelAppointment(context, appointments[index].id),
                      onDelete: () => _deleteAppointment(appointments[index].id),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            height: 50.h,
            color: Colors.transparent,
          )
        ],
      ),
    );
  }

  Future<void> _cancelAppointment(context, String appointmentId) async {
    setState(() => isLoading = true);
    FirebaseNotificationService firebasePushNotificationService = FirebaseNotificationService();
    try {
      // Fetch appointment details
      final appointmentDoc = await _firestore.collection('appointments').doc(appointmentId).get();
      final appointment = appointmentDoc.data() as Map<String, dynamic>;
      final specialistId = appointment['specialistId'] as String;
      final date = (appointment['date'] as Timestamp).toDate();
      final totalDuration = appointment['totalDuration'] as int;

      // Calculate time range affected by the appointment
      final appointmentStart = date;
      final appointmentEnd = appointmentStart.add(Duration(minutes: totalDuration));
      final breakEnd = appointmentEnd.add(Duration(minutes: 15));

      // Get specialist's details
      final specialistDoc = await _firestore.collection('users').doc(specialistId).get();
      final specialistToken = specialistDoc['fcmToken'] as String?;

      // Update appointment status
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      // Calculate the week of the appointment
      DateTime getFirstMonday(DateTime date) {
        date = DateTime(date.year, date.month, date.day);
        while (date.weekday != DateTime.monday) {
          date = date.subtract(Duration(days: 1));
        }
        return date;
      }

      final weekStart = getFirstMonday(date);
      final availabilityRef = _firestore.collection('availability').doc(specialistId).collection('weeks').doc(weekStart.toIso8601String());

      // Reopen slots in availability for the specific day
      final availabilityDoc = await availabilityRef.get();
      if (availabilityDoc.exists) {
        List<TimeSlot> slots = (availabilityDoc.data()!['slots'] as List).map((s) => TimeSlot.fromMap(s)).toList();

        // Calculate the appointment's day offset from weekStart
        final appointmentDayOffset = date.difference(weekStart).inDays;

        // Reopen slots affected by this appointment only on the same day
        for (int i = 0; i < slots.length; i++) {
          final slot = slots[i];
          final slotDate = weekStart.add(Duration(days: slot.day));
          final slotTime = DateTime(
            slotDate.year,
            slotDate.month,
            slotDate.day,
            slot.hour,
            slot.minute,
          );

          if (slot.day == appointmentDayOffset && slotTime.isAfter(appointmentStart.subtract(Duration(minutes: 1))) && slotTime.isBefore(breakEnd)) {
            slots[i] = slot.copyWith(isOpen: true);
          }
        }

        // Re-block slots based on other active appointments
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

          // Calculate the active appointment's day offset from weekStart
          final apptDayOffset = apptDate.difference(weekStart).inDays;

          for (int i = 0; i < slots.length; i++) {
            final slot = slots[i];
            final slotDate = weekStart.add(Duration(days: slot.day));
            final slotTime = DateTime(
              slotDate.year,
              slotDate.month,
              slotDate.day,
              slot.hour,
              slot.minute,
            );

            if (slot.day == apptDayOffset && slotTime.isAfter(apptStart.subtract(Duration(minutes: 1))) && slotTime.isBefore(apptBreakEnd)) {
              slots[i] = slot.copyWith(isOpen: false);
            }
          }
        }

        await availabilityRef.update({
          'slots': slots.map((s) => s.toMap()).toList(),
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment cancelled successfully')),
      );
      setState(() => isLoading = false);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel appointment: an error occurred')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _deleteAppointment(String appointmentId) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete appointment: an error occurred')),
      );
    }
  }
}

class AppointmentCard extends StatefulWidget {
  final String appointmentId;
  final String specialistId;
  final DateTime date;
  final String status;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  const AppointmentCard({
    super.key,
    required this.appointmentId,
    required this.specialistId,
    required this.date,
    required this.status,
    required this.onCancel,
    required this.onDelete,
  });

  @override
  State<AppointmentCard> createState() => _AppointmentCardState();
}

class _AppointmentCardState extends State<AppointmentCard> {
  bool toggleReviewField = false;
  Map<String, dynamic>? _specialistData;
  bool _isLoading = false;

  final ReviewService _reviewService = ReviewService();

  @override
  void initState() {
    super.initState();
    _loadSpecialistData();
  }

  Future<void> _loadSpecialistData() async {
    setState(() => _isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.specialistId).get();

      if (doc.exists) {
        setState(() {
          _specialistData = doc.data();
        });
      }
    } catch (e) {
      // Handle error
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _submitReview(context, int rating, String comment) async {
    String result = await _reviewService.submitReview(
      userId: widget.specialistId,
      rating: rating,
      comment: comment,
    );

    if (result == 'success') {
      setState(() => toggleReviewField = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.appBGColor,
      margin: EdgeInsets.only(bottom: 16.h),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppColors.appBGColor, width: 1.w),
        borderRadius: BorderRadius.circular(12.dg),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoading) const Center(child: SizedBox()) else if (_specialistData != null) _buildSpecialistInfo(),
            SizedBox(height: 12.h),
            _buildAppointmentInfo(),
            SizedBox(height: 16.h),
            _buildActionButtons(),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.status == 'completed' || widget.status == 'cancelled')
                  InkWell(
                    radius: 20.dg,
                    onTap: () {
                      showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                                contentPadding: EdgeInsets.zero,
                                backgroundColor: Colors.transparent,
                                content: SizedBox(
                                  height: 380.h,
                                  width: 350.w,
                                  child: WriteReviewWidget(
                                      // toggleReviewField: toggleReviewField,
                                      onSubmit: (int rating, String review) {
                                    _submitReview(context, rating, review);
                                  }),
                                ),
                              ));

                      // showModalBottomSheet(
                      //   isScrollControlled: true,
                      //   context: context,
                      //   backgroundColor: Colors.transparent,
                      //   builder: (context) => SizedBox(
                      //     height: 250.h,
                      //     child: WriteReviewWidget(
                      //         // toggleReviewField: toggleReviewField,
                      //         onSubmit: (int rating, String review) {
                      //       _submitReview(context, rating, review);
                      //     }),
                      //   ),
                      // );
                    },
                    // => setState(() {
                    //   toggle,ReviewField = !toggleReviewField;
                    // }),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15.w),
                      child: Row(
                        children: [
                          Text(LocaleData.leaveA.getString(context), style: appTextStyle15(AppColors.newThirdGrayColor)),
                          SizedBox(width: 10.w),
                          Text(LocaleData.review.getString(context), style: appTextStyle15(AppColors.mainBlackTextColor)),
                        ],
                      ),
                    ),
                  ),
                // if (toggleReviewField)
                //   WriteReviewWidget(
                //       toggleReviewField: toggleReviewField,
                //       onSubmit: (int rating, String review) {
                //         _submitReview(context, rating, review);
                //       }),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialistInfo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_specialistData?['firstName'] ?? ''} ${_specialistData?['lastName'] ?? ''}',
              style: appTextStyle16500(AppColors.mainBlackTextColor),
            ),
            SizedBox(
              width: 160.w,
              child: Text(
                _specialistData?['profession']?.toString() ?? 'Specialist',
                style: appTextStyle14(AppColors.newThirdGrayColor),
              ),
            ),
          ],
        ),
        Spacer(),
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: _getStatusColor(),
                borderRadius: BorderRadius.circular(4.dg),
              ),
              child: Text(
                widget.status.toUpperCase(),
                style: appTextStyle10(AppColors.whiteColor),
              ),
            ),
            if (widget.status == 'cancelled' || widget.status == 'completed') _buildDeleteButton(),
            // if (widget.status == 'booked')
            //   IconButton(
            //     icon: Icon(
            //       Icons.notifications_on_sharp,
            //     ),
            //     onPressed: _scheduleReminder,
            //   ),
          ],
        ),
      ],
    );
  }

  Widget _buildAppointmentInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Details',
          style: appTextStyle16500(AppColors.mainBlackTextColor),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Icon(Icons.calendar_today, size: 16.dg, color: AppColors.newThirdGrayColor),
            SizedBox(width: 8.w),
            Text(
              DateFormat('EEE, MMM d, y').format(widget.date),
              style: appTextStyle14(AppColors.newThirdGrayColor),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        Row(
          children: [
            Icon(Icons.access_time, size: 16.dg, color: AppColors.newThirdGrayColor),
            SizedBox(width: 8.w),
            Text(
              DateFormat('h:mm a').format(widget.date),
              style: appTextStyle14(AppColors.newThirdGrayColor),
            ),
          ],
        ),
        SizedBox(height: 4.h),
      ],
    );
  }

  Future<void> scheduleReminder() async {
    final now = DateTime.now();
    final appointmentTime = widget.date;
    final oneHourBefore = appointmentTime.subtract(Duration(hours: 1));

    if (oneHourBefore.isBefore(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot set reminder for past appointments.')),
      );
      return;
    }

    try {
      // Assuming FirebaseNotificationService has a method to schedule notifications
      await FirebaseNotificationService().schedulePushNotification(
        title: 'Appointment Reminder',
        body: 'Your appointment with ${_specialistData?['firstName']} is in 1 hour.',
        scheduledTime: oneHourBefore,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reminder set for 1 hour before the appointment.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to set reminder: an error occurred.')),
      );
    }
  }

  Widget _buildActionButtons() {
    // final bool canDelete = widget.status == 'cancelled' || widget.status == 'completed' || widget.date.isBefore(DateTime.now());

    if (widget.status == 'booked') {
      return _buildCancelButton(_isLoading);
      // }
      // else if (canDelete) {
      //   return _buildDeleteButton();
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildDeleteButton() {
    return GestureDetector(
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
                padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 40.w),
                decoration: BoxDecoration(color: AppColors.appBGColor, borderRadius: BorderRadius.circular(12.dg)),
                child: Text('No'),
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.pop(context);
                widget.onDelete();
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 40.w),
                decoration: BoxDecoration(color: AppColors.appBGColor, borderRadius: BorderRadius.circular(12.dg)),
                child: Text('Yes'),
              ),
            ),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: Icon(Icons.delete, size: 25.dg, color: AppColors.mainBlackTextColor),
      ),
    );
  }

  Widget _buildCancelButton(bool isLoading) {
    return Row(
      children: [
        SizedBox(height: 16.h),
        Spacer(),
        SizedBox(height: 16.h),
        Spacer(),
        Expanded(
            child: GestureDetector(
          onTap: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                    backgroundColor: AppColors.whiteColor,
                    contentPadding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.dg)),
                    content: Container(
                      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
                      height: 160.h,
                      child: Column(
                        children: [
                          Text(
                            'Are you sure you want to cancel this appointment on, ${DateFormat('EEE, MMM d, y').format(widget.date)} by ${DateFormat('h:mm a').format(widget.date)}',
                            style: appTextStyle14(AppColors.mainBlackTextColor),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16.h),
                          Row(
                            children: [
                              InkWell(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 40.w),
                                  decoration: BoxDecoration(color: AppColors.appBGColor, borderRadius: BorderRadius.circular(12.dg)),
                                  child: Text('No'),
                                ),
                              ),
                              Spacer(),
                              InkWell(
                                onTap: () {
                                  widget.onCancel();
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 40.w),
                                  decoration: BoxDecoration(color: AppColors.appBGColor, borderRadius: BorderRadius.circular(12.dg)),
                                  child: isLoading ? const CircularProgressIndicator() : Text('Yes'),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  )),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 4.h),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8.dg), color: AppColors.whiteColor),
            child: Center(child: Text(LocaleData.cancel.getString(context), style: appTextStyle12K(AppColors.mainBlackTextColor))),
          ),
        )),
      ],
    );
  }

  Color _getStatusColor() {
    switch (widget.status) {
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
