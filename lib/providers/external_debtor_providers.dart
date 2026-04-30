import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../data/models/external_debtor_model.dart';

final externalDebtorsSearchQueryProvider = StateProvider<String>((ref) => '');

final externalDebtorsStreamProvider = StreamProvider<List<ExternalDebtor>>((ref) {
  final query = ref.watch(externalDebtorsSearchQueryProvider).toLowerCase().trim();
  
  Query firestoreQuery = FirebaseFirestore.instance
      .collection(AppConstants.externalDebtorsCollection)
      .orderBy('name');

  if (query.isNotEmpty) {
    firestoreQuery = firestoreQuery.where('search_terms', arrayContains: query);
  }

  return firestoreQuery.snapshots().map((snapshot) {
    return snapshot.docs
        .map((doc) => ExternalDebtor.fromFirestore(doc))
        .toList();
  });
});
