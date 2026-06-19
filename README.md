# Lotus ERP

Lotus ERP is a Flutter-based jewellery billing and operations system for sales,
girvi, stock, customers, suppliers, finance, karigar workflows, billing setup,
and reporting.

## Technology

- Flutter and Dart
- Drift with SQLite for local persistence
- Firebase for authentication and cloud services
- GoRouter for declarative navigation
- Provider and ChangeNotifier in the current UI state layer

## Local Development

```bash
flutter pub get
flutter analyze
flutter test
flutter build windows
```

## Engineering Standards

- Keep business rules out of widgets.
- Put database work behind repositories or dedicated data sources.
- Use transactions for billing, stock, payment, and ledger mutations.
- Prefer typed Drift queries over raw SQL unless raw SQL is clearly justified.
- Add regression tests for every financial calculation, migration, and posting flow.
- Keep screens focused and split large operational workflows into reusable sections.

## Current Focus

The application builds successfully on Windows and has an active Girvi module
under development. Future work should harden financial precision, migration
safety, test coverage, and module boundaries before large feature expansion.
