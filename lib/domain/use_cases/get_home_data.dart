// domain/use_cases/get_home_data.dart
import 'package:finlife_superapp/domain/entities/home_summary.dart';
import 'package:finlife_superapp/domain/entities/recent_transaction.dart';

class HomeData {
  final HomeSummary summary;
  final List<RecentTransaction> recentTransactions;
  HomeData(this.summary, this.recentTransactions);
}