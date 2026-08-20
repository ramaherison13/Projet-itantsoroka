import 'package:flutter/material.dart';
import '../home/home_screen.dart';
import '../home/monography_screen.dart';
import '../offre_std/offre_std_page.dart';
import '../publications/publish_page_principal_screen.dart';
import '../../widgets/gestion_document/tous_documents_widget.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const MonographieScreen(),
    OffreStdPage(baseUrl: "https://gateway.tsirylab.com", currentUser: const {}),
    const TousDocumentsWidget(baseUrl: "https://gateway.tsirylab.com"),
    const PublishPagePrincipalScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF098E00),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Monographie'),
          BottomNavigationBarItem(icon: Icon(Icons.local_offer), label: 'Offres'),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Documents'),
          BottomNavigationBarItem(icon: Icon(Icons.article), label: 'Publication'),
        ],
      ),
    );
  }
}