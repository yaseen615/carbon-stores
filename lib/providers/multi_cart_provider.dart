import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/store_section.dart';
import '../data/models/cart_item_model.dart';
import '../data/models/product_model.dart';
import '../data/models/student_model.dart';

// ═══════════════════════════════════════════════════════════════
//  CART SESSION — one per customer tab
// ═══════════════════════════════════════════════════════════════

class CartSession {
  final String id;
  final int number; // display number: Customer 1, Customer 2, ...
  final List<CartItem> items;
  final Student? linkedStudent;

  const CartSession({
    required this.id,
    required this.number,
    this.items = const [],
    this.linkedStudent,
  });

  /// Display label for the tab
  String get label {
    if (linkedStudent != null && linkedStudent!.name.isNotEmpty) {
      return linkedStudent!.name;
    }
    return 'Customer $number';
  }

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  double get total => items.fold(0.0, (sum, item) => sum + item.total);

  CartSession copyWith({
    String? id,
    int? number,
    List<CartItem>? items,
    Student? linkedStudent,
    bool clearStudent = false,
  }) {
    return CartSession(
      id: id ?? this.id,
      number: number ?? this.number,
      items: items ?? this.items,
      linkedStudent: clearStudent ? null : (linkedStudent ?? this.linkedStudent),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  MULTI-CART STATE
// ═══════════════════════════════════════════════════════════════

class MultiCartState {
  final List<CartSession> sessions;
  final String activeSessionId;
  final int _counter; // ever-increasing counter for naming

  const MultiCartState({
    required this.sessions,
    required this.activeSessionId,
    int counter = 1,
  }) : _counter = counter;

  int get counter => _counter;

  CartSession get activeSession =>
      sessions.firstWhere((s) => s.id == activeSessionId);

  /// Convenience: active session's cart items
  List<CartItem> get activeItems => activeSession.items;

  /// Convenience: active session's linked student
  Student? get activeStudent => activeSession.linkedStudent;

  /// Auto-detected section for the active session based on items.
  /// cafe → all items are cafe
  /// store → all items are store (or cart empty)
  /// combined → mix of cafe and store items
  StoreSection get activeSessionSection {
    final items = activeItems;
    if (items.isEmpty) return StoreSection.store;
    final sections = items.map((i) => i.section).toSet();
    if (sections.length > 1) return StoreSection.combined;
    return StoreSection.fromString(sections.first);
  }

  MultiCartState copyWith({
    List<CartSession>? sessions,
    String? activeSessionId,
    int? counter,
  }) {
    return MultiCartState(
      sessions: sessions ?? this.sessions,
      activeSessionId: activeSessionId ?? this.activeSessionId,
      counter: counter ?? _counter,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  MULTI-CART NOTIFIER
// ═══════════════════════════════════════════════════════════════

class MultiCartNotifier extends StateNotifier<MultiCartState> {
  MultiCartNotifier()
      : super(MultiCartState(
          sessions: [
            CartSession(id: _generateId(), number: 1),
          ],
          activeSessionId: '',
          counter: 1,
        )) {
    // Fix: set activeSessionId to first session
    state = state.copyWith(activeSessionId: state.sessions.first.id);
  }

  static int _idCounter = 0;
  static String _generateId() => 'session_${DateTime.now().millisecondsSinceEpoch}_${_idCounter++}';

  // ─── Session Management ───

  /// Add a new customer session and switch to it
  void addSession() {
    final newNumber = state.counter + 1;
    final newSession = CartSession(
      id: _generateId(),
      number: newNumber,
    );
    state = state.copyWith(
      sessions: [...state.sessions, newSession],
      activeSessionId: newSession.id,
      counter: newNumber,
    );
  }

  /// Remove a session by ID. If it's the active session, switch to adjacent.
  /// If it's the last session, create a fresh one.
  void removeSession(String sessionId) {
    final sessions = state.sessions;
    if (sessions.length == 1) {
      // Last session: just clear it instead of removing
      final cleared = sessions.first.copyWith(
        items: [],
        clearStudent: true,
      );
      state = state.copyWith(sessions: [cleared]);
      return;
    }

    final idx = sessions.indexWhere((s) => s.id == sessionId);
    if (idx < 0) return;

    final updated = List<CartSession>.from(sessions)..removeAt(idx);
    String newActiveId = state.activeSessionId;

    if (state.activeSessionId == sessionId) {
      // Switch to previous tab, or next if removing first
      final newIdx = idx > 0 ? idx - 1 : 0;
      newActiveId = updated[newIdx].id;
    }

    state = state.copyWith(sessions: updated, activeSessionId: newActiveId);
  }

  /// Switch active session
  void switchSession(String sessionId) {
    if (state.sessions.any((s) => s.id == sessionId)) {
      state = state.copyWith(activeSessionId: sessionId);
    }
  }

  /// Update linked students across all sessions with fresh data
  void refreshLinkedStudents(List<Student> freshStudents) {
    final updatedSessions = state.sessions.map((session) {
      if (session.linkedStudent != null) {
        final studentId = session.linkedStudent!.id;
        try {
          final fresh = freshStudents.firstWhere((s) => s.id == studentId);
          return session.copyWith(linkedStudent: fresh);
        } catch (_) {
          // Keep old if not found
          return session;
        }
      }
      return session;
    }).toList();
    
    state = state.copyWith(sessions: updatedSessions);
  }

  // ─── Cart Operations (on active session) ───

  void addProduct(Product product) {
    if (product.isOutOfStock) return;
    _updateActiveSession((session) {
      final items = List<CartItem>.from(session.items);
      final index = items.indexWhere((item) => item.productId == product.id);

      if (index >= 0) {
        final currentItem = items[index];
        if (currentItem.quantity >= product.stock) return session;
        items[index] = currentItem.copyWith(quantity: currentItem.quantity + 1);
      } else {
        items.add(CartItem(
          productId: product.id,
          name: product.name,
          price: product.price,
          quantity: 1,
          imageId: product.imageId,
          section: product.section, // carry section from product
        ));
      }
      return session.copyWith(items: items);
    });
  }

  void incrementQuantity(String productId, {int maxStock = 999}) {
    _updateActiveSession((session) {
      final items = List<CartItem>.from(session.items);
      final index = items.indexWhere((item) => item.productId == productId);
      if (index < 0) return session;

      final item = items[index];
      if (item.quantity >= maxStock) return session;
      items[index] = item.copyWith(quantity: item.quantity + 1);
      return session.copyWith(items: items);
    });
  }

  void decrementQuantity(String productId) {
    _updateActiveSession((session) {
      final items = List<CartItem>.from(session.items);
      final index = items.indexWhere((item) => item.productId == productId);
      if (index < 0) return session;

      final item = items[index];
      if (item.quantity <= 1) {
        items.removeAt(index);
      } else {
        items[index] = item.copyWith(quantity: item.quantity - 1);
      }
      return session.copyWith(items: items);
    });
  }

  void removeItem(String productId) {
    _updateActiveSession((session) {
      return session.copyWith(
        items: session.items.where((item) => item.productId != productId).toList(),
      );
    });
  }

  void clearCart() {
    _updateActiveSession((session) {
      return session.copyWith(items: []);
    });
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    _updateActiveSession((session) {
      final items = List<CartItem>.from(session.items);
      final index = items.indexWhere((item) => item.productId == productId);
      if (index < 0) return session;
      items[index] = items[index].copyWith(quantity: quantity);
      return session.copyWith(items: items);
    });
  }

  // ─── Student Operations (on active session) ───

  void setStudent(Student student) {
    _updateActiveSession((session) {
      return session.copyWith(linkedStudent: student);
    });
  }

  void clearStudent() {
    _updateActiveSession((session) {
      return session.copyWith(clearStudent: true);
    });
  }

  // ─── Checkout: auto-close the active tab ───

  /// Called after successful payment. Removes the active session tab.
  void closeActiveSessionAfterCheckout() {
    removeSession(state.activeSessionId);
  }

  // ─── Internal ───

  void _updateActiveSession(CartSession Function(CartSession) updater) {
    final sessions = state.sessions.map((s) {
      if (s.id == state.activeSessionId) {
        return updater(s);
      }
      return s;
    }).toList();
    state = state.copyWith(sessions: sessions);
  }
}

// ═══════════════════════════════════════════════════════════════
//  PROVIDERS
// ═══════════════════════════════════════════════════════════════

final multiCartProvider =
    StateNotifierProvider<MultiCartNotifier, MultiCartState>((ref) {
  return MultiCartNotifier();
});

/// Active session's cart items (convenience)
final activeCartItemsProvider = Provider<List<CartItem>>((ref) {
  return ref.watch(multiCartProvider).activeItems;
});

/// Active session's total
final activeCartTotalProvider = Provider<double>((ref) {
  return ref.watch(multiCartProvider).activeSession.total;
});

/// Active session's item count
final activeCartItemCountProvider = Provider<int>((ref) {
  return ref.watch(multiCartProvider).activeSession.itemCount;
});

/// Active session's linked student
final activeStudentProvider = Provider<Student?>((ref) {
  return ref.watch(multiCartProvider).activeStudent;
});

/// Whether active session's cart is empty
final isActiveCartEmptyProvider = Provider<bool>((ref) {
  return ref.watch(multiCartProvider).activeItems.isEmpty;
});
