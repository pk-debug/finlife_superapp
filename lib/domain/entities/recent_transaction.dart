// packages/features/home/lib/domain/entities/recent_transaction.dart
import 'package:equatable/equatable.dart';

class RecentTransaction extends Equatable {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String category; // 'banking', 'stock', 'consumer', etc.

  const RecentTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
  });

  @override
  List<Object?> get props => [id, title, amount, date, category];
}