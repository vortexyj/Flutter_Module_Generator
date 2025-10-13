#!/bin/bash

run_add_feature_mode() {
  echo ""
  echo "--- Mode 2: Add New Feature to Existing Module ---"

  MODULE_NAME_SNAKE=$(basename "$PWD")
  echo "Operating in module: $MODULE_NAME_SNAKE"

  # if [ ! -f "pubspec.yaml" ] || [ ! -d "lib" ]; then echo "Error: This does not appear to be the root of a Flutter module."; exit 1; fi

  echo "Enter the name for the NEW feature to add to '$MODULE_NAME_SNAKE':"
  read FEATURE_NAME_SNAKE
  read -p "Does this new feature include a UI (Screen, Cubit, Router entry)? (y/n): " HAS_UI

  if [ -z "$FEATURE_NAME_SNAKE" ]; then echo "Error: New feature name cannot be empty."; exit 1; fi
  
  MODULE_NAME_PASCAL=$(snake_to_pascal_case "$MODULE_NAME_SNAKE")
  MODULE_NAME_CAMEL=$(pascal_to_camel_case "$MODULE_NAME_PASCAL")
  FEATURE_NAME_PASCAL=$(snake_to_pascal_case "$FEATURE_NAME_SNAKE")
  FEATURE_NAME_CAMEL=$(pascal_to_camel_case "$FEATURE_NAME_PASCAL")
  BASE_PATH="./lib"

  echo ""
  echo "Adding feature '$FEATURE_NAME_SNAKE' to module '$MODULE_NAME_SNAKE'..."
  echo ""

  # --- Define Paths for NEW files and SHARED files (with Entity) ---
  local templates_dir="${SCRIPT_DIR}/src/templates"
  local method_templates_dir="${SCRIPT_DIR}/src/templates/method_templates"
  FILE_LIB_MODULE_ROUTER="$BASE_PATH/${MODULE_NAME_SNAKE}_screen_router.dart"
  DATA_PATH="$BASE_PATH/data"
  DATA_MODULE_REPO_PATH="$DATA_PATH/${MODULE_NAME_SNAKE}_repository"
  FILE_DATA_MODULE_REPO_IMPL="$DATA_MODULE_REPO_PATH/${MODULE_NAME_SNAKE}_repository_impl.dart"
  DATA_MODELS_STATIC_PATH="$DATA_PATH/models"
  DATA_MODELS_FEATURE_PATH="$DATA_MODELS_STATIC_PATH/${FEATURE_NAME_SNAKE}"
  DATA_MODELS_REQUEST_PATH="$DATA_MODELS_FEATURE_PATH/request"
  DATA_MODELS_RESPONSE_PATH="$DATA_MODELS_FEATURE_PATH/response"
  FILE_DATA_FEATURE_REQUEST="$DATA_MODELS_REQUEST_PATH/${FEATURE_NAME_SNAKE}_request.dart"
  FILE_DATA_FEATURE_REQUEST_MODEL="$DATA_MODELS_REQUEST_PATH/${FEATURE_NAME_SNAKE}_request_model.dart"
  FILE_DATA_FEATURE_RESPONSE_MODEL="$DATA_MODELS_RESPONSE_PATH/${FEATURE_NAME_SNAKE}_response_model.dart"
  DATA_REMOTE_PATH="$DATA_PATH/remote_data_source"
  FILE_DATA_MODULE_REMOTE_SOURCE="$DATA_REMOTE_PATH/${MODULE_NAME_SNAKE}_remote_data_source.dart"
  DI_PATH="$BASE_PATH/di"
  FILE_DI_MODULE_MAIN="$DI_PATH/${MODULE_NAME_SNAKE}_di.dart"
  DOMAIN_PATH="$BASE_PATH/Domain"

  # **FIX**: Ensure Entity paths are defined for Mode 2
  DOMAIN_ENTITIES_PATH="$DOMAIN_PATH/entities/${FEATURE_NAME_SNAKE}"
  FILE_DOMAIN_FEATURE_ENTITY="$DOMAIN_ENTITIES_PATH/${FEATURE_NAME_SNAKE}_entity.dart"

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

  # --- Create NEW Directories ---
  echo "Creating new directories for feature '$FEATURE_NAME_SNAKE'..."
  # Always create data and domain directories
  mkdir -p "$DATA_MODULE_REPO_PATH" "$DATA_MODELS_REQUEST_PATH" "$DATA_MODELS_RESPONSE_PATH" "$DATA_REMOTE_PATH" "$DI_PATH" "$DOMAIN_MODULE_REPO_PATH" "$DOMAIN_FEATURE_USECASE_PATH" "$DOMAIN_ENTITIES_PATH"
    
  # Only create presentation directories if the user said yes
  if [[ "$HAS_UI" == "y" || "$HAS_UI" == "Y" ]]; then
    mkdir -p "$PRES_FEATURE_CUBIT_PATH"
  fi
  echo "New directories created."
  echo "Directories are ready."
  echo ""

  # --- **FIXED**: Create and Populate NEW Files, including Entity ---
  echo "Creating new files for feature '$FEATURE_NAME_SNAKE'..."
  
  render_template "${templates_dir}/entity.template"           "$FILE_DOMAIN_FEATURE_ENTITY"
  render_template "${templates_dir}/request.template"          "$FILE_DATA_FEATURE_REQUEST"
  render_template "${templates_dir}/request_model.template"    "$FILE_DATA_FEATURE_REQUEST_MODEL"
  render_template "${templates_dir}/response_model.template"   "$FILE_DATA_FEATURE_RESPONSE_MODEL"
  render_template "${templates_dir}/usecase.template"          "$FILE_DOMAIN_FEATURE_USECASE"
  if [[ "$HAS_UI" == "y" || "$HAS_UI" == "Y" ]]; then
  render_template "${templates_dir}/state.template"            "$FILE_PRES_FEATURE_CUBIT_STATE"
  render_template "${templates_dir}/cubit.template"            "$FILE_PRES_FEATURE_CUBIT"
  
  UI_BODY_CODE=$(run_ai_generation "$FEATURE_NAME_PASCAL")
  render_template "${templates_dir}/view.template"               "$FILE_PRES_FEATURE_SCREEN_VIEW"
  fi
  echo "New files created."
  echo ""

# --- Modify Existing Shared Files ---
  echo "Modifying shared module files to add '$FEATURE_NAME_SNAKE'..."
  
  # --- Define Anchors ---
  ANCHOR_MODEL_IMPORT="// [Adding_new_model_import_here_dont_remove_this_command_!!!]"
  ANCHOR_REPO_METHOD="// [Adding_new_repo_method_here_dont_remove_this_command_!!!]"
  ANCHOR_REPO_IMPL_METHOD="// [Adding_new_repo_impl_method_here_dont_remove_this_command_!!!]"
  ANCHOR_DATASOURCE_METHOD="// [Adding_new_datasource_method_here_dont_remove_this_command_!!!]"
  ANCHOR_DATASOURCE_IMPL_METHOD="// [Adding_new_datasource_impl_method_here_dont_remove_this_command_!!!]"
  ANCHOR_DI_IMPORT="// [Adding_new_di_import_here_dont_remove_this_command_!!!]"
  ANCHOR_DI_DEPENDENCY="// [Adding_new_di_dependency_here_dont_remove_this_command_!!!]"
  ANCHOR_ROUTER_IMPORT="// [Adding_new_router_import_here_dont_remove_this_command_!!!]"
  ANCHOR_ROUTER_CASE="// [Adding_new_router_case_here_dont_remove_this_command_!!!]"
  ANCHOR_ROUTER_ID="// [Adding_new_router_screen_id_here_dont_remove_this_command_!!!]"

  # --- Prepare code blocks that are ALWAYS inserted ---
  NEW_MODEL_IMPORT_DOMAIN_REPO="import '../entities/${FEATURE_NAME_SNAKE}/${FEATURE_NAME_SNAKE}_entity.dart';
import '../../data/models/${FEATURE_NAME_SNAKE}/request/${FEATURE_NAME_SNAKE}_request_model.dart';"
  NEW_MODEL_IMPORT_REPO_IMPL="import '../../domain/entities/${FEATURE_NAME_SNAKE}/${FEATURE_NAME_SNAKE}_entity.dart';
import '../models/${FEATURE_NAME_SNAKE}/request/${FEATURE_NAME_SNAKE}_request_model.dart';"
  NEW_MODEL_IMPORT_DATASOURCE="import '../../domain/entities/${FEATURE_NAME_SNAKE}/${FEATURE_NAME_SNAKE}_entity.dart';
import '../models/${FEATURE_NAME_SNAKE}/request/${FEATURE_NAME_SNAKE}_request.dart';
import '../models/${FEATURE_NAME_SNAKE}/request/${FEATURE_NAME_SNAKE}_request_model.dart';
import '../models/${FEATURE_NAME_SNAKE}/response/${FEATURE_NAME_SNAKE}_response_model.dart';"
  NEW_REPO_METHOD="  Future<Either<Failure, ${FEATURE_NAME_PASCAL}Entity>> ${FEATURE_NAME_SNAKE}({required ${FEATURE_NAME_PASCAL}RequestModel requestModel});"
  NEW_DATASOURCE_METHOD="  Future<${FEATURE_NAME_PASCAL}Entity> ${FEATURE_NAME_SNAKE}(${FEATURE_NAME_PASCAL}RequestModel requestModel);"
  NEW_REPO_IMPL_METHOD=$(render_partial "${method_templates_dir}/repository_impl_method.template")
  NEW_DATASOURCE_IMPL_METHOD=$(render_partial "${method_templates_dir}/datasource_impl_method.template")

  # --- Always modify the Data and Domain layers ---
  insert_before "$FILE_DOMAIN_MODULE_REPO" "$ANCHOR_MODEL_IMPORT" "$NEW_MODEL_IMPORT_DOMAIN_REPO"
  insert_before "$FILE_DOMAIN_MODULE_REPO" "$ANCHOR_REPO_METHOD" "$NEW_REPO_METHOD"
  
  insert_before "$FILE_DATA_MODULE_REPO_IMPL" "$ANCHOR_MODEL_IMPORT" "$NEW_MODEL_IMPORT_REPO_IMPL"
  insert_before "$FILE_DATA_MODULE_REPO_IMPL" "$ANCHOR_REPO_IMPL_METHOD" "$NEW_REPO_IMPL_METHOD"
  
  insert_before "$FILE_DATA_MODULE_REMOTE_SOURCE" "$ANCHOR_MODEL_IMPORT" "$NEW_MODEL_IMPORT_DATASOURCE"
  insert_before "$FILE_DATA_MODULE_REMOTE_SOURCE" "$ANCHOR_DATASOURCE_METHOD" "$NEW_DATASOURCE_METHOD"
  insert_before "$FILE_DATA_MODULE_REMOTE_SOURCE" "$ANCHOR_DATASOURCE_IMPL_METHOD" "$NEW_DATASOURCE_IMPL_METHOD"

  # --- Conditionally modify Presentation layer files ---
  if [[ "$HAS_UI" == "y" || "$HAS_UI" == "Y" ]]; then
    echo "Adding Presentation Layer (UI) modifications..."
    # Prepare code blocks for UI
    NEW_DI_IMPORT="import '../domain/${MODULE_NAME_SNAKE}_usecase/${FEATURE_NAME_SNAKE}_usecase/${FEATURE_NAME_SNAKE}_usecase.dart';
import '../presentation/cubits/${FEATURE_NAME_SNAKE}/${FEATURE_NAME_SNAKE}_cubit.dart';"
    NEW_DI_DEPENDENCY="..registerFactory(() => ${FEATURE_NAME_PASCAL}UseCase(repository: di()))
       ..registerFactory(() => ${FEATURE_NAME_PASCAL}Cubit(di(), di()))"
    NEW_ROUTER_IMPORT="import 'presentation/Ui/screens/${FEATURE_NAME_SNAKE}_screen_view.dart';"
    NEW_SCREEN_ID="  static const String ${FEATURE_NAME_CAMEL}Screen = ${FEATURE_NAME_PASCAL}ScreenView.id;"
    NEW_ROUTE_CASE=$(render_partial "${method_templates_dir}/router_case.template")

    # Modify DI File with ALL dependencies (UseCase and Cubit)
    insert_before "$FILE_DI_MODULE_MAIN" "$ANCHOR_DI_IMPORT" "$NEW_DI_IMPORT"
    insert_before "$FILE_DI_MODULE_MAIN" "$ANCHOR_DI_DEPENDENCY" "      $NEW_DI_DEPENDENCY"
    
    # Modify Router File
    insert_before "$FILE_LIB_MODULE_ROUTER" "$ANCHOR_ROUTER_IMPORT" "$NEW_ROUTER_IMPORT"
    insert_before "$FILE_LIB_MODULE_ROUTER" "$ANCHOR_ROUTER_CASE" "$NEW_ROUTE_CASE"
    insert_before "$FILE_LIB_MODULE_ROUTER" "$ANCHOR_ROUTER_ID" "$NEW_SCREEN_ID"
  else
    echo "Skipping Presentation Layer (UI) modifications..."
    # Only register the UseCase in the DI file, not the Cubit
    NEW_DI_IMPORT="import '../domain/${MODULE_NAME_SNAKE}_usecase/${FEATURE_NAME_SNAKE}_usecase/${FEATURE_NAME_SNAKE}_usecase.dart';"
    NEW_DI_DEPENDENCY="..registerFactory(() => ${FEATURE_NAME_PASCAL}UseCase(repository: di()))"

    insert_before "$FILE_DI_MODULE_MAIN" "$ANCHOR_DI_IMPORT" "$NEW_DI_IMPORT"
    insert_before "$FILE_DI_MODULE_MAIN" "$ANCHOR_DI_DEPENDENCY" "      $NEW_DI_DEPENDENCY"
  fi

  echo ""
  echo "✅ New feature '$FEATURE_NAME_SNAKE' added successfully to module '$MODULE_NAME_SNAKE'."
}