import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy_food/view/Login/login_page.dart';
import 'package:kealthy_food/view/home/provider.dart';
import 'package:kealthy_food/view/profile%20page/edit_profile.dart';
import 'package:kealthy_food/view/profile%20page/provider.dart';

class KealthyPage extends ConsumerWidget {
  const KealthyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final phoneNumber = ref.watch(phoneNumberProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
          child: Column(
            children: [
              Image.asset(
                'lib/assets/images/PHOTO-2025-01-22-11-55-26.jpg',
                height: screenHeight * 0.06,
              ),
              SizedBox(height: screenHeight * 0.01),
              Text(
                "Savour The Healthier Choice",
                style: GoogleFonts.poppins(
                  fontSize: screenWidth * 0.045,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: screenHeight * 0.01),
              Text(
                "With Love From Kochi",
                style: GoogleFonts.poppins(
                    fontSize: screenWidth * 0.04, color: Colors.grey[400]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        SizedBox(height: screenHeight * 0.04),
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: screenWidth * 0.05,
            runSpacing: screenHeight * 0.02,
            children: [
              LabeledCircle(
                color: Colors.green[100]!,
                icon: Icons.spa_outlined,
                label: "Wellness",
              ),
              LabeledCircle(
                color: Colors.yellow[100]!,
                icon: Icons.favorite_border,
                label: "Care",
              ),
              LabeledCircle(
                color: Colors.blue[100]!,
                icon: CupertinoIcons.checkmark_seal_fill,
                label: "Quality",
              ),
              LabeledCircle(
                color: Colors.orange[100]!,
                icon: Icons.local_florist_outlined,
                label: "Natural",
              ),
            ],
          ),
        ),
        SizedBox(height: screenHeight * 0.02),
        Padding(
          padding: EdgeInsets.only(bottom: screenHeight * 0.02),
          child: Column(
            children: [
              Text(
                "Crafted with Care for a Healthier You",
                style: GoogleFonts.poppins(
                  fontSize: screenWidth * 0.035,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: screenHeight * 0.01),
              Text(
                "Join us on a journey towards a healthier lifestyle!",
                style: GoogleFonts.poppins(
                  fontSize: screenWidth * 0.03,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
              if (phoneNumber.isNotEmpty &&
                  profile.name.isEmpty &&
                  profile.email.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0,vertical: 10),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Subscribe to our newsletter",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color.fromRGBO(0, 0, 0, 0.4),
                          ),
                        ),
                        const SizedBox(width: 5),
                        GestureDetector(
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditProfilePage(
                                    name: profile.name, email: profile.email),
                              ),
                            );
                            if (result == true) {
                              ref
                                  .read(newsletterSubscribedProvider.notifier)
                                  .state = true;
                            }
                          },
                          child: Text(
                            'click here',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade400,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class LabeledCircle extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;

  const LabeledCircle({
    required this.color,
    required this.icon,
    required this.label,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Column(
      children: [
        Container(
          width: screenWidth * 0.10,
          height: screenWidth * 0.10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(icon, size: screenWidth * 0.06, color: Colors.grey[800]),
        ),
        SizedBox(height: screenWidth * 0.04),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: screenWidth * 0.030,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
