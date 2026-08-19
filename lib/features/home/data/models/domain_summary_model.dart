import '../../domain/entities/domain_summary.dart';

/// Data-layer DTO for a dashboard tile, as it would arrive from an API
/// (today: from an in-memory fake datasource that mimics that shape).
///
/// WHAT: the wire/storage representation of [DomainSummary]. Distinct from
/// the domain entity on purpose, even though today the fields line up
/// 1:1 — the moment a real backend returns e.g. `headline_value_cents`
/// as an int instead of a formatted string, only this model's `fromJson`
/// and `toEntity` change; [DomainSummary] and everything above it in the
/// domain/presentation layers stay untouched.
///
/// WHY keep Model and Entity separate even when small: it's the textbook
/// Clean Architecture boundary — entities represent business truth, models
/// represent transport truth. Collapsing them is a common shortcut that
/// works fine at prototype scale and then costs a painful refactor the
/// first time the API shape and the UI's ideal shape diverge.
///
/// WHERE: `data/models` — imported only by `data/datasources` and
/// `data/repositories`. Never imported by `domain/` or `presentation/`.
///
/// WHEN: constructed by [HomeRemoteDataSource] from raw JSON (or, today,
/// from an in-memory `Map`); converted to [DomainSummary] by
/// `HomeRepositoryImpl` before crossing into the domain layer.
///
/// HOW: a manual `fromJson`/`toEntity` pair — no `json_serializable`
/// codegen for this small shape, to keep feature 1 buildable without a
/// build_runner step. Larger DTOs (Banking transactions, Stock quotes)
/// will use codegen once the project's build pipeline is set up.
class DomainSummaryModel {
  const DomainSummaryModel({
    required this.domainKey,
    required this.title,
    required this.headlineValue,
    required this.statusLine,
    required this.isStale,
  });

  /// String key matching [AppDomain].name, e.g. "banking".
  ///
  /// WHY a string here and an enum in the entity: JSON has no enums.
  /// This is exactly the seam this model exists to own.
  final String domainKey;
  final String title;
  final String headlineValue;
  final String statusLine;
  final bool isStale;

  /// Parses a raw JSON-like map into a [DomainSummaryModel].
  ///
  /// HOW MUCH: defensive on missing `is_stale` (defaults to `false`) since
  /// not every backend will bother sending `false` explicitly; every other
  /// field is required and will throw a clear `TypeError` if absent,
  /// which is preferable to silently rendering an empty card.
  factory DomainSummaryModel.fromJson(Map<String, dynamic> json) {
    return DomainSummaryModel(
      domainKey: json['domain'] as String,
      title: json['title'] as String,
      headlineValue: json['headline_value'] as String,
      statusLine: json['status_line'] as String,
      isStale: json['is_stale'] as bool? ?? false,
    );
  }

  /// Converts this transport model into the domain entity.
  ///
  /// WHEN: called exactly once per model, inside `HomeRepositoryImpl`,
  /// right before the data crosses the data→domain boundary.
  DomainSummary toEntity() {
    return DomainSummary(
      domain: AppDomain.values.firstWhere(
        (d) => d.name == domainKey,
        orElse: () => throw ArgumentError(
          'Unknown domain key "$domainKey" — add it to AppDomain first.',
        ),
      ),
      title: title,
      headlineValue: headlineValue,
      statusLine: statusLine,
      isStale: isStale,
    );
  }
}
