import os
import subprocess

def is_project_root():
    """
    Checks if the current directory is the root of a Flutter project (App).
    Criteria: Has pubspec.yaml AND (android OR ios folder).
    """
    return os.path.exists("pubspec.yaml") and (os.path.isdir("android") or os.path.isdir("ios"))

def is_flutter_module():
    """
    Checks if the current directory is a Flutter module/package.
    Criteria: Has pubspec.yaml AND lib folder.
    """
    return os.path.exists("pubspec.yaml") and os.path.isdir("lib")

def find_modules():
    """
    Scans for Flutter modules in the current directory, excluding standard folders.
    Returns a list of paths to modules found.
    """
    # Using 'find' command via subprocess for efficiency, similar to original Bash script.
    # We can also implement this in pure Python if desired.
    cmd = [
        "find", ".", "-maxdepth", "3", "-type", "f", "-name", "pubspec.yaml",
        "-not", "-path", "*/.*",
        "-not", "-path", "./android*",
        "-not", "-path", "./ios*",
        "-not", "-path", "./build*",
        "-not", "-path", "./assets*",
        "-not", "-path", "./images*",
        "-not", "-path", "./test*",
        "-not", "-path", "./web*",
        "-not", "-path", "./macos*",
        "-not", "-path", "./windows*",
        "-not", "-path", "./linux*",
        "-not", "-path", "./pubspec.yaml",
        "-not", "-path", "."
    ]
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        paths = result.stdout.strip().split("\n")
        # Clean paths: remove '/pubspec.yaml' and leading './'
        filtered_paths = []
        for p in paths:
            if not p: continue
            clean_p = p.replace("/pubspec.yaml", "").replace("./", "")
            if clean_p and clean_p != ".":
                filtered_paths.append(clean_p)
        return filtered_paths
    except subprocess.CalledProcessError:
        return []

def get_script_context():
    """
    Determines the script context: ROOT, MODULE, or OTHER.
    """
    if is_project_root():
        return "ROOT"
    elif is_flutter_module():
        return "MODULE"
    else:
        return "OTHER"
