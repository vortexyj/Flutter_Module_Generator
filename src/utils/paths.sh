#!/bin/bash

# Defines all the standard file paths used by the module creator.
# Arguments:
#   $1: MODULE_NAME_SNAKE
#   $2: FEATURE_NAME_SNAKE
#   $3: BASE_PATH (optional, defaults to "./lib")
define_module_paths() {
  local module_name_snake="$1"
  local feature_name_snake="$2"
  local base_path="${3:-./lib}"

  # Derived names
  local module_name_pascal=$(snake_to_pascal_case "$module_name_snake")
  local module_name_camel=$(pascal_to_camel_case "$module_name_pascal")
  local feature_name_pascal=$(snake_to_pascal_case "$feature_name_snake")
  local feature_name_camel=$(pascal_to_camel_case "$feature_name_pascal")

  # Export derived names so they are available in the calling scope
  export MODULE_NAME_PASCAL="$module_name_pascal"
  export MODULE_NAME_CAMEL="$module_name_camel"
  export FEATURE_NAME_PASCAL="$feature_name_pascal"
  export FEATURE_NAME_CAMEL="$feature_name_camel"

  # --- Define Paths ---
  export FILE_LIB_MODULE_MAIN="$base_path/${module_name_snake}.dart"
  export FILE_LIB_MODULE_ROUTER="$base_path/${module_name_snake}_screen_router.dart"
  
  export DATA_PATH="$base_path/data"
  export DATA_MODULE_REPO_PATH="$DATA_PATH/${module_name_snake}_repository"
  export FILE_DATA_MODULE_REPO_IMPL="$DATA_MODULE_REPO_PATH/${module_name_snake}_repository_impl.dart"
  
  export DATA_MODELS_STATIC_PATH="$DATA_PATH/models"
  export DATA_MODELS_FEATURE_PATH="$DATA_MODELS_STATIC_PATH/${feature_name_snake}"
  export DATA_MODELS_REQUEST_PATH="$DATA_MODELS_FEATURE_PATH/request"
  export DATA_MODELS_RESPONSE_PATH="$DATA_MODELS_FEATURE_PATH/response"
  
  export FILE_DATA_FEATURE_REQUEST="$DATA_MODELS_REQUEST_PATH/${feature_name_snake}_request.dart"
  export FILE_DATA_FEATURE_REQUEST_MODEL="$DATA_MODELS_REQUEST_PATH/${feature_name_snake}_request_model.dart"
  export FILE_DATA_FEATURE_RESPONSE="$DATA_MODELS_RESPONSE_PATH/${feature_name_snake}_response.dart"
  export FILE_DATA_FEATURE_RESPONSE_MODEL="$DATA_MODELS_RESPONSE_PATH/${feature_name_snake}_response_model.dart"
  
  export DATA_REMOTE_PATH="$DATA_PATH/remote_data_source"
  export FILE_DATA_MODULE_REMOTE_SOURCE="$DATA_REMOTE_PATH/${module_name_snake}_remote_data_source.dart"
  
  export DI_PATH="$base_path/di"
  export FILE_DI_MODULE_MAIN="$DI_PATH/${module_name_snake}_di.dart"
  
  export DOMAIN_PATH="$base_path/domain"
  export DOMAIN_ENTITIES_PATH="$DOMAIN_PATH/entities/${feature_name_snake}"
  export FILE_DOMAIN_FEATURE_ENTITY="$DOMAIN_ENTITIES_PATH/${feature_name_snake}_entity.dart"
  
  export DOMAIN_MODULE_REPO_PATH="$DOMAIN_PATH/${module_name_snake}_repository"
  export FILE_DOMAIN_MODULE_REPO="$DOMAIN_MODULE_REPO_PATH/${module_name_snake}_repository.dart"
  
  export DOMAIN_MODULE_USECASE_BASE_PATH="$DOMAIN_PATH/${module_name_snake}_usecase"
  export DOMAIN_FEATURE_USECASE_PATH="$DOMAIN_MODULE_USECASE_BASE_PATH/${feature_name_snake}_usecase"
  export FILE_DOMAIN_FEATURE_USECASE="$DOMAIN_FEATURE_USECASE_PATH/${feature_name_snake}_usecase.dart"
  
  export PRESENTATION_PATH="$base_path/presentation"
  export PRES_UI_PATH="$PRESENTATION_PATH/Ui"
  export PRES_UI_SCREENS_PATH="$PRES_UI_PATH/screens"
  export FILE_PRES_FEATURE_SCREEN_VIEW="$PRES_UI_SCREENS_PATH/${feature_name_snake}_screen_view.dart"
  
  export PRES_UI_WIDGET_PATH="$PRES_UI_PATH/widget"
  
  export PRES_CUBITS_BASE_PATH="$PRESENTATION_PATH/cubits"
  export PRES_FEATURE_CUBIT_PATH="$PRES_CUBITS_BASE_PATH/${feature_name_snake}"
  export FILE_PRES_FEATURE_CUBIT="$PRES_FEATURE_CUBIT_PATH/${feature_name_snake}_cubit.dart"
  export FILE_PRES_FEATURE_CUBIT_STATE="$PRES_FEATURE_CUBIT_PATH/${feature_name_snake}_state.dart"
}
