/// Represents the two business sections: Cafe and Store.
/// Used for filtering data across billing, inventory, expenses, and analytics.
enum StoreSection {
  cafe,
  store,
  combined, // Cart had both cafe + store items
  all; // UI-only filter: show everything

  String get label {
    switch (this) {
      case StoreSection.cafe:
        return 'Cafe';
      case StoreSection.store:
        return 'Store';
      case StoreSection.combined:
        return 'Combined';
      case StoreSection.all:
        return 'All';
    }
  }

  String get emoji {
    switch (this) {
      case StoreSection.cafe:
        return '☕';
      case StoreSection.store:
        return '🏪';
      case StoreSection.combined:
        return '🔀';
      case StoreSection.all:
        return '◎';
    }
  }

  /// Firestore-safe value. 'all' is a UI filter, never persisted.
  String get firestoreValue {
    switch (this) {
      case StoreSection.cafe:
        return 'cafe';
      case StoreSection.store:
        return 'store';
      case StoreSection.combined:
        return 'combined';
      case StoreSection.all:
        return 'all';
    }
  }

  /// Parse from Firestore string. Defaults to 'store' for backward compat.
  static StoreSection fromString(String? value) {
    switch (value) {
      case 'cafe':
        return StoreSection.cafe;
      case 'combined':
        return StoreSection.combined;
      case 'store':
      default:
        return StoreSection.store;
    }
  }
}
