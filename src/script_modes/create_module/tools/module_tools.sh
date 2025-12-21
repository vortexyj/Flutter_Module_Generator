#!/bin/bash

create_flutter_package() {
  local module_name="$1"
  
  echo "Creating Flutter package (module): $module_name..."
  flutter create --template=package "$module_name"

  if [ ! -d "$module_name" ] || [ ! -f "$module_name/pubspec.yaml" ]; then 
    echo "Error: Failed to create module '$module_name'."
    exit 1
  fi
  echo "Module '$module_name' created successfully."
  echo ""
}

enter_module_directory() {
  local module_name="$1"
  echo "Changing directory to '$module_name'..."
  cd "$module_name"
  if [ $? -ne 0 ]; then echo "Error: Failed to change directory to '$module_name'."; exit 1; fi
  echo "Now operating inside module: $PWD"
  echo ""
}

update_pubspec_and_clean() {
  local module_name="$1"
  echo "Updating pubspec.yaml and cleaning project files..."
  
  local pubspec_file="./pubspec.yaml"
  local test_file_path="./test/${module_name}_test.dart"
  
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

  insert_after "$pubspec_file" "sdk: flutter" "$DEPENDENCIES"
  echo "     [SUCCESS] Dependencies added to pubspec.yaml."
  
  if [ -f "$test_file_path" ]; then
    echo "// TODO: Implement module tests." > "$test_file_path"
    echo "     [SUCCESS] Cleaned default test file."
  fi
  
  echo "Running 'flutter pub get' in the new module..."
  flutter pub get
  echo ""
}

create_module_directories() {
  echo "Creating directories..."
  mkdir -p "$DATA_MODULE_REPO_PATH" "$DATA_MODELS_REQUEST_PATH" "$DATA_MODELS_RESPONSE_PATH" "$DATA_REMOTE_PATH" "$DI_PATH" "$DOMAIN_MODULE_REPO_PATH" "$DOMAIN_FEATURE_USECASE_PATH" "$PRES_UI_SCREENS_PATH" "$PRES_UI_WIDGET_PATH" "$PRES_FEATURE_CUBIT_PATH" "$DOMAIN_ENTITIES_PATH"
  echo "Directories created."
  echo ""
}

generate_module_files() {
  local feature_name_pascal="$1"
  local templates_dir="${SCRIPT_DIR}/src/templates"
  
  echo "Creating files from templates..."
  
  render_template "${templates_dir}/lib_main.template"           "$FILE_LIB_MODULE_MAIN"
  render_template "${templates_dir}/router.template"             "$FILE_LIB_MODULE_ROUTER"
  render_template "${templates_dir}/repository.template"         "$FILE_DOMAIN_MODULE_REPO"
  render_template "${templates_dir}/repository_impl.template"    "$FILE_DATA_MODULE_REPO_IMPL"
  render_template "${templates_dir}/remote_data_source.template" "$FILE_DATA_MODULE_REMOTE_SOURCE"
  render_template "${templates_dir}/di.template"                 "$FILE_DI_MODULE_MAIN"
  render_template "${templates_dir}/request.template"            "$FILE_DATA_FEATURE_REQUEST"
  render_template "${templates_dir}/request_model.template"      "$FILE_DATA_FEATURE_REQUEST_MODEL"
  render_template "${templates_dir}/response.template"           "$FILE_DATA_FEATURE_RESPONSE"
  render_template "${templates_dir}/response_model.template"     "$FILE_DATA_FEATURE_RESPONSE_MODEL"
  render_template "${templates_dir}/entity.template"             "$FILE_DOMAIN_FEATURE_ENTITY"
  render_template "${templates_dir}/usecase.template"            "$FILE_DOMAIN_FEATURE_USECASE"
  render_template "${templates_dir}/state.template"              "$FILE_PRES_FEATURE_CUBIT_STATE"
  render_template "${templates_dir}/cubit.template"              "$FILE_PRES_FEATURE_CUBIT"
  
  # Special Handling for Screen View with AI Integration
  UI_BODY_CODE=$(run_ai_generation "$feature_name_pascal")
  render_template "${templates_dir}/view.template" "$FILE_PRES_FEATURE_SCREEN_VIEW"
  
  echo ""
}
