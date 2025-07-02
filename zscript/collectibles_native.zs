// Selaco Collectibles Map Mod v4.0 - Native Sprite Edition
// Fixed for Selaco v0.34+ compatibility

// Marker categories enum
enum EMarkerCategory {
    MARKER_COLLECTIBLE,
    MARKER_HEALTH,
    MARKER_ARMOR,
    MARKER_AMMO,
    MARKER_WEAPON,
    MARKER_POWERUP,
    MARKER_SECRET,
    MARKER_KEY,
    MARKER_MISC
}

// Scanner powerup for map reveal
class SCMv2_Scanner : PowerupGiver {
    default {
        +INVENTORY.AUTOACTIVATE
        +INVENTORY.ALWAYSPICKUP
        Inventory.MaxAmount 0;
        Powerup.Type "PowerScanner";
        Powerup.Duration 1;
    }
}

// Base marker class using native sprites
class SCMv2_MarkerBase : MasterMarker {
    Actor trackedItem;
    int markerCategory;
    double pulseTime;
    double baseScale;
    double baseAlpha;
    
    default {
        +NOINTERACTION
        +NOGRAVITY
        +BRIGHT
        +FORCEXYBILLBOARD
        RenderStyle "Add";
        Alpha 0.8;
        Scale 0.5;
    }
    
    override void BeginPlay() {
        super.BeginPlay();
        baseScale = scale.x;
        baseAlpha = alpha;
        SetupMarkerStyle();
    }
    
    virtual void SetupMarkerStyle() {
        // Override in subclasses
    }
    
    override void Tick() {
        super.Tick();
        
        if(!trackedItem || trackedItem.bDORMANT) {
            HandleItemRemoval();
            return;
        }
        
        SetOrigin(trackedItem.pos, true);
        UpdateVisuals();
    }
    
    virtual void UpdateVisuals() {
        // Update scale from user settings
        float markerScale = CVar.GetCVar("scm_marker_size", players[consoleplayer]).GetFloat();
        
        // Add pulse effect for important items
        if(ShouldPulse()) {
            pulseTime += 0.05;
            double pulse = sin(pulseTime * 180.0) * 0.15 + 1.0;
            scale = (markerScale * baseScale * pulse, markerScale * baseScale * pulse);
            alpha = baseAlpha + (sin(pulseTime * 180.0) * 0.2);
        } else {
            scale = (markerScale * baseScale, markerScale * baseScale);
        }
        
        // Apply style variations
        int styleMode = CVar.GetCVar("scm_marker_style", players[consoleplayer]).GetInt();
        if(styleMode == 2) { // Minimal mode
            alpha *= 0.6;
            scale *= 0.8;
        }
    }
    
    virtual bool ShouldPulse() {
        return markerCategory == MARKER_COLLECTIBLE || 
               markerCategory == MARKER_SECRET ||
               markerCategory == MARKER_KEY;
    }
    
    void HandleItemRemoval() {
        if (CVar.GetCVar("scm_show_cleared", players[consoleplayer]).GetBool()) {
            let cleared = Actor.Spawn("SCMv2_MarkerCleared", pos);
            if (cleared) {
                cleared.scale = scale * 0.7;  // Make cleared markers 70% of original size
                SCMv2_MarkerCleared(cleared).previousCategory = markerCategory;
            }
        }
        Destroy();
    }
}

// Collectible marker - Uses data pad sprite with purple glow
class SCMv2_MarkerCollectible : SCMv2_MarkerBase {
    default {
        Scale 0.5;  // Standardized
        Alpha 0.9;
    }
    
    override void BeginPlay() {
        super.BeginPlay();
        markerCategory = MARKER_COLLECTIBLE;
        
        // Try to use actual collectible sprites
        if(trackedItem) {
            string itemClass = trackedItem.GetClassName();
            if(itemClass.IndexOf("DataPad") >= 0 || itemClass.IndexOf("DataLog") >= 0) {
                sprite = GetSpriteIndex("LOGB");  // Data log sprite
                frame = 0;
            }
        }
    }
    
    override void SetupMarkerStyle() {
        // Purple/sapphire tint for collectibles
        A_SetTranslation("0:255=%[0,0,0]:[0.6,0.4,1.0]");
    }
    
    States {
        Spawn:
            PFLA H -1 Bright;  // Purple flare as default
            Stop;
    }
}

