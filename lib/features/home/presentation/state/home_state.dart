import 'package:equatable/equatable.dart';

import '../../domain/entities/domain_summary.dart';

/// Immutable snapshot of everything the Home view needs to render at any
/// given moment — the "Model" half of MVVM's View/ViewModel/Model split.
///
/// WHAT: a single object capturing loading/error/data state together,
/// instead of three separate booleans/nullable fields scattered around.
///
/// WHY one combined state class over `AsyncValue<List<DomainSummary>>`
/// directly: [AsyncValue] is used internally by the ViewModel's provider,
/// but this project's convention is to expose a feature-specific state
/// class from the ViewModel so the View never has to `.when(...)` pattern
/// -match Riverpod internals — the View only ever asks three questions:
/// "am I loading", "did it fail", "what's the data". This also means
/// swapping Riverpod for Bloc later (see README's per-feature state
/// table) only touches the ViewModel, not the View, because the View
/// depends on this plain state class, not on Riverpod's types.
///
/// WHERE: `presentation/state` — imported by both the ViewModel (which
/// produces it) and the View (which consumes it). Never imported by
/// `domain/` or `data/`.
///
/// WHEN: a new instance is created on every state transition — initial
/// load start, success, error, and refresh — via [copyWith].
///
/// HOW: plain immutable class + [Equatable], with a private default
/// constructor and named factory constructors for each meaningful state,
/// so call sites read as intent ("HomeState.loading()") rather than
/// positional booleans.
class HomeState extends Equatable {
  const HomeState._({
    required this.isLoading,
    required this.summaries,
    this.errorMessage,
  });

  /// Initial/loading state — shown once, before the first fetch resolves.
  const HomeState.loading()
      : this._(isLoading: true, summaries: const [], errorMessage: null);

  /// Successful load (or refresh) with data to show.
  const HomeState.data(List<DomainSummary> summaries)
      : this._(isLoading: false, summaries: summaries, errorMessage: null);

  /// Fetch failed and there is no data to fall back to.
  ///
  /// WHY keep [summaries] rather than force it empty on error: if this
  /// ever becomes an error *during refresh* (data already on screen), the
  /// UI can choose to keep showing the last good data with a small error
  /// banner instead of a full-screen error — a strictly better UX. Today's
  /// ViewModel doesn't yet do partial-refresh-preserves-data (see TODO in
  /// `HomeViewModel.refresh`), but the state shape already supports it.
  const HomeState.error(String message, {List<DomainSummary> summaries = const []})
      : this._(isLoading: false, summaries: summaries, errorMessage: message);

  final bool isLoading;
  final List<DomainSummary> summaries;
  final String? errorMessage;

  bool get hasError => errorMessage != null;
  bool get hasData => summaries.isNotEmpty;

  @override
  List<Object?> get props => [isLoading, summaries, errorMessage];
}
