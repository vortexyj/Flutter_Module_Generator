import os
import json
import urllib.request
import urllib.error

def run_ai_generation(feature_pascal_name):
    """
    Determines what Dart code to use for the UI body using Gemini AI.
    """
    ui_body_code = f"const Center(child: Text('Default UI for {feature_pascal_name}ScreenView'))"
    
    gemini_api_key = os.environ.get("GEMINI_API_KEY")
    
    print("\nWould you like to generate the UI for this screen using AI? (y/n): ", end="")
    generate_ui = input().lower()
    
    if generate_ui == 'y':
        if not gemini_api_key:
            print("  [ERROR] GEMINI_API_KEY is not set. Using default UI instead.")
        else:
            print("  Please describe the UI you want to build (e.g., 'a login form with email, password, and a login button'):")
            print("> ", end="")
            ui_description = input()
            
            if ui_description:
                while True:
                    print("  Generating UI with Gemini... (this may take a moment)")
                    
                    prompt = (
                        "You are an expert Flutter developer. Your task is to write clean, modern, and production-ready Dart code "
                        "for a widget that will be placed in the 'body' of a Scaffold. Based on the user's request, create that widget. "
                        "IMPORTANT RULES: - ONLY output the Dart code for the widget. - Do NOT include 'import' statements. "
                        "- Do NOT include the 'Scaffold', 'AppBar', or 'backgroundColor' properties. - Do NOT wrap your code in Markdown backticks. "
                        f"USER REQUEST: \"{ui_description}\""
                    )
                    
                    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key={gemini_api_key}"
                    data = {
                        "contents": [{
                            "parts": [{"text": prompt}]
                        }]
                    }
                    
                    try:
                        req = urllib.request.Request(url, data=json.dumps(data).encode('utf-8'), headers={'Content-Type': 'application/json'})
                        with urllib.request.urlopen(req) as response:
                            res_data = json.loads(response.read().decode('utf-8'))
                            
                            if 'candidates' in res_data and res_data['candidates']:
                                generated_code = res_data['candidates'][0]['content']['parts'][0]['text']
                                if generated_code and generated_code != "null":
                                    ui_body_code = generated_code.strip()
                                    print("  [SUCCESS] AI-generated UI will be used.")
                                else:
                                    print("  [WARNING] AI did not return any code. Using default UI instead.")
                            else:
                                print("  [WARNING] AI did not return any candidates. Using default UI instead.")
                            break
                            
                    except urllib.error.HTTPError as e:
                        res_body = e.read().decode('utf-8')
                        if "overloaded" in res_body.lower():
                            print("  [WARNING] The Gemini API is temporarily overloaded.")
                            print("  Would you like to try again or use the default UI? (try/default): ", end="")
                            retry_choice = input().lower()
                            if retry_choice in ['try', 't']:
                                print("  Retrying...")
                                continue
                            else:
                                print("  Using default UI.")
                                break
                        else:
                            print(f"  [ERROR] The API returned an error: {e.code}")
                            print(res_body)
                            print("  Using default UI instead.")
                            break
                    except Exception as e:
                        print(f"  [ERROR] An unexpected error occurred: {e}")
                        print("  Using default UI instead.")
                        break

    return ui_body_code
