#!/usr/bin/env python3
"""Checks that every prayer's text is a verbatim excerpt of its source.

Each prayer's text is a table of its own in the translations (i18n/<lang>.json, a table named "text<Name>"
holding one text), and its note ("//") names its source. SOURCES below lists, for each text, the page it is
copied from and the pages that print the same words, the running headers a PDF prints inside the text, and
the corrections made to the source's typos. The pages themselves are not in the repository: download each
URL into one folder, under the name url_to_filename(url) gives it (--name prints it).

A page is reduced to its visible text (HTML tags, scripts and styles removed, entities decoded; PDFs through
pdftotext, which must be on the PATH, with the words a line end hyphenates rejoined; ePubs chapter by
chapter), its running headers removed and its corrections applied. The page and the text are then compared
after NFC normalization with all whitespace, all digits and stanza numbers ("2. ") removed, so line breaks
and verse and stanza numbers are ignored while every letter and punctuation mark must match exactly. A correction
counts only when the page prints its wrong words exactly once and the text holds the right ones.

The check also fails when a text table has no entry in SOURCES or the reverse, or when a table's note does
not name its source's URL.

Usage:
  python3 -I scripts/check-texts.py <sources-dir> [i18n/spa.json]
  python3 -I scripts/check-texts.py --name <url>      prints the file name the page is downloaded under

Prints VERBATIM or FAIL per text and page, and exits 1 when any check fails.
"""
import html
import json
import re
import shutil
import subprocess
import sys
import unicodedata
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_TEXTS = ROOT / "i18n" / "spa.json"
COMPENDIUM = "https://www.vatican.va/archive/compendium_ccc/documents/archive_2005_compendium-ccc_sp.html"
COMPENDIUM_EN = "https://www.vatican.va/archive/compendium_ccc/documents/archive_2005_compendium-ccc_en.html"
INVISIBLE = {"​", "‌", "‍", "⁠", "﻿", "­"}

