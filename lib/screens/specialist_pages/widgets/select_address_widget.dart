import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:stylehub/constants/app/app_colors.dart';
import 'package:stylehub/constants/app/textstyle.dart';
import 'package:stylehub/screens/specialist_pages/provider/location_provider.dart';

class SelectAddressBottomSheet extends StatelessWidget {
  final TextEditingController addressController;

  const SelectAddressBottomSheet({
    super.key,
    required this.addressController,
  });

  @override
  Widget build(BuildContext context) {
    bool isLoading = false;
    bool hasFetchedLocation = false;
    Address? fetchedAddress0;

    return StatefulBuilder(
      builder: (context, setState) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Consumer<AddressProvider>(
            builder: (context, addressProvider, _) {
              return Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.appBGColor, width: 2.w),
                  borderRadius: BorderRadius.circular(25.dg),
                  color: AppColors.whiteColor,
                ),
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                          margin: EdgeInsets.only(bottom: 20.h),
                          width: 60.w,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100.dg),
                            border: Border.all(color: AppColors.appBGColor, width: 2.w),
                          )),
                      Text('Pick Your Address', style: appTextStyle18(AppColors.mainBlackTextColor).copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 20),
                      if (addressProvider.addresses.isNotEmpty)
                        ...addressProvider.addresses.map(
                          (address) => RadioListTile<Address>(
                            // title: Text(address.name),
                            title: Text(
                              address.address,
                              style: appTextStyle14(AppColors.mainBlackTextColor).copyWith(fontWeight: FontWeight.w500),
                            ),
                            value: address,
                            groupValue: addressProvider.selectedAddress,
                            onChanged: (value) {
                              addressProvider.selectedAddress = value;
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      if (addressProvider.addresses.isNotEmpty) const Divider(height: 30),
                      if (!hasFetchedLocation)
                        ElevatedButton(
                          onPressed: () async {
                            setState(() => isLoading = true);
                            try {
                              final fetchedAddress = await addressProvider.getCurrentLocationAddress();
                              fetchedAddress0 = fetchedAddress;
                              addressController.text = fetchedAddress.address;
                              setState(() => hasFetchedLocation = true);
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                            } finally {
                              setState(() => isLoading = false);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.appBGColor,
                            minimumSize: Size(187.w, 46.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),

                              // side: BorderSide(color: AppColors.mainBlackTextColor),
                            ),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator()
                              : Text(
                                  'Get Address',
                                  style: appTextStyle12(),
                                ),
                        )
                      else
                        Column(
                          children: [
                            TextField(
                              readOnly: true,
                              controller: addressController,
                              decoration: InputDecoration(
                                labelText: 'Enter or edit address',
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.location_pin),
                                  onPressed: () async {
                                    setState(() => isLoading = true);
                                    try {
                                      final fetchedAddress = await addressProvider.getCurrentLocationAddress();
                                      fetchedAddress0 = fetchedAddress;
                                      addressController.text = fetchedAddress.address;
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                    } finally {
                                      setState(() => isLoading = false);
                                    }
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  minimumSize: Size(187.w, 46.h),
                                  backgroundColor: AppColors.whiteColor,
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(color: AppColors.appBGColor),
                                    borderRadius: BorderRadius.circular(20.dg),
                                  )),
                              onPressed: () async {
                                if (addressController.text.isNotEmpty) {
                                  final newAddress = Address(
                                    name: 'Custom Address',
                                    address: addressController.text,
                                    lat: fetchedAddress0?.lat,
                                    lng: fetchedAddress0?.lng,
                                  );
                                  await addressProvider.addAddress(newAddress);
                                  Navigator.pop(context);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please enter your address')),
                                  );
                                }
                              },
                              child: Text(
                                'Save Address',
                                style: appTextStyle12(),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
