// Selaco Collectibles Map Mod v3.1.4 - Fixed Caching Issue
// Shows collectibles on map with customizable options

// Map marker for collectibles
class SCMv2_Marker : MasterMarker {
    Actor trackedItem;
    
    default {
        +NOINTERACTION
        +NOGRAVITY
        +BRIGHT
        RenderStyle "Normal";
        Alpha 1.0;
    }
    
    override void BeginPlay() {
        super.BeginPlay();
        UpdateColor();
    }
    
    void UpdateColor() {
        // Use simpler color tinting approach
        int colorChoice = CVar.GetCVar("scm_marker_color", players[consoleplayer]).GetInt();
        switch(colorChoice) {
            case 0: break; // Original colors
            case 1: A_SetTranslation("Ice"); break; // Red tint
            case 2: A_SetTranslation("X1Green"); break; // Green tint  
            case 3: A_SetTranslation("SapphireBlue"); break; // Blue tint
            case 4: A_SetTranslation("White"); break; // White/bright
        }
    }
    
    override void Tick() {
        super.Tick();
        
        if(!trackedItem || trackedItem.bDORMANT) {
            if (CVar.GetCVar("scm_show_cleared", players[consoleplayer]).GetBool()) {
                // Spawn cleared marker
                let cleared = Actor.Spawn("SCMv2_MarkerCleared", pos);
                if (cleared) {
                    cleared.scale = scale;
                }
            }
            Destroy();
            return;
        }
        
        SetOrigin(trackedItem.pos, true);
        
        // Update scale
        float markerScale = CVar.GetCVar("scm_marker_size", players[consoleplayer]).GetFloat();
        scale = (markerScale, markerScale);
        
        // Update color if changed
        UpdateColor();
    }
    
    States {
        Spawn:
            SCMF A -1;
            Stop;
    }
}

// Cleared marker
class SCMv2_MarkerCleared : MasterMarkerCleared {
    default {
        +BRIGHT
        Alpha 0.5;
    }
    
    override void BeginPlay() {
        super.BeginPlay();
        A_SetTranslation("Ice"); // Grayscale effect
    }
    
    States {
        Spawn:
            SCMF A -1;
            Stop;
    }
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

// Main event handler
class SCMv2_Handler : EventHandler {
    Array<SCMv2_Marker> markers;
    bool levelRevealed;
    
    override void WorldLoaded(WorldEvent e) {
        ClearAllMarkers();  // Clear any existing markers from previous games/saves
        levelRevealed = false;
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
        // Check if tracking is enabled
        bool trackCollectibles = CVar.GetCVar("scm_track_collectibles", players[consoleplayer]).GetBool();
        bool trackAllPickups = CVar.GetCVar("scm_track_all_pickups", players[consoleplayer]).GetBool();
        
        if (!trackCollectibles && !trackAllPickups) {
            ClearAllMarkers();
            return;
        }
        
        // Find items to track
        ThinkerIterator it = ThinkerIterator.Create("Inventory");
        Actor item;
        
        while(item = Actor(it.Next())) {
            if(!item || item.bDORMANT) continue;
            
            // Skip if item has an owner
            let inv = Inventory(item);
            if(inv && inv.owner) continue;
            
            bool shouldTrack = false;
            
            // Check if we should track this item
            if (trackCollectibles) {
                string className = item.GetClassName();
                if (className ~== "SelacoCollectible" || 
                    className ~== "Collectible" ||
                    className ~== "DataLog" ||
                    className ~== "SecretItem" ||
                    className.IndexOf("Collectible") >= 0) {
                    shouldTrack = true;
                }
            }
            
            if (trackAllPickups) {
                shouldTrack = true;
            }
            
            if (shouldTrack && !HasMarker(item)) {
                CreateMarker(item);
            }
        }
        
        // Update existing markers
        for(int i = 0; i < markers.Size(); i++) {
            if(!markers[i]) {
                markers.Delete(i);
                i--;
            }
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
    
    void CreateMarker(Actor item) {
        let marker = SCMv2_Marker(Actor.Spawn("SCMv2_Marker", item.pos));
        if(marker) {
            marker.trackedItem = item;
            float markerScale = CVar.GetCVar("scm_marker_size", players[consoleplayer]).GetFloat();
            marker.scale = (markerScale, markerScale);
            markers.Push(marker);
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
        
        // Give scanner powerup
        player.GiveInventory("SCMv2_Scanner", 1);
        
        // Reveal all sectors
        for(int i = 0; i < level.sectors.Size(); i++) {
            level.sectors[i].MoreFlags |= Sector.SECMF_DRAWN;
        }
        
        // Reveal all lines
        for(int i = 0; i < level.lines.Size(); i++) {
            level.lines[i].flags |= Line.ML_MAPPED;
        }
        
        Console.Printf("\c[yellow]Collectibles Mod v3.1.4: Map revealed!");
    }
}
