#!/bin/bash

create_feature_directories() {
  local feature_type="$1"
  
  echo "Creating new directories for feature '$FEATURE_NAME_SNAKE'..."
  
  # Type 1 (Full) or 2 (Logic Only): Create Data and Domain
  if [[ "$feature_type" == "1" || "$feature_type" == "2" ]]; then
    mkdir -p "$DATA_MODULE_REPO_PATH" "$DATA_MODELS_REQUEST_PATH" "$DATA_MODELS_RESPONSE_PATH" "$DATA_REMOTE_PATH" "$DI_PATH" "$DOMAIN_MODULE_REPO_PATH" "$DOMAIN_FEATURE_USECASE_PATH" "$DOMAIN_ENTITIES_PATH"
  fi
    
  # Type 1 (Full) or 3 (UI Only): Create Presentation
  if [[ "$feature_type" == "1" || "$feature_type" == "3" ]]; then
    mkdir -p "$PRES_FEATURE_CUBIT_PATH"
  fi
  
  echo "New directories created."
  echo "Directories are ready."
  echo ""
}

generate_feature_files() {
  local feature_type="$1"
  local templates_dir="${SCRIPT_DIR}/src/templates"
  
  echo "Creating new files for feature '$FEATURE_NAME_SNAKE'..."
  
  # Type 1 (Full) or 2 (Logic Only): Generate Data and Domain files
  if [[ "$feature_type" == "1" || "$feature_type" == "2" ]]; then
    render_template "${templates_dir}/entity.template"           "$FILE_DOMAIN_FEATURE_ENTITY"
    render_template "${templates_dir}/request.template"          "$FILE_DATA_FEATURE_REQUEST"
    render_template "${templates_dir}/request_model.template"    "$FILE_DATA_FEATURE_REQUEST_MODEL"
    render_template "${templates_dir}/response_model.template"   "$FILE_DATA_FEATURE_RESPONSE_MODEL"
    render_template "${templates_dir}/response.template"         "$FILE_DATA_FEATURE_RESPONSE"
    render_template "${templates_dir}/usecase.template"          "$FILE_DOMAIN_FEATURE_USECASE"
  fi
  
  # Type 1 (Full) or 3 (UI Only): Generate Presentation files
  if [[ "$feature_type" == "1" || "$feature_type" == "3" ]]; then
    if [[ "$feature_type" == "1" ]]; then
      # Full Feature: Standard Cubit with UseCase dependency
      render_template "${templates_dir}/cubit.template"            "$FILE_PRES_FEATURE_CUBIT"
      render_template "${templates_dir}/state.template"            "$FILE_PRES_FEATURE_CUBIT_STATE"
    else
      # UI Only: Simple Cubit without dependencies
      render_template "${templates_dir}/feature_templates/cubit_ui.template"     "$FILE_PRES_FEATURE_CUBIT"
      render_template "${templates_dir}/feature_templates/state_ui.template"     "$FILE_PRES_FEATURE_CUBIT_STATE"
    fi
    
    UI_BODY_CODE=$(run_ai_generation "$FEATURE_NAME_PASCAL")
    render_template "${templates_dir}/view.template"               "$FILE_PRES_FEATURE_SCREEN_VIEW"
  fi
  echo "New files created."
  echo ""
}

