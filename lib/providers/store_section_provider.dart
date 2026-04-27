import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/store_section.dart';

/// Global section filter — controls what data is shown across all screens.
/// Default: [StoreSection.all] so users see everything on app launch.
final storeSectionProvider = StateProvider<StoreSection>((ref) => StoreSection.all);
