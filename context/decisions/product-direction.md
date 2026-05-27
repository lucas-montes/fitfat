# Product Direction

## Confirmed decisions
- The app is a single-user fitness tracker.
- Nutrition and training are both first-class parts of the product.
- The app should work offline by default and not depend on internet access.
- User-facing workout terminology should be localized, with support for French, English, and Spanish.
- Settings are currently best modeled as a dashboard tab.
- The near-term goal is polish: simpler code, easier tests, and fewer bugs.

## Terminology guidance
- Prefer `workout` in English UI.
- Preserve localization-friendly terminology so the same concept can render naturally in French and Spanish.
- Avoid locking the product into a French-only term like `seance` in user-facing copy.

## Implications for future work
- Favor offline persistence and local-only flows where possible.
- Keep architecture readable and testable rather than over-optimized.
- Treat both nutrition and training features as equally important when prioritizing fixes.
