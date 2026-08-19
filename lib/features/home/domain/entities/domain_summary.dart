import 'package:equatable/equatable.dart';

/// Identifies which business domain a [DomainSummary] belongs to.
///
/// WHAT: an enum so the presentation layer can pick an icon/color/route
/// per domain without string-matching a name field.
/// WHY: a typed enum over a raw string prevents typos like "banking " vs
/// "Banking" silently breaking a switch statement at runtime.
/// WHERE: shared by domain entities, data mappers, and presentation widgets.
enum AppDomain { banking, insurance, stock, consumer, lifestyle }

/// A single tile's worth of data on the Home Dashboard — one per business
/// domain (Banking, Insurance, Stock, Consumer, Lifestyle).
///
/// WHAT: an immutable value object summarizing "the one number and one
/// status line" a user wants to see about a domain at a glance — e.g.
/// "Banking: ₹42,500 available, balance synced".
///
/// WHY: the Home screen deliberately does NOT know how a balance is
/// calculated or how a portfolio value is derived — that logic lives in
/// each domain's own feature module. Home only depends on this small,
/// domain-agnostic shape, which is what keeps Home from becoming a god
/// module that imports every other feature's internals.
///
/// WHERE: lives in `domain/entities` — no Flutter or package imports, so
/// this class is trivially unit-testable and reusable if the app is ever
/// split into a Dart-only package (Melos) for shared domain code.
///
/// WHEN: constructed by [HomeRepository] implementations after fetching/
/// aggregating each domain's headline data; consumed by [HomeViewModel]
/// and rendered by `DomainSummaryCard`.
///
/// WHO: owned by the Home feature; each domain feature (Banking, Stock, ...)
/// is expected to expose *its own* richer entities separately — this is
/// intentionally a lossy, display-only projection of them.
///
/// HOW: plain Dart class + [Equatable] for value equality (no `freezed`
/// needed for something this small — avoids a build_runner dependency for
/// feature 1).
///
/// HOW MUCH: five fields, all required except [isStale] which defaults to
/// `false`. Kept intentionally minimal — this is a summary, not a report.
class DomainSummary extends Equatable {
  const DomainSummary({
    required this.domain,
    required this.title,
    required this.headlineValue,
    required this.statusLine,
    this.isStale = false,
  });

  /// Which business domain this tile represents.
  final AppDomain domain;

  /// Short label shown on the card, e.g. "Banking".
  final String title;

  /// The one number/value the user cares about most at a glance, already
  /// formatted for display, e.g. "₹42,500.00" or "12 policies".
  ///
  /// WHY pre-formatted here (not a raw `double`): formatting rules differ
  /// per domain (currency vs. count vs. percentage change) and belong to
  /// the data layer that knows the domain, not to a shared UI widget.
  final String headlineValue;

  /// One short line of context, e.g. "Synced 2 min ago" or "3 claims open".
  final String statusLine;

  /// True when this summary was served from local cache because the
  /// live fetch failed or is still in flight.
  ///
  /// WHEN this flips true: set by [HomeRepositoryImpl] whenever it falls
  /// back to a cached value instead of a fresh network response.
  /// WHY it matters: the UI must never show a stale balance without
  /// indicating it's stale (see project system-design notes on banking
  /// sync) — this flag is how that rule is threaded through to the widget.
  final bool isStale;

  @override
  List<Object?> get props => [domain, title, headlineValue, statusLine, isStale];
}