# For each text: "source", the page it is copied from (named in its table's note); "also", other pages that
# print the same words; "furniture", running headers a PDF prints inside the text; "corrections", the
# source's typos as (wrong words as printed, right words, why), applied to the page before comparing.
SOURCES = {
    "TextOurFatherSpa": {
        "source": COMPENDIUM,
        "also": ["https://www.vaticannews.va/es/oraciones/padre-nuestro.html"],
    },
    "TextOurFatherLat": {"source": COMPENDIUM},
    "TextOurFatherEng": {"source": "https://www.usccb.org/prayers/our-father"},
    "TextHailMarySpa": {
        "source": COMPENDIUM,
        "also": ["https://www.vaticannews.va/es/oraciones/ave-maria.html"],
    },
    "TextHailMaryLat": {"source": COMPENDIUM_EN, "also": [COMPENDIUM]},
    "TextHailMaryEng": {"source": COMPENDIUM_EN},
    "TextComeHolySpirit": {
        "source": "https://www.architoledo.org/wp-content/uploads/2026/05/Cadena-de-oracion.pdf",
    },
    "TextSequence": {
        "source": COMPENDIUM,
        "also": ["https://www.vaticannews.va/es/oraciones/ven-santo-espiritu.html",
                 "https://www.conferenciaepiscopal.es/liturgia/cpentecostes.pdf"],
        "furniture": ["LECCIONARIO I (C)", "DOMINGO DE PENTECOSTÉS – MISA DEL DÍA [63]"],
    },
    "TextPsalm16": {"source": "https://www.vatican.va/archive/ESL0506/__PGL.HTM"},
    "TextPsalm23": {"source": "https://www.vatican.va/archive/ESL0506/__PGS.HTM"},
    "TextPsalm27": {"source": "https://www.vatican.va/archive/ESL0506/__PGW.HTM"},
    "TextPsalm51": {"source": "https://www.vatican.va/archive/ESL0506/__PHK.HTM"},
    "TextPsalm84": {"source": "https://www.vatican.va/archive/ESL0506/__PIH.HTM"},
    "TextPsalm136": {"source": "https://www.vatican.va/archive/ESL0506/__PJX.HTM"},
    "TextBeatitudes": {"source": "https://www.vatican.va/archive/ESL0506/__PUF.HTM"},
    "TextHymnOfLove": {
        "source": "https://www.vatican.va/archive/ESL0506/__PYC.HTM",
        "corrections": [
            ("no tienen en cuenta el mal recibido", "no tiene en cuenta el mal recibido",
             "1 Cor 13, 5: love \"no tiene\" (does not keep), singular as its subject, not the plural \"tienen\""),
            ("la más grande todas es el amor", "la más grande de todas es el amor",
             "1 Cor 13, 13: the missing \"de\" of \"la más grande de todas\""),
        ],
    },
    "TextJohnPrologue": {"source": "https://www.vatican.va/archive/ESL0506/__PW7.HTM"},
    "TextMagnificat": {
        "source": "https://www.vatican.va/archive/ESL0506/__PVJ.HTM",
        "corrections": [
            ("porque el miró", "porque él miró",
             "Lc 1, 48: the pronoun \"él\" (he looked), not the article \"el\""),
            ("el Todopoderoso he hecho", "el Todopoderoso ha hecho",
             "Lc 1, 49: \"ha hecho\" (has done), not the first person \"he hecho\""),
        ],
    },
    "TextAngelus": {"source": COMPENDIUM},
    "TextBlessedPurity": {
        "source": "https://lapresentacion.es/wp-content/uploads/2020/11/Solemnidad-de-la-Virgen-de-la-Almudena.pdf",
    },
    "TextConsecration": {
        "source": "https://www.gran-poder.es/wp-content/uploads/2019/01/devocionario-Gran-Poder-web.pdf",
    },
    "TextSpiritualCommunion": {"source": "https://www.vaticannews.va/es/oraciones/comunion-espiritual.html"},
    "TextAdoroTe": {"source": "https://www.aciprensa.com/recurso/1505/himno-adoro-te-devote"},
    "TextDailyOffering": {"source": "https://www.popesprayer.va/es/reza/"},
    "TextContrition": {"source": COMPENDIUM},
    "TextNightPrayer": {"source": "https://www.almudi.org/Portals/0/docs/LH/V_COMPLETAS.epub"},
    "TextAnimaChristi": {
        "source": COMPENDIUM,
        "also": ["https://www.vaticannews.va/es/oraciones/alma-de-cristo.html"],
    },
    "TextSaintFrancis": {"source": "https://www.aciprensa.com/recurso/1707/oracion-por-la-paz"},
    "TextNadaTeTurbe": {
        "source": "https://www.vatican.va/content/francesco/es/messages/pont-messages/2021/documents/"
                  "papa-francesco_20210415_videomessaggio-mujer-excepcional.html",
    },
    "TextAbandonment": {"source": "https://www.aciprensa.com/Oracion/entrega.htm"},
    "TextSaintMichael": {"source": "https://www.vaticannews.va/es/oraciones/san-miguel-arcangel.html"},
}


def url_to_filename(url):
    rest = re.sub(r"^[a-zA-Z]+://", "", url).rstrip("/")
    return re.sub(r"[^A-Za-z0-9.-]+", "_", rest)


def decode(raw):
    match = re.search(rb'charset=["\']?([A-Za-z0-9_-]+)', raw[:4000])
    encoding = match.group(1).decode().lower() if match else "utf-8"
    if encoding in ("iso-8859-1", "latin-1", "latin1", "us-ascii", "ascii"):
        encoding = "cp1252"  # browsers decode these labels as windows-1252
    for candidate in (encoding, "utf-8", "latin-1"):
        try:
            return raw.decode(candidate)
        except (LookupError, UnicodeDecodeError):
            continue
    return raw.decode("latin-1", "replace")


def html_text(document):
    document = re.sub(r"(?is)<(script|style|noscript|template)\b[^>]*>.*?</\1\s*>", " ", document)
    document = re.sub(r"(?s)<!--.*?-->", " ", document)
    document = re.sub(r"<[^>]*>", " ", document)
    return html.unescape(document)


def pdf_text(path):
    tool = shutil.which("pdftotext")
    if tool is None:
        raise RuntimeError("pdftotext not found on PATH")
    out = subprocess.run([tool, "-enc", "UTF-8", str(path), "-"], check=True, capture_output=True)
    # Rejoins the words the PDF hyphenates at a line end ("afec-\nto").
    return re.sub(r"(\w)-\n(\w)", r"\1\2", out.stdout.decode("utf-8"))


