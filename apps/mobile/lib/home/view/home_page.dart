import 'package:flutter/material.dart';
import 'package:mobile/venues/view/venue_search_page.dart';

/// Home page - main screen after authentication
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const HomePage());
  }

  @override
  Widget build(BuildContext context) {
    return const VenueSearchPage();
  }
}
