import json, os, time
from square_level_engine import generate_square_level, solve

N = 21 # Exact square grid: 21 x 21

LEVEL_METADATA = [
    (1, "Faithful Scottish Terrier", "dog", 42, "Hard"),
    (2, "Grand Championship Trophy", "trophy", 42, "Hard"),
    (3, "Deep Ocean Anchor", "anchor", 38, "Hard"),
    (4, "Golden Monarch Butterfly", "butterfly", 42, "Hard"),
    (5, "Labyrinth Square Maze", "square_maze", 44, "Expert"),
    (6, "Imperial Royal Crown", "crown", 42, "Medium"),
    (7, "Sacred Heart Locket", "heart", 38, "Medium"),
    (8, "Apollo Orbital Rocket", "rocket", 40, "Hard"),
    (9, "Crusader Excalibur Sword", "sword", 38, "Medium"),
    (10, "Electric Acoustic Guitar", "guitar", 40, "Hard"),
    (11, "Knight's Citadel Shield", "shield", 40, "Medium"),
    (12, "Mystic Forest Dragon", "dragon", 44, "Expert"),
    (13, "Imperial Golden Lion", "lion", 42, "Hard"),
    (14, "Camelot Stone Castle", "castle", 44, "Hard"),
    (15, "Maneki-Neko Lucky Cat", "cat", 38, "Medium"),
    (16, "Ancient Zen Bonsai", "tree", 40, "Hard"),
    (17, "Brilliant Faceted Diamond", "gem", 38, "Medium"),
    (18, "Corsair Pirate Skull", "skull", 40, "Hard"),
    (19, "Wise Barn Owl", "owl", 40, "Hard"),
    (20, "Grand Championship Trophy II", "trophy", 44, "Expert"),
    (21, "Faithful Scottish Terrier II", "dog", 44, "Expert"),
    (22, "Deep Ocean Anchor II", "anchor", 40, "Hard"),
    (23, "Golden Monarch Butterfly II", "butterfly", 44, "Expert"),
    (24, "Labyrinth Square Maze II", "square_maze", 46, "Expert"),
    (25, "Imperial Royal Crown II", "crown", 44, "Expert"),
    (26, "Sacred Heart Locket II", "heart", 40, "Hard"),
    (27, "Apollo Orbital Rocket II", "rocket", 42, "Hard"),
    (28, "Crusader Excalibur Sword II", "sword", 40, "Hard"),
    (29, "Electric Acoustic Guitar II", "guitar", 42, "Hard"),
    (30, "Knight's Citadel Shield II", "shield", 42, "Hard"),
    (31, "Mystic Forest Dragon II", "dragon", 46, "Expert"),
    (32, "Imperial Golden Lion II", "lion", 44, "Expert"),
    (33, "Camelot Stone Castle II", "castle", 46, "Expert"),
    (34, "Maneki-Neko Lucky Cat II", "cat", 40, "Hard"),
    (35, "Ancient Zen Bonsai II", "tree", 42, "Hard"),
    (36, "Brilliant Faceted Diamond II", "gem", 40, "Hard"),
    (37, "Corsair Pirate Skull II", "skull", 42, "Hard"),
    (38, "Wise Barn Owl II", "owl", 42, "Hard"),
    (39, "Grand Championship Trophy III", "trophy", 46, "Expert"),
    (40, "Faithful Scottish Terrier III", "dog", 46, "Expert"),
    (41, "Deep Ocean Anchor III", "anchor", 42, "Hard"),
    (42, "Golden Monarch Butterfly III", "butterfly", 46, "Expert"),
    (43, "Labyrinth Square Maze III", "square_maze", 48, "Expert"),
    (44, "Imperial Royal Crown III", "crown", 46, "Expert"),
    (45, "Sacred Heart Locket III", "heart", 42, "Hard"),
    (46, "Apollo Orbital Rocket III", "rocket", 44, "Expert"),
    (47, "Crusader Excalibur Sword III", "sword", 42, "Hard"),
    (48, "Electric Acoustic Guitar III", "guitar", 44, "Expert"),
    (49, "Knight's Citadel Shield III", "shield", 44, "Expert"),
    (50, "Mystic Forest Dragon Apex", "dragon", 48, "Expert")
]

all_levels = []

print("Generating 50 Square Grid Levels (N = 21x21)...")
start_time = time.time()

for (lvl_id, name, shape, target_cnt, diff) in LEVEL_METADATA:
    arrows, solve_order = generate_square_level(shape, target_cnt, N, lvl_id * 1047)
    solvable, check_order = solve(arrows, N, N)

    if not solvable:
        print(f"FAILED SOLVE FOR LEVEL {lvl_id} ({name})! Retrying...")
        for retry in range(1, 10):
            arrows, solve_order = generate_square_level(shape, target_cnt, N, lvl_id * 1047 + retry * 997)
            solvable, check_order = solve(arrows, N, N)
            if solvable:
                break

    paths_data = []
    for a in arrows:
        paths_data.append({
            "id": a['id'],
            "points": a['points'],
            "dir": a['dir'],
            "cells": a['cells']
        })

    lvl_obj = {
        "id": lvl_id,
        "name": name,
        "difficulty": diff,
        "bounds": {
            "min_x": 0,
            "min_y": 0,
            "max_x": N - 1,
            "max_y": N - 1,
            "width": N,
            "height": N
        },
        "paths": paths_data,
        "solve_order": check_order
    }
    all_levels.append(lvl_obj)
    print(f"Generated Level {lvl_id:2d}: '{name}' ({len(arrows)} arrows, {N}x{N} square grid, Solvable: {solvable})")

out_path = "data/levels.json"
with open(out_path, "w") as f:
    json.dump(all_levels, f, indent=2)

print(f"Successfully saved all 50 square levels to {out_path} in {time.time() - start_time:.1f}s!")
