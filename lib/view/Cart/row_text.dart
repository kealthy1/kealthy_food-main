import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RowTextWidget extends StatelessWidget {
  final String label;
  final String value;
  final Color? colr;

  const RowTextWidget({
    super.key,
    required this.label,
    required this.value,
    this.colr,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: colr , // Default color if not provided
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: colr,
          ),
        ),
      ],
    );
  }
}