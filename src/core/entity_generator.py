"""
entity_generator.py

Python port of the Dart Entity & Model Generator logic from the web tool
(entites_creation_tool/public/index.html).

Parses a JSON example and generates Dart entity + response model file contents.
"""

import json
import re


# ─────────────────────────────────────────────
#  Internal Data Models
# ─────────────────────────────────────────────

class DartProperty:
    def __init__(self, name, prop_type, is_list=False, is_custom=False):
        self.name = name          # raw JSON key (used as Dart field name)
        self.type = prop_type     # Dart type or nested class name (PascalCase)
        self.is_list = is_list
        self.is_custom = is_custom


class ClassDefinition:
    def __init__(self, name):
        self.name = name               # PascalCase class name
        self.properties = {}           # ordered dict: key → DartProperty

    def add_property(self, prop):
        self.properties[prop.name] = prop


# ─────────────────────────────────────────────
#  Case Utilities  (mirrors the JS helpers)
# ─────────────────────────────────────────────

def _to_snake_case(s):
    """Convert any string to snake_case (mirrors JS toSnakeCase)."""
    if not s:
        return ''
    s = re.sub(r'\s+', '_', s)
    s = re.sub(r'([A-Z])', lambda m: f'_{m.group(1).lower()}', s)
    s = s.lstrip('_')
    s = re.sub(r'_+', '_', s)
    return s.lower()


def _to_pascal_case(s):
    """Convert any string to PascalCase (mirrors JS toPascalCase)."""
    if not s:
        return ''
    snake = _to_snake_case(s)
    return ''.join(word.capitalize() for word in snake.split('_') if word)


# ─────────────────────────────────────────────
#  JSON Parser  (mirrors JS parseFromJson)
# ─────────────────────────────────────────────

def parse_from_json(json_str, root_class_name):
    """
    Parse a JSON string into a list of ClassDefinition objects.

    Returns:
        (class_definitions: list[ClassDefinition], is_result_list: bool)

    Raises:
        ValueError: if the JSON string is invalid.
    """
    try:
        data = json.loads(json_str)
    except json.JSONDecodeError as e:
        raise ValueError(f"Invalid JSON: {e}")

    is_result_list = False
    data_to_parse = data

    # Detect 'result' key or root array — same logic as the JS version
    if isinstance(data, dict) and 'result' in data:
        result_val = data['result']
        if isinstance(result_val, list):
            is_result_list = True
            data_to_parse = result_val[0] if result_val else None
        elif isinstance(result_val, dict) and result_val is not None:
            data_to_parse = result_val
        else:
            data_to_parse = None
    elif isinstance(data, list):
        is_result_list = True
        data_to_parse = data[0] if data else None

    if data_to_parse is None:
        return [], is_result_list

    classes_to_generate = {}   # insertion-ordered

    def recursive_parse(json_obj, class_name):
        if not json_obj or class_name in classes_to_generate:
            return

        class_def = ClassDefinition(class_name)
        classes_to_generate[class_name] = class_def

        for key, value in json_obj.items():
            pascal_prop_name = _to_pascal_case(key)

            if value is not None and isinstance(value, dict):
                # Nested object → custom type
                class_def.add_property(DartProperty(key, pascal_prop_name, False, True))
                recursive_parse(value, pascal_prop_name)

            elif isinstance(value, list):
                if value and isinstance(value[0], dict) and value[0] is not None:
                    # List of objects → custom type (strip trailing 's' for type name)
                    prop_type = pascal_prop_name
                    if prop_type.endswith('s'):
                        prop_type = prop_type[:-1]
                    class_def.add_property(DartProperty(key, prop_type, True, True))
                    recursive_parse(value[0], prop_type)
                # Primitive lists are skipped (same as web tool)

            else:
                # Primitive value → map to Dart type
                if isinstance(value, bool):
                    dart_type = 'bool'
                elif isinstance(value, str):
                    dart_type = 'String'
                elif isinstance(value, (int, float)):
                    dart_type = 'num'
                else:
                    dart_type = 'dynamic'
                class_def.add_property(DartProperty(key, dart_type, False, False))

    recursive_parse(data_to_parse, root_class_name)
    return list(classes_to_generate.values()), is_result_list


# ─────────────────────────────────────────────
#  File Generator  (mirrors JS generateFiles)
# ─────────────────────────────────────────────