modify_shared_files() {
  local feature_type="$1"
  local method_templates_dir="${SCRIPT_DIR}/src/templates/feature_templates"
  
  echo "Modifying shared module files to add '$FEATURE_NAME_SNAKE'..."
  
  # --- Define Anchors ---
  local ANCHOR_MODEL_IMPORT="// [Adding_new_model_import_here_dont_remove_this_command_!!!]"
  local ANCHOR_REPO_METHOD="// [Adding_new_repo_method_here_dont_remove_this_command_!!!]"
  local ANCHOR_REPO_IMPL_METHOD="// [Adding_new_repo_impl_method_here_dont_remove_this_command_!!!]"
  local ANCHOR_DATASOURCE_METHOD="// [Adding_new_datasource_method_here_dont_remove_this_command_!!!]"
  local ANCHOR_DATASOURCE_IMPL_METHOD="// [Adding_new_datasource_impl_method_here_dont_remove_this_command_!!!]"
  local ANCHOR_DI_IMPORT="// [Adding_new_di_import_here_dont_remove_this_command_!!!]"
  local ANCHOR_DI_DEPENDENCY="// [Adding_new_di_dependency_here_dont_remove_this_command_!!!]"
  local ANCHOR_ROUTER_IMPORT="// [Adding_new_router_import_here_dont_remove_this_command_!!!]"
  local ANCHOR_ROUTER_CASE="// [Adding_new_router_case_here_dont_remove_this_command_!!!]"
  local ANCHOR_ROUTER_ID="// [Adding_new_router_screen_id_here_dont_remove_this_command_!!!]"

  # --- Prepare code blocks ---
  local NEW_MODEL_IMPORT_DOMAIN_REPO="import '../entities/${FEATURE_NAME_SNAKE}/${FEATURE_NAME_SNAKE}_entity.dart';
import '../../data/models/${FEATURE_NAME_SNAKE}/request/${FEATURE_NAME_SNAKE}_request_model.dart';"
  local NEW_MODEL_IMPORT_REPO_IMPL="import '../../domain/entities/${FEATURE_NAME_SNAKE}/${FEATURE_NAME_SNAKE}_entity.dart';
import '../models/${FEATURE_NAME_SNAKE}/request/${FEATURE_NAME_SNAKE}_request_model.dart';"
  local NEW_MODEL_IMPORT_DATASOURCE="import '../models/${FEATURE_NAME_SNAKE}/request/${FEATURE_NAME_SNAKE}_request.dart';
import '../models/${FEATURE_NAME_SNAKE}/request/${FEATURE_NAME_SNAKE}_request_model.dart';
import '../models/${FEATURE_NAME_SNAKE}/response/${FEATURE_NAME_SNAKE}_response.dart';"
  local NEW_REPO_METHOD="  Future<Either<Failure, ${FEATURE_NAME_PASCAL}Entity>> ${FEATURE_NAME_CAMEL}({required ${FEATURE_NAME_PASCAL}RequestModel requestModel});"
  local NEW_DATASOURCE_METHOD="  Future<${FEATURE_NAME_PASCAL}Response> ${FEATURE_NAME_CAMEL}(${FEATURE_NAME_PASCAL}RequestModel requestModel);"
  local NEW_REPO_IMPL_METHOD=$(render_partial "${method_templates_dir}/repository_impl_method.template")
  local NEW_DATASOURCE_IMPL_METHOD=$(render_partial "${method_templates_dir}/datasource_impl_method.template")

  # --- Type 1 (Full) or 2 (Logic Only): Modify Data and Domain layers ---
  if [[ "$feature_type" == "1" || "$feature_type" == "2" ]]; then
    insert_before "$FILE_DOMAIN_MODULE_REPO" "$ANCHOR_MODEL_IMPORT" "$NEW_MODEL_IMPORT_DOMAIN_REPO"
    insert_before "$FILE_DOMAIN_MODULE_REPO" "$ANCHOR_REPO_METHOD" "$NEW_REPO_METHOD"
    
    insert_before "$FILE_DATA_MODULE_REPO_IMPL" "$ANCHOR_MODEL_IMPORT" "$NEW_MODEL_IMPORT_REPO_IMPL"
    insert_before "$FILE_DATA_MODULE_REPO_IMPL" "$ANCHOR_REPO_IMPL_METHOD" "$NEW_REPO_IMPL_METHOD"
    
    insert_before "$FILE_DATA_MODULE_REMOTE_SOURCE" "$ANCHOR_MODEL_IMPORT" "$NEW_MODEL_IMPORT_DATASOURCE"
    insert_before "$FILE_DATA_MODULE_REMOTE_SOURCE" "$ANCHOR_DATASOURCE_METHOD" "$NEW_DATASOURCE_METHOD"
    insert_before "$FILE_DATA_MODULE_REMOTE_SOURCE" "$ANCHOR_DATASOURCE_IMPL_METHOD" "$NEW_DATASOURCE_IMPL_METHOD"
  fi

  # --- Type 1 (Full) or 3 (UI Only): Modify Presentation layer files ---
  if [[ "$feature_type" == "1" || "$feature_type" == "3" ]]; then
    echo "Adding Presentation Layer (UI) modifications..."
    
    local NEW_DI_IMPORT=""
    local NEW_DI_DEPENDENCY=""

    if [[ "$feature_type" == "1" ]]; then
      # Full Feature: Import UseCase and Cubit, Register both
      NEW_DI_IMPORT="import '../domain/${MODULE_NAME_SNAKE}_usecase/${FEATURE_NAME_SNAKE}_usecase/${FEATURE_NAME_SNAKE}_usecase.dart';
import '../presentation/cubits/${FEATURE_NAME_SNAKE}/${FEATURE_NAME_SNAKE}_cubit.dart';"
      NEW_DI_DEPENDENCY="..registerFactory(() => ${FEATURE_NAME_PASCAL}UseCase(repository: di()))
       ..registerFactory(() => ${FEATURE_NAME_PASCAL}Cubit(di()))"
    else
      # UI Only: Import Cubit only, Register Cubit (no args)
      NEW_DI_IMPORT="import '../presentation/cubits/${FEATURE_NAME_SNAKE}/${FEATURE_NAME_SNAKE}_cubit.dart';"
      NEW_DI_DEPENDENCY="..registerFactory(() => ${FEATURE_NAME_PASCAL}Cubit())"
    fi

    local NEW_ROUTER_IMPORT="import 'presentation/Ui/screens/${FEATURE_NAME_SNAKE}_screen_view.dart';"
    local NEW_SCREEN_ID="  static const String ${FEATURE_NAME_CAMEL}Screen = ${FEATURE_NAME_PASCAL}ScreenView.id;"
    local NEW_ROUTE_CASE=$(render_partial "${method_templates_dir}/router_case.template")

    # Modify DI File
    insert_before "$FILE_DI_MODULE_MAIN" "$ANCHOR_DI_IMPORT" "$NEW_DI_IMPORT"
    insert_before "$FILE_DI_MODULE_MAIN" "$ANCHOR_DI_DEPENDENCY" "      $NEW_DI_DEPENDENCY"
    
    # Modify Router File
    insert_before "$FILE_LIB_MODULE_ROUTER" "$ANCHOR_ROUTER_IMPORT" "$NEW_ROUTER_IMPORT"
    insert_before "$FILE_LIB_MODULE_ROUTER" "$ANCHOR_ROUTER_CASE" "$NEW_ROUTE_CASE"
    insert_before "$FILE_LIB_MODULE_ROUTER" "$ANCHOR_ROUTER_ID" "$NEW_SCREEN_ID"
  
  elif [[ "$feature_type" == "2" ]]; then
    # Logic Only: Register UseCase only
    echo "Skipping Presentation Layer (UI) modifications..."
    local NEW_DI_IMPORT="import '../domain/${MODULE_NAME_SNAKE}_usecase/${FEATURE_NAME_SNAKE}_usecase/${FEATURE_NAME_SNAKE}_usecase.dart';"
    local NEW_DI_DEPENDENCY="..registerFactory(() => ${FEATURE_NAME_PASCAL}UseCase(repository: di()))"

    insert_before "$FILE_DI_MODULE_MAIN" "$ANCHOR_DI_IMPORT" "$NEW_DI_IMPORT"
    insert_before "$FILE_DI_MODULE_MAIN" "$ANCHOR_DI_DEPENDENCY" "      $NEW_DI_DEPENDENCY"
  fi
}
