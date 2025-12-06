#!/bin/bash

# Source the tools
source "${SCRIPT_DIR}/src/script_modes/add_feature/tools/feature_tools.sh"

run_add_feature_mode() {
  echo ""
  echo "--- Mode 2: Add New Feature to Existing Module ---"

  MODULE_NAME_SNAKE=$(basename "$PWD")
  echo "Operating in module: $MODULE_NAME_SNAKE"

  # if [ ! -f "pubspec.yaml" ] || [ ! -d "lib" ]; then echo "Error: This does not appear to be the root of a Flutter module."; exit 1; fi

  echo "Enter the name for the NEW feature to add to '$MODULE_NAME_SNAKE':"
  read FEATURE_NAME_SNAKE
  FEATURE_NAME_SNAKE=$(normalize_to_snake_case "$FEATURE_NAME_SNAKE")
  echo "Select the type of feature to add:"
  echo "  1) Full Feature (Data + Domain + Presentation)"
  echo "  2) Logic Only (Data + Domain)"
  echo "  3) UI Only (Presentation)"
  read -p "Enter your choice (1-3): " FEATURE_TYPE

  # Default to 1 if empty
  if [ -z "$FEATURE_TYPE" ]; then FEATURE_TYPE="1"; fi

  if [ -z "$FEATURE_NAME_SNAKE" ]; then echo "Error: New feature name cannot be empty."; exit 1; fi
  
  BASE_PATH="./lib"

  echo ""
  echo "Adding feature '$FEATURE_NAME_SNAKE' to module '$MODULE_NAME_SNAKE'..."
  echo ""

  # 1. Define Paths
  define_module_paths "$MODULE_NAME_SNAKE" "$FEATURE_NAME_SNAKE" "$BASE_PATH"

  # 2. Create Directories
  create_feature_directories "$FEATURE_TYPE"

  # 3. Generate Files
  generate_feature_files "$FEATURE_TYPE"

  # 4. Modify Shared Files
  modify_shared_files "$FEATURE_TYPE"

  echo ""
  echo "✅ New feature '$FEATURE_NAME_SNAKE' added successfully to module '$MODULE_NAME_SNAKE'."
}
