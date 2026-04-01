import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Navigation state for the app shell sidebar
enum AppPage { pos, students, inventory, expenses, analytics }

final currentPageProvider = StateProvider<AppPage>((ref) => AppPage.pos);
