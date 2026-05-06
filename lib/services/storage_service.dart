import 'package:cloud_firestore/cloud_firestore.dart';
import '../models.dart';

class StorageService {
  static final _db = FirebaseFirestore.instance;

  static Stream<List<Allotment>> streamAllotments() {
    return _db.collection('allotments').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Allotment.fromJson({...doc.data(), 'id': doc.id})).toList();
    });
  }

  static Stream<List<Expense>> streamExpenses() {
    return _db.collection('expenses').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Expense.fromJson({...doc.data(), 'id': doc.id})).toList();
    });
  }

  static Future<void> addAllotment(Allotment allotment) async {
    await _db.collection('allotments').doc(allotment.id).set(allotment.toJson());
  }

  static Future<void> addExpense(Expense expense) async {
    await _db.collection('expenses').doc(expense.id).set(expense.toJson());
  }

  // To keep compatibility with PDF generation or anything that just needs a one-time fetch
  static Future<({List<Allotment> allotments, List<Expense> expenses})> load() async {
    final allotsSnap = await _db.collection('allotments').get();
    final expSnap = await _db.collection('expenses').get();
    
    final allotments = allotsSnap.docs.map((doc) => Allotment.fromJson({...doc.data(), 'id': doc.id})).toList();
    final expenses = expSnap.docs.map((doc) => Expense.fromJson({...doc.data(), 'id': doc.id})).toList();
    
    return (allotments: allotments, expenses: expenses);
  }
}
