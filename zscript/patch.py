#!/usr/bin/env python3
"""
Automatically fix the weapon check issue in collectibles_native.zs
"""

import re

def fix_weapon_check():
    # Read the file
    with open('collectibles_native.zs', 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Find and replace the weapon check section
    # Look for the pattern around line 487
    old_pattern = r'// Check weapons.*?\n\s+if\s*\(\s*item\s+is\s+"Weapon".*?\n.*?\n.*?\n.*?\n\s+return MARKER_WEAPON;\n\s+\}'
    
    new_code = '''// Check weapons - WORKAROUND VERSION
        // Avoiding 'is' operator due to parser bug
        let wpn = Weapon(item);  // Try casting to Weapon class
        if(wpn || 
           className.IndexOf("WEAPON") >= 0 ||
           className.IndexOf("Shotgun") >= 0 ||
           className.IndexOf("Cricket") >= 0) {
            return MARKER_WEAPON;
        }'''
    
    # Try to replace
    if re.search(old_pattern, content, re.DOTALL):
        new_content = re.sub(old_pattern, new_code, content, flags=re.DOTALL)
        print("Found and replaced weapon check pattern")
    else:
        # Alternative: Just replace the specific line
        lines = content.split('\n')
        for i, line in enumerate(lines):
            if 'if(item is "Weapon"' in line or 'if(item is "weapon"' in line:
                print(f"Found problematic line at {i+1}: {line}")
                # Replace this section
                indent = len(line) - len(line.lstrip())
                new_lines = [
                    ' ' * indent + '// Check weapons - WORKAROUND VERSION',
                    ' ' * indent + '// Avoiding \'is\' operator due to parser bug',
                    ' ' * indent + 'let wpn = Weapon(item);  // Try casting to Weapon class',
                    ' ' * indent + 'if(wpn ||'
                ]
                lines[i] = new_lines[0]
                lines.insert(i+1, new_lines[1])
                lines.insert(i+2, new_lines[2])
                lines.insert(i+3, new_lines[3])
                new_content = '\n'.join(lines)
                break
        else:
            print("ERROR: Could not find the weapon check line!")
            return False
    
    # Write the fixed version
    with open('collectibles_native_fixed.zs', 'w', encoding='utf-8') as f:
        f.write(new_content)
    
    print("\nCreated fixed version: collectibles_native_fixed.zs")
    print("\nTo use it:")
    print("1. Rename collectibles_native.zs to collectibles_native_backup.zs")
    print("2. Rename collectibles_native_fixed.zs to collectibles_native.zs")
    print("3. Run build_native.py again")
    
    return True

if __name__ == "__main__":
    fix_weapon_check()