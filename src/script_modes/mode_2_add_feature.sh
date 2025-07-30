#!/bin/bash

run_add_feature_mode() {
  echo ""
  echo "--- Mode 2: Add New Feature to Existing Module ---"

  MODULE_NAME_SNAKE=$(basename "$PWD")
  echo "Operating in module: $MODULE_NAME_SNAKE"

  if [ ! -f "pubspec.yaml" ] || [ ! -d "lib" ]; then echo "Error: This does not appear to be the root of a Flutter module."; exit 1; fi

  echo "Enter the name for the NEW feature to add to '$MODULE_NAME_SNAKE':"
  read FEATURE_NAME_SNAKE

  if [ -z "$FEATURE_NAME_SNAKE" ]; then echo "Error: New feature name cannot be empty."; exit 1; fi
  
  MODULE_NAME_PASCAL=$(snake_to_pascal_case "$MODULE_NAME_SNAKE")
  FEATURE_NAME_PASCAL=$(snake_to_pascal_case "$FEATURE_NAME_SNAKE")
  FEATURE_NAME_CAMEL=$(pascal_to_camel_case "$FEATURE_NAME_PASCAL")
  BASE_PATH="./lib"

  echo ""
  echo "Adding feature '$FEATURE_NAME_SNAKE' to module '$MODULE_NAME_SNAKE'..."
  echo ""

  # --- Define Paths for NEW files and SHARED files ---
  FILE_LIB_MODULE_ROUTER="$BASE_PATH/${MODULE_NAME_SNAKE}_screen_router.dart"
  DATA_MODELS_FEATURE_PATH="$BASE_PATH/data/models/${FEATURE_NAME_SNAKE}"
  FILE_DATA_FEATURE_REQUEST="$DATA_MODELS_FEATURE_PATH/${FEATURE_NAME_SNAKE}_request.dart"
  FILE_DATA_FEATURE_REQUEST_MODEL="$DATA_MODELS_FEATURE_PATH/${FEATURE_NAME_SNAKE}_request_model.dart"
  FILE_DATA_FEATURE_RESPONSE_MODEL="$DATA_MODELS_FEATURE_PATH/${FEATURE_NAME_SNAKE}_response_model.dart"
  DOMAIN_FEATURE_USECASE_PATH="$BASE_PATH/domain/${MODULE_NAME_SNAKE}_usecase/${FEATURE_NAME_SNAKE}_usecase"
  FILE_DOMAIN_FEATURE_USECASE="$DOMAIN_FEATURE_USECASE_PATH/${FEATURE_NAME_SNAKE}_usecase.dart"
  PRES_FEATURE_CUBIT_PATH="$BASE_PATH/presentation/cubits/${FEATURE_NAME_SNAKE}"
  FILE_PRES_FEATURE_CUBIT="$PRES_FEATURE_CUBIT_PATH/${FEATURE_NAME_SNAKE}_cubit.dart"
  FILE_PRES_FEATURE_CUBIT_STATE="$PRES_FEATURE_CUBIT_PATH/${FEATURE_NAME_SNAKE}_state.dart"
  FILE_PRES_FEATURE_SCREEN_VIEW="$BASE_PATH/presentation/Ui/screens/${FEATURE_NAME_SNAKE}_screen_view.dart"
  FILE_DOMAIN_MODULE_REPO="$BASE_PATH/domain/${MODULE_NAME_SNAKE}_repository/${MODULE_NAME_SNAKE}_repository.dart"
  FILE_DATA_MODULE_REPO_IMPL="$BASE_PATH/data/${MODULE_NAME_SNAKE}_repository/${MODULE_NAME_SNAKE}_repository_impl.dart"
  FILE_DATA_MODULE_REMOTE_SOURCE="$BASE_PATH/data/remote_data_source/${MODULE_NAME_SNAKE}_remote_data_source.dart"
  FILE_DI_MODULE_MAIN="$BASE_PATH/di/${MODULE_NAME_SNAKE}_di.dart"

  # --- Create NEW Directories ---
  echo "Creating new directories for feature '$FEATURE_NAME_SNAKE'..."
  mkdir -p "$DATA_MODELS_FEATURE_PATH" "$DOMAIN_FEATURE_USECASE_PATH" "$PRES_FEATURE_CUBIT_PATH"
  echo "New directories created."
  echo ""

  # --- Create and Populate NEW Files for the new feature ---
  echo "Creating new files for feature '$FEATURE_NAME_SNAKE'..."
  local templates_dir="${SCRIPT_DIR}/src/templates"
  
  render_template "${templates_dir}/request.template"            "$FILE_DATA_FEATURE_REQUEST"
  render_template "${templates_dir}/request_model.template"      "$FILE_DATA_FEATURE_REQUEST_MODEL"
  render_template "${templates_dir}/response_model.template"     "$FILE_DATA_FEATURE_RESPONSE_MODEL"
  render_template "${templates_dir}/usecase.template"            "$FILE_DOMAIN_FEATURE_USECASE"
  render_template "${templates_dir}/state.template"              "$FILE_PRES_FEATURE_CUBIT_STATE"
  render_template "${templates_dir}/cubit.template"              "$FILE_PRES_FEATURE_CUBIT"
  render_template "${templates_dir}/view.template"               "$FILE_PRES_FEATURE_SCREEN_VIEW"
  
  echo "New files created."
  echo ""

  # --- Modify Existing Shared Files ---
  echo "Modifying shared module files to add '$FEATURE_NAME_SNAKE'..."
  
  # --- Define Anchors (as literal strings) ---
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

  # --- Prepare the new code blocks to be inserted ---

  # Imports
  NEW_MODEL_IMPORT_DOMAIN_REPO="import '../../data/models/${FEATURE_NAME_SNAKE}/${FEATURE_NAME_SNAKE}_request_model.dart';
import '../../data/models/${FEATURE_NAME_SNAKE}/${FEATURE_NAME_SNAKE}_response_model.dart';"
  NEW_MODEL_IMPORT_DATA_FILES="import '../models/${FEATURE_NAME_SNAKE}/${FEATURE_NAME_SNAKE}_request.dart';
import '../models/${FEATURE_NAME_SNAKE}/${FEATURE_NAME_SNAKE}_response_model.dart';
import '../models/${FEATURE_NAME_SNAKE}/${FEATURE_NAME_SNAKE}_request_model.dart';"
  NEW_DI_IMPORT="import '../domain/${MODULE_NAME_SNAKE}_usecase/${FEATURE_NAME_SNAKE}_usecase/${FEATURE_NAME_SNAKE}_usecase.dart';
import '../presentation/cubits/${FEATURE_NAME_SNAKE}/${FEATURE_NAME_SNAKE}_cubit.dart';"
  NEW_ROUTER_IMPORT="import 'presentation/Ui/screens/${FEATURE_NAME_SNAKE}_screen_view.dart';"

  # Method signatures and single lines
  NEW_REPO_METHOD="  Future<Either<Failure, ${FEATURE_NAME_PASCAL}Response>> ${FEATURE_NAME_SNAKE}({required ${FEATURE_NAME_PASCAL}RequestModel ${FEATURE_NAME_SNAKE}Data});"
  NEW_DATASOURCE_METHOD="  Future<${FEATURE_NAME_PASCAL}Response> ${FEATURE_NAME_SNAKE}(${FEATURE_NAME_PASCAL}RequestModel ${FEATURE_NAME_SNAKE}Data);"
  NEW_DI_DEPENDENCY="..registerFactory(() => ${FEATURE_NAME_PASCAL}UseCase(repository: di()))
       ..registerFactory(() => ${FEATURE_NAME_PASCAL}Cubit(di(), di()))"
  NEW_SCREEN_ID="  static const String ${FEATURE_NAME_CAMEL}Screen = ${FEATURE_NAME_PASCAL}ScreenView.id;"

  # Multi-line repository implementation method
  read -r -d '' NEW_REPO_IMPL_METHOD << EOM
  @override
  Future<Either<Failure, ${FEATURE_NAME_PASCAL}Response>> ${FEATURE_NAME_SNAKE}(
      {required ${FEATURE_NAME_PASCAL}RequestModel ${FEATURE_NAME_SNAKE}Data}) async {
    try {
      final response = await authRemoteDataSource.${FEATURE_NAME_SNAKE}(${FEATURE_NAME_SNAKE}Data);
      return Right(response);
    } on Exception catch (error) {
      return Left(FailureHandler(error).getExceptionFailure());
    }
  }

EOM

  # Multi-line data source implementation method
  read -r -d '' NEW_DATASOURCE_IMPL_METHOD << EOM
  @override
  Future<${FEATURE_NAME_PASCAL}Response> ${FEATURE_NAME_SNAKE}(
      ${FEATURE_NAME_PASCAL}RequestModel ${FEATURE_NAME_SNAKE}Data) async {
    final apiRequest = ${FEATURE_NAME_PASCAL}Request(${FEATURE_NAME_SNAKE}Data);
    final result = await network.send(
      request: apiRequest,
      responseFromMap: (map) => ${FEATURE_NAME_PASCAL}Response.fromJson(map),
    );
    return result;
  }

EOM

  # Multi-line router case
  read -r -d '' NEW_ROUTE_CASE << EOM
      case ${FEATURE_NAME_PASCAL}ScreenView.id:
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const ${FEATURE_NAME_PASCAL}ScreenView(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return AppAnimations.slideAnimation(animation, child);
          },
        );
