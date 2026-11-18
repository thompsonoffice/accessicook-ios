#!/usr/bin/env python3
"""Turn content/Accessicook plain-text recipes into Accessicook/Resources/accessicook-data.json.

The app ships that JSON. It does not invent recipes: every entry is one source file,
and the script checks the book's published counts (13 lessons and 327 recipes).

Usage: python3 tools/export_cookbook.py
"""
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / "content" / "Accessicook"
DEST = ROOT / "Accessicook" / "Resources" / "accessicook-data.json"

SKIP = {"README.txt", "CONTENTS.txt", "INDEX.txt", "Accessicook-all-recipes.txt"}

# Folder name, id, display name, kind, summary. Order is the book order.
CATEGORIES = [
    ("00-Kitchen-Basics", "kitchen-basics", "Kitchen Basics", "lesson",
     "13 short lessons on setting up, measuring by touch, knife safety, the stove, the oven, and more."),
    ("01-Breakfast", "breakfast", "Breakfast", "recipe", "Breakfast recipes."),
    ("02-Lunch", "lunch", "Lunch", "recipe", "Lunch recipes."),
    ("03-Supper", "supper", "Supper", "recipe", "Supper recipes."),
    ("04-Baked-Goods", "baked-goods", "Baked Goods", "recipe", "Baked goods."),
    ("05-Midnight-Snacks", "midnight-snacks", "Midnight Snacks", "recipe", "Midnight snacks."),
    ("06-Misc", "misc", "Misc", "recipe",
     "Sides, sauces, appetizers, drinks, and staples."),
]

EXPECTED_COUNTS = {
    "kitchen-basics": 13,
    "breakfast": 40,
    "lunch": 55,
    "supper": 73,
    "baked-goods": 58,
    "midnight-snacks": 36,
    "misc": 65,
}

# Sentences from content/accessicook-description.txt. Not new claims.
HONEST_NOTES = [
    "This is everyday American home cooking.",
    "Deep frying is left out on purpose for safety.",
    "A few breads start from store-bought dough.",
    "The recipes have not been individually kitchen-tested and the files have not been formally screen-reader tested.",
    "Written with AI assistance and reviewed for consistency.",
]

RECIPE_TAIL = [
    "HOW TO TELL WHEN IT IS DONE",
    "FOR THE SIGHTED HELPER",
    "SAFETY",
    "TIPS AND VARIATIONS",
    "LEFTOVERS",
    "SOURCES",
]
RECIPE_HEAD = [
    "INTRODUCTION",
    "SERVINGS",
    "TOTAL TIME",
    "DIFFICULTY",
    "EQUIPMENT",
    "INGREDIENTS",
    "TACTILE TIPS",
    "BEFORE YOU START",
]

SMALL_WORDS = {"a", "an", "the", "and", "or", "for", "of", "to", "in", "on", "with"}
NUMBERED = re.compile(r"^(\d+)\.\s+(.*)$")


def is_heading(line):
    text = line.strip()
    if len(text) < 2 or text.startswith("-") or text.startswith("="):
        return False
    if not any(character.isalpha() for character in text):
        return False
    return text == text.upper()


def display_heading(raw):
    words = raw.split(" ")
    output = []
    for index, word in enumerate(words):
        lower = word.lower()
        core = lower.strip(".,:;()'")
        previous = words[index - 1] if index else ""
        force = index == 0 or previous.endswith(":")
        if not force and lower == core and core in SMALL_WORDS:
            output.append(lower)
        elif lower:
            output.append(lower[0].upper() + lower[1:])
        else:
            output.append(lower)
    return " ".join(output)


def slug(text):
    cleaned = re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")
    return cleaned or "section"


def blocks_from(lines, steps):
    blocks = []
    for line in lines:
        text = line.strip()
        if not text:
            continue
        numbered = NUMBERED.match(text)
        if numbered:
            kind = "step" if steps else "numbered"
            blocks.append({
                "kind": kind,
                "number": int(numbered.group(1)),
                "text": numbered.group(2).strip(),
            })
        elif text.startswith("- "):
            blocks.append({"kind": "bullet", "text": text[2:].strip()})
        else:
            blocks.append({"kind": "paragraph", "text": text})
    return blocks


def section_plain(section):
    return "\n".join(block["text"] for block in section["blocks"]).strip()


