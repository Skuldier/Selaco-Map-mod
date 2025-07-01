#!/usr/bin/env python3
"""
Selaco Collectibles Mod v4.0 - Native Sprite Edition
Build script for the lightweight native sprite version
"""

import os
import zipfile
import shutil
from pathlib import Path
import datetime

# Configuration
MOD_NAME = "SelacoCollectiblesNative"
MOD_VERSION = "4.0"
SELACO_MODS_PATH = r"C:\Program Files (x86)\Steam\steamapps\common\Selaco\Mods"

def clean_old_versions():
    """Remove all old versions of the mod"""
    mods_path = Path(SELACO_MODS_PATH)
    if not mods_path.exists():
        print(f"[WARNING] Mods path not found: {mods_path}")
        return
    
    print("\nCleaning old versions...")
    patterns = [
        "*CollectiblesMod*.pk3",
        "*collectibles*.pk3",
        "*CollectiblesNative*.pk3",
        "SCM*.pk3"
    ]
    
    removed = 0
    for pattern in patterns:
        for file in mods_path.glob(pattern):
            try:
                file.unlink()
                print(f"  Removed: {file.name}")
                removed += 1
            except Exception as e:
                print(f"  [ERROR] Could not remove {file.name}: {e}")
    
    if removed == 0:
        print("  No old versions found")
    else:
        print(f"  Removed {removed} old version(s)")

def build_mod():
    """Build the mod with all files"""
    build_dir = Path("build")
    
    print(f"\nBuilding {MOD_NAME} v{MOD_VERSION}...")
    
    if build_dir.exists():
        shutil.rmtree(build_dir)
    
    build_dir.mkdir()
    (build_dir / "zscript").mkdir()
    
    print("\nCreating mod files...")
    
    # Create CVARINFO
    cvarinfo_content = """// Collectibles Mod CVars
server bool scm_track_collectibles = true;
server bool scm_track_all_pickups = false;
server bool scm_track_health = false;
server bool scm_track_armor = false;
server bool scm_track_ammo = false;
server bool scm_track_weapons = false;
server bool scm_track_powerups = false;
server bool scm_track_keys = true;
server bool scm_autoreveal_map = true;
server bool scm_show_cleared = true;
server float scm_marker_size = 1.0;
server int scm_marker_style = 0;
server int scm_update_frequency = 10;
"""
    (build_dir / "CVARINFO").write_text(cvarinfo_content, encoding='utf-8')
    print("  Created: CVARINFO")
    
    # Create MENUDEF
    menudef_content = """// Add to existing ModOptionsMenu
AddOptionMenu "ModOptionsMenu" {
    Submenu "Collectibles Tracker", "SCMv2_Options"
}

OptionMenu "SCMv2_Options" {
    Title "Collectibles Tracker Options"
    
    StaticText " "
    StaticText "General Options", 1
    StaticText " "
    Option "Auto-Reveal Map", "scm_autoreveal_map", "OnOff"
    Option "Show Cleared Markers", "scm_show_cleared", "OnOff"
    Option "Track All Pickups", "scm_track_all_pickups", "OnOff"
    
    StaticText " "
    StaticText "Item Categories", 1
    StaticText " "
    Option "Track Collectibles", "scm_track_collectibles", "OnOff"
    Option "Track Health Items", "scm_track_health", "OnOff"
    Option "Track Armor Items", "scm_track_armor", "OnOff"
    Option "Track Ammunition", "scm_track_ammo", "OnOff"
    Option "Track Weapons", "scm_track_weapons", "OnOff"
    Option "Track Powerups", "scm_track_powerups", "OnOff"
    Option "Track Keys", "scm_track_keys", "OnOff"
    
    StaticText " "
    StaticText "Display Options", 1
    StaticText " "
    Slider "Marker Size", "scm_marker_size", 0.1, 2.0, 0.1, 1
    Option "Marker Style", "scm_marker_style", "MarkerStyles"
    Slider "Update Frequency", "scm_update_frequency", 1, 35, 5, 0
    
    StaticText " "
    StaticText "Performance: Lower update frequency for better FPS", "White"
}

OptionValue "MarkerStyles" {
    0, "Native Icons"
    1, "Flare Only"
    2, "Minimal"
}
"""
    (build_dir / "MENUDEF").write_text(menudef_content, encoding='utf-8')
    print("  Created: MENUDEF")
    
    # Create zscript.txt
    zscript_content = """version "4.6"
#include "zscript/collectibles_native.zs"
"""
    (build_dir / "zscript.txt").write_text(zscript_content, encoding='utf-8')
    print("  Created: zscript.txt")
    
    # Create main zscript file
    # Read from the existing file if it exists, otherwise use embedded code
    zscript_file = Path("collectibles_native.zs")
    if zscript_file.exists():
        zscript_code = zscript_file.read_text(encoding='utf-8')
        print("  Using existing collectibles_native.zs")
    else:
        print("  [WARNING] collectibles_native.zs not found, using embedded code")
        # You would need to include the full code here or error out
        print("  Please ensure collectibles_native.zs is in the same directory")
        return None
    
    (build_dir / "zscript" / "collectibles_native.zs").write_text(zscript_code, encoding='utf-8')
    print("  Created: zscript/collectibles_native.zs")
    
    # Create mapinfo.txt
    mapinfo_content = """GameInfo {
    AddEventHandlers = "SCMv2_Handler"
}
"""
    (build_dir / "mapinfo.txt").write_text(mapinfo_content, encoding='utf-8')
    print("  Created: mapinfo.txt")
    
    # Create language file
    language_content = """[enu default]
COLLECTIBLES_MAP_REVEALED = "\\c[yellow]Collectibles Mod v4.0: Map revealed!";
MAPICON_COLLECTIBLE = "Collectible";
MAPICON_HEALTH = "Health";
MAPICON_ARMOR = "Armor";
MAPICON_AMMO = "Ammunition";
MAPICON_WEAPON = "Weapon";
MAPICON_POWERUP = "Powerup";
MAPICON_KEY = "Keycard";
MAPICON_SECRET = "Secret";
"""
    (build_dir / "language.enu").write_text(language_content, encoding='utf-8')
    print("  Created: language.enu")
    
    # Create README
    readme_content = f"""Selaco Collectibles Map Mod v{MOD_VERSION} - Native Sprite Edition
================================================================

This lightweight version uses Selaco's built-in sprites for perfect visual integration.

FEATURES:
---------
• Uses native game sprites - no custom graphics needed
• Track collectibles, keys, health, armor, ammo, weapons, powerups
• Auto-reveal entire map
• Customizable marker size and style
• Cleared item indicators
• Performance options
• Category filtering

VISUAL STYLE:
-------------
• Collectibles: Purple glowing flare (PFLA sprite)
• Health: Red medical cross icon (ZZZD sprite)  
• Armor: Green glowing flare
• Ammo: Type-specific icons (shells, energy, etc.)
• Weapons: Bright green flare
• Powerups: Rotating purple energy
• Secrets: Intense golden glow
• Keys: Color-coded by type (VOXE sprite)

PERFORMANCE:
------------
• Adjustable update frequency (1-35 ticks)
• Minimal memory footprint
• No additional textures to load
• Optimized for smooth gameplay

INSTALLATION:
-------------
Place {MOD_NAME}_v{MOD_VERSION}.pk3 in your Selaco Mods folder

Built: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
Version: {MOD_VERSION}
"""
    (build_dir / "readme.txt").write_text(readme_content, encoding='utf-8')
    print("  Created: readme.txt")
    
    # Create PK3
    pk3_name = f"{MOD_NAME}_v{MOD_VERSION}.pk3"
    print(f"\nCreating {pk3_name}...")
    
    with zipfile.ZipFile(pk3_name, 'w', zipfile.ZIP_DEFLATED) as pk3:
        for file_path in build_dir.rglob('*'):
            if file_path.is_file():
                arcname = file_path.relative_to(build_dir)
                pk3.write(file_path, arcname)
                print(f"  Added: {arcname}")
    
    # Get file size
    file_size = os.path.getsize(pk3_name) / 1024  # Size in KB
    print(f"\nMod size: {file_size:.1f} KB")
    
    shutil.rmtree(build_dir)
    
    return Path(pk3_name)

