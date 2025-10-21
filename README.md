# Untitled Game

A third-person action game built with Godot 4, featuring combat, inventory management, and AI-driven enemies.

## Project Origin

**Starting point:** https://www.gdquest.com/library/first_3d_game_godot4_arena_fps/

Initial changes:
- Converted from first person to third person camera
- Split Camera and Player into separate scenes
- Setup Player and Camera controllers
- Basic world environment setup

**Inventory System:** Following tutorials from:
- https://www.youtube.com/watch?v=A0ShW-ZMXm0
- https://www.youtube.com/watch?v=zqbmUv-S1io
- https://www.youtube.com/watch?v=RDcW8mf9PXI
- https://www.youtube.com/watch?v=VJVGSB5M1pc

## Current Features

### Combat System
- **Bullet/Projectile System**
  - Object pooling for performance optimization
  - Damage scaling based on player strength
  - Team-based collision filtering (no friendly fire)
  - Shooter tracking to prevent self-hits
  - Configurable speed, range, and damage
- **Critical Hit System**
  - Configurable crit chance and multiplier
  - Visual feedback with "CRIT!" text and camera shake
  - Equipment bonuses affect crit stats

### Mob/Enemy System
- **Extensible Architecture:**
  - Base `Mob` class with common functionality (health, attack, AI, loot)
  - Specialized `Bat` class with flying behavior extending base
  - Easy to add new mob types by extending base class
- **AI Behaviors:**
  - Multiple AI types: aggressive, hit_and_run, coward
  - Each mob type defines its own available AI types
  - Bats use aggressive and hit_and_run (no coward behavior)
- **Flying Behavior (Bats):**
  - Height control with hover and max/min height limits
  - Orbiting attack pattern around player
  - Randomized orbit direction and speed for organic movement
  - Vertical avoidance - bats fly over/under each other
  - Preferred orbit angles for even distribution around player
  - Boundary detection keeps mobs on platform (avoids falling off edges)
- **Separation/Flocking:**
  - Mobs avoid crowding each other
  - Separation forces prevent stacking
  - Priority-based movement (boundary > separation > attack)
- **Randomized Loot System:**
  - Percentage-based drop chances with rarity support
  - Configurable quantity ranges (e.g., 1-2 health potions)
  - LootTable class for easy loot configuration
  - Safe loot spawning (spawns near player if mob falls off map)
- **Dynamic Stats:** Randomized speed, configurable health and damage
- **Mob Spawner:** Automatic spawning with configurable timers

### Inventory System
- **Item Stacking:**
  - Items with max_stack_size > 1 automatically stack
  - Drag stacks onto compatible items to combine
  - Stack splitting with Shift+Click (choose amount with slider)
  - Proper stack validation (same name and type required)
- **Equipment Slots:** Dedicated slots for weapons, armor, and accessories
- **Item Validation:** Type-checking prevents wrong items in equipment slots
- **Drag & Drop:**
  - Move/swap items between slots
  - Swap stacks with single items in either direction
  - Drop items outside inventory to spawn all items in stack
  - Drop items on trash to delete
- **Item Tooltips:** Hover tooltips showing item stats, rarity, and description

### Item System
- **Item Types:** Weapon, Armor, Useable, Interactable
- **Rarity System:** Common, Uncommon, Rare, Epic, Legendary with color-coded borders
- **Stackable Items:** Configurable max stack size per item
- **Item Effects:**
  - Health potions (drink effect, restores 50 HP)
  - Revive potions (revive on death, rare drop)
  - Equipment stat bonuses (health, strength, armor, crit chance, crit multiplier)
- **3D Item Models:**
  - Health Potion: Red glowing transparent bottle with metallic neck
  - Revive Potion: Purple/pink glowing bottle with golden neck (brighter to show rarity)
  - Custom materials with emission effects for glowing liquid
- **PickupItem Base Class:** Shared functionality for all world items

### Player Systems
- **Movement:**
  - Third-person movement with camera-relative controls
  - Swimming/water mechanics with enhanced jump force in water
  - Can jump out of hazard zones
- **Combat:** Shooting with configurable fire rate and critical hits
- **Stats System:**
  - Base stats: Health, strength, armor, crit chance, crit multiplier
  - Equipment bonuses modify base stats
  - Dynamic stat updates when equipping/unequipping items
- **Death/Respawn:**
  - Context-aware death messages based on death cause:
    - "You fell off the edge!" (falling)
    - "You were defeated in battle!" (combat)
    - "You burned in lava!" (lava hazard)
    - "You were swallowed by quicksand!" (quicksand hazard)
  - Death dialog with revive and respawn options
  - Revive items bring player back to safe position if died from falling
  - Respawn returns player to level start and clears all enemies
  - Movement disabled during death
- **Interaction:** Pick up items from world

### Environment/Hazard System
- **DeathZone/Hazard Areas:**
  - Configurable hazard types: Water, Lava, Quicksand, Void
  - Each hazard has unique physics and damage behavior
- **Water Hazard:**
  - Buoyancy forces keep player and items floating
  - Items drift toward shore (center)
  - Player can swim and jump out
  - No damage
- **Lava Hazard:**
  - Reduced buoyancy (sinks more than water)
  - Damage over time (10 HP/second by default)
  - Items float and drift to shore
- **Quicksand Hazard:**
  - Pulls player downward
  - Heavy drag on movement
  - Damage when fully submerged
  - Items sink
- **Void Hazard:**
  - Instant death for player
  - Mobs drop loot safely, items destroyed
- **Safety Features:**
  - Mobs avoid hazard boundaries automatically
  - Items that fall off respawn at surface or drift to shore
  - Loot from off-map mobs spawns near player

