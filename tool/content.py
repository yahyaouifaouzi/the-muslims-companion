#!/usr/bin/env python3
"""Build and validate bundled content (assets/data/*.json).

All religious text is copied verbatim from the raw source files in
`data-sources/` (not committed; see `docs/CONTENT_PUBLISHING.md`). Nothing
here writes Arabic religious wording from memory — every entry's `text`
comes straight out of a source file, and `diff` re-checks that afterwards
character by character.

Usage:
  python3 tool/content.py build morning|evening|quran|general|hadith|manifest
  python3 tool/content.py validate [--strict]
  python3 tool/content.py diff
  python3 tool/content.py review
"""

from __future__ import annotations

import json
import re
import sys
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "assets" / "data"
SRC = ROOT / "data-sources"

SEEN = SRC / "adhkar_seen_arabic.json"
HISN = SRC / "hisn_almuslim.json"
NAWAWI = SRC / "nawawi40.json"
QURAN = SRC / "quran_uthmani.json"

# ---------------------------------------------------------------------------
# text helpers
# ---------------------------------------------------------------------------


def strip_tashkeel(s: str) -> str:
    """Remove combining marks only; everything else stays verbatim."""
    return "".join(c for c in s if not unicodedata.combining(c))


def clean_display(s: str) -> str:
    """strip_tashkeel + alef-wasla normalisation (display names only)."""
    return strip_tashkeel(s).translate(str.maketrans({"ٱ": "ا", "ٰ": "ا"}))


def norm_letters(s: str) -> str:
    """Letters only; both sources normalised the same way (matching only).

    Handles the alternate spellings the two datasets use for the same
    wording (آ vs ء+ا, hamza bases, wasla alef, small waw/yeh, superscript
    alef) so a verbatim passage can be located in the Tanzil text.
    """
    s = unicodedata.normalize("NFD", s)
    # dagger alef is dropped (the datasets spell those words without it),
    # wasla alef normalises to a plain alef, small waw/yeh disappear.
    s = s.translate(str.maketrans({"ٱ": "ا", "ٰ": "", "ۥ": "", "ۦ": ""}))
    out = []
    for ch in s:
        if unicodedata.category(ch).startswith("M"):
            continue
        if ch == "ـ":  # tatweel (kashida) is decoration, not content
            continue
        if ch in "آأإ":
            ch = "ا"
        elif ch == "ة":
            ch = "ه"
        elif ch == "ى":
            ch = "ي"
        if ch.isalpha():
            out.append(ch)
    # Tanzil writes آ as ء + ا while the datasets use the precomposed آ;
    # collapsing in that order keeps a single alef on both sides.
    return "".join(out).replace("ءا", "ا").replace("ء", "ا")


def load(path: Path):
    with path.open(encoding="utf-8") as f:
        return json.load(f)


def dump(path: Path, obj) -> None:
    with path.open("w", encoding="utf-8") as f:
        json.dump(obj, f, ensure_ascii=False, indent=2)
        f.write("\n")


# ---------------------------------------------------------------------------
# grading — derived from the wording of the source string, never invented
# ---------------------------------------------------------------------------


def grading(text: str) -> str | None:
    s = strip_tashkeel(text)
    if "حسن صحيح" in s:
        return "صحيح"
    if "حسن" in s:
        return "حسن"
    if "صحح" in s or "صحيح" in s:
        return "صحيح"
    if re.search(r"بخاري", s) or re.search(r"مسلم(?![ةين])", s):
        return "صحيح"
    return None


# ---------------------------------------------------------------------------
# quran locator — finds the surah/ayah of a quoted passage
# ---------------------------------------------------------------------------

_quran_cache: list | None = None


_MATCH_MODES = (
    ("exact", lambda s: s),
    ("noalef", lambda s: s.replace("ا", "")),
    ("skel", lambda s: s.replace("ا", "").replace("و", "")),
    # hamza carriers and long-vowel letters can be alef in one dataset and
    # waw/ya in the other (مولانا vs مَوْلَىٰنَا) — last-resort skeleton.
    ("min", lambda s: s.replace("ا", "").replace("و", "").replace("ي", "")),
)


