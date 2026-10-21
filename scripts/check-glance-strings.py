#!/usr/bin/env python3
"""Checks that the glance uses only the texts and the code it can load.

The glance loads only the code annotated (:glance) and only the resources marked scope="glance". Loading any
other resource from the glance crashes it on the watch ("Symbol Not Found Error"), and neither the compiler
(even with -w) nor the unit tests, which run as the full app, notice. Every text is in a JSON table per
language (i18n/<lang>.json, generated into resources/i18n by scripts/gen-i18n.py), and only the "glance"
table is glance-scoped. So this check reads the code annotated (:glance) and fails when:

- it loads a JSON table (Rez.JsonData.<id>) or a string (Rez.Strings.<id>) that is not marked
  scope="glance";
- it looks up a text (I18n.<id>) of a table other than the glance table;
- it calls a function or creates a class that only code outside the glance defines, such as I18n.text or
  the group and prayer titles in source/Prayers.mc, which load tables the glance cannot load;
- a glance-scoped table or string, or a text of the glance table, is never used by the glance: each one
  takes room in the glance's 32KB.

Usage: python3 scripts/check-glance-strings.py   (exits 0 when the glance is clean, 1 otherwise)
"""
import json
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ANNOTATION = re.compile(r"\(\s*((?::\w+\s*)+)\)")
DECLARATION = re.compile(r"\s*(?:(?:static|private|protected|public|hidden)\s+)*(module|class|function|const|var)\s+(\w+)")
RESOURCE = re.compile(r"\bRez\s*\.\s*(Strings|JsonData)\s*\.\s*(\w+)")
# A word that may be a text's key: I18n.<id>, or <id> alone inside module I18n. The keys' own declarations in
# source/I18nKeys.mc (<id> = <number>) are not uses.
TEXT_KEY = re.compile(r"\b([A-Za-z_]\w*)\b(?!\s*=[^=])")
GLANCE_TABLE = "glance"
# The model language, whose file names every text's table (LANGUAGES[0] in scripts/gen-i18n.py).
MODEL = "spa"
CALL =re.compile(r"\b(\w+)\s*\(")
NOT_CALLS = {"if", "for", "while", "switch", "return", "function", "catch", "new", "and", "or", "instanceof", "has"}
# Methods of the (:glance) app class that the system calls only for the full-screen app, never for the
# glance: the code in them may use anything.
FULL_APP_ONLY = {"getInitialView"}


def code_only(text):
    """The source with comments and string and character literals blanked out (same length and lines)."""
    out = []
    i, n = 0, len(text)
    while i < n:
        c = text[i]
        if text.startswith("//", i):
            end = text.find("\n", i)
            end = n if end < 0 else end
            out.append(" " * (end - i))
            i = end
        elif text.startswith("/*", i):
            end = text.find("*/", i + 2)
            end = n if end < 0 else end + 2
            out.append(re.sub(r"[^\n]", " ", text[i:end]))
            i = end
        elif c in "\"'":
            j = i + 1
            while j < n and text[j] != c and text[j] != "\n":
                j += 2 if text[j] == "\\" else 1
            out.append(c + " " * (min(j, n) - i - 1) + (c if j < n else ""))
            i = j + 1
        else:
            out.append(c)
            i += 1
    return "".join(out)


def block_end(code, start):
    """Index just past the brace block that opens at or after start."""
    depth = 0
    for i in range(code.index("{", start), len(code)):
        if code[i] == "{":
            depth += 1
        elif code[i] == "}":
            depth -= 1
            if depth == 0:
                return i + 1
    return len(code)


def glance_spans(code):
    """[start, end) spans of the code the glance runs: the declarations annotated (:glance), less the
    FULL_APP_ONLY methods inside them."""
    spans = []
    for match in ANNOTATION.finditer(code):
        if ":glance" not in match.group(1).split():
            continue
        declaration = DECLARATION.match(code, match.end())
        if not declaration:
            continue
        if declaration.group(1) in ("const", "var"):
            spans.append((declaration.start(), code.find(";", declaration.end()) + 1))
        else:
            spans.append((declaration.start(), block_end(code, declaration.end())))
    for match in re.finditer(r"\bfunction\s+(\w+)", code):
        if match.group(1) in FULL_APP_ONLY:
            spans = cut(spans, match.start(), block_end(code, match.end()))
    return spans


