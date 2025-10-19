#!/bin/bash

# --- Helper Functions for Text Manipulation ---

snake_to_pascal_case() {
  echo "$1" | awk -F_ '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2); print}' OFS=""
}

pascal_to_camel_case() {
  local pascal_string="$1"
  local first_char_lower=$(echo "${pascal_string:0:1}" | tr '[:upper:]' '[:lower:]')
  local rest_of_string="${pascal_string:1}"
  echo "${first_char_lower}${rest_of_string}"
}

# --- Helper Function for Creating Files from Templates ---
# This new function reads a template file, replaces all variables, and saves it to the destination.
render_template() {
    local template_path="$1"
    local destination_path="$2"

    if [ ! -f "$template_path" ]; then
        echo "[ERROR] Template file not found: $template_path"
        return 1
    fi

    # Read the template and use sed to replace all variable placeholders
    sed -e "s|\${MODULE_NAME_SNAKE}|${MODULE_NAME_SNAKE}|g" \
        -e "s|\${MODULE_NAME_PASCAL}|${MODULE_NAME_PASCAL}|g" \
        -e "s|\${MODULE_NAME_CAMEL}|${MODULE_NAME_CAMEL}|g" \
        -e "s|\${FEATURE_NAME_SNAKE}|${FEATURE_NAME_SNAKE}|g" \
        -e "s|\${FEATURE_NAME_PASCAL}|${FEATURE_NAME_PASCAL}|g" \
        -e "s|\${FEATURE_NAME_CAMEL}|${FEATURE_NAME_CAMEL}|g" \
        -e "s|\${UI_BODY_CODE}|${UI_BODY_CODE}|g" \
        "$template_path" > "$destination_path"

    echo "Created: $destination_path"
}

# Renders a partial template and returns the content as a string
render_partial() {
    local template_path="$1"
    if [ ! -f "$template_path" ]; then
        echo "[ERROR] Partial template file not found: $template_path"
        return 1
    fi

    # Read the template, substitute variables, and echo the result to be captured in a variable
    sed -e "s/\${MODULE_NAME_SNAKE}/${MODULE_NAME_SNAKE}/g" \
        -e "s/\${MODULE_NAME_PASCAL}/${MODULE_NAME_PASCAL}/g" \
        -e "s/\${MODULE_NAME_CAMEL}/${MODULE_NAME_CAMEL}/g" \
        -e "s/\${FEATURE_NAME_SNAKE}/${FEATURE_NAME_SNAKE}/g" \
        -e "s/\${FEATURE_NAME_PASCAL}/${FEATURE_NAME_PASCAL}/g" \
        -e "s/\${FEATURE_NAME_CAMEL}/${FEATURE_NAME_CAMEL}/g" \
        "$template_path"
}
# --- Helper Functions for Modifying Existing Files (for Mode 2) ---

insert_before() {
  local file="$1"
  local pattern="$2"
  local content="$3"
  local tmp_file

  echo "  -> Modifying File: '$file'"
  if [ ! -r "$file" ]; then echo "     [ERROR] File not found or is not readable. Skipping."; return 1; fi
  if ! grep -qF -- "$pattern" "$file"; then echo "     [WARNING] Anchor pattern '$pattern' not found. Skipping."; return 1; fi
  
  tmp_file=$(mktemp)
  if [ -z "$tmp_file" ]; then echo "     [ERROR] Could not create temporary file."; return 1; fi

  export CONTENT_FOR_AWK="$content"
  awk -v p="$pattern" 'index($0, p) { print ENVIRON["CONTENT_FOR_AWK"] } { print }' "$file" > "$tmp_file"
  unset CONTENT_FOR_AWK

  if [ $? -eq 0 ]; then
    mv "$tmp_file" "$file"
    if [ $? -ne 0 ]; then echo "     [ERROR] Failed to move temporary file."; rm -f "$tmp_file"; return 1; fi
  else
    echo "     [ERROR] awk command failed."; rm -f "$tmp_file"; return 1;
  fi
}

insert_after() {
  local file="$1"
  local pattern="$2"
  local content="$3"
  local tmp_file

  echo "  -> Modifying File: '$file'"
  if [ ! -r "$file" ]; then echo "     [ERROR] File not found or is not readable. Skipping."; return 1; fi
  if ! grep -qF -- "$pattern" "$file"; then echo "     [WARNING] Anchor pattern '$pattern' not found. Skipping."; return 1; fi

  tmp_file=$(mktemp)
  if [ -z "$tmp_file" ]; then echo "     [ERROR] Could not create temporary file."; return 1; fi

  export CONTENT_FOR_AWK="$content"
  awk -v p="$pattern" '{ print } index($0, p) { print ENVIRON["CONTENT_FOR_AWK"] }' "$file" > "$tmp_file"
  unset CONTENT_FOR_AWK

  if [ $? -eq 0 ]; then
    mv "$tmp_file" "$file"
    if [ $? -ne 0 ]; then echo "     [ERROR] Failed to move temporary file."; rm -f "$tmp_file"; return 1; fi
  else
    echo "     [ERROR] awk command failed."; rm -f "$tmp_file"; return 1;
  fi
}

# NEW: This function normalizes various user inputs into clean snake_case.
# MainScreen -> main_screen
# mainScreen -> main_screen
# main screen -> main_screen
normalize_to_snake_case() {
  echo "$1" | \
  sed 's/ /_/g' | \
  sed -E 's/([a-z0-9])([A-Z])/\1_\2/g' | \
  tr '[:upper:]' '[:lower:]' | \
  sed 's/__/_/g'
}