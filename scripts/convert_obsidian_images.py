#!/usr/bin/env python3

import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parents[1]
POSTS_DIR = ROOT / "_posts"
ASSETS_PREFIX = "/assets/images/"

IMAGE_EMBED_PATTERN = re.compile(r"!\[\[(.+?)\]\]")


def convert_file(path: pathlib.Path) -> bool:
    original = path.read_text(encoding="utf-8")
    changed = original

    def _replace(match: re.Match) -> str:
        filename = match.group(1).strip()
        alt = filename.rsplit(".", 1)[0]
        return f"![{alt}]({ASSETS_PREFIX}{filename})"

    changed = IMAGE_EMBED_PATTERN.sub(_replace, changed)

    if changed != original:
        path.write_text(changed, encoding="utf-8")
        return True
    return False


def main() -> None:
    md_files = sorted(POSTS_DIR.glob("*.md"))
    touched = 0
    for md in md_files:
        if convert_file(md):
            touched += 1
    print(f"Converted Obsidian image embeds in {touched} file(s).")


if __name__ == "__main__":
    main()

