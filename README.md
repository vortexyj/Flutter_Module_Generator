# Flutter Module & Feature Scaffolding Tool

This tool automates the creation of a new Flutter module (as a separate package) and scaffolds an initial feature structure within it, following clean architecture conventions.
It has been rewritten in **Python** for better maintainability and extensibility.

## 1. Features

- **Create New Module**: Generates a new Flutter package with standard Clean Architecture layers (Data, Domain, Presentation).
- **Add Feature**: Adds a new feature (Full, Logic Only, or UI Only) to an existing module.
- **AI Integration**: Optionally generates UI code using Google's Gemini AI.
- **Clean Architecture**: Automatically sets up repositories, use cases, cubits, and dependency injection.

## 2. Prerequisites

- **Python 3.6+**: Ensure Python is installed (`python3 --version`).
- **Flutter SDK**: Installed and configured in your `PATH`.
- **Gemini API Key (Optional)**: Set the `GEMINI_API_KEY` environment variable to use AI features.

## 3. Setup

### 3.1. Make Runnable (Optional)
You can run the script directly with Python, or make it executable:

```bash
chmod +x main.py
```

### 3.2. Add to PATH (Optional)
To run it from anywhere, add the project directory to your shell's PATH, or create an alias.

For Zsh (`~/.zshrc`):
```bash
alias flutter_creator="python3 /path/to/flutter_module_creator/main.py"
```

## 4. Usage

### Run the Tool
Navigate to your project folder (or anywhere if you set up an alias) and run:

```bash
# Direct execution
python3 main.py

# Or if you made it executable
./main.py

# Or via alias
flutter_creator
```

### Modes
1.  **Create a new Module and its first Feature**:
    - Creates a new Flutter package.
    - Sets up the directory structure.
    - Generates initial boilerplate code.
2.  **Add a new Feature to an existing Module**:
    - Scans for existing modules (if run from root).
    - Adds new directories and files for the feature.
    - Automatically updates `di.dart`, `router.dart`, and repositories to include the new feature.

## 5. Generated Structure

The tool creates the following structure inside `lib/`:

- **`data/`**: Models, Remote Data Source, Repository Implementation.
- **`domain/`**: Entities, Repository Interface, Use Cases.
- **`presentation/`**: Cubits, States, CI Screens.
- **`di/`**: Dependency Injection setup.

## 6. AI Integration

To use the AI UI generation feature:
1.  Get an API key from [Google AI Studio](https://aistudio.google.com/).
2.  Export it in your terminal:
    ```bash
    export GEMINI_API_KEY="your_api_key_here"
    ```
3.  When prompted during script execution, choose `y` to generate UI and describe what you want.