def parse_file(path, category_id, kind):
    lines = path.read_text(encoding="utf-8-sig").replace("\r\n", "\n").split("\n")
    try:
        start = lines.index("ACCESSICOOK")
    except ValueError:
        sys.exit(f"{path} has no ACCESSICOOK header")
    title_lines = []
    index = start + 1
    while index < len(lines) and not lines[index].startswith("="):
        if lines[index].strip():
            title_lines.append(lines[index].strip())
        index += 1
    if not title_lines:
        sys.exit(f"{path} has no title")
    while index < len(lines) and (not lines[index].strip() or lines[index].startswith("=")):
        index += 1
    body = lines[index:]
    heading_indexes = [i for i, line in enumerate(body) if is_heading(line)]
    if not heading_indexes:
        sys.exit(f"{path} has no headings")
    preamble = [line.strip() for line in body[:heading_indexes[0]] if line.strip()]
    if preamble:
        sys.exit(f"{path} has text before the first heading: {preamble[:1]}")

    raw_titles = []
    sections = []
    used_ids = {}
    for position, start_index in enumerate(heading_indexes):
        raw = body[start_index].strip()
        raw_titles.append(raw)
        end = heading_indexes[position + 1] if position + 1 < len(heading_indexes) else len(body)
        steps = raw.startswith("STEPS")
        title = display_heading(raw)
        base = slug(title)
        used_ids[base] = used_ids.get(base, 0) + 1
        section_id = base if used_ids[base] == 1 else f"{base}-{used_ids[base]}"
        block_lines = body[start_index + 1:end]
        sections.append({
            "id": section_id,
            "title": title,
            "isSteps": steps,
            "blocks": blocks_from(block_lines, steps),
        })

    if kind == "recipe":
        head = raw_titles[:len(RECIPE_HEAD)]
        if head != RECIPE_HEAD:
            sys.exit(f"{path} headings start with {head}, expected {RECIPE_HEAD}")
        if not any(title.startswith("STEPS") for title in raw_titles):
            sys.exit(f"{path} has no STEPS section")
        tail = raw_titles[-len(RECIPE_TAIL):]
        if tail != RECIPE_TAIL:
            sys.exit(f"{path} headings end with {tail}, expected {RECIPE_TAIL}")
        middle = raw_titles[len(RECIPE_HEAD):-len(RECIPE_TAIL)]
        if not middle or not all(title.startswith("STEPS") for title in middle):
            sys.exit(f"{path} has unexpected headings between the introduction and doneness: {middle}")
    else:
        if raw_titles[0] != "INTRODUCTION":
            sys.exit(f"{path} lesson does not start with INTRODUCTION")

    by_title = {section["title"]: section for section in sections}
    stem = path.stem
    number = int(stem.split("-", 1)[0])
    entry_slug = slug(stem.split("-", 1)[1])
    entry = {
        "id": f"{category_id}/{entry_slug}",
        "categoryID": category_id,
        "title": title_lines[0],
        "fileName": path.name,
        "sortIndex": number,
        "kind": kind,
        "sections": sections,
    }
    if len(title_lines) > 1:
        entry["subtitle"] = " ".join(title_lines[1:])
    if kind == "recipe":
        entry["servings"] = section_plain(by_title["Servings"])
        entry["totalTime"] = section_plain(by_title["Total Time"])
        entry["difficulty"] = section_plain(by_title["Difficulty"])
        if not any(block["kind"] == "step" for section in sections for block in section["blocks"]):
            sys.exit(f"{path} has a STEPS heading but no numbered steps")
    return entry


def main():
    categories = []
    entries = []
    seen_ids = set()
    for sort_index, (folder, category_id, name, kind, summary) in enumerate(CATEGORIES):
        directory = SRC / folder
        if not directory.is_dir():
            sys.exit(f"missing category folder {directory}")
        files = sorted(path for path in directory.glob("*.txt") if path.name not in SKIP)
        if len(files) != EXPECTED_COUNTS[category_id]:
            sys.exit(f"{folder} has {len(files)} files, expected {EXPECTED_COUNTS[category_id]}")
        categories.append({
            "id": category_id,
            "name": name,
            "kind": kind,
            "summary": summary,
            "sortIndex": sort_index,
        })
        for path in files:
            entry = parse_file(path, category_id, kind)
            if entry["id"] in seen_ids:
                sys.exit(f"duplicate id {entry['id']}")
            seen_ids.add(entry["id"])
            entries.append(entry)

    recipes = [entry for entry in entries if entry["kind"] == "recipe"]
    lessons = [entry for entry in entries if entry["kind"] == "lesson"]
    if len(recipes) != 327 or len(lessons) != 13:
        sys.exit(f"expected 327 recipes and 13 lessons, got {len(recipes)} and {len(lessons)}")

    book = {
        "version": 1,
        "title": "Accessicook",
        "honestNotes": HONEST_NOTES,
        "categories": categories,
        "entries": entries,
    }
    DEST.parent.mkdir(parents=True, exist_ok=True)
    payload = json.dumps(book, ensure_ascii=False, separators=(",", ":")) + "\n"
    DEST.write_text(payload, encoding="utf-8")
    print(f"wrote {DEST} ({len(lessons)} lessons, {len(recipes)} recipes)")


if __name__ == "__main__":
    main()
