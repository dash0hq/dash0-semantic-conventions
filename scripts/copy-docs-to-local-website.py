#!/usr/bin/env python3
# SPDX-FileCopyrightText: Copyright 2026 Dash0 Inc.
#
# Simulate what dash0hq/sync-docs-action does locally:
# applies transformations from transformations.yaml and copies files
# to a local dash0-website checkout for end-to-end testing.
#
# Usage:
#   ./scripts/copy-docs-to-local-website.py [path-to-dash0-website]
#
# Default website path: ~/git/dash0-website

import os
import re
import json
import datetime
import sys

try:
    import yaml
except ImportError:
    print("Error: pyyaml not installed. Run: pip3 install pyyaml --break-system-packages")
    sys.exit(1)

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCE_ROOT = os.path.join(REPO_ROOT, "docs-website")
TRANSFORMATIONS_FILE = os.path.join(
    REPO_ROOT, ".github/workflows/sync-docs/transformations.yaml"
)
WEBSITE_ROOT = sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser("~/git/dash0-website")
TARGET_BASE = os.path.join(WEBSITE_ROOT, "src/app/(core)/docs/content")


def apply_transform(content, transform):
    t = transform["type"]
    if t == "replace-regex":
        flags = 0
        for f in transform.get("flags", []):
            if f == "multiline":
                flags |= re.MULTILINE
            elif f == "dotall":
                flags |= re.DOTALL
            elif f == "ignorecase":
                flags |= re.IGNORECASE
        pattern = transform["find"]
        replacement = transform.get("replace", "")
        new_content, n = re.subn(pattern, replacement, content, flags=flags)
        required = transform.get("required", True)
        if required and n == 0:
            raise ValueError(f"replace-regex '{pattern}' matched 0 times (required: true)")
        return new_content
    elif t == "remove-line":
        marker = transform["line"]
        lines = content.splitlines(keepends=True)
        new_lines = [l for l in lines if marker not in l]
        # Collapse multiple consecutive blank lines to one
        result = []
        prev_blank = False
        for line in new_lines:
            is_blank = line.strip() == ""
            if is_blank and prev_blank:
                continue
            result.append(line)
            prev_blank = is_blank
        return "".join(result)
    elif t == "prepend":
        return transform["content"] + content
    else:
        raise ValueError(f"Unknown transformation type: {t}")


def yaml_scalar(value):
    """Serialize a string value for YAML frontmatter (quoted when needed)."""
    # Use dump on a dict so yaml.dump doesn't append the '...' document-end marker
    dumped = yaml.dump({"v": value}, default_flow_style=False, allow_unicode=True, width=10000)
    # Result is 'v: <value>\n' — extract the value part
    return dumped.split("v: ", 1)[1].rstrip("\n")


def build_nav_json(nav_cfg, files_cfg):
    """Build the nav.json content mirroring sync-docs-action's nav generator."""
    targets = [e["target"] for e in files_cfg]
    titles = {e["target"]: e["title"] for e in files_cfg}

    # Find longest common directory prefix
    dirs = [os.path.dirname(t) for t in targets]
    common = dirs[0] if dirs else ""
    for d in dirs[1:]:
        while common and not d.startswith(common + "/") and d != common:
            common = os.path.dirname(common)
        if not common:
            break

    group_titles = nav_cfg.get("groupTitles", {})
    root_children = []
    groups_order = []
    groups_map = {}

    for entry in files_cfg:
        target = entry["target"]
        title = entry["title"]
        rel = target[len(common):].lstrip("/") if common else target

        parts = rel.split("/")
        if len(parts) == 1:
            # Top-level leaf (e.g. overview.md — drop .md suffix for path key)
            root_children.append({"title": title, "path": target})
        else:
            group_slug = parts[0]
            if group_slug not in groups_map:
                display = group_titles.get(group_slug, group_slug.replace("-", " ").title())
                node = {"title": display, "children": []}
                groups_map[group_slug] = node
                groups_order.append(group_slug)
                root_children.append(node)
            groups_map[group_slug]["children"].append({"title": title, "path": target})

    nav = {
        "order": nav_cfg["order"],
        "id": nav_cfg["id"],
    }
    if "parentPath" in nav_cfg:
        nav["parentPath"] = nav_cfg["parentPath"]
    nav["items"] = [{"title": nav_cfg["title"], "children": root_children}]
    return nav


def main():
    if not os.path.isdir(SOURCE_ROOT):
        print(f"Error: docs-website/ not found at {SOURCE_ROOT}")
        print("Run first:  ./scripts/generate-docs.sh ./docs-website/ website")
        sys.exit(1)

    if not os.path.isdir(WEBSITE_ROOT):
        print(f"Error: dash0-website not found at {WEBSITE_ROOT}")
        sys.exit(1)

    with open(TRANSFORMATIONS_FILE) as f:
        config = yaml.safe_load(f)

    timestamp = datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%S.000Z")
    common_transforms = config.get("common", [])
    nav_cfg = config.get("nav")
    files_cfg = config.get("files", [])

    print(f"Source:  {SOURCE_ROOT}")
    print(f"Target:  {TARGET_BASE}")
    print(f"Pages:   {len(files_cfg)}")
    print()

    written = []
    errors = []

    for entry in files_cfg:
        source_rel = entry["source"]
        target_rel = entry["target"]
        title = entry["title"]
        description = entry.get("description", "")

        source_path = os.path.join(SOURCE_ROOT, source_rel)
        target_path = os.path.join(TARGET_BASE, target_rel)

        if not os.path.exists(source_path):
            errors.append(f"  MISSING source: {source_rel}")
            continue

        with open(source_path) as f:
            content = f.read()

        # Apply common transformations
        try:
            for t in common_transforms:
                content = apply_transform(content, t)
        except ValueError as e:
            errors.append(f"  TRANSFORM ERROR {source_rel}: {e}")
            continue

        # Prepend frontmatter
        title_val = yaml_scalar(title)
        desc_val = yaml_scalar(description)
        frontmatter = (
            f"---\ntitle: {title_val}\n"
            f"description: {desc_val}\n"
            f"lastUpdated: {timestamp}\n---\n\n"
        )
        content = frontmatter + content.lstrip("\n")

        os.makedirs(os.path.dirname(target_path), exist_ok=True)
        with open(target_path, "w") as f:
            f.write(content)

        print(f"  ✓ {source_rel}")
        print(f"    → {target_rel}")
        written.append(entry)

    # Generate nav.json
    if nav_cfg and written:
        nav_data = build_nav_json(nav_cfg, written)
        nav_target_path = os.path.join(TARGET_BASE, nav_cfg["target"])
        os.makedirs(os.path.dirname(nav_target_path), exist_ok=True)
        with open(nav_target_path, "w") as f:
            json.dump(nav_data, f, indent=2)
            f.write("\n")
        print(f"\n  ✓ nav.json → {nav_cfg['target']}")

    print(f"\n{'='*60}")
    if errors:
        print("ERRORS:")
        for e in errors:
            print(e)
        print()
    print(f"Written {len(written)}/{len(files_cfg)} pages to {TARGET_BASE}")


if __name__ == "__main__":
    main()
