#!/usr/bin/env python3
"""
Quick fix script to ensure all 'weapon' instances are properly capitalized
"""

import re

def fix_weapon_case(filename):
    """Fix any lowercase 'weapon' class references"""
    try:
        with open(filename, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Count original occurrences
        lowercase_count = len(re.findall(r'is\s+"weapon"', content, re.IGNORECASE))
        
        # Fix the issue - replace 'is "weapon"' with 'is "Weapon"'
        fixed_content = re.sub(r'is\s+"weapon"', 'is "Weapon"', content, flags=re.IGNORECASE)
        
        # Also fix any standalone weapon checks
        fixed_content = re.sub(r'item\s+is\s+"weapon"', 'item is "Weapon"', fixed_content, flags=re.IGNORECASE)
        
        # Count fixes
        fixes_made = content != fixed_content
        
        if fixes_made:
            # Backup original
            with open(filename + '.backup', 'w', encoding='utf-8') as f:
                f.write(content)
            
            # Write fixed version
            with open(filename, 'w', encoding='utf-8') as f:
                f.write(fixed_content)
            
            print(f"Fixed {lowercase_count} instances of lowercase 'weapon'")
            print(f"Backup saved as {filename}.backup")
        else:
            print("No lowercase 'weapon' found - file appears correct")
            
        # Show the line around 487
        lines = fixed_content.split('\n')
        if len(lines) > 487:
            print(f"\nLine 487 content:")
            for i in range(max(0, 486), min(len(lines), 490)):
                print(f"{i+1}: {lines[i]}")
                
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    fix_weapon_case("collectibles_native.zs")