import json
import sys

file_path = r"C:\Users\DELL\AppData\Roaming\Code\User\settings.json"

try:
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Try parsing
    data = json.loads(content)
    print("VALID_JSON")
    
except json.JSONDecodeError as e:
    print(f"INVALID_JSON: {e}")
    # Print context around error
    lines = content.split('\n')
    err_line = e.lineno - 1
    start = max(0, err_line - 2)
    end = min(len(lines), err_line + 3)
    for i in range(start, end):
        print(f"{i+1}: {lines[i]}")
except Exception as e:
    print(f"ERROR: {e}")
