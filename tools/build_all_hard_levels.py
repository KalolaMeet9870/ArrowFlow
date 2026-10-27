import json, sys, os
from dense_level_engine import generate_dense_level, solve

HARD_LEVEL_SPECS = [
    # Levels 1 - 4: Exact User Requested Screenshots
    (1, "Grand Championship Trophy", "Hard", "trophy", 42, 22, 24),
    (2, "Deep Ocean Anchor", "Hard", "anchor", 38, 22, 24),
    (3, "Faithful Scottish Terrier", "Hard", "dog", 40, 22, 24),
    (4, "Golden Monarch Butterfly", "Hard", "butterfly", 42, 22, 24),

    # Levels 5 - 15: Iconic Silhouette Mazes
    (5, "Imperial Royal Crown", "Hard", "crown", 42, 22, 22),
    (6, "Eternal Zen Heart", "Hard", "heart", 40, 22, 22),
    (7, "Apollo Starship", "Hard", "rocket", 42, 22, 24),
    (8, "Celestial Dragon", "Hard", "dragon", 44, 22, 24),
    (9, "Rockstar Acoustic Guitar", "Hard", "guitar", 42, 22, 24),
    (10, "Excalibur Holy Blade", "Hard", "sword", 40, 22, 24),
    (11, "Aegis Knight Shield", "Hard", "shield", 42, 22, 24),
    (12, "Savanna King Lion", "Hard", "lion", 44, 22, 24),
    (13, "Citadel Fortress Castle", "Hard", "castle", 44, 22, 24),
    (14, "Midnight Shadow Cat", "Hard", "cat", 40, 22, 22),
    (15, "Viking War Galleon", "Hard", "boat", 42, 22, 24),

    # Levels 16 - 30: Advanced Winding Silhouette Challenges
    (16, "Ancient Sacred Bonsai", "Hard", "tree", 42, 22, 24),
    (17, "Imperial Prism Diamond", "Hard", "gem", 42, 22, 22),
    (18, "Corsair Pirate Skull", "Hard", "skull", 40, 22, 24),
    (19, "Nocturnal Wise Owl", "Hard", "owl", 42, 22, 24),
    (20, "Trophy of Champions II", "Hard", "trophy", 45, 22, 24),
    (21, "Leviathan Deep Anchor II", "Hard", "anchor", 42, 22, 24),
    (22, "Origami Shiba Inu", "Hard", "dog", 42, 22, 24),
    (23, "Emerald Swallowtail Butterfly", "Hard", "butterfly", 45, 22, 24),
    (24, "Sovereign Golden Crown", "Hard", "crown", 44, 22, 22),
    (25, "Crimson Crystal Heart", "Hard", "heart", 42, 22, 22),
    (26, "Saturn V Orbital Rocket", "Hard", "rocket", 44, 22, 24),
    (27, "Mythic Fire Drake", "Hard", "dragon", 46, 22, 24),
    (28, "Electric Fender Guitar", "Hard", "guitar", 44, 22, 24),
    (29, "Gladiator Paladin Shield", "Hard", "shield", 44, 22, 24),
    (30, "Silver Claymore Sword", "Hard", "sword", 42, 22, 24),

    # Levels 31 - 45: Expert Intricate Mazes
    (31, "Highland Terrier Dog", "Expert", "dog", 45, 22, 24),
    (32, "Phoenix Ascending", "Expert", "butterfly", 46, 22, 24),
    (33, "Admiralty Iron Anchor", "Expert", "anchor", 44, 22, 24),
    (34, "Victor Gold Cup", "Expert", "trophy", 46, 22, 24),
    (35, "Royal Coronation Tiara", "Expert", "crown", 45, 22, 22),
    (36, "Infinite Labyrinth Heart", "Expert", "heart", 44, 22, 22),
    (37, "Interstellar Hyperion", "Expert", "rocket", 46, 22, 24),
    (38, "Grand Imperial Dragon", "Expert", "dragon", 48, 22, 24),
    (39, "Gothic Cathedral Castle", "Expert", "castle", 46, 22, 24),
    (40, "Prismatic Star Diamond", "Expert", "gem", 45, 22, 22),
    (41, "Spectral Corsair Skull", "Expert", "skull", 44, 22, 24),
    (42, "Mystic Athena Owl", "Expert", "owl", 46, 22, 24),
    (43, "Nordic Frost Longship", "Expert", "boat", 45, 22, 24),
    (44, "Zen Master Bonsai", "Expert", "tree", 45, 22, 24),
    (45, "Panthera Royal Lion", "Expert", "lion", 48, 22, 24),

    # Levels 46 - 50: Master Grandmaster Tier (48 - 55+ arrows)
    (46, "Excalibur Master Blade", "Master", "sword", 48, 24, 26),
    (47, "Golden Phoenix Wings", "Master", "butterfly", 50, 24, 26),
    (48, "Poseidon Colossus Anchor", "Master", "anchor", 48, 24, 26),
    (49, "World Cup Pinnacle", "Master", "trophy", 52, 24, 26),
    (50, "Grand Labyrinth Sovereign", "Master", "dragon", 54, 24, 26)
]

def generate_all():
    print("=" * 60)
    print("GENERATING 50 HARD, INTRICATE, SOLVABLE SHAPED PUZZLE LEVELS")
    print("=" * 60)

    all_levels_json = []

    for item in HARD_LEVEL_SPECS:
        lvl_id, name, diff, shape, target_cnt, W, H = item
        print(f"Generating Level {lvl_id:02d}: '{name}' ({diff}) - shape='{shape}', target={target_cnt} arrows on {W}x{H}...")

        seed = 5000 + lvl_id * 179
        arrows, solve_order = generate_dense_level(shape, target_cnt, W, H, seed)

        assert len(arrows) >= 25, f"Level {lvl_id} failed to reach minimum 25 arrows (got {len(arrows)})!"
        solvable, verify_order = solve(arrows, W, H)
        assert solvable, f"Level {lvl_id} failed solvability test!"
        assert len(verify_order) == len(arrows), f"Level {lvl_id} solve order count mismatch!"

        # Calculate bounding box of all arrows
        all_x = []
        all_y = []
        for a in arrows:
            for pt in a['points']:
                all_x.append(pt[0])
                all_y.append(pt[1])

        min_x = min(all_x)
        max_x = max(all_x)
        min_y = min(all_y)
        max_y = max(all_y)
        width = max_x - min_x + 1
        height = max_y - min_y + 1

        level_dict = {
            "id": lvl_id,
            "name": name,
            "difficulty": diff,
            "shape": shape,
            "arrows_count": len(arrows),
            "drops": 3,
            "bounds": {
                "min_x": min_x,
                "max_x": max_x,
                "min_y": min_y,
                "max_y": max_y,
                "width": width,
                "height": height
            },
            "solve_order": solve_order,
            "paths": [
                {
                    "id": a['id'],
                    "points": a['points'],
                    "dir": a['dir']
                } for a in arrows
            ]
        }
        all_levels_json.append(level_dict)
        print(f"  -> SUCCESS! Level {lvl_id} generated: {len(arrows)} arrows, {width}x{height} bounds, 100% Solvable!")

    out_path = "data/levels.json"
    with open(out_path, "w") as f:
        json.dump(all_levels_json, f, indent=2)

    print("\n" + "=" * 60)
    print(f"SUCCESSFULLY SAVED ALL 50 HARD SHAPED LEVELS TO {out_path}!")
    print("=" * 60)

if __name__ == "__main__":
    generate_all()
