# NutAndJamPack

A comprehensive Minecraft modpack for version 1.20.1 built with Forge 47.4.12.

## Overview

NutAndJamPack is a kitchen-sink style modpack combining technology, magic, exploration, and building. The pack features Create-based automation, mystical mods like Ars Nouveau and Botania, extensive world generation, and comprehensive quality-of-life improvements.

## Version

Current Version: 1.0.5

## Requirements

- Minecraft: 1.20.1
- Forge: 47.4.12
- Recommended RAM: 6-8GB minimum

## Key Features

### Technology & Automation
- Create and extensive Create addons (Steam n' Rails, New Age, TFMG, Big Cannons)
- Mekanism with Generators, Tools, and Additions
- Applied Energistics 2
- Immersive Engineering
- Advanced Peripherals and CC: Tweaked

### Magic & Mysticism
- Ars Nouveau with multiple addons (Ars Elemental, Ars Additions, Ars Scalaes)
- Botania
- Hex Casting with Hexal
- Occultism
- Nature's Aura

### Exploration & Dimensions
- The Aether
- The Twilight Forest
- Blue Skies
- The Undergarden
- Deeper and Darker
- Ad Astra (space exploration)

### World Generation
- Biomes O' Plenty
- YUNG's suite (Better Dungeons, Desert Temples, Strongholds, Ocean Monuments, etc.)
- When Dungeons Arise
- Awesome Dungeons series
- Repurposed Structures
- Towns and Towers
- Additional Structures

### Building & Decoration
- Extensive furniture mods (Macaw's suite, MrCrayfish's, Handcrafted, Another Furniture)
- Chipped and Rechiseled for block variants
- Framed Blocks
- Create Deco
- Supplementaries
- Decorative Blocks

### Quality of Life
- JEI and EMI for recipe viewing
- Xaero's Minimap and World Map
- FTB Chunks
- Inventory Profiles Next
- Mouse Tweaks
- Just Zoom
- Waystones (implied by world generation focus)

### Performance
- Embeddium (Sodium port)
- Oculus (Iris port)
- ModernFix
- FerriteCore
- Canary
- EntityCulling
- ImmediatelyFast

### Social & Multiplayer
- Simple Voice Chat
- MineColonies for collaborative building
- FTB Teams

## Installation

### Using Packwiz (Recommended)

1. Download `packwiz-installer-bootstrap.jar` from the setup folder
2. Place it in your Minecraft instance folder
3. Run the installer, which will download and install all mods

### Manual Installation

Download the `.mrpack` file and import it into your preferred launcher:
- Modrinth (Ideally)
- PrismMC (If custom updates.json support feed added)

## Docker Support

Docker is used in this project for building and testing CI/CD style integration. This is not yet feature complete.

## Development

This modpack is managed using packwiz for easy version control and updates.

### Building

Scripts are provided in the `scripts/` folder for building and packaging the modpack.

### Structure

- `mods/` - Mod configuration files (.pw.toml)
- `kubejs/` - KubeJS scripts for custom modifications
- `shaderpacks/` - Included shader packs
- `manual_mods/` - Mods not available through automated distribution
- `scripts/` - Build and utility scripts
- `docker/` - Docker deployment configurations

## License

Please respect the licenses of individual mods included in this pack. This modpack is for personal and server use.
