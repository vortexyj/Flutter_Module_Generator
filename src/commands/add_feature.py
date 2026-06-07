import os
import subprocess
from src.core.case_utils import normalize_to_snake_case
from src.core.project_scanner import get_script_context, find_modules
from src.core.template_engine import render_template, render_partial
from src.core.file_modifier import insert_before
from src.core.ai_client import run_ai_generation
from src.core.entity_json_step import run_entity_json_step
from src.models.paths import ModulePaths

def run_add_feature_mode():
    print("\n--- Mode 2: Add New Feature to Existing Module ---")

    context = get_script_context()
    if context == "ROOT":
        print("You are in the Project Root. Scanning for modules...")
        modules = find_modules()
        
        if not modules:
            print("No modules found in this project.")
            return
        
        print("Found modules:")
        for i, module in enumerate(modules, 1):
            print(f"  {i}) {module}")
        
        try:
            choice = int(input(f"Select a module to add a feature to (1-{len(modules)}): "))
            if choice < 1 or choice > len(modules):
                print("Invalid selection.")
                return
            selected_module = modules[choice - 1]
        except ValueError:
            print("Invalid input.")
            return
        
        print(f"Selected module: {selected_module}")
        os.chdir(selected_module)
        module_name_snake = os.path.basename(os.getcwd())
    elif context == "MODULE":
        module_name_snake = os.path.basename(os.getcwd())
    else:
        print("Error: You must be in a Flutter Project Root or Module to add a feature.")
        return

    print(f"Operating in module: {module_name_snake}")

    print(f"Enter the name for the NEW feature to add to '{module_name_snake}':")
    feature_name_input = input()
    feature_name_snake = normalize_to_snake_case(feature_name_input)
    
    print("Select the type of feature to add:")
    print("  1) Full Feature (Data + Domain + Presentation)")
    print("  2) Logic Only (Data + Domain)")
    print("  3) UI Only (Presentation)")
    feature_type = input("Enter your choice (1-3): ") or "1"

    if not feature_name_snake:
        print("Error: New feature name cannot be empty.")
        return
    
    base_path = "./lib"
    print(f"\nAdding feature '{feature_name_snake}' to module '{module_name_snake}'...\n")

    # 1. Define Paths
    paths = ModulePaths(module_name_snake, feature_name_snake, base_path)

    # 2. Create Directories
    create_feature_directories(paths, feature_type)

    # 3. Generate Files
    generate_feature_files(paths, feature_type)

    # 4. Modify Shared Files
    modify_shared_files(paths, feature_type)

    print(f"\n✅ New feature '{feature_name_snake}' added successfully to module '{module_name_snake}'.")

def create_feature_directories(paths, feature_type):
    print(f"Creating new directories for feature '{paths.feature_name_snake}'...")
    
    # Type 1 (Full) or 2 (Logic Only): Create Data and Domain
    if feature_type in ["1", "2"]:
        dirs = [
            paths.data_module_repo_path,
            paths.data_models_request_path,
            paths.data_models_response_path,
            paths.data_remote_path,
            paths.di_path,
            paths.domain_module_repo_path,
            paths.domain_feature_usecase_path,
            paths.domain_entities_path
        ]
        for d in dirs:
            os.makedirs(d, exist_ok=True)
            
    # Type 1 (Full) or 3 (UI Only): Create Presentation
    if feature_type in ["1", "3"]:
        os.makedirs(paths.pres_feature_cubit_path, exist_ok=True)
        os.makedirs(paths.pres_ui_screens_path, exist_ok=True)
    
    print("New directories created.\n")

