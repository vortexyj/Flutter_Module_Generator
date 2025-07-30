#!/bin/bash

run_create_mode() {
  echo ""
  echo "--- Mode 1: Create New Module ---"
  
  echo "Enter the name for the new Flutter Module (package, snake_case):"
  read MODULE_NAME_SNAKE

  if [ -z "$MODULE_NAME_SNAKE" ]; then echo "Error: Module name cannot be empty."; exit 1; fi
  if [ -d "$MODULE_NAME_SNAKE" ]; then echo "Error: A directory named '$MODULE_NAME_SNAKE' already exists here."; exit 1; fi

  echo "Creating Flutter package (module): $MODULE_NAME_SNAKE..."
  flutter create --template=package "$MODULE_NAME_SNAKE"

  if [ ! -d "$MODULE_NAME_SNAKE" ] || [ ! -f "$MODULE_NAME_SNAKE/pubspec.yaml" ]; then echo "Error: Failed to create module '$MODULE_NAME_SNAKE'."; exit 1; fi
  echo "Module '$MODULE_NAME_SNAKE' created successfully."
  echo ""

  echo "Changing directory to '$MODULE_NAME_SNAKE'..."
  cd "$MODULE_NAME_SNAKE"
  if [ $? -ne 0 ]; then echo "Error: Failed to change directory to '$MODULE_NAME_SNAKE'."; exit 1; fi
  echo "Now operating inside module: $PWD"
  echo ""

  # --- Add Dependencies and Clean Project ---
  echo "Updating pubspec.yaml and cleaning project files..."
  
  PUBSPEC_FILE="./pubspec.yaml"
  TEST_FILE_PATH="./test/${MODULE_NAME_SNAKE}_test.dart"

  read -r -d '' DEPENDENCIES << EOM

  ### MODULES
  core:
    path: ../core
  failures:
    path: ../failures
  ui_components:
    path: ../ui_components
  local_storage:
    path: ../local_storage
EOM

  insert_after "$PUBSPEC_FILE" "sdk: flutter" "$DEPENDENCIES"
  echo "     [SUCCESS] Dependencies added to pubspec.yaml."
  
  if [ -f "$TEST_FILE_PATH" ]; then
    echo "// TODO: Implement module tests." > "$TEST_FILE_PATH"
    echo "     [SUCCESS] Cleaned default test file."
  fi
  
  echo "Running 'flutter pub get' in the new module..."
  flutter pub get
  echo ""

  MODULE_NAME_PASCAL=$(snake_to_pascal_case "$MODULE_NAME_SNAKE")
  MODULE_NAME_CAMEL=$(pascal_to_camel_case "$MODULE_NAME_PASCAL")

  echo "Enter the name for the initial FEATURE (e.g., user_login):"
  read FEATURE_NAME_SNAKE

  if [ -z "$FEATURE_NAME_SNAKE" ]; then echo "Error: Feature name cannot be empty."; exit 1; fi
  FEATURE_NAME_PASCAL=$(snake_to_pascal_case "$FEATURE_NAME_SNAKE")
  FEATURE_NAME_CAMEL=$(pascal_to_camel_case "$FEATURE_NAME_PASCAL")

  BASE_PATH="./lib"
  if [ ! -d "$BASE_PATH" ]; then echo "Error: '$BASE_PATH' directory not found inside '$PWD'."; exit 1; fi

  # --- Define Paths and Filenames ---
  FILE_LIB_MODULE_MAIN="$BASE_PATH/${MODULE_NAME_SNAKE}.dart"
  FILE_LIB_MODULE_ROUTER="$BASE_PATH/${MODULE_NAME_SNAKE}_screen_router.dart"
  DATA_PATH="$BASE_PATH/data"
  DATA_MODULE_REPO_PATH="$DATA_PATH/${MODULE_NAME_SNAKE}_repository"
  FILE_DATA_MODULE_REPO_IMPL="$DATA_MODULE_REPO_PATH/${MODULE_NAME_SNAKE}_repository_impl.dart"
  DATA_MODELS_STATIC_PATH="$DATA_PATH/models"
  DATA_MODELS_FEATURE_PATH="$DATA_MODELS_STATIC_PATH/${FEATURE_NAME_SNAKE}"
  FILE_DATA_FEATURE_REQUEST="$DATA_MODELS_FEATURE_PATH/${FEATURE_NAME_SNAKE}_request.dart"
  FILE_DATA_FEATURE_REQUEST_MODEL="$DATA_MODELS_FEATURE_PATH/${FEATURE_NAME_SNAKE}_request_model.dart"
  FILE_DATA_FEATURE_RESPONSE_MODEL="$DATA_MODELS_FEATURE_PATH/${FEATURE_NAME_SNAKE}_response_model.dart"
  DATA_REMOTE_PATH="$DATA_PATH/remote_data_source"
  FILE_DATA_MODULE_REMOTE_SOURCE="$DATA_REMOTE_PATH/${MODULE_NAME_SNAKE}_remote_data_source.dart"
  DI_PATH="$BASE_PATH/di"
  FILE_DI_MODULE_MAIN="$DI_PATH/${MODULE_NAME_SNAKE}_di.dart"
  DOMAIN_PATH="$BASE_PATH/domain"
  DOMAIN_MODULE_REPO_PATH="$DOMAIN_PATH/${MODULE_NAME_SNAKE}_repository"
  FILE_DOMAIN_MODULE_REPO="$DOMAIN_MODULE_REPO_PATH/${MODULE_NAME_SNAKE}_repository.dart"
  DOMAIN_MODULE_USECASE_BASE_PATH="$DOMAIN_PATH/${MODULE_NAME_SNAKE}_usecase"
  DOMAIN_FEATURE_USECASE_PATH="$DOMAIN_MODULE_USECASE_BASE_PATH/${FEATURE_NAME_SNAKE}_usecase"
  FILE_DOMAIN_FEATURE_USECASE="$DOMAIN_FEATURE_USECASE_PATH/${FEATURE_NAME_SNAKE}_usecase.dart"
  PRESENTATION_PATH="$BASE_PATH/presentation"
  PRES_UI_PATH="$PRESENTATION_PATH/Ui"
  PRES_UI_SCREENS_PATH="$PRES_UI_PATH/screens"
  FILE_PRES_FEATURE_SCREEN_VIEW="$PRES_UI_SCREENS_PATH/${FEATURE_NAME_SNAKE}_screen_view.dart"
  PRES_UI_WIDGET_PATH="$PRES_UI_PATH/widget"
  PRES_CUBITS_BASE_PATH="$PRESENTATION_PATH/cubits"
  PRES_FEATURE_CUBIT_PATH="$PRES_CUBITS_BASE_PATH/${FEATURE_NAME_SNAKE}"
  FILE_PRES_FEATURE_CUBIT="$PRES_FEATURE_CUBIT_PATH/${FEATURE_NAME_SNAKE}_cubit.dart"
  FILE_PRES_FEATURE_CUBIT_STATE="$PRES_FEATURE_CUBIT_PATH/${FEATURE_NAME_SNAKE}_state.dart"

  # --- Create Directory Structure ---
  echo "Creating directories..."
  mkdir -p "$DATA_MODULE_REPO_PATH" "$DATA_MODELS_FEATURE_PATH" "$DATA_REMOTE_PATH" "$DI_PATH" "$DOMAIN_MODULE_REPO_PATH" "$DOMAIN_FEATURE_USECASE_PATH" "$PRES_UI_SCREENS_PATH" "$PRES_UI_WIDGET_PATH" "$PRES_FEATURE_CUBIT_PATH"
  echo "Directories created."
  echo ""

  # --- Create Files by Rendering Templates ---
  echo "Creating files from templates..."
  
  local templates_dir="${SCRIPT_DIR}/src/templates"
  
  render_template "${templates_dir}/lib_main.template"           "$FILE_LIB_MODULE_MAIN"
  render_template "${templates_dir}/router.template"             "$FILE_LIB_MODULE_ROUTER"
  render_template "${templates_dir}/repository.template"         "$FILE_DOMAIN_MODULE_REPO"
  render_template "${templates_dir}/repository_impl.template"    "$FILE_DATA_MODULE_REPO_IMPL"
  render_template "${templates_dir}/remote_data_source.template" "$FILE_DATA_MODULE_REMOTE_SOURCE"
  render_template "${templates_dir}/di.template"                 "$FILE_DI_MODULE_MAIN"
  render_template "${templates_dir}/request.template"            "$FILE_DATA_FEATURE_REQUEST"
  render_template "${templates_dir}/request_model.template"      "$FILE_DATA_FEATURE_REQUEST_MODEL"
  render_template "${templates_dir}/response_model.template"     "$FILE_DATA_FEATURE_RESPONSE_MODEL"
  render_template "${templates_dir}/usecase.template"            "$FILE_DOMAIN_FEATURE_USECASE"
  render_template "${templates_dir}/state.template"              "$FILE_PRES_FEATURE_CUBIT_STATE"
  render_template "${templates_dir}/cubit.template"              "$FILE_PRES_FEATURE_CUBIT"
  render_template "${templates_dir}/view.template"               "$FILE_PRES_FEATURE_SCREEN_VIEW"
  
  echo ""
  echo "✅ Flutter module '$MODULE_NAME_SNAKE' and initial feature '$FEATURE_NAME_SNAKE' created successfully."
  cd ..
  echo "Returned to: $PWD"
}