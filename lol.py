import re

# Input and output paths
input_path = r"C:\Users\mattf\Downloads\New folder (102)\FNF-Psych-Engine-with-3d-mods\source\objects\Character.hx"
output_path = r"C:\Users\mattf\Downloads\New folder (102)\FNF-Psych-Engine-with-3d-mods\source\objects\Character_FIXED.hx"

# Vars duplicated in both engines – keep first only
DUPLICATE_VARS = [
    "animOffsets",
    "debugMode",
    "isPlayer",
    "curCharacter",
    "holdTimer"
]

def remove_duplicate_vars(text):
    lines = text.split("\n")
    seen = set()
    result = []

    var_pattern = re.compile(r"^\s*public var (\w+)\b")

    for line in lines:
        m = var_pattern.match(line)
        if m:
            varname = m.group(1)
            if varname in DUPLICATE_VARS:
                if varname in seen:
                    # skip duplicate definition
                    continue
                seen.add(varname)

        result.append(line)

    return "\n".join(result)


print("[INFO] Loading Character.hx…")
with open(input_path, "r", encoding="utf-8") as f:
    code = f.read()

print("[INFO] Removing duplicate vars…")
fixed = remove_duplicate_vars(code)

print(f"[INFO] Saving cleaned Character.hx → {output_path}")
with open(output_path, "w", encoding="utf-8") as f:
    f.write(fixed)

print("✅ DONE — Duplicates removed successfully!")