### UI/UX
- **Inventory UI:**
  - Backpack, toolbar, and equipment slots
  - Stack count display on items
  - Rarity-colored borders on items
  - Visual feedback for dragging
  - Game pauses when inventory is open
- **Main Menu:**
  - New Game (automatically finds next save slot)
  - Continue (loads most recent save)
  - Load Game (choose from save slots)
  - Manage Saves (view and delete saves)
- **Pause Menu:**
  - Save/Load game functionality
  - Quick save (F5) and quick load (F6) shortcuts
  - Overwrite confirmation when all save slots are full
- **Death Dialog:** Modal dialog with revive/respawn options
- **Stats Display:** Live enemy count, player health, bullets fired
- **Save/Load System:**
  - 10 save slots with timestamp-based naming
  - Saves player position, stats, inventory, and game state
  - Save management UI to view and delete saves

### Code Quality Improvements
- **Refactored Architecture:**
  - Created PickupItem base class to eliminate code duplication
  - Extracted GameStats helper methods
  - Signal-based item usage system in SlotNode
  - Separated concerns (SlotNode no longer directly accesses PlayerStats)
  - Resource duplication to prevent shared state bugs in inventory
- **Node Groups:** Replaced fragile `get_node("../..")` paths with node group lookups
- **Consistent Naming:** Removed underscore prefix from public API methods
- **Proper Pausing:** Uses Godot's built-in pause system
- **Debug Cleanup:** Removed unnecessary print statements throughout codebase

## TODO

### High Priority
- [ ] Mob projectile attacks
- [ ] Experience/leveling system
- [ ] More item variety (weapons, armor pieces)
- [ ] More mob types (ground-based, ranged, etc.)

### Medium Priority
- [ ] Health bars above mobs
- [ ] Player health/mana HUD improvements
- [ ] Minimap
- [ ] Toolbar hotkeys (1-9 to use items)
- [ ] Item pickup animations
- [ ] Pathfinding for mob AI
- [ ] Mob spawning waves/difficulty scaling
- [ ] Better visual effects for combat
- [ ] Sound effects and music

### Completed Features
- [x] Item tooltips on hover
- [x] Item rarity system
- [x] Equipment stat bonuses affecting PlayerStats
- [x] Bullet/projectile pooling for performance
- [x] Critical hit system with visual feedback
- [x] Save/load system with multiple save slots
- [x] Stack splitting and combining
- [x] Camera shake on critical hits
- [x] Loot tables for different mob types (randomized drops with rarity)
- [x] 3D item models for potions
- [x] Advanced mob AI with flocking and orbiting
- [x] Swimming/water mechanics
- [x] Hazard system (water, lava, quicksand, void)
- [x] Context-aware death messages
- [x] Mob respawn clearing on player respawn

### Assets Needed
- [ ] Player character model with animations
- [ ] More mob variations (ground enemies, ranged enemies)
- [ ] Weapon models (swords, bows, staffs)
- [ ] Armor models (helmets, chest pieces, boots)
- [ ] Environment assets (trees, rocks, structures)
- [ ] Water/hazard visual effects
- [ ] UI/HUD graphics

## Recent Changes

### Latest Updates
- **Mob Architecture Refactor:**
  - Created base `Mob` class with shared functionality
  - Specialized `Bat` class with flying/orbiting behavior
  - Mobs define their own available AI types
- **Advanced Flying AI:**
  - Organic orbiting patterns with randomization
  - Vertical avoidance for 3D navigation
  - Even distribution around player via preferred angles
  - Boundary detection to prevent falling off edges
- **Randomized Loot System:**
  - LootTable class with percentage-based drops
  - Configurable quantity ranges
  - Rarity support (common health potions, rare revive potions)
- **3D Potion Models:**
  - Created custom bottle models with glowing effects
  - Health potion (red) and Revive potion (purple/pink)
- **Hazard/DeathZone System:**
  - Four configurable hazard types (Water, Lava, Quicksand, Void)
  - Unique physics for each hazard type
  - Buoyancy, drag, and damage systems
  - Swimming mechanics with enhanced jump in water
- **Context-Aware Death Messages:**
  - Death dialog shows different messages based on death cause
  - Tracks deaths from combat, falling, lava, quicksand
- **Code Cleanup:**
  - Removed unused functions across multiple files
  - Deleted deprecated Mob_old.gd backup file
  - Fixed signal connection errors

### Previous Updates
- **Save/Load System:** Complete implementation with 10 save slots, timestamp-based naming, and save management UI
- **Stack Splitting:** Shift+Click to split item stacks with slider dialog
- **Stack Combining:** Fixed inventory stacking logic to properly combine compatible items
- **Critical Hits:** Added visual feedback with "CRIT!" text and camera shake
- **Object Pooling:** Implemented bullet pooling for better performance

### Bug Fixes
- Fixed stack combining showing incorrect counts
- Fixed stacks not swapping properly with single items
- Fixed dropped stacks only spawning one item in world
- Fixed player respawn position to return to level start
- Fixed player movement not restoring after revival/respawn
- Fixed item type validation in equipment slots
- Fixed game pause to properly freeze mobs and projectiles
- Fixed mob attacking only triggering once (moved to frame-based checking)
- Fixed mobs crowding player (tuned separation forces and distances)
- Fixed mobs floating too high (added height control)
- Fixed mobs facing wrong direction during orbit
- Fixed mobs not navigating around each other (added vertical avoidance)
- Fixed mobs clustering on one side (added preferred orbit angles)
- Fixed loot being lost when mobs fall off map
- Fixed player unable to jump out of water
- Fixed death dialog not showing correct death reason

## Technical Notes

- Built with Godot 4
- Uses GDScript
- Node group-based architecture for loose coupling
- Signal-based communication between systems
