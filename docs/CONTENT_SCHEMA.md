# Content Schema — رفيق المسلم

Version: **1** (this document describes `schemaVersion: 1`).

`schemaVersion` describes the JSON contract (field names, types, rules) and
changes only when the contract changes. `contentVersion` (in
`manifest.json`) bumps whenever actual text content is revised. Keep them
separate: a text fix bumps `contentVersion`, a field change bumps
`schemaVersion`.

## Files

| File | Contents |
|---|---|
| `assets/data/manifest.json` | Snapshot metadata (the only file carrying `contentVersion`) |
| `assets/data/categories.json` | Array of categories under key `categories` |
| `assets/data/duas.json` | Array of entries under key `entries` |
| `assets/data/hadiths.json` | Array of entries under key `entries` |
| `assets/data/adhkar.json` | Array of entries under key `entries` |

All files are UTF-8 encoded JSON. Entry payloads are structurally identical
across the three content files; categories reference a content file by name.

## manifest.json

```json
{
  "schemaVersion": 1,
  "contentVersion": 1,
  "updatedAt": "2026-10-13",
  "files": ["categories.json", "duas.json", "hadiths.json", "adhkar.json"]
}
```

- `schemaVersion`, `contentVersion`: non-negative integers (contracted as int).
- `updatedAt`: non-empty ISO-8601 date string.
- `files`: non-empty array of file names. Filenames are checked against a fixed
  allow-list before loading; a file name in the JSON is never used as an
  arbitrary path component.

## categories.json — category object

| Field | Type | Notes |
|---|---|---|
| `id` | string, non-empty | Stable identifier; never reused, used for navigation |
| `title` | string, non-empty | Arabic category title |
| `subtitle` | string, optional | Arabic subtitle; empty string when omitted |
| `iconKey` | string, non-empty | Icon mapping key; UI uses a safe fallback for unknown keys |
| `contentFile` | string, non-empty | Content file holding this category's entries |
| `sortOrder` | int ≥ 0 | Display order |
| `enabled` | bool | `false` hides the category while keeping its data valid |

Duplicate `id` values across the array are rejected.

## Entry object (duas.json / hadiths.json / adhkar.json)

| Field | Type | Notes |
|---|---|---|
| `id` | string, non-empty | Stable identifier; never reused |
| `categoryId` | string, non-empty | Must reference an existing category id |
| `title` | string, non-empty | Arabic title |
| `text` | string, non-empty | Arabic body text, copied verbatim — never re-normalize diacritics for display |
| `source` | object, optional | See below. Omitted when no verified attribution exists |
| `repeatCount` | int > 0, optional | Prescribed repetition count. **Omitted everywhere in bundled data unless verified upstream.** UI must never invent a count; a user-defined target is stored locally instead |
| `tags` | array of non-empty strings, optional | Search keywords; defaults to `[]` |
| `sortOrder` | int ≥ 0 | Display order |
| `verified` | bool | `true` only when wording and attribution were reviewed |
| `placeholder` | bool | `true` marks schema/demo rows; a placeholder must never appear as real religious content |

Duplicate `id` values across the array are rejected.

### source object

```json
{ "reference": "سورة البقرة، آية 201", "kind": "quran", "authenticity": "صحيح" }
```

- `reference` (required, non-empty string): e.g. sura/ayah number or hadith
  collection + number.
- `kind` (optional string): coarse origin, e.g. `"quran"` or `"hadith"`.
- `authenticity` (optional string): hadith authenticity grade only. Must not
  be attached to Quran content.
- A `source` must only be present when `verified: true`. Unverified entries
  omit it so the UI cannot display an attribution as fact; empty fields are
  hidden, never rendered as empty claims.

## Placeholder policy

Placeholder rows exist only to exercise the schema and UI states. They are
marked with `"placeholder": true, "verified": false`, contain the literal
text `[محتوى تجريبي ...]`, and carry the tag `تجريبي`. Placeholder rows must
be filtered or visibly labelled before any production release; they can never
be mistaken for verified content.

## Validation rules (implemented in `lib/content/models/`)

1. Required string fields must be non-empty strings.
2. `sortOrder >= 0`; `repeatCount`, when present, must be an integer `> 0`.
3. `verified`, `placeholder`, and category `enabled` must be booleans.
4. Duplicate ids in a category list or an entry list are rejected with
   `ContentException`.
5. Parsing failures raise a typed `ContentException`; callers must not treat
   malformed content as empty lists.
6. Favorite state is never stored in content files — it lives in local user
   settings only.
