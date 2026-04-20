import os
import subprocess
from src.core.case_utils import normalize_to_snake_case
from src.core.project_scanner import get_script_context
from src.core.template_engine import render_template
from src.core.file_modifier import insert_after
from src.core.ai_client import run_ai_generation
from src.models.paths import ModulePaths

def run_create_mode():
    print("\n--- Mode 1: Create New Module ---")
    
    print("Enter the name for the new Flutter Module (package, snake_case):")
    module_name_input = input()
    module_name_snake = normalize_to_snake_case(module_name_input)

    if not module_name_snake:
        print("Error: Module name cannot be empty.")
        return

    if os.path.exists(module_name_snake):
        print(f"Error: A directory named '{module_name_snake}' already exists here.")
        return

    # 1. Create Package
    print(f"Creating Flutter package (module): {module_name_snake}...")
    try:
        subprocess.run(["flutter", "create", "--template=package", module_name_snake], check=True)
    except subprocess.CalledProcessError:
        print(f"Error: Failed to create module '{module_name_snake}'.")
        return

    if not os.path.exists(module_name_snake) or not os.path.exists(os.path.join(module_name_snake, "pubspec.yaml")):
        print(f"Error: Failed to create module '{module_name_snake}'.")
        return
    print(f"Module '{module_name_snake}' created successfully.\n")

    # 2. Enter Directory
    original_dir = os.getcwd()
    os.chdir(module_name_snake)
    print(f"Now operating inside module: {os.getcwd()}\n")

    # 3. Add Dependencies & Clean
    update_pubspec_and_clean(module_name_snake)

    print("Enter the name for the initial FEATURE (e.g., user_login):")
    feature_name_input = input()
    feature_name_snake = normalize_to_snake_case(feature_name_input)

    if not feature_name_snake:
        print("Error: Feature name cannot be empty.")
        os.chdir(original_dir)
        return

    base_path = "./lib"
    if not os.path.exists(base_path):
        print(f"Error: '{base_path}' directory not found inside '{os.getcwd()}'.")
        os.chdir(original_dir)
        return

    # 4. Define Paths
    paths = ModulePaths(module_name_snake, feature_name_snake, base_path)

    # 5. Create Directories
    create_module_directories(paths)

    # 6. Generate Files
    generate_module_files(paths)
    
    print(f"✅ Flutter module '{module_name_snake}' and initial feature '{feature_name_snake}' created successfully.")
    os.chdir(original_dir)
    print(f"Returned to: {os.getcwd()}")

def update_pubspec_and_clean(module_name):
    print("Updating pubspec.yaml and cleaning project files...")
    
    pubspec_file = "./pubspec.yaml"
    test_file_path = f"./test/{module_name}_test.dart"
    
    dependencies = """
  ### MODULES
  core:
    path: ../core
  failures:
    path: ../failures
  ui_components:
    path: ../ui_components
  local_storage:
    path: ../local_storage"""

    if insert_after(pubspec_file, "sdk: flutter", dependencies):
        print("     [SUCCESS] Dependencies added to pubspec.yaml.")
    
    if os.path.exists(test_file_path):
        with open(test_file_path, 'w') as f:
            f.write("// TODO: Implement module tests.\n")
        print("     [SUCCESS] Cleaned default test file.")
    
    print("Running 'flutter pub get' in the new module...")
    try:
        subprocess.run(["flutter", "pub", "get"], check=True)
    except subprocess.CalledProcessError:
        print("     [WARNING] 'flutter pub get' failed. You may need to run it manually.")
    print("")

def create_module_directories(paths):
    print("Creating directories...")
    dirs_to_create = [
        paths.data_module_repo_path,
        paths.data_models_request_path,
        paths.data_models_response_path,
        paths.data_remote_path,
        paths.di_path,
        paths.domain_module_repo_path,
        paths.domain_feature_usecase_path,
        paths.pres_ui_screens_path,
        paths.pres_ui_widget_path,
        paths.pres_feature_cubit_path,
        paths.domain_entities_path
    ]
    for d in dirs_to_create:
        os.makedirs(d, exist_ok=True)
    print("Directories created.\n")

def generate_module_files(paths):
    # SCRIPT_DIR is where the main.py is located. 
    # For now, let's assume we can find the templates relative to our current file or via an absolute path if we set it up.
    # In main.py we should probably define a TEMPLATES_DIR.
    
    # We'll use a relative path from the root of the project.
    # Since this script is in src/commands, we go up two levels.
    templates_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "templates"))
    
    print("Creating files from templates...")
    
    context = paths.get_template_context()
    
    render_template(os.path.join(templates_dir, "lib_main.template"),           paths.file_lib_module_main, context)
    render_template(os.path.join(templates_dir, "router.template"),             paths.file_lib_module_router, context)
    render_template(os.path.join(templates_dir, "repository.template"),         paths.file_domain_module_repo, context)
    render_template(os.path.join(templates_dir, "repository_impl.template"),    paths.file_data_module_repo_impl, context)
    render_template(os.path.join(templates_dir, "remote_data_source.template"), paths.file_data_module_remote_source, context)
    render_template(os.path.join(templates_dir, "di.template"),                 paths.file_di_module_main, context)
    render_template(os.path.join(templates_dir, "request.template"),            paths.file_data_feature_request, context)
    render_template(os.path.join(templates_dir, "request_model.template"),      paths.file_data_feature_request_model, context)
    render_template(os.path.join(templates_dir, "response.template"),           paths.file_data_feature_response, context)
    render_template(os.path.join(templates_dir, "response_model.template"),     paths.file_data_feature_response_model, context)
    render_template(os.path.join(templates_dir, "entity.template"),             paths.file_domain_feature_entity, context)
    render_template(os.path.join(templates_dir, "usecase.template"),            paths.file_domain_feature_usecase, context)
    render_template(os.path.join(templates_dir, "state.template"),              paths.file_pres_feature_cubit_state, context)
    render_template(os.path.join(templates_dir, "cubit.template"),              paths.file_pres_feature_cubit, context)
    
    # Special Handling for Screen View with AI Integration
    ui_body_code = run_ai_generation(paths.feature_name_pascal)
    context_with_ai = paths.get_template_context(ui_body_code=ui_body_code)
    render_template(os.path.join(templates_dir, "view.template"), paths.file_pres_feature_screen_view, context_with_ai)
    
    print("")
