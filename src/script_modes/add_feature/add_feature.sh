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
  read -p "Does this new feature include a UI (Screen, Cubit, Router entry)? (y/n): " HAS_UI

  if [ -z "$FEATURE_NAME_SNAKE" ]; then echo "Error: New feature name cannot be empty."; exit 1; fi
  
  BASE_PATH="./lib"

  echo ""
  echo "Adding feature '$FEATURE_NAME_SNAKE' to module '$MODULE_NAME_SNAKE'..."
  echo ""

  # 1. Define Paths
  define_module_paths "$MODULE_NAME_SNAKE" "$FEATURE_NAME_SNAKE" "$BASE_PATH"

  # 2. Create Directories
  create_feature_directories "$HAS_UI"

  # 3. Generate Files
  generate_feature_files "$HAS_UI"

  # 4. Modify Shared Files
  modify_shared_files "$HAS_UI"

  echo ""
  echo "✅ New feature '$FEATURE_NAME_SNAKE' added successfully to module '$MODULE_NAME_SNAKE'."
}