def generate_entity_files(class_definitions, is_result_list, feature_file_name,
                           base_class_name='ResponseModel', should_flatten_ids=False):
    """
    Generate Dart file contents from parsed class definitions.

    Args:
        class_definitions:  list of ClassDefinition (from parse_from_json)
        is_result_list:     bool (from parse_from_json)
        feature_file_name:  snake_case feature name, e.g. 'home_offers'
        base_class_name:    base response class, default 'ResponseModel'
        should_flatten_ids: if True, List<X> with only an id field → List<int>

    Returns:
        list of dicts:  [{'path': 'lib-relative/path.dart', 'content': '...'}, ...]
        Paths are relative to the module's lib/ directory.
    """
    root_class_name = _to_pascal_case(feature_file_name)
    generated_files = []

    root_entity_name = f"{root_class_name}Entity"
    root_model_name  = f"{root_class_name}ResponseModel"

    # ── 1. Response Wrapper ──────────────────────────────────────────────────
    generic_type = f"List<{root_entity_name}>" if is_result_list else root_entity_name

    if is_result_list:
        from_json_mapper = (
            f"(data) => (data as List)"
            f".map((item) => {root_model_name}.fromJson(item)).toList()"
        )
    else:
        from_json_mapper = f"(data) => {root_model_name}.fromJson(data)"

    main_response_name = f"{root_class_name}Response"
    response_file_name = f"{feature_file_name}_response.dart"

    response_content = (
        f"import 'package:core/core.dart';\n"
        f"import '../../../../domain/entities/{feature_file_name}/{feature_file_name}_entity.dart';\n"
        f"import './{feature_file_name}_response_model.dart';\n"
        f"\n"
        f"class {main_response_name} extends {base_class_name}<{generic_type}> {{\n"
        f"  {main_response_name}({{\n"
        f"    super.result,\n"
        f"    super.message,\n"
        f"    super.statusCode,\n"
        f"    super.statusName,\n"
        f"  }});\n"
        f"\n"
        f"  {main_response_name}.fromJson(Map<String, dynamic> json)\n"
        f"      : super.fromJson(json, {from_json_mapper});\n"
        f"}}\n"
    )
    generated_files.append({
        'path': f"data/models/{feature_file_name}/response/{response_file_name}",
        'content': response_content
    })

    # ── 2. Empty fallback (no fields parsed) ────────────────────────────────
    if not class_definitions:
        entity_file_name = f"{feature_file_name}_entity.dart"
        entity_content = (
            f"import 'package:core/packages/equatable/equatable.dart';\n"
            f"\n"
            f"class {root_entity_name} extends Equatable {{\n"
            f"\n"
            f"  const {root_entity_name}();\n"
            f"\n"
            f"  @override\n"
            f"  List<Object?> get props => [];\n"
            f"}}\n"
        )
        generated_files.append({
            'path': f"domain/entities/{feature_file_name}/{entity_file_name}",
            'content': entity_content
        })

        model_file_name = f"{feature_file_name}_response_model.dart"
        model_content = (
            f"import '../../../../domain/entities/{feature_file_name}/{entity_file_name}';\n"
            f"\n"
            f"class {root_model_name} extends {root_entity_name} {{\n"
            f"  const {root_model_name}();\n"
            f"\n"
            f"  factory {root_model_name}.fromJson(Map<String, dynamic> json) {{\n"
            f"    return const {root_model_name}();\n"
            f"  }}\n"
            f"\n"
            f"  Map<String, dynamic> toJson() => {{}};\n"
            f"}}\n"
        )
        generated_files.append({
            'path': f"data/models/{feature_file_name}/response/{model_file_name}",
            'content': model_content
        })
        return generated_files

    # ── 3. Full generation with fields ──────────────────────────────────────
    class_map = {c.name: c for c in class_definitions}

    for class_def in reversed(class_definitions):
        snake_class_name = _to_snake_case(class_def.name)
        entity_name      = f"{class_def.name}Entity"
        entity_file_name = f"{snake_class_name}_entity.dart"
        model_name       = f"{class_def.name}ResponseModel"
        model_file_name  = f"{snake_class_name}_response_model.dart"

        # Accumulate per-file parts
        entity_imports        = {"import 'package:core/packages/equatable/equatable.dart';"}
        entity_fields         = []
        constructor_params    = []
        props_items           = []

        model_imports         = {
            f"import '../../../../domain/entities/{feature_file_name}/{entity_file_name}';"
        }
        model_ctor_params     = []
        from_json_items       = []
        to_json_items         = []

        for prop in class_def.properties.values():

            # ── Flatten IDs check ────────────────────────────────────────────
            flatten_info = None
            if should_flatten_ids and prop.is_list and prop.is_custom:
                sub = class_map.get(prop.type)
                if sub and len(sub.properties) == 1:
                    only_prop = list(sub.properties.values())[0]
                    if 'id' in only_prop.name.lower():
                        base = _to_snake_case(prop.name).rstrip('s')
                        flatten_info = {
                            'prop_name': f"{base}_ids",
                            'id_key': only_prop.name,
                        }

            if flatten_info:
                fn = flatten_info['prop_name']
                ik = flatten_info['id_key']
                entity_fields.append(f"  final List<int>? {fn};")
                constructor_params.append(f"    this.{fn},")
                props_items.append(f"        {fn},")
                model_ctor_params.append(f"    super.{fn},")
                from_json_items.append(
                    f"      {fn}: (json['{prop.name}'] as List<dynamic>?)\n"
                    f"          ?.map((e) => e['{ik}'] as int?)\n"
                    f"          .where((e) => e != null).cast<int>()\n"
                    f"          .toList(),"
                )
                to_json_items.append(
                    f"      '{prop.name}': {fn}?.map((id) => {{'{ik}': id}}).toList(),"
                )

            else:
                # ── Regular property ─────────────────────────────────────────
                if prop.is_custom:
                    entity_imports.add(
                        f"import './{_to_snake_case(prop.type)}_entity.dart';"
                    )
                    model_imports.add(
                        f"import './{_to_snake_case(prop.type)}_response_model.dart';"
                    )
                    prop_type_str  = (f"List<{prop.type}Entity>"
                                      if prop.is_list else f"{prop.type}Entity")
                    model_prop_type = f"{prop.type}ResponseModel"
                else:
                    prop_type_str  = (f"List<{prop.type}>"
                                      if prop.is_list else prop.type)
                    model_prop_type = None

                entity_fields.append(f"  final {prop_type_str}? {prop.name};")
                constructor_params.append(f"    this.{prop.name},")
                props_items.append(f"        {prop.name},")
                model_ctor_params.append(f"    super.{prop.name},")

                if prop.is_custom:
                    if prop.is_list:
                        from_json_items.append(
                            f"      {prop.name}: (json['{prop.name}'] as List<dynamic>?)\n"
                            f"          ?.map((v) => {model_prop_type}.fromJson(v))\n"
                            f"          .toList(),"
                        )
                        to_json_items.append(
                            f"      '{prop.name}': ({prop.name} as List<{model_prop_type}>?)"
                            f"?.map((v) => v.toJson()).toList(),"
                        )
                    else:
                        from_json_items.append(
                            f"      {prop.name}: json['{prop.name}'] != null\n"
                            f"          ? {model_prop_type}.fromJson(json['{prop.name}'])\n"
                            f"          : null,"
                        )
                        to_json_items.append(
                            f"      '{prop.name}': ({prop.name} as {model_prop_type}?)?.toJson(),"
                        )
                else:
                    from_json_items.append(f"      {prop.name}: json['{prop.name}'],")
                    to_json_items.append(f"      '{prop.name}': {prop.name},")

        # ── Assemble entity file ─────────────────────────────────────────────
        entity_lines = sorted(entity_imports) + ['']
        entity_lines += [f"class {entity_name} extends Equatable {{"]
        entity_lines += entity_fields
        entity_lines += ['', f"  const {entity_name}({{"]
        entity_lines += constructor_params
        entity_lines += ["  });", "", "  @override", "  List<Object?> get props => ["]
        entity_lines += props_items
        entity_lines += ["      ];", "}", ""]

        generated_files.append({
            'path': f"domain/entities/{feature_file_name}/{entity_file_name}",
            'content': '\n'.join(entity_lines)
        })

        # ── Assemble model file ──────────────────────────────────────────────
        model_lines = sorted(model_imports) + ['']
        model_lines += [f"class {model_name} extends {entity_name} {{"]
        model_lines += [f"  const {model_name}({{"]
        model_lines += model_ctor_params
        model_lines += ["  });", ""]
        model_lines += [
            f"  factory {model_name}.fromJson(dynamic json) {{",
            f"    return {model_name}("
        ]
        model_lines += from_json_items
        model_lines += ["    );", "  }", ""]
        model_lines += ["  Map<String, dynamic> toJson() {", "    return {"]
        model_lines += to_json_items
        model_lines += ["    };", "  }", "}", ""]

        generated_files.append({
            'path': f"data/models/{feature_file_name}/response/{model_file_name}",
            'content': '\n'.join(model_lines)
        })

    return generated_files
