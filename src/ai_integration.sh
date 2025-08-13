#!/bin/bash

run_ai_generation() {
  # This function determines what Dart code to use for the UI body.
  local feature_pascal_name="$1"
  local ui_body_code="const Center(child: Text('Default UI for ${feature_pascal_name}ScreenView'))"

  echo "" >&2
  echo -n "Would you like to generate the UI for this screen using AI? (y/n): " >&2
  read GENERATE_UI
  
  if [[ "$GENERATE_UI" == "y" || "$GENERATE_UI" == "Y" ]]; then
    
    if [ -z "$GEMINI_API_KEY" ]; then
      echo "  [ERROR] GEMINI_API_KEY is not set. Using default UI instead." >&2
    else
      echo "  Please describe the UI you want to build (e.g., 'a login form with email, password, and a login button'):" >&2
      echo -n "> " >&2
      read UI_DESCRIPTION

      if [ -n "$UI_DESCRIPTION" ]; then
        
        # Loop to allow for retries on specific errors
        while true; do
          echo "  Generating UI with Gemini... (this may take a moment)" >&2

          AI_PROMPT="You are an expert Flutter developer. Your task is to write clean, modern, and production-ready Dart code for a widget that will be placed in the 'body' of a Scaffold. Based on the user's request, create that widget. IMPORTANT RULES: - ONLY output the Dart code for the widget. - Do NOT include 'import' statements. - Do NOT include the 'Scaffold', 'AppBar', or 'backgroundColor' properties. - Do NOT wrap your code in Markdown backticks. USER REQUEST: \"${UI_DESCRIPTION}\""

          JSON_DATA=$(jq -n --arg prompt "$AI_PROMPT" \
            '{contents: [{parts: [{text: $prompt}]}]}')

          API_RESPONSE=$(curl -s -H 'Content-Type: application/json' -d "$JSON_DATA" "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=${GEMINI_API_KEY}")
          
          # --- NEW ERROR HANDLING LOGIC ---

          # Case 1: Success (No "error" in response)
          if ! echo "$API_RESPONSE" | grep -q "error"; then
            GENERATED_CODE=$(echo "$API_RESPONSE" | jq -r '.candidates[0].content.parts[0].text')
            if [ -n "$GENERATED_CODE" ] && [ "$GENERATED_CODE" != "null" ]; then
              ui_body_code="$GENERATED_CODE"
              echo "  [SUCCESS] AI-generated UI will be used." >&2
            else
              echo "  [WARNING] AI did not return any code. Using default UI instead." >&2
            fi
            break # Exit the loop on success

          # Case 2: Recoverable Error (Model is overloaded)
          elif echo "$API_RESPONSE" | grep -q "overloaded"; then
            echo "  [WARNING] The Gemini API is temporarily overloaded." >&2
            echo -n "  Would you like to try again or use the default UI? (try/default): " >&2
            read RETRY_CHOICE
            if [[ "$RETRY_CHOICE" == "try" || "$RETRY_CHOICE" == "t" ]]; then
              echo "  Retrying..." >&2
              sleep 1 # Wait a second before trying again
              continue # Go back to the start of the loop
            else
              echo "  Using default UI." >&2
              break # Exit the loop and use the default
            fi

          # Case 3: All other unrecoverable errors
          else
            echo "  [ERROR] The API returned an unrecoverable error:" >&2
            echo "$API_RESPONSE" >&2
            echo "  Using default UI instead." >&2
            break # Exit the loop and use the default
          fi
        done
      fi
    fi
  fi
  
  # This is the ONLY echo command that writes to stdout.
  # It returns the final code (either the default or the AI-generated one).
  echo "$ui_body_code"
}