def epub_text(path):
    """The visible text of every XHTML chapter of an ePub, in archive order."""
    with zipfile.ZipFile(path) as book:
        names = [name for name in book.namelist() if name.lower().endswith((".xhtml", ".html", ".htm"))]
        return " ".join(html_text(book.read(name).decode("utf-8", "replace")) for name in names)


def page_text(path):
    raw = path.read_bytes()
    if raw[:5] == b"%PDF-":
        return pdf_text(path)
    if raw[:2] == b"PK" and b"application/epub+zip" in raw[:100]:
        return epub_text(path)
    return html_text(decode(raw))


def normalize(text):
    text = unicodedata.normalize("NFC", text)
    text = re.sub(r"(?<!\w)\d+\.(?=\s)", "", text)  # stanza numbers such as "2. "
    return "".join(ch for ch in text if not ch.isspace() and not ch.isdigit() and ch not in INVISIBLE)


def first_divergence(needle, hay):
    """Length of the longest prefix of needle found in hay."""
    low, high = 0, len(needle)
    while low < high:
        middle = (low + high + 1) // 2
        if needle[:middle] in hay:
            low = middle
        else:
            high = middle - 1
    return low


def check(sources_dir, url, text, entry, cache):
    """(ok, why) for the text against one page, with the entry's furniture and corrections."""
    path = sources_dir / url_to_filename(url)
    if not path.is_file():
        return False, f"missing download {path}"
    if path not in cache:
        cache[path] = normalize(page_text(path))
    hay = cache[path]
    for item in entry.get("furniture", ()):
        hay = hay.replace(normalize(item), "")
    needle = normalize(text)
    if not needle:
        return False, "empty text"
    for wrong, right, _ in entry.get("corrections", ()):
        found = hay.count(normalize(wrong))
        if found != 1:
            return False, f"correction \"{wrong}\" -> \"{right}\": the page prints \"{wrong}\" {found} times, not once"
        if normalize(right) not in needle:
            return False, f"correction \"{wrong}\" -> \"{right}\": the text does not read \"{right}\""
        hay = hay.replace(normalize(wrong), normalize(right))
    if needle in hay:
        return True, ""
    n = first_divergence(needle, hay)
    return False, f"matches up to char {n} of {len(needle)}; diverges at: ...{needle[max(0, n - 30):n]}[{needle[n:n + 30]}]..."


def read_texts(path):
    """{text id: (text, note)} of every "text..." table of the translations."""
    document = json.loads(path.read_text(encoding="utf-8"))
    texts = {}
    for name, table in document.items():
        if not name.startswith("text"):
            continue
        entries = [(key, value) for key, value in table.items() if not key.startswith("//")]
        if len(entries) != 1:
            sys.exit(f"{path.name}: table {name} holds {len(entries)} texts; a prayer's table holds one")
        key, text = entries[0]
        texts[key] = (text, table.get("//", ""))
    return texts


def main(argv):
    if len(argv) == 3 and argv[1] == "--name":
        print(url_to_filename(argv[2]))
        return 0
    if len(argv) not in (2, 3) or argv[1].startswith("-"):
        print(__doc__.strip(), file=sys.stderr)
        return 2
    sources_dir = Path(argv[1])
    texts = read_texts(Path(argv[2]) if len(argv) == 3 else DEFAULT_TEXTS)
    failed = 0
    for key in sorted(set(SOURCES) - set(texts)):
        print(f"FAIL      {key:20} listed in SOURCES but no table holds it")
        failed += 1
    cache = {}
    for key, (text, note) in texts.items():
        entry = SOURCES.get(key)
        if entry is None:
            print(f"FAIL      {key:20} has no entry in SOURCES")
            failed += 1
            continue
        if entry["source"] not in note:
            print(f"FAIL      {key:20} its note does not name its source {entry['source']}")
            failed += 1
        corrected = [f"\"{wrong}\" -> \"{right}\"" for wrong, right, _ in entry.get("corrections", ())]
        for i, url in enumerate([entry["source"]] + list(entry.get("also", []))):
            ok, why = check(sources_dir, url, text, entry, cache)
            label = key if i == 0 else key + " (also)"
            fixes = f" (corrected: {'; '.join(corrected)})" if ok and corrected else ""
            print(f"{'VERBATIM' if ok else 'FAIL':9} {label:27} {url}{fixes}" + ("" if ok else "\n          " + why))
            failed += 0 if ok else 1
    print(f"{failed} check(s) failed" if failed else f"ALL VERBATIM: {len(texts)} texts")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