EOM

  # --- Use helper function to modify files ---

  # Modify Domain Repository Interface
  insert_before "$FILE_DOMAIN_MODULE_REPO" "$ANCHOR_MODEL_IMPORT" "$NEW_MODEL_IMPORT_DOMAIN_REPO"
  insert_before "$FILE_DOMAIN_MODULE_REPO" "$ANCHOR_REPO_METHOD" "$NEW_REPO_METHOD"
  
  # Modify Data Repository Implementation
  insert_before "$FILE_DATA_MODULE_REPO_IMPL" "$ANCHOR_MODEL_IMPORT" "$NEW_MODEL_IMPORT_DATA_FILES"
  insert_before "$FILE_DATA_MODULE_REPO_IMPL" "$ANCHOR_REPO_IMPL_METHOD" "$NEW_REPO_IMPL_METHOD"
  
  # Modify Remote Data Source
  insert_before "$FILE_DATA_MODULE_REMOTE_SOURCE" "$ANCHOR_MODEL_IMPORT" "$NEW_MODEL_IMPORT_DATA_FILES"
  insert_before "$FILE_DATA_MODULE_REMOTE_SOURCE" "$ANCHOR_DATASOURCE_METHOD" "$NEW_DATASOURCE_METHOD"
  insert_before "$FILE_DATA_MODULE_REMOTE_SOURCE" "$ANCHOR_DATASOURCE_IMPL_METHOD" "$NEW_DATASOURCE_IMPL_METHOD"
  
  # Modify DI File
  insert_before "$FILE_DI_MODULE_MAIN" "$ANCHOR_DI_IMPORT" "$NEW_DI_IMPORT"
  insert_before "$FILE_DI_MODULE_MAIN" "$ANCHOR_DI_DEPENDENCY" "      $NEW_DI_DEPENDENCY"
  
  # Modify Router File
  insert_before "$FILE_LIB_MODULE_ROUTER" "$ANCHOR_ROUTER_IMPORT" "$NEW_ROUTER_IMPORT"
  insert_before "$FILE_LIB_MODULE_ROUTER" "$ANCHOR_ROUTER_CASE" "$NEW_ROUTE_CASE"
  insert_before "$FILE_LIB_MODULE_ROUTER" "$ANCHOR_ROUTER_ID" "$NEW_SCREEN_ID"
  
  echo ""
  echo "✅ New feature '$FEATURE_NAME_SNAKE' added successfully to module '$MODULE_NAME_SNAKE'."
}