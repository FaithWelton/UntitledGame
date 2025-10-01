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
  - Damage scaling based on player strength
  - Team-based collision filtering (no friendly fire)
  - Shooter tracking to prevent self-hits
  - Configurable speed, range, and damage

### Mob/Enemy System
- **AI Behaviors:** Multiple AI types (aggressive, hit_and_run, coward)
- **Dynamic Stats:** Randomized speed, configurable health and damage
- **Loot Drops:** Mobs drop items on death
- **Mob Spawner:** Configurable spawner with AI type selection

### Inventory System
- **Item Stacking:** Items with max_stack_size > 1 automatically stack
- **Equipment Slots:** Dedicated slots for weapons, armor, and accessories
- **Item Validation:** Type-checking prevents wrong items in equipment slots
- **Drag & Drop:**
  - Move/swap items between slots
  - Drop items outside inventory to spawn in world
  - Drop items on trash to delete
- **Item Tooltips:** (In Progress) Hover tooltips showing item stats and info

### Item System
- **Item Types:** Weapon, Armor, Useable, Interactable
- **Stackable Items:** Configurable max stack size per item
- **Item Effects:**
  - Health potions (drink effect)
  - Revive potions (revive on death)
  - Equipment stat bonuses (health, strength, armor)
- **PickupItem Base Class:** Shared functionality for all world items

### Player Systems
- **Movement:** Third-person movement with camera-relative controls
- **Combat:** Shooting with configurable fire rate
- **Stats System:** Health, strength, armor
- **Death/Respawn:**
  - Death dialog with revive and respawn options
  - Revive items can bring player back to life
  - Movement disabled during death
- **Interaction:** Pick up items from world

### UI/UX
- **Inventory UI:**
  - Backpack, toolbar, and equipment slots
  - Stack count display on items
  - Visual feedback for dragging
  - Game pauses when inventory is open
- **Death Dialog:** Modal dialog with revive/respawn options
- **Stats Display:** Live enemy count, player health/strength/armor

### Code Quality Improvements
- **Refactored Architecture:**
  - Created PickupItem base class to eliminate code duplication
  - Extracted GameStats helper methods
  - Signal-based item usage system in SlotNode
  - Separated concerns (SlotNode no longer directly accesses PlayerStats)
- **Node Groups:** Replaced fragile `get_node("../..")` paths with node group lookups
- **Consistent Naming:** Removed underscore prefix from public API methods
- **Proper Pausing:** Uses Godot's built-in pause system

## TODO

### High Priority
- [ ] Item tooltips on hover (In Progress)
- [ ] Item rarity system
- [ ] Equipment stat bonuses affecting PlayerStats
- [ ] Bullet/projectile pooling for performance
- [ ] Hit effects and feedback (damage numbers, screen shake)
- [ ] Critical hit system
- [ ] Mob projectile attacks
- [ ] Save/load system

### Medium Priority
- [ ] Health bars above mobs
- [ ] Player health/mana HUD
- [ ] Minimap
- [ ] Toolbar hotkeys (1-9 to use items)
- [ ] Item pickup animations
- [ ] Pathfinding for mob AI
- [ ] Mob spawning waves/difficulty scaling

### Assets Needed
- [ ] Player character model
- [ ] Mob variations
- [ ] Item models (health potion, armor, weapons)
- [ ] Environment assets
- [ ] UI/HUD graphics

## Recent Changes

### Code Refactoring
- Eliminated code duplication between Ball.gd and GenericItem.gd with PickupItem base class
- Fixed fragile node paths by using node groups instead of relative paths
- Removed debug print statements throughout codebase
- Improved Global.gd naming conventions
- Extracted duplicate signal emission logic in GameStats.gd
- Refactored SlotNode to use signals for item usage instead of direct stat manipulation

### Bug Fixes
- Fixed player movement not restoring after revival/respawn
- Fixed inventory drop logic for dropping items outside inventory to world
- Fixed item type validation in equipment slots
- Fixed has_property() error (changed to `in` operator)
- Fixed game pause to properly freeze mobs and projectiles when inventory is open

### New Features
- Item stacking system with configurable max stack sizes
- Stack count labels on inventory items
- Bullet damage system with team collision filtering
- Death/respawn system with revival items
- Mob AI with multiple behavior types
- Mob spawner with configurable settings
- Proper game pause when inventory is open

## Technical Notes

- Built with Godot 4
- Uses GDScript
- Node group-based architecture for loose coupling
- Signal-based communication between systems