def quran_surahs() -> list:
    global _quran_cache
    if _quran_cache is None:
        raw = load(QURAN)["data"]["surahs"]
        surahs = []
        for s in raw:
            ayahs = [
                {
                    "n": a["numberInSurah"],
                    "letters": norm_letters(a["text"]),
                }
                for a in s["ayahs"]
            ]
            forms = {}
            for mode, fn in _MATCH_MODES:
                full, starts, lens, off = [], [], [], 0
                for a in ayahs:
                    letters = fn(a["letters"])
                    starts.append(off)
                    lens.append(len(letters))
                    off += len(letters)
                    full.append(letters)
                forms[mode] = ("".join(full), starts, lens)
            surahs.append(
                {
                    "number": s["number"],
                    "name": clean_display(s["name"]),
                    "ayahs": ayahs,
                    "forms": forms,
                }
            )
        _quran_cache = surahs
    return _quran_cache


PIETISM = norm_letters("أعوذ بالله من الشيطان الرجيم")


def find_ayah_range(content: str) -> tuple[str, int, int] | None:
    """Return (surah name, first ayah, last ayah) when `content` is Quran text.

    Match passes, in order: exact letters → alefs removed → alefs and waws
    removed. The datasets spell long alefs, hamza seats and tatweel
    differently from the Tanzil text; a pass is accepted only when it hits
    exactly one place in the whole Quran.
    """
    # Trailing "[سورة X n - m]" reference footers are not part of the passage.
    content = re.sub(r"\s*\[[^\]]*\]\s*$", "", content)
    c0 = norm_letters(content).replace(PIETISM, "")
    if len(c0) < 25:
        return None
    for idx, (mode, fn) in enumerate(_MATCH_MODES):
        c = fn(c0)
        floor = {"exact": 1, "noalef": 1, "skel": 25, "min": 40}[mode]
        if len(c) < floor:
            continue
        hits = []
        for surah in quran_surahs():
            full, _starts, _lens = surah["forms"][mode]
            pos = full.find(c)
            while pos != -1:
                hits.append((surah, pos, pos + len(c)))
                pos = full.find(c, pos + 1)
        if len(hits) == 1:
            surah, start, end = hits[0]
            _full, starts, lens = surah["forms"][mode]
            first = last = None
            for i, a in enumerate(surah["ayahs"]):
                if starts[i] < end and starts[i] + lens[i] > start:
                    first = a["n"] if first is None else first
                    last = a["n"]
            if first is not None:
                return (surah["name"], first, last)
        elif hits and idx == len(_MATCH_MODES) - 1:
            where = [(h[0]["name"], h[1]) for h in hits]
            raise SystemExit(
                f"ambiguous quran match for {content[:40]!r}: {where}"
            )
    return None


def quran_reference(name: str, first: int, last: int) -> str:
    ayah = f"آية {first}" if first == last else f"آية {first}-{last}"
    return f"{name}، {ayah}"


# ---------------------------------------------------------------------------
# adhkar (morning / evening) from the Seen-Arabic dataset
# ---------------------------------------------------------------------------

MORNING_TYPES = (0, 1)
EVENING_TYPES = (0, 2)

TITLES = {
    1: "الحمد لله وحده",
    2: "آية الكرسي",
    3: "آخر آيتين من سورة البقرة",
    4: "سورة الإخلاص",
    5: "سورة الفلق",
    6: "سورة الناس",
    7: "أصبحنا وأصبح الملك",
    8: "أمسينا وأمسى الملك",
    9: "اللهم بك أصبحنا",
    10: "اللهم بك أمسينا",
    11: "سيد الاستغفار",
    12: "اللهم إني أصبحت أشهدك",
    13: "اللهم إني أمسيت أشهدك",
    14: "اللهم ما أصبح بي من نعمة",
    15: "اللهم ما أمسى بي من نعمة",
    16: "اللهم عافني",
    17: "حسبي الله",
    18: "العفو والعافية",
    19: "اللهم عالم الغيب",
    20: "بسم الله الذي لا يضر",
    21: "رضيت بالله رباً",
    22: "يا حي يا قيوم",
    23: "خير هذا اليوم",
    24: "خير هذه الليلة",
    25: "أصبحنا على فطرة الإسلام",
    26: "أمسينا على فطرة الإسلام",
    27: "العلم النافع والرزق الطيب",
    28: "الباقيات الصالحات",
    29: "الصلاة على النبي",
    30: "أعوذ بكلمات الله التامات",
    31: "التسبيح بعدد خلقه",
    32: "التوحيد عشر مرات",
    33: "الاستغفار",
    34: "سبحان الله وبحمده",
}

# Entries marked مختارة — the curated "مختارات" strip on the home screen.
CURATED_MORNING = {2, 4, 5, 6, 11, 17, 20}

