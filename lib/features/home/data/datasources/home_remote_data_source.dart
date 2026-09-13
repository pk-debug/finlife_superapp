import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/domain_summary_model.dart';

/// Contract + fake implementation for fetching dashboard data "remotely".
///
/// WHAT: today this is an in-memory stand-in that returns hardcoded data
/// after a simulated network delay. It exists so the rest of the stack
/// (repository → use case → ViewModel → view) can be built and tested
/// against a *stable, real interface* before a backend exists.
///
/// WHY build a fake datasource instead of stubbing the repository
/// directly: the fake lives exactly where the real Dio-backed datasource
/// will live later. Swapping this class for `HomeRemoteDataSourceDio`
/// (implementing the same abstract contract) requires touching exactly
/// one line — the provider wiring in `home_providers.dart` — nothing in
/// `domain/` or `presentation/` changes. That's the whole point of the
/// datasource being behind an interface even on day one.
///
/// WHERE: `data/datasources` — the outermost ring of Clean Architecture.
/// This is the only file in the Home feature allowed to "know" about
/// network/IO concepts (delays, timeouts, JSON).
///
/// WHEN: invoked by `HomeRepositoryImpl.getDashboardSummaries()`.
///
/// WHO: owned by whoever is implementing the Home API contract on the
/// backend side — this class documents the exact JSON shape they need to
/// return (see [_fakeJsonPayload]).
///
/// HOW: `Future.delayed` simulates network latency so the ViewModel's
/// loading state is exercised realistically even before a real backend
/// exists (otherwise the loading spinner would never actually render
/// during local development).
abstract class HomeRemoteDataSource {
  Future<List<DomainSummaryModel>> fetchDashboardSummaries();
}

/// Asset-backed mock implementation used until the Home API exists.
///
/// [AssetBundle] is injected, rather than read directly from [rootBundle], so
/// widget/unit tests can provide their own bundle without changing data,
/// domain, or presentation code.
class AssetHomeRemoteDataSource implements HomeRemoteDataSource {
  const AssetHomeRemoteDataSource(this._assets);

  static const _assetPath = 'assets/mock/home_dashboard.json';

  final AssetBundle _assets;

  @override
  Future<List<DomainSummaryModel>> fetchDashboardSummaries() async {
    final rawJson = await _assets.loadString(_assetPath);
    final decoded = jsonDecode(rawJson) as List<dynamic>;
    return decoded
        .cast<Map<String, dynamic>>()
        .map(DomainSummaryModel.fromJson)
        .toList();
  }
}
