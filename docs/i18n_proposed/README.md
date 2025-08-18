# Proposed ARB Localization Files (Staging)

## Purpose

Conservative staging area for rebuilding clean ARB files before replacing the corrupted production `app_en.arb` / `app_ar.arb` in `lib/l10n`.

## Contents

- `proposed_app_en.arb` – Draft English keys & strings.
- `proposed_app_ar.arb` – Draft Arabic translations mirroring the key set.

## Next Steps

1. Expand key set: continue extracting hard-coded Arabic UI strings into these proposed files.
2. Review placeholders: add metadata (`@key`) entries if needed for plurals or parameter descriptions.
3. Validation pass: once coverage reaches ~100%, backup current corrupted ARB files, then promote these drafts (rename & move to `lib/l10n`).
4. Run: `flutter gen-l10n` (implicitly via build) to regenerate localization classes.
5. Incremental refactor: replace hard-coded strings with `S.of(context).keyName` usages.

## Guidelines

- Keep keys semantic and stable (avoid embedding language-specific words in keys).
- Use placeholders for dynamic values: e.g. `"saleNumber": "Sale #{saleId}"` with a matching `@saleNumber` metadata block when adding context.
- For repeated generic labels (OK, Cancel), reuse existing keys.
- For multi-line or formatted text, use `\n` within the value; avoid raw newlines until final.

## Do NOT

- Overwrite production ARB until coverage audited.
- Remove an existing key in drafts without listing it for deprecation.

## After Promotion

Create a changelog entry summarizing:

- Number of new keys
- Keys renamed / deprecated
- Any placeholders introduced

This README exists only in staging; it need not be moved with the ARB files.