// Health marker - Already uses native health cross icon
class SCMv2_MarkerHealth : SCMv2_MarkerBase {
    default {
        Scale 0.5;  // Standardized
        Alpha 0.7;
        RenderStyle "Normal"; // Icon looks better without additive
    }
    
    override void BeginPlay() {
        super.BeginPlay();
        markerCategory = MARKER_HEALTH;
    }
    
    States {
        Spawn:
            ZZZD A -1 Bright;  // Medical cross icon
            Stop;
    }
}

// Armor marker - Uses armor pickup sprite
class SCMv2_MarkerArmor : SCMv2_MarkerBase {
    default {
        Scale 0.5;  // Standardized
        Alpha 0.7;
        RenderStyle "Normal";  // Better for icon visibility
    }
    
    override void BeginPlay() {
        super.BeginPlay();
        markerCategory = MARKER_ARMOR;
    }
    
    override void SetupMarkerStyle() {
        // Green tint for armor
        A_SetTranslation("0:255=%[0,0,0]:[0.2,1.0,0.2]");
    }
    
    States {
        Spawn:
            BON2 A -1 Bright;  // Try armor bonus sprite
            Stop;
    }
}

// Ammo marker - Already has dynamic icon selection
class SCMv2_MarkerAmmo : SCMv2_MarkerBase {
    default {
        Scale 0.5;  // Standardized
        Alpha 0.5;
        RenderStyle "Translucent";
    }
    
    override void BeginPlay() {
        super.BeginPlay();
        markerCategory = MARKER_AMMO;
        
        // Choose appropriate ammo icon based on item type
        if(trackedItem) {
            string itemClass = trackedItem.GetClassName();
            
            // Check for specific ammo types
            if(itemClass.IndexOf("Shell") >= 0 || itemClass.IndexOf("SHOTGUN") >= 0) {
                sprite = GetSpriteIndex("ZZZB"); // Shell icon
            } else if(itemClass.IndexOf("Cricket") >= 0 || itemClass.IndexOf("ROARING") >= 0) {
                sprite = GetSpriteIndex("ZZZG"); // Cricket icon
            } else if(itemClass.IndexOf("Energy") >= 0 || itemClass.IndexOf("ENERGY") >= 0) {
                sprite = GetSpriteIndex("ZZZM"); // Energy icon
            } else if(itemClass.IndexOf("Railgun") >= 0 || itemClass.IndexOf("RAIL") >= 0) {
                sprite = GetSpriteIndex("ZZZN"); // Railgun icon
                frame = 0; // Frame A
            } else if(itemClass.IndexOf("DMR") >= 0 || itemClass.IndexOf("Rifle") >= 0) {
                sprite = GetSpriteIndex("ZZZN"); // DMR icon
                frame = 1; // Frame B
            } else if(itemClass.IndexOf("Grenade") >= 0) {
                sprite = GetSpriteIndex("ZZZY"); // Grenade icon
            } else {
                sprite = GetSpriteIndex("ZZZA"); // Generic ammo icon
            }
        }
    }
    
    States {
        Spawn:
            #### # -1 Bright;
            Stop;
    }
}

// Weapon marker - Uses the actual pickup sprite
class SCMv2_MarkerWeapon : SCMv2_MarkerBase {
    default {
        Scale 0.5;
        Alpha 0.8;
    }
    
    override void BeginPlay() {
        super.BeginPlay();
        markerCategory = MARKER_WEAPON;
        
        // Try to use the actual weapon pickup's sprite
        if(trackedItem && trackedItem.sprite > 0) {
            sprite = trackedItem.sprite;
            frame = trackedItem.frame;
        }
    }
    
    override void SetupMarkerStyle() {
        // Light green glow for weapons
        A_SetTranslation("0:255=%[0,0,0]:[0.7,1.0,0.7]");
    }
    
    States {
        Spawn:
            #### # -1 Bright;  // Uses dynamic sprite
            VOXE L -1 Bright;  // Fallback
            Stop;
    }
}

// Powerup marker - Uses rotating orb with purple energy
class SCMv2_MarkerPowerup : SCMv2_MarkerBase {
    default {
        Scale 0.5;  // Standardized
        Alpha 0.9;
        RenderStyle "Add";  // Glowing effect
    }
    
