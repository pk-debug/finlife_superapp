// packages/features/home/lib/domain/entities/home_summary.dart
import 'package:equatable/equatable.dart';
//equatable is the go-to lightweight solution for value equality.
class HomeSummary extends Equatable {
  final String userName;
  final double accountBalance;
  final double portfolioValue;
  final int unreadNotifications;

  const HomeSummary({
    required this.userName,
    required this.accountBalance,
    required this.portfolioValue,
    required this.unreadNotifications,
  });

  @override
  List<Object?> get props => [
        userName,
        accountBalance,
        portfolioValue,
        unreadNotifications,
      ];
}