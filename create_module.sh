#!/bin/bash

# Get the directory where this script is located to reliably find the 'src' folder.
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

# Source (include) our other script files from their new locations.
source "${SCRIPT_DIR}/src/functions.sh"
source "${SCRIPT_DIR}/src/script_modes/mode_1_create_module.sh"
source "${SCRIPT_DIR}/src/script_modes/mode_2_add_feature.sh"

# --- Main Menu ---
echo "Flutter Module & Feature Scaffolder"
echo "-----------------------------------"
echo "What would you like to do?"
echo "  1) Create a new Module and its first Feature"
echo "  2) Add a new Feature to an existing Module"
read -p "Enter your choice (1 or 2): " SCRIPT_MODE

# --- Route to the correct mode based on user's choice ---
if [ "$SCRIPT_MODE" == "1" ]; then
  run_create_mode # This function is in 'src/script_modes/mode_1_create_module.sh'
elif [ "$SCRIPT_MODE" == "2" ]; then
  run_add_feature_mode # This function is in 'src/script_modes/mode_2_add_feature.sh'
else
  echo "Invalid choice. Exiting."
  exit 1
fi