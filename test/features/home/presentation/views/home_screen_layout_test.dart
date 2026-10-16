import 'package:finlife_superapp/features/home/domain/entities/domain_summary.dart';
import 'package:finlife_superapp/features/home/domain/repositories/home_repository.dart';
import 'package:finlife_superapp/features/home/domain/usecases/get_home_dashboard.dart';
import 'package:finlife_superapp/features/home/presentation/providers/home_providers.dart';
import 'package:finlife_superapp/features/home/presentation/viewmodel/home_viewmodel.dart';
import 'package:finlife_superapp/features/home/presentation/views/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('dashboard fits a narrow phone at increased text scale', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeViewModelProvider.overrideWith(
            (ref) => HomeViewModel(GetHomeDashboard(_FakeHomeRepository())),
          ),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: const HomeScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('₹42,500.00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FakeHomeRepository implements HomeRepository {
  @override
  Future<List<DomainSummary>> getDashboardSummaries() async => const [
    DomainSummary(
      domain: AppDomain.banking,
      title: 'Banking',
      headlineValue: '₹42,500.00',
      statusLine: 'Last synced just now',
    ),
    DomainSummary(
      domain: AppDomain.insurance,
      title: 'Insurance',
      headlineValue: '3 policies',
      statusLine: '1 policy renewal upcoming',
    ),
    DomainSummary(
      domain: AppDomain.stock,
      title: 'Stock Market',
      headlineValue: '+2.4% today',
      statusLine: 'Portfolio updated just now',
    ),
    DomainSummary(
      domain: AppDomain.consumer,
      title: 'Shopping',
      headlineValue: '2 orders in transit',
      statusLine: 'Next delivery expected tomorrow',
    ),
    DomainSummary(
      domain: AppDomain.lifestyle,
      title: 'Lifestyle',
      headlineValue: '5-day habit streak',
      statusLine: 'Keep up the great work',
    ),
  ];
}
