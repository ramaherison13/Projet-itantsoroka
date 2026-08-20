import 'package:flutter/material.dart';
import 'ajout_form_widget.dart'; // Assurez-vous que le nom du fichier correspond

class AjoutDocumentWidget extends StatelessWidget {
  const AjoutDocumentWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Adaptation responsive des marges (simulant ml-15 md:ml-20)
    final double screenWidth = MediaQuery.of(context).size.width;
    final double leftMargin = screenWidth > 768 ? 80.0 : 60.0;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(top: 40.0), // mt-10
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre "Ajout document"
            Padding(
              padding: EdgeInsets.only(left: leftMargin),
              child: Text(
                'Ajout document',
                style: TextStyle(
                  fontSize: screenWidth > 640 ? 48.0 : 36.0, // sm:text-5xl / text-4xl
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.grey.shade100 : Colors.black87,
                ),
              ),
            ),
            
            // Ligne décorative orange (#E98C21)
            Padding(
              padding: EdgeInsets.only(left: leftMargin, top: 20.0, bottom: 8.0), // my-2 mt-5
              child: Container(
                width: 120.0, // w-30 (30 * 4px)
                height: 6.0,  // h-1.5
                color: const Color(0xFFE98C21),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Intégration directe du formulaire complet (AjoutForm)
            const AjoutFormWidget(),
          ],
        ),
      ),
    );
  }
}