REPORT: list[str] = []
SKIPPED: list[str] = []


def build_adhkar(category: str) -> None:
    types = MORNING_TYPES if category == "morning" else EVENING_TYPES
    items = [x for x in load(SEEN) if x["type"] in types]
    entries = []
    for item in items:
        order = item["order"]
        content = item["content"]
        source = item["source"]
        q = find_ayah_range(content)
        if q:
            src_obj: dict = {
                "reference": quran_reference(q[0], q[1], q[2]),
                "kind": "quran",
            }
        else:
            g = grading(source)
            if g is None:
                SKIPPED.append(f"adhkar-{category}-{order:02d}: no grading in source")
                continue
            src_obj = {"reference": source, "kind": "hadith", "authenticity": g}
        tags = ["صباح"] if category == "morning" else ["مساء"]
        if category == "morning" and order in CURATED_MORNING:
            tags.append("مختارة")
        entries.append(
            {
                "id": f"dhikr-{category}-{order:02d}",
                "categoryId": f"adhkar-{category}",
                "title": TITLES[order],
                "text": content,
                "source": src_obj,
                "repeatCount": item["count"],
                "tags": tags,
                "sortOrder": len(entries) + 1,
                "verified": True,
                "placeholder": False,
            }
        )

    path = DATA / "adhkar.json"
    doc = load(path)
    kept = [e for e in doc["entries"] if e["categoryId"] != f"adhkar-{category}"]
    doc["entries"] = kept + entries
    dump(path, doc)
    REPORT.append(f"adhkar-{category}: {len(entries)} entries")


# ---------------------------------------------------------------------------
# Quranic duas
# ---------------------------------------------------------------------------

# (surah, first ayah, last ayah) — chosen supplication passages; text itself
# is pulled verbatim from the Tanzil Uthmani dataset by number.
QURAN_DUAS = [
    (1, 5, 5),
    (2, 128, 128),
    (2, 201, 201),
    (2, 250, 250),
    (2, 286, 286),
    (3, 8, 8),
    (3, 147, 147),
    (3, 191, 191),
    (7, 23, 23),
    (7, 89, 89),
    (10, 85, 86),
    (14, 40, 41),
    (17, 80, 80),
    (18, 10, 10),
    (20, 25, 25),
    (21, 83, 83),
    (21, 87, 87),
    (23, 97, 98),
    (25, 74, 74),
    (27, 19, 19),
    (28, 24, 24),
    (40, 7, 8),
    (46, 15, 15),
    (59, 10, 10),
    (66, 8, 8),
    (67, 29, 29),
]


def build_quran_duas() -> None:
    surah_lookup = {s["number"]: s for s in quran_surahs()}
    raw = load(QURAN)["data"]["surahs"]
    entries = []
    for surah, first, last in QURAN_DUAS:
        name = surah_lookup[surah]["name"]
        texts = [
            a["text"]
            for a in raw[surah - 1]["ayahs"]
            if first <= a["numberInSurah"] <= last
        ]
        if len(texts) != last - first + 1:
            raise SystemExit(f"missing ayat {surah}:{first}-{last}")
        entries.append(
            {
                "id": f"dua-q{surah}-{first}",
                "categoryId": "duas-quran",
                "title": quran_reference(name, first, last),
                "text": " ".join(texts),
                "source": {
                    "reference": quran_reference(name, first, last),
                    "kind": "quran",
                },
                "tags": ["قرآن"],
                "sortOrder": len(entries) + 1,
                "verified": True,
                "placeholder": False,
            }
        )
        REPORT.append(
            f"  dua {surah}:{first}-{last} | {entries[-1]['text'][:50]}"
        )

    path = DATA / "duas.json"
    doc = load(path)
    kept = [e for e in doc["entries"] if e["categoryId"] != "duas-quran"]
    doc["entries"] = entries + kept
    dump(path, doc)
    REPORT.append(f"duas-quran: {len(entries)} entries")


# ---------------------------------------------------------------------------
# general duas from Hisn al-Muslim (footnote = source, graded verbatim)
# ---------------------------------------------------------------------------


