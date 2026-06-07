"""
entity_json_step.py

Orchestrates the optional JSON → entity generation step.

Called from both create_module.py and add_feature.py after the
empty template files have been written. If the user provides a
valid JSON example, the template-generated entity / response files
are overwritten with the properly typed versions.
"""

import os

from src.core.json_input import collect_json_from_user
from src.core.entity_generator import parse_from_json, generate_entity_files


# ─────────────────────────────────────────────
#  Public entry point
# ─────────────────────────────────────────────

def run_entity_json_step(paths, base_path: str = "./lib"):
    """
    Ask the user if they want to generate entity/response files from JSON.
    If yes, collect JSON, preview what will be generated, confirm, then write.

    Args:
        paths:      ModulePaths instance (has feature_name_snake, feature_name_pascal, etc.)
        base_path:  The module's lib directory, e.g. "./lib"
    """
    print()
    try:
        answer = input(
            f"   Generate entity & response files from a JSON example for ? "
            f"'{paths.feature_name_snake}'? [y/N]: "
        ).strip().lower()
    except EOFError:
        return

    if answer not in ("y", "yes"):
        print("  → Skipping JSON generation. Using empty templates.")
        return

    # ── Collect JSON ─────────────────────────────────────────────────────────
    json_str = collect_json_from_user(paths.feature_name_snake)
    if not json_str:
        print("  → No valid JSON provided. Keeping empty templates.")
        return

    # ── Optional: flatten IDs ────────────────────────────────────────────────
    try:
        flatten_answer = input(
            "  Flatten single-id nested objects to List<int>? [y/N]: "
        ).strip().lower()
    except EOFError:
        flatten_answer = "n"
    should_flatten = flatten_answer in ("y", "yes")

    # ── Parse JSON ───────────────────────────────────────────────────────────
    print("\n  Parsing JSON...")
    try:
        class_defs, is_result_list = parse_from_json(
            json_str,
            root_class_name=paths.feature_name_pascal
        )
    except ValueError as e:
        print(f"  ✗ {e}")
        print("  → Keeping empty templates.")
        return

    # ── Preview ──────────────────────────────────────────────────────────────
    _print_preview(class_defs, is_result_list, paths.feature_name_pascal)

    # ── Confirm ──────────────────────────────────────────────────────────────
    try:
        confirm = input("\n  Looks good? Overwrite template files? [Y/n]: ").strip().lower()
    except EOFError:
        confirm = "y"

    if confirm in ("n", "no"):
        print("  → Cancelled. Keeping empty templates.")
        return

    # ── Generate file contents ────────────────────────────────────────────────
    generated = generate_entity_files(
        class_definitions=class_defs,
        is_result_list=is_result_list,
        feature_file_name=paths.feature_name_snake,
        base_class_name='ResponseModel',
        should_flatten_ids=should_flatten,
    )

    # ── Write files ───────────────────────────────────────────────────────────
    print("\n  Writing generated files...")
    success_count = 0
    for file_info in generated:
        # file_info['path'] is relative to lib/, e.g.
        #   "domain/entities/home_offers/home_offers_entity.dart"
        #   "data/models/home_offers/response/home_offers_response.dart"
        abs_path = os.path.join(base_path, file_info['path'])
        abs_dir  = os.path.dirname(abs_path)

        os.makedirs(abs_dir, exist_ok=True)
        try:
            with open(abs_path, 'w') as f:
                f.write(file_info['content'])
            print(f"  ✓  {file_info['path']}")
            success_count += 1
        except OSError as e:
            print(f"  ✗  {file_info['path']}  ({e})")

    print(
        f"\n  ✅ Entity generation complete — "
        f"{success_count}/{len(generated)} files written."
    )


# ─────────────────────────────────────────────
#  Preview helper
# ─────────────────────────────────────────────

def _print_preview(class_defs, is_result_list, root_class_name):
    """Print a human-readable summary of what will be generated."""
    result_shape = (
        f"List<{root_class_name}Entity>"
        if is_result_list
        else f"{root_class_name}Entity"
    )
    print(f"\n  ── Preview ───────────────────────────────────────")
    print(f"  Response result type : {result_shape}")

    if not class_defs:
        print("  Classes              : (none — empty entity will be created)")
        return

    print(f"  Classes to generate  : {len(class_defs)}")
    for cls in class_defs:
        field_names = list(cls.properties.keys())
        field_summary = ", ".join(field_names[:5])
        if len(field_names) > 5:
            field_summary += f", … (+{len(field_names) - 5} more)"
        print(f"    • {cls.name}Entity  ({len(field_names)} fields): {field_summary}")

    print(f"  ─────────────────────────────────────────────────")