    override void BeginPlay() {
        super.BeginPlay();
        markerCategory = MARKER_POWERUP;
        
        // Try to use actual powerup sprite
        if(trackedItem && trackedItem.sprite > 0) {
            sprite = trackedItem.sprite;
            frame = trackedItem.frame;
        }
    }
    
    override void SetupMarkerStyle() {
        // Purple/energy tint
        A_SetTranslation("0:255=%[0,0,0]:[0.9,0.2,0.9]");
    }
    
    override void UpdateVisuals() {
        super.UpdateVisuals();
        // Rotate powerup markers
        angle += 2;
    }
    
    States {
        Spawn:
            #### # -1 Bright;  // Uses dynamic sprite
            PFLA H -1 Bright;  // Fallback purple flare
            Stop;
    }
}

// Secret marker - Intense golden star
class SCMv2_MarkerSecret : SCMv2_MarkerBase {
    default {
        Scale 0.5;  // Standardized
        Alpha 1.0;
        RenderStyle "Add";
    }
    
    override void BeginPlay() {
        super.BeginPlay();
        markerCategory = MARKER_SECRET;
    }
    
    override void SetupMarkerStyle() {
        // Golden glow for secrets
        A_SetTranslation("0:255=%[0,0,0]:[1.0,0.8,0.2]");
    }
    
    override void UpdateVisuals() {
        super.UpdateVisuals();
        // Intense pulsing for secrets
        pulseTime += 0.03;
        alpha = (sin(pulseTime * 180.0) * 0.4) + 0.6;
    }
    
    States {
        Spawn:
            BON3 A -1 Bright;  // Try using soul sphere sprite for secrets
            Stop;
    }
}

// Key marker - Already uses color-coded VOXE sprite
class SCMv2_MarkerKey : SCMv2_MarkerBase {
    default {
        Scale 0.5;
        Alpha 0.9;
        RenderStyle "Normal"; // Keys look better solid
    }
    
    override void BeginPlay() {
        super.BeginPlay();
        markerCategory = MARKER_KEY;
        
        // Set color based on key type
        if(trackedItem) {
            string itemClass = trackedItem.GetClassName();
            
            if(itemClass.IndexOf("BLUE") >= 0) {
                A_SetTranslation("0:255=%[0,0,0]:[0.3,0.7,1.0]");
            } else if(itemClass.IndexOf("YELLOW") >= 0) {
                A_SetTranslation("0:255=%[0,0,0]:[1.0,1.0,0.3]");
            } else if(itemClass.IndexOf("RED") >= 0) {
                A_SetTranslation("0:255=%[0,0,0]:[1.0,0.3,0.3]");
            } else if(itemClass.IndexOf("PURPLE") >= 0) {
                A_SetTranslation("0:255=%[0,0,0]:[0.8,0.3,0.8]");
            }
        }
    }
    
    States {
        Spawn:
            VOXE L -1 Bright;  // Key sprite
            Stop;
    }
}

// Cleared marker - Faded X indicator
class SCMv2_MarkerCleared : MasterMarkerCleared {
    int previousCategory;
    
    default {
        +BRIGHT
        +FORCEXYBILLBOARD
        Alpha 0.2;
        RenderStyle "Translucent";
        Scale 0.35;  // Slightly smaller than active markers
    }
    
    override void BeginPlay() {
        super.BeginPlay();
        A_SetTranslation("Ice"); // Grayscale effect
    }
    
    States {
        Spawn:
            PFLA H -1;  // Faded flare
            Stop;
    }
}

// Main event handler
class SCMv2_Handler : EventHandler {
    Array<SCMv2_MarkerBase> markers;
    bool levelRevealed;
    int updateTimer;
    
    override void WorldLoaded(WorldEvent e) {
        ClearAllMarkers();
        levelRevealed = false;
        updateTimer = 0;
        if (CVar.GetCVar("scm_autoreveal_map", players[consoleplayer]).GetBool()) {
            DoMapReveal();
        }
    }
    
    override void PlayerEntered(PlayerEvent e) {
        if(!levelRevealed && CVar.GetCVar("scm_autoreveal_map", players[consoleplayer]).GetBool()) {
            DoMapReveal();
        }
    }
    
