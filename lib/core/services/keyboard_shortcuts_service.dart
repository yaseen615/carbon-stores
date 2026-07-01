import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/multi_cart_provider.dart';
import '../../providers/product_providers.dart';
import '../../providers/student_providers.dart';
import '../../features/pos/widgets/payment_dialog.dart';

/// Wraps the POS screen with keyboard shortcuts for fast billing.
///
/// Shortcuts:
///   `/` or `Ctrl+K`      → Focus product search
///   `Escape`             → Clear search / unfocus
///   `F2`                 → Open checkout dialog
///   `F5`                 → Refresh data
///   `Ctrl+N`             → New customer session
///   `Ctrl+W`             → Close current session
///   `Ctrl+Tab`           → Next customer session
///   `Ctrl+Shift+Tab`     → Previous customer session
///   `Ctrl+Backspace`     → Clear cart
///   `Ctrl+L`             → Toggle list/grid view
class PosKeyboardShortcuts extends ConsumerStatefulWidget {
  final Widget child;
  final FocusNode searchFocusNode;
  final TextEditingController searchController;

  const PosKeyboardShortcuts({
    super.key,
    required this.child,
    required this.searchFocusNode,
    required this.searchController,
  });

  @override
  ConsumerState<PosKeyboardShortcuts> createState() =>
      _PosKeyboardShortcutsState();
}

class _PosKeyboardShortcutsState extends ConsumerState<PosKeyboardShortcuts> {
  late final FocusNode _rootFocusNode;

  @override
  void initState() {
    super.initState();
    _rootFocusNode = FocusNode(debugLabel: 'PosKeyboardRoot');
  }

  @override
  void dispose() {
    _rootFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _rootFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: widget.child,
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    // Only handle key-down events
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    final isCtrl = HardwareKeyboard.instance.isControlPressed;
    final isShift = HardwareKeyboard.instance.isShiftPressed;

    // If we're inside a text field (search bar, quantity edit, etc.),
    // only handle Escape — let everything else pass through.
    if (_isTextInputFocused()) {
      if (key == LogicalKeyboardKey.escape) {
        _handleEscape();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    // ─── `/` or `Ctrl+K` → Focus search ───
    if (key == LogicalKeyboardKey.slash ||
        (isCtrl && key == LogicalKeyboardKey.keyK)) {
      widget.searchFocusNode.requestFocus();
      return KeyEventResult.handled;
    }

    // ─── Escape → Unfocus / clear ───
    if (key == LogicalKeyboardKey.escape) {
      _handleEscape();
      return KeyEventResult.handled;
    }

    // ─── F2 → Checkout ───
    if (key == LogicalKeyboardKey.f2) {
      _openCheckout();
      return KeyEventResult.handled;
    }

    // ─── F5 → Refresh data ───
    if (key == LogicalKeyboardKey.f5) {
      _refreshData();
      return KeyEventResult.handled;
    }

    // ─── Ctrl+N → New customer session ───
    if (isCtrl && key == LogicalKeyboardKey.keyN) {
      ref.read(multiCartProvider.notifier).addSession();
      return KeyEventResult.handled;
    }

    // ─── Ctrl+W → Close current session ───
    if (isCtrl && key == LogicalKeyboardKey.keyW) {
      final state = ref.read(multiCartProvider);
      ref.read(multiCartProvider.notifier).removeSession(state.activeSessionId);
      return KeyEventResult.handled;
    }

    // ─── Ctrl+Tab / Ctrl+Shift+Tab → Switch sessions ───
    if (isCtrl && key == LogicalKeyboardKey.tab) {
      _switchSession(forward: !isShift);
      return KeyEventResult.handled;
    }

    // ─── Ctrl+Backspace → Clear cart ───
    if (isCtrl && key == LogicalKeyboardKey.backspace) {
      ref.read(multiCartProvider.notifier).clearCart();
      return KeyEventResult.handled;
    }

    // ─── Ctrl+L → Toggle list/grid view ───
    if (isCtrl && key == LogicalKeyboardKey.keyL) {
      final current = ref.read(isProductListViewProvider);
      ref.read(isProductListViewProvider.notifier).state = !current;
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  bool _isTextInputFocused() {
    final focus = FocusManager.instance.primaryFocus;
    if (focus == null) return false;
    // Check if the focused widget's context has an EditableText ancestor
    final ctx = focus.context;
    if (ctx == null) return false;
    try {
      // Walk up to see if there's an EditableText
      bool found = false;
      ctx.visitAncestorElements((element) {
        if (element.widget is EditableText) {
          found = true;
          return false; // stop
        }
        return true; // continue
      });
      return found;
    } catch (_) {
      return false;
    }
  }

  void _handleEscape() {
    // If search has text, clear it
    if (widget.searchController.text.isNotEmpty) {
      widget.searchController.clear();
      ref.read(productSearchQueryProvider.notifier).state = '';
    }
    // Unfocus everything back to root
    widget.searchFocusNode.unfocus();
    _rootFocusNode.requestFocus();
  }

  void _openCheckout() {
    final cart = ref.read(multiCartProvider).activeItems;
    if (cart.isEmpty) return;
    showDialog(
      context: context,
      builder: (_) => const PaymentDialog(),
    );
  }

  void _refreshData() {
    ref.invalidate(productsStreamProvider);
    ref.invalidate(studentsStreamProvider);
  }

  void _switchSession({required bool forward}) {
    final state = ref.read(multiCartProvider);
    final sessions = state.sessions;
    if (sessions.length <= 1) return;

    final currentIdx =
        sessions.indexWhere((s) => s.id == state.activeSessionId);
    if (currentIdx < 0) return;

    int nextIdx;
    if (forward) {
      nextIdx = (currentIdx + 1) % sessions.length;
    } else {
      nextIdx = (currentIdx - 1 + sessions.length) % sessions.length;
    }
    ref.read(multiCartProvider.notifier).switchSession(sessions[nextIdx].id);
  }
}
