import os
from src.core.case_utils import snake_to_pascal_case, pascal_to_camel_case

class ModulePaths:
    def __init__(self, module_name_snake, feature_name_snake, base_path="./lib"):
        self.module_name_snake = module_name_snake
        self.feature_name_snake = feature_name_snake
        self.base_path = base_path

        # Derived names
        self.module_name_pascal = snake_to_pascal_case(module_name_snake)
        self.module_name_camel = pascal_to_camel_case(self.module_name_pascal)
        self.feature_name_pascal = snake_to_pascal_case(feature_name_snake)
        self.feature_name_camel = pascal_to_camel_case(self.feature_name_pascal)

        # --- Define Paths ---
        self.file_lib_module_main = os.path.join(base_path, f"{module_name_snake}.dart")
        self.file_lib_module_router = os.path.join(base_path, f"{module_name_snake}_screen_router.dart")
        
        self.data_path = os.path.join(base_path, "data")
        self.data_module_repo_path = os.path.join(self.data_path, f"{module_name_snake}_repository")
        self.file_data_module_repo_impl = os.path.join(self.data_module_repo_path, f"{module_name_snake}_repository_impl.dart")
        
        self.data_models_static_path = os.path.join(self.data_path, "models")
        self.data_models_feature_path = os.path.join(self.data_models_static_path, feature_name_snake)
        self.data_models_request_path = os.path.join(self.data_models_feature_path, "request")
        self.data_models_response_path = os.path.join(self.data_models_feature_path, "response")
        
        self.file_data_feature_request = os.path.join(self.data_models_request_path, f"{feature_name_snake}_request.dart")
        self.file_data_feature_request_model = os.path.join(self.data_models_request_path, f"{feature_name_snake}_request_model.dart")
        self.file_data_feature_response = os.path.join(self.data_models_response_path, f"{feature_name_snake}_response.dart")
        self.file_data_feature_response_model = os.path.join(self.data_models_response_path, f"{feature_name_snake}_response_model.dart")
        
        self.data_remote_path = os.path.join(self.data_path, "remote_data_source")
        self.file_data_module_remote_source = os.path.join(self.data_remote_path, f"{module_name_snake}_remote_data_source.dart")
        
        self.di_path = os.path.join(base_path, "di")
        self.file_di_module_main = os.path.join(self.di_path, f"{module_name_snake}_di.dart")
        
        self.domain_path = os.path.join(base_path, "domain")
        self.domain_entities_path = os.path.join(self.domain_path, "entities", feature_name_snake)
        self.file_domain_feature_entity = os.path.join(self.domain_entities_path, f"{feature_name_snake}_entity.dart")
        
        self.domain_module_repo_path = os.path.join(self.domain_path, f"{module_name_snake}_repository")
        self.file_domain_module_repo = os.path.join(self.domain_module_repo_path, f"{module_name_snake}_repository.dart")
        
        self.domain_module_usecase_base_path = os.path.join(self.domain_path, f"{module_name_snake}_usecase")
        self.domain_feature_usecase_path = os.path.join(self.domain_module_usecase_base_path, f"{feature_name_snake}_usecase")
        self.file_domain_feature_usecase = os.path.join(self.domain_feature_usecase_path, f"{feature_name_snake}_usecase.dart")
        
        self.presentation_path = os.path.join(base_path, "presentation")
        self.pres_ui_path = os.path.join(self.presentation_path, "Ui")
        self.pres_ui_screens_path = os.path.join(self.pres_ui_path, "screens")
        self.file_pres_feature_screen_view = os.path.join(self.pres_ui_screens_path, f"{feature_name_snake}_screen_view.dart")
        
        self.pres_ui_widget_path = os.path.join(self.pres_ui_path, "widget")
        
        self.pres_cubits_base_path = os.path.join(self.presentation_path, "cubits")
        self.pres_feature_cubit_path = os.path.join(self.pres_cubits_base_path, feature_name_snake)
        self.file_pres_feature_cubit = os.path.join(self.pres_feature_cubit_path, f"{feature_name_snake}_cubit.dart")
        self.file_pres_feature_cubit_state = os.path.join(self.pres_feature_cubit_path, f"{feature_name_snake}_state.dart")

    def get_template_context(self, ui_body_code=None):
        context = {
            "MODULE_NAME_SNAKE": self.module_name_snake,
            "MODULE_NAME_PASCAL": self.module_name_pascal,
            "MODULE_NAME_CAMEL": self.module_name_camel,
            "FEATURE_NAME_SNAKE": self.feature_name_snake,
            "FEATURE_NAME_PASCAL": self.feature_name_pascal,
            "FEATURE_NAME_CAMEL": self.feature_name_camel,
        }
        if ui_body_code:
            context["UI_BODY_CODE"] = ui_body_code
        return context
