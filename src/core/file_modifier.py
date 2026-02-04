import os

def insert_before(file_path, pattern, content):
    """
    Inserts content before the first occurrence of pattern in the file.
    """
    print(f"  -> Modifying File: '{file_path}'")
    if not os.path.exists(file_path):
        print(f"     [ERROR] File not found or is not readable. Skipping.")
        return False

    with open(file_path, 'r') as f:
        lines = f.readlines()

    new_lines = []
    found = False
    for line in lines:
        if pattern in line and not found:
            new_lines.append(content + ("\n" if not content.endswith("\n") else ""))
            found = True
        new_lines.append(line)

    if not found:
        print(f"     [WARNING] Anchor pattern '{pattern}' not found. Skipping.")
        return False

    with open(file_path, 'w') as f:
        f.writelines(new_lines)
    return True

def insert_after(file_path, pattern, content):
    """
    Inserts content after the first occurrence of pattern in the file.
    """
    print(f"  -> Modifying File: '{file_path}'")
    if not os.path.exists(file_path):
        print(f"     [ERROR] File not found or is not readable. Skipping.")
        return False

    with open(file_path, 'r') as f:
        lines = f.readlines()

    new_lines = []
    found = False
    for line in lines:
        new_lines.append(line)
        if pattern in line and not found:
            new_lines.append(content + ("\n" if not content.endswith("\n") else ""))
            found = True

    if not found:
        print(f"     [WARNING] Anchor pattern '{pattern}' not found. Skipping.")
        return False

    with open(file_path, 'w') as f:
        f.writelines(new_lines)
    return True
