#!/usr/bin/env python3
import sys
import os

# Add the current directory to sys.path so we can import our modules
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from src.core.project_scanner import get_script_context
from src.commands.create_module import run_create_mode
from src.commands.add_feature import run_add_feature_mode

def main():
    print("Flutter Module & Feature Scaffolder (Python Version)")
    print("-----------------------------------")
    
    context = get_script_context()
    if context == "ROOT":
        print("Context: Project Root detected.")
    elif context == "MODULE":
        print("Context: Module detected.")
    else:
        print("Context: Unknown (Not a Flutter Project Root or Module).")
        print("You can create a new module, but adding features requires a valid context.")

    print("\nWhat would you like to do?")
    print("  1) Create a new Module and its first Feature")
    print("  2) Add a new Feature to an existing Module")
    
    try:
        choice = input("Enter your choice (1 or 2): ")
    except EOFError:
        return

    if choice == "1":
        run_create_mode()
    elif choice == "2":
        if context == "OTHER":
            print("Error: You must be in a Flutter Project Root or Module to add a feature.")
            sys.exit(1)
        run_add_feature_mode()
    else:
        print("Invalid choice. Exiting.")
        sys.exit(1)

if __name__ == "__main__":
    main()