def build_general() -> None:
    # "فضل ..." chapters are virtue notes (skipped by decision) and the
    # morning/evening adhkar chapter overlaps the adhkar category.
    skip_names = {"أذكار الصباح والمساء"}
    hisn = load(HISN)
    entries = []
    for name, chapter in hisn.items():
        if name.startswith("فضل") or name in skip_names:
            continue
        texts = chapter.get("text", [])
        footnotes = chapter.get("footnote", [])
        if len(texts) != len(footnotes):
            SKIPPED.append(f"hisn {name}: {len(texts)} texts vs {len(footnotes)} footnotes")
            continue
        for i, (text, footnote) in enumerate(zip(texts, footnotes)):
            g = grading(footnote)
            if g is None:
                SKIPPED.append(f"hisn {name}: no grading in footnote {footnote[:60]!r}")
                continue
            n = len(entries) + 1
            title = name if len(texts) == 1 else f"{name} ({i + 1})"
            entries.append(
                {
                    "id": f"dua-hisn-{n:03d}",
                    "categoryId": "duas-general",
                    "title": title,
                    "text": text,
                    "source": {
                        "reference": footnote,
                        "kind": "hadith",
                        "authenticity": g,
                    },
                    "tags": ["أدعية"],
                    "sortOrder": n,
                    "verified": True,
                    "placeholder": False,
                }
            )
    path = DATA / "duas.json"
    doc = load(path)
    kept = [e for e in doc["entries"] if e["categoryId"] != "duas-general"]
    doc["entries"] = entries + kept
    dump(path, doc)
    REPORT.append(f"duas-general: {len(entries)} entries")


# ---------------------------------------------------------------------------
# Forty Nawawi hadiths
# ---------------------------------------------------------------------------


def parse_coll_numbers(text: str) -> str:
    s = strip_tashkeel(text)
    parts = []
    for name, pattern in (
        ("صحيح البخاري", r"بخاري[^.\]]{0,80}?\[رقم:(\d+)\]"),
        ("صحيح مسلم", r"مسلم[^.\]]{0,80}?\[رقم:(\d+)\]"),
    ):
        m = re.search(pattern, s)
        if m:
            parts.append(f"{name} {m.group(1)}")
    return "، ".join(parts)


def build_hadiths() -> None:
    items = load(NAWAWI)
    entries = []
    for it in items:
        n = it["id"]
        text = it["arabic"]
        g = grading(text)
        if g is None:
            SKIPPED.append(f"hadith-nawawi-{n}: no grading in text")
            continue
        ref = f"الأربعون النووية {n}"
        extra = parse_coll_numbers(text)
        if extra:
            ref = f"{ref}، {extra}"
        entries.append(
            {
                "id": f"hadith-nawawi-{n}",
                "categoryId": "hadiths",
                "title": f"الحديث {n} من الأربعون النووية",
                "text": text,
                "source": {"reference": ref, "kind": "hadith", "authenticity": g},
                "tags": ["حديث"],
                "sortOrder": n,
                "verified": True,
                "placeholder": False,
            }
        )
    path = DATA / "hadiths.json"
    dump(path, {"schemaVersion": 1, "entries": entries})
    REPORT.append(f"hadiths: {len(entries)} entries")


def build_manifest() -> None:
    path = DATA / "manifest.json"
    doc = load(path)
    doc["contentVersion"] = 2
    doc["updatedAt"] = "2026-10-14"
    dump(path, doc)
    REPORT.append("manifest: contentVersion=2 updatedAt=2026-10-14")


# ---------------------------------------------------------------------------
# validate / diff
# ---------------------------------------------------------------------------

CONTENT_FILES = ["adhkar.json", "duas.json", "hadiths.json"]


def all_entries():
    for name in CONTENT_FILES:
        doc = load(DATA / name)
        if doc.get("schemaVersion") != 1:
            raise SystemExit(f"{name}: schemaVersion must be 1")
        for e in doc["entries"]:
            yield name, e


