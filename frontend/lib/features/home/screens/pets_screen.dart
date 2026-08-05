import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vetmate/core/widgets/empty_state.dart';

class PetsScreen extends StatelessWidget {
  const PetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Pets',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: EmptyState(
          title: 'No Pets Added Yet',
          description:
              'Add your pets here to keep track of their medical history, prescriptions, and vaccine details.',
          icon: Icons.pets_outlined,
          actionText: 'Add New Pet',
          onActionPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Pet addition flow simulated.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ),
    );
  }
}