def generate_feature_files(paths, feature_type):
    templates_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "templates"))
    
    print(f"Creating new files for feature '{paths.feature_name_snake}'...")
    context = paths.get_template_context()
    
    # Type 1 (Full) or 2 (Logic Only): Generate Data and Domain files
    if feature_type in ["1", "2"]:
        render_template(os.path.join(templates_dir, "entity.template"),           paths.file_domain_feature_entity, context)
        render_template(os.path.join(templates_dir, "request.template"),          paths.file_data_feature_request, context)
        render_template(os.path.join(templates_dir, "request_model.template"),    paths.file_data_feature_request_model, context)
        render_template(os.path.join(templates_dir, "response_model.template"),   paths.file_data_feature_response_model, context)
        render_template(os.path.join(templates_dir, "response.template"),         paths.file_data_feature_response, context)
        render_template(os.path.join(templates_dir, "usecase.template"),          paths.file_domain_feature_usecase, context)

        # ── Optional: overwrite entity/response files from a JSON example ──
        run_entity_json_step(paths, base_path=paths.base_path)
    
    # Type 1 (Full) or 3 (UI Only): Generate Presentation files
    if feature_type in ["1", "3"]:
        if feature_type == "1":
            # Full Feature: Standard Cubit with UseCase dependency
            render_template(os.path.join(templates_dir, "cubit.template"),            paths.file_pres_feature_cubit, context)
            render_template(os.path.join(templates_dir, "state.template"),            paths.file_pres_feature_cubit_state, context)
        else:
            # UI Only: Simple Cubit without dependencies
            render_template(os.path.join(templates_dir, "feature_templates/cubit_ui.template"),     paths.file_pres_feature_cubit, context)
            render_template(os.path.join(templates_dir, "feature_templates/state_ui.template"),     paths.file_pres_feature_cubit_state, context)
        
        ui_body_code = run_ai_generation(paths.feature_name_pascal)
        context_with_ai = paths.get_template_context(ui_body_code=ui_body_code)
        render_template(os.path.join(templates_dir, "view.template"), paths.file_pres_feature_screen_view, context_with_ai)
    
    print("New files created.\n")