def validate(strict: bool) -> int:
    errors: list[str] = []
    warnings: list[str] = []
    categories = {c["id"] for c in load(DATA / "categories.json")["categories"]}
    counts: dict[str, int] = {}
    seen_ids: set[str] = set()
    placeholders = 0

    for name, e in all_entries():
        ctx = f"{name}:{e.get('id', '?')}"
        for key in ("id", "categoryId", "title", "text"):
            v = e.get(key)
            if not isinstance(v, str) or not v.strip():
                errors.append(f"{ctx}: missing/empty {key}")
        if e["id"] in seen_ids:
            errors.append(f"{ctx}: duplicate id")
        seen_ids.add(e["id"])
        if e["categoryId"] not in categories:
            errors.append(f"{ctx}: unknown categoryId {e['categoryId']}")
        counts[e["categoryId"]] = counts.get(e["categoryId"], 0) + 1
        if e.get("verified") is not True:
            errors.append(f"{ctx}: verified must be true")
        if e.get("placeholder") is True:
            placeholders += 1
            if strict:
                errors.append(f"{ctx}: placeholder entry still present")
        rc = e.get("repeatCount")
        if rc is not None and (not isinstance(rc, int) or rc <= 0):
            errors.append(f"{ctx}: repeatCount must be a positive int")
        so = e.get("sortOrder")
        if not isinstance(so, int) or so < 0:
            errors.append(f"{ctx}: sortOrder must be a non-negative int")
        src = e.get("source")
        if src is None:
            errors.append(f"{ctx}: source is required")
        else:
            ref = src.get("reference")
            if not isinstance(ref, str) or not ref.strip():
                errors.append(f"{ctx}: source.reference missing")
            kind = src.get("kind")
            auth = src.get("authenticity")
            if kind == "quran" and auth is not None:
                errors.append(f"{ctx}: quran entries must not carry authenticity")
            if kind == "hadith":
                if auth not in ("صحيح", "حسن"):
                    msg = f"{ctx}: hadith authenticity must be صحيح/حسن (got {auth!r})"
                    (errors if strict else warnings).append(msg)
            if kind not in ("quran", "hadith", None):
                errors.append(f"{ctx}: unknown source.kind {kind!r}")
        tags = e.get("tags", [])
        if not isinstance(tags, list) or any(
            not isinstance(t, str) or not t.strip() for t in tags
        ):
            errors.append(f"{ctx}: tags must be non-empty strings")

    manifest = load(DATA / "manifest.json")
    if sorted(manifest["files"]) != sorted(["categories.json"] + CONTENT_FILES):
        errors.append("manifest.files mismatch")
    for cat in load(DATA / "categories.json")["categories"]:
        if counts.get(cat["id"], 0) == 0:
            msg = f"category {cat['id']} has no entries"
            (errors if strict else warnings).append(msg)

    print("counts:", json.dumps(counts, ensure_ascii=False))
    for w in warnings:
        print("WARN ", w)
    for err in errors:
        print("ERROR", err)
    print(f"{len(errors)} error(s), {len(warnings)} warning(s)")
    return 1 if errors else 0


def source_texts() -> set[str]:
    texts: set[str] = set()
    for x in load(SEEN):
        texts.add(x["content"])
    hisn = load(HISN)
    for chapter in hisn.values():
        for t in chapter.get("text", []):
            texts.add(t)
    for it in load(NAWAWI):
        texts.add(it["arabic"])
    for s in load(QURAN)["data"]["surahs"]:
        for a in s["ayahs"]:
            texts.add(a["text"])
    return texts


def _verbatim_quran(entry: dict) -> bool:
    """Multi-ayah Quran entries are joined with spaces, so their text is not
    a single raw ayah string — rebuild it from the Tanzil source instead."""
    src = entry.get("source") or {}
    if src.get("kind") != "quran":
        return False
    m = re.match(r"^(.*)، آية (\d+)(?:-(\d+))?$", src["reference"])
    if not m:
        return False
    num = next(
        (s["number"] for s in quran_surahs() if s["name"] == m.group(1)),
        None,
    )
    if num is None:
        return False
    first = int(m.group(2))
    last = int(m.group(3) or m.group(2))
    ayats = [
        a["text"]
        for a in load(QURAN)["data"]["surahs"][num - 1]["ayahs"]
        if first <= a["numberInSurah"] <= last
    ]
    return entry["text"] == " ".join(ayats)


