import json
import sys

file_path = r"C:\Users\DELL\AppData\Roaming\Code\User\settings.json"

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if "【设定说明】" in line and "testGeneration" not in line and "codeGeneration" not in line and "Commit" not in line and "PR" not in line and "review" not in line and "Review" not in line:
        # This naive check tries to find the broken line.
        # But better to just look around the area where we suspect damage (around line 64)
        pass

# Print all lines to see the current state of headers
print("--- CONTEXT ---")
for i, line in enumerate(lines):
    if "===" in line:
        print(f"LINE_{i+1}: {line.rstrip()}")