def deploy_mod(pk3_path):
    """Deploy the mod"""
    mods_path = Path(SELACO_MODS_PATH)
    dest_path = mods_path / pk3_path.name
    
    try:
        shutil.copy2(pk3_path, dest_path)
        print(f"\n[OK] Deployed to: {dest_path}")
        return True
    except Exception as e:
        print(f"\n[ERROR] Deployment failed: {e}")
        return False

def main():
    print("="*60)
    print(f"Selaco Collectibles Mod v{MOD_VERSION} - Native Sprite Edition")
    print("="*60)
    
    print("\n✨ NATIVE SPRITE VERSION FEATURES:")
    print("   • No custom sprites needed")
    print("   • Uses Selaco's built-in graphics")
    print("   • Smaller file size (~50 KB)")
    print("   • Better performance")
    print("   • Perfect visual integration")
    print("="*60)
    
    # Check for the zscript file
    if not Path("collectibles_native.zs").exists():
        print("\n[ERROR] collectibles_native.zs not found!")
        print("Please ensure the ZScript file is in the same directory as this build script.")
        input("\nPress Enter to exit...")
        return
    
    print("\nIMPORTANT: Make sure Selaco is CLOSED!")
    response = input("\nIs Selaco closed? (y/n): ").lower().strip()
    
    if response != 'y':
        print("\nPlease close Selaco first.")
        input("Press Enter to exit...")
        return
    
    clean_old_versions()
    
    pk3_path = build_mod()
    
    if not pk3_path:
        input("\nPress Enter to exit...")
        return
    
    if deploy_mod(pk3_path):
        print("\n" + "="*60)
        print("SUCCESS! NATIVE SPRITE VERSION INSTALLED!")
        print("="*60)
        print("\nYour collectibles mod now uses Selaco's native sprites:")
        print("✓ Purple flares for collectibles")
        print("✓ Medical crosses for health")
        print("✓ Type-specific ammo icons")
        print("✓ Color-coded keycards")
        print("✓ And more!")
        print("\nEnjoy the lightweight, integrated experience!")
    else:
        print(f"\nManually copy {pk3_path} to your Mods folder.")
    
    input("\nPress Enter to exit...")

if __name__ == "__main__":
    main()