def modify_shared_files(paths, feature_type):
    method_templates_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "templates", "feature_templates"))
    
    print(f"Modifying shared module files to add '{paths.feature_name_snake}'...")
    
    # --- Define Anchors ---
    ANCHOR_MODEL_IMPORT = "// [Adding_new_model_import_here_dont_remove_this_command_!!!]"
    ANCHOR_REPO_METHOD = "// [Adding_new_repo_method_here_dont_remove_this_command_!!!]"
    ANCHOR_REPO_IMPL_METHOD = "// [Adding_new_repo_impl_method_here_dont_remove_this_command_!!!]"
    ANCHOR_DATASOURCE_METHOD = "// [Adding_new_datasource_method_here_dont_remove_this_command_!!!]"
    ANCHOR_DATASOURCE_IMPL_METHOD = "// [Adding_new_datasource_impl_method_here_dont_remove_this_command_!!!]"
    ANCHOR_DI_IMPORT = "// [Adding_new_di_import_here_dont_remove_this_command_!!!]"
    ANCHOR_DI_DEPENDENCY = "// [Adding_new_di_dependency_here_dont_remove_this_command_!!!]"
    ANCHOR_ROUTER_IMPORT = "// [Adding_new_router_import_here_dont_remove_this_command_!!!]"
    ANCHOR_ROUTER_CASE = "// [Adding_new_router_case_here_dont_remove_this_command_!!!]"
    ANCHOR_ROUTER_ID = "// [Adding_new_router_screen_id_here_dont_remove_this_command_!!!]"

    context = paths.get_template_context()

    # --- Prepare code blocks ---
    NEW_MODEL_IMPORT_DOMAIN_REPO = f"import '../entities/{paths.feature_name_snake}/{paths.feature_name_snake}_entity.dart';\nimport '../../data/models/{paths.feature_name_snake}/request/{paths.feature_name_snake}_request_model.dart';"
    NEW_MODEL_IMPORT_REPO_IMPL = f"import '../../domain/entities/{paths.feature_name_snake}/{paths.feature_name_snake}_entity.dart';\nimport '../models/{paths.feature_name_snake}/request/{paths.feature_name_snake}_request_model.dart';"
    NEW_MODEL_IMPORT_DATASOURCE = f"import '../models/{paths.feature_name_snake}/request/{paths.feature_name_snake}_request.dart';\nimport '../models/{paths.feature_name_snake}/request/{paths.feature_name_snake}_request_model.dart';\nimport '../models/{paths.feature_name_snake}/response/{paths.feature_name_snake}_response.dart';"
    
    NEW_REPO_METHOD = f"  Future<Either<Failure, {paths.feature_name_pascal}Entity>> {paths.feature_name_camel}({{required {paths.feature_name_pascal}RequestModel requestModel}});"
    NEW_DATASOURCE_METHOD = f"  Future<{paths.feature_name_pascal}Response> {paths.feature_name_camel}({paths.feature_name_pascal}RequestModel requestModel);"
    
    NEW_REPO_IMPL_METHOD = render_partial(os.path.join(method_templates_dir, "repository_impl_method.template"), context)
    NEW_DATASOURCE_IMPL_METHOD = render_partial(os.path.join(method_templates_dir, "datasource_impl_method.template"), context)

    # --- Type 1 (Full) or 2 (Logic Only): Modify Data and Domain layers ---
    if feature_type in ["1", "2"]:
        insert_before(paths.file_domain_module_repo, ANCHOR_MODEL_IMPORT, NEW_MODEL_IMPORT_DOMAIN_REPO)
        insert_before(paths.file_domain_module_repo, ANCHOR_REPO_METHOD, NEW_REPO_METHOD)
        
        insert_before(paths.file_data_module_repo_impl, ANCHOR_MODEL_IMPORT, NEW_MODEL_IMPORT_REPO_IMPL)
        insert_before(paths.file_data_module_repo_impl, ANCHOR_REPO_IMPL_METHOD, NEW_REPO_IMPL_METHOD)
        
        insert_before(paths.file_data_module_remote_source, ANCHOR_MODEL_IMPORT, NEW_MODEL_IMPORT_DATASOURCE)
        insert_before(paths.file_data_module_remote_source, ANCHOR_DATASOURCE_METHOD, NEW_DATASOURCE_METHOD)
        insert_before(paths.file_data_module_remote_source, ANCHOR_DATASOURCE_IMPL_METHOD, NEW_DATASOURCE_IMPL_METHOD)

    # --- Type 1 (Full) or 3 (UI Only): Modify Presentation layer files ---
    if feature_type in ["1", "3"]:
        print("Adding Presentation Layer (UI) modifications...")
        
        if feature_type == "1":
            NEW_DI_IMPORT = f"import '../domain/{paths.module_name_snake}_usecase/{paths.feature_name_snake}_usecase/{paths.feature_name_snake}_usecase.dart';\nimport '../presentation/cubits/{paths.feature_name_snake}/{paths.feature_name_snake}_cubit.dart';"
            NEW_DI_DEPENDENCY = f"..registerFactory(() => {paths.feature_name_pascal}UseCase(repository: di()))\n       ..registerFactory(() => {paths.feature_name_pascal}Cubit(di()))"
        else:
            NEW_DI_IMPORT = f"import '../presentation/cubits/{paths.feature_name_snake}/{paths.feature_name_snake}_cubit.dart';"
            NEW_DI_DEPENDENCY = f"..registerFactory(() => {paths.feature_name_pascal}Cubit())"

        NEW_ROUTER_IMPORT = f"import 'presentation/Ui/screens/{paths.feature_name_snake}_screen_view.dart';"
        NEW_SCREEN_ID = f"  static const String {paths.feature_name_camel}Screen = {paths.feature_name_pascal}ScreenView.id;"
        NEW_ROUTE_CASE = render_partial(os.path.join(method_templates_dir, "router_case.template"), context)

        # Modify DI File
        insert_before(paths.file_di_module_main, ANCHOR_DI_IMPORT, NEW_DI_IMPORT)
        insert_before(paths.file_di_module_main, ANCHOR_DI_DEPENDENCY, f"      {NEW_DI_DEPENDENCY}")
        
        # Modify Router File
        insert_before(paths.file_lib_module_router, ANCHOR_ROUTER_IMPORT, NEW_ROUTER_IMPORT)
        insert_before(paths.file_lib_module_router, ANCHOR_ROUTER_CASE, NEW_ROUTE_CASE)
        insert_before(paths.file_lib_module_router, ANCHOR_ROUTER_ID, NEW_SCREEN_ID)
  
    elif feature_type == "2":
        # Logic Only: Register UseCase only
        print("Skipping Presentation Layer (UI) modifications...")
        NEW_DI_IMPORT = f"import '../domain/{paths.module_name_snake}_usecase/{paths.feature_name_snake}_usecase/{paths.feature_name_snake}_usecase.dart';"
        NEW_DI_DEPENDENCY = f"..registerFactory(() => {paths.feature_name_pascal}UseCase(repository: di()))"

        insert_before(paths.file_di_module_main, ANCHOR_DI_IMPORT, NEW_DI_IMPORT)
        insert_before(paths.file_di_module_main, ANCHOR_DI_DEPENDENCY, f"      {NEW_DI_DEPENDENCY}")
