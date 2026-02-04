import re

def snake_to_pascal_case(snake_str):
    if not snake_str:
        return ""
    return "".join(word.capitalize() for word in snake_str.split("_"))

def pascal_to_camel_case(pascal_str):
    if not pascal_str:
        return ""
    return pascal_str[0].lower() + pascal_str[1:]

def normalize_to_snake_case(text):
    if not text:
        return ""
    # Replace spaces with underscores
    text = text.replace(" ", "_")
    # Handle CamelCase/pascalCase (lowercase followed by uppercase)
    text = re.sub(r"([a-z0-9])([A-Z])", r"\1_\2", text)
    # Lowercase everything
    text = text.lower()
    # Replace double underscores
    text = re.sub(r"__+", "_", text)
    return text.strip("_")