    override void WorldTick() {
        // Get update frequency from settings
        int updateFreq = CVar.GetCVar("scm_update_frequency", players[consoleplayer]).GetInt();
        
        // Throttle updates for performance
        updateTimer++;
        if(updateTimer < updateFreq) return;
        updateTimer = 0;
        
        // Check which categories are enabled
        bool trackCollectibles = CVar.GetCVar("scm_track_collectibles", players[consoleplayer]).GetBool();
        bool trackAllPickups = CVar.GetCVar("scm_track_all_pickups", players[consoleplayer]).GetBool();
        bool trackHealth = CVar.GetCVar("scm_track_health", players[consoleplayer]).GetBool();
        bool trackArmor = CVar.GetCVar("scm_track_armor", players[consoleplayer]).GetBool();
        bool trackAmmo = CVar.GetCVar("scm_track_ammo", players[consoleplayer]).GetBool();
        bool trackWeapons = CVar.GetCVar("scm_track_weapons", players[consoleplayer]).GetBool();
        bool trackPowerups = CVar.GetCVar("scm_track_powerups", players[consoleplayer]).GetBool();
        bool trackKeys = CVar.GetCVar("scm_track_keys", players[consoleplayer]).GetBool();
        
        if (!trackCollectibles && !trackAllPickups && !trackHealth && 
            !trackArmor && !trackAmmo && !trackWeapons && !trackPowerups && !trackKeys) {
            ClearAllMarkers();
            return;
        }
        
        // Find items to track
        ThinkerIterator it = ThinkerIterator.Create("Inventory");
        Actor item;
        
        while(item = Actor(it.Next())) {
            if(!item || item.bDORMANT) continue;
            
            let inv = Inventory(item);
            if(inv && inv.owner) continue;
            
            if(!HasMarker(item)) {
                int category = GetItemCategory(item);
                bool shouldTrack = ShouldTrackItem(category, trackCollectibles, trackHealth, 
                                                  trackArmor, trackAmmo, trackWeapons, 
                                                  trackPowerups, trackKeys, trackAllPickups);
                
                if(shouldTrack) {
                    CreateMarker(item, category);
                }
            }
        }
        
        CleanupNullMarkers();
    }
    
    int GetItemCategory(Actor item) {
        string className = item.GetClassName();
        
        // Check Selaco-specific collectibles
        if(className ~== "SelacoCollectible" || 
           className ~== "DataLog" ||
           className ~== "DataPad" ||
           className.IndexOf("Collectible") >= 0) {
            return MARKER_COLLECTIBLE;
        }
        
        // Check for secrets
        if(item.bCOUNTSECRET || className.IndexOf("Secret") >= 0) {
            return MARKER_SECRET;
        }
        
        // Check keys - Selaco uses card pickups
        if(className.IndexOf("CARD_PICKUP") >= 0 || 
           className.IndexOf("CARD") >= 0 ||
           className.IndexOf("Key") >= 0) {
            return MARKER_KEY;
        }
        
        // Check health items - String matching approach
        if(className.IndexOf("Health") >= 0 ||
           className.IndexOf("Medkit") >= 0 || 
           className.IndexOf("HEALTH") >= 0 ||
           className.IndexOf("Medical") >= 0 ||
           className.IndexOf("Protein") >= 0 ||
           className.IndexOf("Heal") >= 0) {
            return MARKER_HEALTH;
        }
        
        // Check armor - String matching approach
        if(className.IndexOf("Armor") >= 0 ||
           className.IndexOf("ARMOR") >= 0 ||
           className.IndexOf("Vest") >= 0 ||
           className.IndexOf("VEST") >= 0) {
            return MARKER_ARMOR;
        }
        
        // Check ammo - String matching approach
        if(className.IndexOf("Ammo") >= 0 ||
           className.IndexOf("AmmoPickup") >= 0 ||
           className.IndexOf("ROUNDS") >= 0 || 
           className.IndexOf("SHELL") >= 0 ||
           className.IndexOf("ENERGY") >= 0 ||
           className.IndexOf("Clip") >= 0 ||
           className.IndexOf("Reserve") >= 0) {
            return MARKER_AMMO;
        }
        
        // Check weapons - String matching only (avoiding type check issues)
        if(className.IndexOf("WEAPON") >= 0 ||
           className.IndexOf("Weapon") >= 0 ||
           className.IndexOf("_PICKUP") >= 0 ||
           className.IndexOf("Shotgun") >= 0 ||
           className.IndexOf("Cricket") >= 0 ||
           className.IndexOf("SMG") >= 0 ||
           className.IndexOf("Rifle") >= 0 ||
           className.IndexOf("Pistol") >= 0 ||
           className.IndexOf("Nailgun") >= 0 ||
           className.IndexOf("Railgun") >= 0 ||
           className.IndexOf("PlasmaRifle") >= 0 ||
           className.IndexOf("DMR") >= 0) {
            return MARKER_WEAPON;
        }
        
        // Check powerups - String matching approach
        if(className.IndexOf("PowerupGiver") >= 0 ||
           className.IndexOf("Powerup") >= 0 ||
           className.IndexOf("Power") >= 0) {
            return MARKER_POWERUP;
        }
        
        return MARKER_MISC;
    }
    
