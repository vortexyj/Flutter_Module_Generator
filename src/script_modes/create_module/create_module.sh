#!/bin/bash

# Source the tools
source "${SCRIPT_DIR}/src/script_modes/create_module/tools/module_tools.sh"

run_create_mode() {
  echo ""
  echo "--- Mode 1: Create New Module ---"
  
  echo "Enter the name for the new Flutter Module (package, snake_case):"
  read MODULE_NAME_SNAKE
  MODULE_NAME_SNAKE=$(normalize_to_snake_case "$MODULE_NAME_SNAKE")

  if [ -z "$MODULE_NAME_SNAKE" ]; then echo "Error: Module name cannot be empty."; exit 1; fi
  if [ -d "$MODULE_NAME_SNAKE" ]; then echo "Error: A directory named '$MODULE_NAME_SNAKE' already exists here."; exit 1; fi

  # 1. Create Package
  create_flutter_package "$MODULE_NAME_SNAKE"

  # 2. Enter Directory
  enter_module_directory "$MODULE_NAME_SNAKE"

  # 3. Add Dependencies & Clean
  update_pubspec_and_clean "$MODULE_NAME_SNAKE"

  echo "Enter the name for the initial FEATURE (e.g., user_login):"
  read FEATURE_NAME_SNAKE
  FEATURE_NAME_SNAKE=$(normalize_to_snake_case "$FEATURE_NAME_SNAKE")

  if [ -z "$FEATURE_NAME_SNAKE" ]; then echo "Error: Feature name cannot be empty."; exit 1; fi

  BASE_PATH="./lib"
  if [ ! -d "$BASE_PATH" ]; then echo "Error: '$BASE_PATH' directory not found inside '$PWD'."; exit 1; fi

  # 4. Define Paths
  define_module_paths "$MODULE_NAME_SNAKE" "$FEATURE_NAME_SNAKE" "$BASE_PATH"

  # 5. Create Directories
  create_module_directories

  # 6. Generate Files
  generate_module_files "$FEATURE_NAME_PASCAL"
  
  echo "✅ Flutter module '$MODULE_NAME_SNAKE' and initial feature '$FEATURE_NAME_SNAKE' created successfully."
  cd ..
  echo "Returned to: $PWD"
}