def review() -> int:
    """Emit a printable RTL HTML package of every bundled entry for human
    review (diacritics, attribution, verification flags). No network, no
    extra dependencies — open the file in any browser and print to PDF."""
    import html as html_mod

    esc = html_mod.escape
    categories = {c["id"]: c["title"] for c in load(DATA / "categories.json")["categories"]}
    manifest = load(DATA / "manifest.json")
    by_cat: dict[str, list[tuple[str, dict]]] = {}
    for name, e in all_entries():
        by_cat.setdefault(e["categoryId"], []).append((name, e))

    parts = [
        "<!DOCTYPE html>",
        '<html lang="ar" dir="rtl">',
        "<head>",
        '<meta charset="utf-8">',
        "<title>مراجعة محتوى رفيق المسلم</title>",
        "<style>",
        "body{font-family:sans-serif;margin:2rem;line-height:1.9}",
        "h1{font-size:1.6rem} h2{font-size:1.3rem;border-bottom:1px solid #ccc}",
        ".entry{break-inside:avoid;margin:1.2rem 0;padding:0.8rem;border:1px solid #ddd}",
        ".title{font-weight:700;font-size:1.1rem}",
        ".meta{color:#555;font-size:0.85rem}",
        ".text{margin:0.5rem 0;white-space:pre-wrap}",
        ".flag{display:inline-block;padding:0 0.4rem;border-radius:4px;"
        "background:#eef;font-size:0.8rem;margin-inline-start:0.4rem}",
        ".warn{background:#fee}",
        "@media print{h2{break-before:page}h2:first-of-type{break-before:auto}}",
        "</style>",
        "</head>",
        "<body>",
        "<h1>مراجعة محتوى رفيق المسلم</h1>",
        f"<p>إصدار المحتوى: {manifest.get('contentVersion')} — "
        f"آخر تحديث: {manifest.get('updatedAt')}</p>",
        "<p>كل نص أدناه منقول حرفياً من ملفات المصدر؛ راجع التشكيل "
        "والمراجع وحالة التوثيق قبل النشر.</p>",
    ]
    total = verified = placeholders = with_source = 0
    for cat_id, title in categories.items():
        entries = by_cat.get(cat_id, [])
        parts.append(f"<h2>{esc(title)} ({len(entries)})</h2>")
        for name, e in sorted(entries, key=lambda x: x[1].get("sortOrder", 0)):
            total += 1
            if e.get("verified"):
                verified += 1
            if e.get("placeholder"):
                placeholders += 1
            src = e.get("source")
            if src:
                with_source += 1
            flags = "".join(
                [
                    f'<span class="flag{" warn" if not e.get("verified") else ""}">'
                    f'{"موثّق" if e.get("verified") else "غير موثّق"}</span>',
                    '<span class="flag">تجريبي</span>' if e.get("placeholder") else "",
                ]
            )
            parts += [
                '<div class="entry">',
                f'<div class="title">{esc(e["title"])} {flags}</div>',
                f'<div class="meta">{esc(name)} · {esc(e["id"])} · '
                f'تكرار={e.get("repeatCount", "—")}</div>',
                f'<div class="text">{esc(e["text"])}</div>',
            ]
            if src:
                parts.append(
                    f'<div class="meta">المصدر: {esc(src["reference"])}'
                    f' ({esc(src.get("kind", ""))})</div>'
                )
            if e.get("tags"):
                parts.append(f'<div class="meta">وسوم: {esc(", ".join(e["tags"]))}</div>')
            parts.append("</div>")
    parts += [
        f"<h2>الإجمالي</h2><p>{total} مدخلة — {verified} موثّقة، "
        f"{with_source} بمصدر، {placeholders} تجريبية.</p>",
        "</body></html>",
    ]
    out = ROOT / "build" / "content_review.html"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text("\n".join(parts), encoding="utf-8")
    print(f"review: wrote {out} ({total} entries)")
    return 0


def diff() -> int:
    texts = source_texts()
    seen_sources = {x["source"] for x in load(SEEN)}
    errors = []
    for name, e in all_entries():
        ctx = f"{name}:{e['id']}"
        if e["text"] not in texts and not _verbatim_quran(e):
            errors.append(f"{ctx}: text not verbatim in any source file")
        src = e.get("source")
        if src is None:
            continue
        if src["kind"] == "hadith" and src["reference"] not in seen_sources:
            if name == "adhkar.json":
                errors.append(f"{ctx}: hadith reference not verbatim in adhkar source")
    for err in errors:
        print("ERROR", err)
    print(f"diff: {len(errors)} mismatch(es) over all entries")
    return 1 if errors else 0


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    cmd = sys.argv[1]
    if cmd == "build":
        stage = sys.argv[2] if len(sys.argv) > 2 else ""
        if stage == "morning":
            build_adhkar("morning")
        elif stage == "evening":
            build_adhkar("evening")
        elif stage == "quran":
            build_quran_duas()
        elif stage == "general":
            build_general()
        elif stage == "hadith":
            build_hadiths()
        elif stage == "manifest":
            build_manifest()
        else:
            print(f"unknown stage {stage!r}")
            return 2
        for line in REPORT:
            print(line)
        for line in SKIPPED:
            print("SKIP ", line)
        return 0
    if cmd == "validate":
        return validate(strict="--strict" in sys.argv)
    if cmd == "diff":
        return diff()
    if cmd == "review":
        return review()
    print(__doc__)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