    bool ShouldTrackItem(int category, bool trackCollectibles, bool trackHealth,
                        bool trackArmor, bool trackAmmo, bool trackWeapons,
                        bool trackPowerups, bool trackKeys, bool trackAllPickups) {
        if(trackAllPickups) return true;
        
        switch(category) {
            case MARKER_COLLECTIBLE:
            case MARKER_SECRET:
                return trackCollectibles;
            case MARKER_HEALTH:
                return trackHealth;
            case MARKER_ARMOR:
                return trackArmor;
            case MARKER_AMMO:
                return trackAmmo;
            case MARKER_WEAPON:
                return trackWeapons;
            case MARKER_POWERUP:
                return trackPowerups;
            case MARKER_KEY:
                return trackKeys;
        }
        
        return trackAllPickups;
    }
    
    void CreateMarker(Actor item, int category) {
        SCMv2_MarkerBase marker;
        
        // Create appropriate marker type
        switch(category) {
            case MARKER_COLLECTIBLE:
                marker = SCMv2_MarkerCollectible(Actor.Spawn("SCMv2_MarkerCollectible", item.pos));
                break;
            case MARKER_HEALTH:
                marker = SCMv2_MarkerHealth(Actor.Spawn("SCMv2_MarkerHealth", item.pos));
                break;
            case MARKER_ARMOR:
                marker = SCMv2_MarkerArmor(Actor.Spawn("SCMv2_MarkerArmor", item.pos));
                break;
            case MARKER_AMMO:
                marker = SCMv2_MarkerAmmo(Actor.Spawn("SCMv2_MarkerAmmo", item.pos));
                break;
            case MARKER_WEAPON:
                marker = SCMv2_MarkerWeapon(Actor.Spawn("SCMv2_MarkerWeapon", item.pos));
                break;
            case MARKER_POWERUP:
                marker = SCMv2_MarkerPowerup(Actor.Spawn("SCMv2_MarkerPowerup", item.pos));
                break;
            case MARKER_SECRET:
                marker = SCMv2_MarkerSecret(Actor.Spawn("SCMv2_MarkerSecret", item.pos));
                break;
            case MARKER_KEY:
                marker = SCMv2_MarkerKey(Actor.Spawn("SCMv2_MarkerKey", item.pos));
                break;
            default:
                marker = SCMv2_MarkerBase(Actor.Spawn("SCMv2_MarkerBase", item.pos));
                break;
        }
        
        if(marker) {
            marker.trackedItem = item;
            markers.Push(marker);
        }
    }
    
    bool HasMarker(Actor item) {
        for(int i = 0; i < markers.Size(); i++) {
            if(markers[i] && markers[i].trackedItem == item) {
                return true;
            }
        }
        return false;
    }
    
    void CleanupNullMarkers() {
        for(int i = 0; i < markers.Size(); i++) {
            if(!markers[i]) {
                markers.Delete(i);
                i--;
            }
        }
    }
    
    void ClearAllMarkers() {
        for(int i = 0; i < markers.Size(); i++) {
            if(markers[i]) {
                markers[i].Destroy();
            }
        }
        markers.Clear();
    }
    
    void DoMapReveal() {
        if(levelRevealed) return;
        levelRevealed = true;
        
        let player = players[consoleplayer].mo;
        if(!player) return;
        
        player.GiveInventory("SCMv2_Scanner", 1);
        
        for(int i = 0; i < level.sectors.Size(); i++) {
            level.sectors[i].MoreFlags |= Sector.SECMF_DRAWN;
        }
        
        for(int i = 0; i < level.lines.Size(); i++) {
            level.lines[i].flags |= Line.ML_MAPPED;
        }
        
        Console.Printf("\\c[yellow]Collectibles Mod v4.0: Map revealed!");
    }
}