---
applyTo: "lib/**/*.dart"
description: "Use when changing Flutter or Dart source in this repository. Covers the existing game architecture, widget lifecycle, async state, formatting, and analysis."
---

# Flutter and Dart conventions

- Follow the existing organization under `lib/games/` and `lib/shared/`. Check nearby code before introducing a new abstraction, package, or state-management approach; avoid broad architectural rewrites for a focused change.
- Keep game rules and data transformations out of presentation widgets where the existing engine, model, or service layer owns that responsibility. Reuse the project's established patterns rather than adding a second way to manage the same state.
- Treat Flutter lifecycle as part of correctness: check `mounted` after asynchronous gaps before using `context` or calling `setState`; dispose controllers, focus nodes, and other owned resources in `dispose()`.
- Keep asynchronous UI actions safe against repeated taps and errors. Show actionable user-facing feedback, and do not silently swallow failures.
- Preserve support for the project's existing platforms and dependency constraints. Before adding or upgrading a package, check compatibility with the current Flutter/Dart SDK and other pinned dependencies.
- Format changed Dart files with `dart format` and run `flutter analyze` on the changed files. Run the relevant tests; for broad or shared changes, run the full `flutter test` suite.
- Do not reformat or modify unrelated files just to clear pre-existing analyzer notices.
