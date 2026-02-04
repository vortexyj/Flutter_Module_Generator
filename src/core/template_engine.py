import os
import re

def render_template(template_path, destination_path, context):
    """
    Renders a template file by replacing placeholders with context values.
    """
    if not os.path.exists(template_path):
        print(f"[ERROR] Template file not found: {template_path}")
        return False

    with open(template_path, 'r') as f:
        content = f.read()

    rendered_content = render_content(content, context)

    os.makedirs(os.path.dirname(destination_path), exist_ok=True)
    with open(destination_path, 'w') as f:
        f.write(rendered_content)

    print(f"Created: {destination_path}")
    return True

def render_partial(template_path, context):
    """
    Renders a partial template and returns the content as a string.
    """
    if not os.path.exists(template_path):
        print(f"[ERROR] Partial template file not found: {template_path}")
        return ""

    with open(template_path, 'r') as f:
        content = f.read()

    return render_content(content, context)

def render_content(content, context):
    """
    Helper to replace ${VARIABLE} placeholders in content.
    """
    for key, value in context.items():
        # Escape special characters in value for safe use in regex if needed, 
        # but here we just use string replacement for simplicity as Bash did.
        placeholder = f"${{{key}}}"
        content = content.replace(placeholder, str(value))
    return content