def cut(spans, start, end):
    """The spans less [start, end)."""
    result = []
    for a, b in spans:
        if end <= a or b <= start:
            result.append((a, b))
            continue
        if a < start:
            result.append((a, start))
        if end < b:
            result.append((end, b))
    return result


def line_of(text, index):
    return text.count("\n", 0, index) + 1


def read_sources():
    """For every source file: (path, code, glance spans)."""
    sources = []
    for path in sorted((ROOT / "source").rglob("*.mc")):
        code = code_only(path.read_text(encoding="utf-8"))
        sources.append((path, code, glance_spans(code)))
    return sources


def read_resources():
    """{"Strings": {id: scope}, "JsonData": {id: scope}} for the resources in resources/."""
    resources = {"Strings": {}, "JsonData": {}}
    for xml in sorted((ROOT / "resources").rglob("*.xml")):
        for element in ET.parse(xml).getroot().iter():
            kind = {"string": "Strings", "jsonData": "JsonData"}.get(element.tag)
            if kind:
                resources[kind][element.get("id")] = element.get("scope", "")
    return resources


def read_text_tables():
    """{text id: table name} from the model translations, i18n/<MODEL>.json (see scripts/gen-i18n.py)."""
    document = json.loads((ROOT / "i18n" / f"{MODEL}.json").read_text(encoding="utf-8"))
    tables = {}
    for name, table in document.items():
        if name.startswith("//"):
            continue
        for key in table:
            if not key.startswith("//"):
                tables[key] = name
    return tables


def main():
    sources = read_sources()
    tables = read_text_tables()
    glance_names, other_names = set(), {}
    used_resources, used_keys, calls = {}, {}, []
    for path, code, spans in sources:
        inside = lambda index: any(start <= index < end for start, end in spans)
        for match in re.finditer(r"\b(function|class)\s+(\w+)", code):
            if inside(match.start()):
                glance_names.add(match.group(2))
            else:
                other_names.setdefault(match.group(2), f"{path.relative_to(ROOT)}:{line_of(code, match.start())}")
        for start, end in spans:
            where = lambda match: f"{path.relative_to(ROOT)}:{line_of(code, match.start())}"
            for match in RESOURCE.finditer(code, start, end):
                used_resources.setdefault((match.group(1), match.group(2)), where(match))
            for match in TEXT_KEY.finditer(code, start, end):
                if match.group(1) in tables:
                    used_keys.setdefault(match.group(1), where(match))
            for match in CALL.finditer(code, start, end):
                if match.group(1) not in NOT_CALLS:
                    calls.append((match.group(1), where(match)))

    problems = []
    for name, where in calls:
        if name in other_names and name not in glance_names:
            problems.append(f"{where}: the glance calls {name}, which only code outside the glance defines "
                            f"({other_names[name]})")

    resources = read_resources()
    for (kind, resource_id), where in sorted(used_resources.items()):
        scope = resources[kind].get(resource_id)
        if scope is None:
            problems.append(f"{where}: the glance loads Rez.{kind}.{resource_id}, which resources/ does not define")
        elif scope != "glance":
            problems.append(f"{where}: the glance loads Rez.{kind}.{resource_id}, which is not marked "
                            f"scope=\"glance\"")
    for kind, scopes in resources.items():
        for resource_id, scope in sorted(scopes.items()):
            if scope == "glance" and (kind, resource_id) not in used_resources:
                problems.append(f"resources/: Rez.{kind}.{resource_id} is marked scope=\"glance\" but the glance "
                                f"never loads it")

    for key, where in sorted(used_keys.items()):
        if key in tables and tables[key] != GLANCE_TABLE:
            problems.append(f"{where}: the glance looks up I18n.{key}, a text of the \"{tables[key]}\" table, "
                            f"which the glance cannot load")
    glance_keys = sorted(key for key, table in tables.items() if table == GLANCE_TABLE)
    for key in glance_keys:
        if key not in used_keys:
            problems.append(f"i18n/{MODEL}.json: {GLANCE_TABLE}.{key} is in the glance table but the glance never "
                            f"looks it up")

    if problems:
        print("Glance texts FAILED:")
        for problem in problems:
            print("  " + problem)
        return 1
    glance_tables = sum(1 for (kind, _) in used_resources if kind == "JsonData")
    print(f"Glance texts OK: the glance looks up {len(glance_keys)} texts, all in the glance table, and loads "
          f"{glance_tables} glance-scoped tables; {len(calls)} calls in glance code, none to code outside the "
          f"glance.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
