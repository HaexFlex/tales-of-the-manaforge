TALES OF THE MANAFORGE
Cozy Top-Down Pixel Art Adventure  ·  Secret of Mana Inspired  ·  Restart Edition
Updated August 2026 for a clean restart: agent-first development, high-resolution pixel art, point-and-click controls, native Windows first. The soul of the game is unchanged. Implementation details from the first prototype are retired.
Game Summary
Tales of the Manaforge is a peaceful yet magical top-down pixel art game. You play as the Keeper — a gentle guardian who tends a living, growing Manatree in the last living fragment of a dying fairy-forest.
The Manatree passes through beautiful growth stages. Each stage brings new bonuses and stronger presence. When the tree reaches its final, ancient form, the Keeper may harvest the Primordial Fruit. This resets the Manatree to a sapling while granting permanent upgrades, creating a satisfying prestige loop that makes every new cycle feel meaningful.
Core Fantasy & Tone
Tone: cozy, magical, contemplative, lightly melancholic. Never stressful or dark.
Core fantasy: growth, caretaking, gentle power, and legacy across cycles. Every prestige is another chance to prove that this time the cycle ends with hope instead of another cataclysm.
Prototype Scope (v0.1)
The first playable slice is intentionally small. We ship a satisfying core loop on PC before expanding.
Must have
Keeper with point-and-click controls: click the ground to move; click an object to walk there and interact
Manatree with clear growth stages
Basic manual resource gathering
Simple prestige / reset with a few permanent upgrades
Clean, readable UI
Working save / load
Explicitly postponed
WASD / direct movement
Complex whisp assignment systems
Deep crafting and the full Forge
Full equipment and detailed combat stats
Heavy world decoration
Mobile touch controls and HTML5 / web export
Long-Term Gameplay Loop
This remains the intended full loop. Only the first steps belong in v0.1.
Care for the Manatree (watering and tending)
Gather resources (Wood, Stone, Food, Manashards, Essence)
Assign glowing whisps for idle help (later)
Craft and, later, use the Forge inside the Manatree
Grow the tree through its stages
Harvest the Primordial Fruit → Ascend → choose permanent upgrades → reset stronger
Key Systems (Vision)
Manatree growth with unique visuals, bonuses, and requirements per stage
Whisp management as idle helpers (after the prototype)
Handcrafting and inventory, later expanding into the Forge
Prestige / ascension with stacking permanent upgrades
Save system with versioning
Optional later portal: Echo Chamber of Failures (redemption, not conquest)
Equipment and Stats (Later)
These systems stay in the vision, but they are not part of the first prototype.
The Keeper grows stronger across ascensions through permanent stats and later through crafted equipment.
Seven core stats
Might — Physical Attack
Arcana — Magical Attack
Resilience — Physical Resistance
Ward — Magical Resistance
Vitality — Health and survivability
Swiftness — Speed
Fate — Luck, crit chance, rare finds
Stats persist through prestige. They are intended to be raised mainly at Runestones using Manashards. Equipment (Weapon and Relic first) is a later Forge-driven layer that adds flat bonuses on top of prestige growth.
Art Direction
High-resolution pixel art inspired by Secret of Mana (SNES). Magical, peaceful fairy-forest atmosphere with glowing accents.
Characters: about 128×128 or 256×256
Tiles and props: 64×64 or 128×128
Nearest-neighbor filtering so pixels stay crisp
Grok Imagine is the primary art tool; specialized sprite tools may be added later
The old strict 32×32 / 64×32 constraint is retired. The look should still feel like classic SNES pixel art, just at a more comfortable working resolution.
Platform, Controls & Distribution
Primary target: native Windows
Later: native mobile (Android / iOS)
HTML5 / web export: dropped
Prototype controls: point-and-click only
Distribution: itch.io Windows builds + GitHub Releases
Keep costs low during the learning and prototype phase
How We Build
This restart is agent-first. The human acts as Product Owner and Game Designer. Grok and Grok Build implement most of the work. The goal is to learn how to direct AI agents well, not to write every line by hand.
Godot 4.x, GDScript only, fully typed
Complete full files, never partial snippets
Composition, signals, modular autoloads
Small testable vertical slices
Commit and tag meaningful working states
Roadmap
Short-term — Prototype
Clean Godot project structure
Point-and-click Keeper + Manatree + basic resources + simple prestige + save
Reliable Imagine art pipeline for the first assets
Windows build on itch.io / GitHub
Mid-term
Whisps, deeper crafting, Forge inside the Manatree
Stats, Runestones, first equipment
Richer forest, better audio, more prestige options
Long-term
Portal / Echo Chamber of Failures and redeemed companions
Forest becoming a living community
New biomes, customization, optional co-op
Narrative Heart
The fairy-forest is the last living fragment of a once-vibrant realm. The Manatree is the World Seed. Hidden inside it is the ancient Manaforge that once powered civilizations.
Every previous Keeper tried to make the realm eternal and failed. The player is the latest in that line. The question is not whether the cycle exists — it is whether this Keeper can break it through wisdom, compassion, and redemption.
The forest itself stays peaceful. Any conflict belongs later, in an optional portal. Even there the goal is forgiveness, not conquest.
Document updated August 2026 for the clean restart. Lore and long-term vision preserved. Platform, art, controls, and prototype scope revised.