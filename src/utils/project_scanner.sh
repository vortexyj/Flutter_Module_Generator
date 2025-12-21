#!/bin/bash

# Checks if the current directory is the root of a Flutter project (App).
# Criteria: Has pubspec.yaml AND (android OR ios folder).
is_project_root() {
  if [ -f "pubspec.yaml" ] && { [ -d "android" ] || [ -d "ios" ]; }; then
    return 0 # True
  else
    return 1 # False
  fi
}

# Checks if the current directory is a Flutter module/package.
# Criteria: Has pubspec.yaml AND lib folder.
is_flutter_module() {
  if [ -f "pubspec.yaml" ] && [ -d "lib" ]; then
    return 0 # True
  else
    return 1 # False
  fi
}

# Scans for Flutter modules in the current directory, excluding standard folders.
# Returns a list of paths to modules found.
find_modules() {
  echo "Scanning for modules..." >&2
  
  # Find directories containing pubspec.yaml, excluding common non-module directories.
  # We search up to depth 3 to avoid going too deep, but can adjust if needed.
  # Exclusions: hidden files/dirs, android, ios, build, assets, images, test, .git, .idea
  
  find . -maxdepth 3 -type f -name "pubspec.yaml" \
    -not -path '*/.*' \
    -not -path './android*' \
    -not -path './ios*' \
    -not -path './build*' \
    -not -path './assets*' \
    -not -path './images*' \
    -not -path './test*' \
    -not -path './web*' \
    -not -path './macos*' \
    -not -path './windows*' \
    -not -path './linux*' \
    -not -path './pubspec.yaml' \
    -not -path '.' \
    | sed 's|/pubspec.yaml||' | sed 's|^\./||' | grep -v "^\.$"
}

# Helper to check context and set a global variable
check_context() {
  if is_project_root; then
    export SCRIPT_CONTEXT="ROOT"
    echo "Context: Project Root detected."
  elif is_flutter_module; then
    export SCRIPT_CONTEXT="MODULE"
    echo "Context: Module detected."
  else
    export SCRIPT_CONTEXT="OTHER"
    echo "Context: Unknown (Not a Flutter Project Root or Module)."
    echo "You can create a new module, but adding features requires a valid context."
  fi
}
