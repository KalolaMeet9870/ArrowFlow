import json, random, math

# Orthogonal directions: UP, DOWN, LEFT, RIGHT
DIRS = [(0, -1), (0, 1), (-1, 0), (1, 0)]
OPPOSITE = {(0, -1): (0, 1), (0, 1): (0, -1), (-1, 0): (1, 0), (1, 0): (-1, 0)}

def ray_intersects_segment(origin, direction, seg_a, seg_b):
    ox, oy = origin
    dx, dy = direction
    ax, ay = seg_a
    bx, by = seg_b

    if ax == bx: # Vertical segment
        sx = ax
        sy_min, sy_max = min(ay, by), max(ay, by)
        if dx == 1 and sx > ox and sy_min <= oy <= sy_max:
            return True, sx - ox
        elif dx == -1 and sx < ox and sy_min <= oy <= sy_max:
            return True, ox - sx
        elif dx == 0 and sx == ox:
            if dy == 1 and sy_min > oy:
                return True, sy_min - oy
            elif dy == -1 and sy_max < oy:
                return True, oy - sy_max
    elif ay == by: # Horizontal segment
        sy = ay
        sx_min, sx_max = min(ax, bx), max(ax, bx)
        if dy == 1 and sy > oy and sx_min <= ox <= sx_max:
            return True, sy - oy
        elif dy == -1 and sy < oy and sx_min <= ox <= sx_max:
            return True, oy - sy
        elif dy == 0 and sy == oy:
            if dx == 1 and sx_min > ox:
                return True, sx_min - ox
            elif dx == -1 and sx_max < ox:
                return True, ox - sx_max
    return False, float('inf')

def is_arrow_free(paths, arrow_idx, active_indices):
    arrow = paths[arrow_idx]
    head = arrow['points'][-1]
    direction = arrow['dir']

    for other_idx in active_indices:
        if other_idx == arrow_idx:
            continue
        other_pts = paths[other_idx]['points']
        for i in range(len(other_pts) - 1):
            hit, dist = ray_intersects_segment(head, direction, other_pts[i], other_pts[i+1])
            if hit and dist > 1e-4:
                return False
    return True

def solve_level(paths):
    active = set(range(len(paths)))
    cleared = []
    while active:
        free_ones = [idx for idx in active if is_arrow_free(paths, idx, active)]
        if not free_ones:
            return False, cleared
        # Prefer an arrow that unlocks the most
        chosen = free_ones[0]
        active.remove(chosen)
        cleared.append(chosen)
    return True, cleared

LEVEL_META = [
    # Simple (1 - 15)
    (1, "Warmup Tri", "Simple", 3, 8, 8, "triangle"),
    (2, "Square Box", "Simple", 4, 8, 8, "square"),
    (3, "Cross Roads", "Simple", 4, 8, 8, "cross"),
    (4, "Diamond Pin", "Simple", 4, 9, 9, "diamond"),
    (5, "Four Corners", "Simple", 5, 9, 9, "box"),
    (6, "Arrow Sign", "Simple", 5, 10, 10, "arrow"),
    (7, "Hourglass", "Simple", 6, 10, 10, "hourglass"),
    (8, "Windmill", "Simple", 6, 10, 10, "pinwheel"),
    (9, "Little House", "Simple", 7, 11, 11, "house"),
    (10, "Trophy Cup", "Simple", 7, 11, 11, "trophy"),
    (11, "Antique Key", "Simple", 7, 12, 12, "key"),
    (12, "Goldfish", "Simple", 8, 12, 12, "fish"),
    (13, "Coffee Mug", "Simple", 8, 12, 12, "mug"),
    (14, "Sea Anchor", "Simple", 8, 12, 12, "anchor"),
    (15, "Sparkle Gem", "Simple", 8, 12, 12, "gem"),

    # Medium (16 - 35)
    (16, "Heartbeat", "Medium", 9, 13, 13, "heart"),
    (17, "Bonsai Tree", "Medium", 10, 14, 14, "tree"),
    (18, "Sweet Apple", "Medium", 10, 14, 14, "apple"),
    (19, "Sailboat", "Medium", 11, 14, 14, "boat"),
    (20, "Space Rocket", "Medium", 12, 15, 15, "rocket"),
    (21, "Butterfly Wings", "Medium", 12, 15, 15, "butterfly"),
    (22, "Royal Crown", "Medium", 13, 15, 15, "crown"),
    (23, "Acoustic Guitar", "Medium", 13, 16, 16, "guitar"),
    (24, "Knight Shield", "Medium", 14, 16, 16, "shield"),
    (25, "Castle Tower", "Medium", 14, 16, 16, "castle"),
    (26, "Playful Kitten", "Medium", 15, 16, 16, "cat"),
    (27, "Retro Car", "Medium", 15, 17, 17, "car"),
    (28, "Mallard Duck", "Medium", 16, 17, 17, "duck"),
    (29, "Forest Mushroom", "Medium", 16, 17, 17, "mushroom"),
    (30, "Vintage Camera", "Medium", 16, 17, 17, "camera"),
    (31, "Ceramic Teapot", "Medium", 17, 18, 18, "teapot"),
    (32, "Jetliner", "Medium", 17, 18, 18, "airplane"),
    (33, "Rain Umbrella", "Medium", 18, 18, 18, "umbrella"),
    (34, "Wise Owl", "Medium", 18, 18, 18, "owl"),
    (35, "Retro Robot", "Medium", 18, 18, 18, "robot"),

    # Hard (36 - 50)
    (36, "Champion Trophy", "Hard", 22, 20, 20, "trophy"),
    (37, "Hound Dog", "Hard", 24, 20, 20, "dog"),
    (38, "Puppy Run", "Hard", 26, 21, 21, "dog"),
    (39, "Majestic Lion", "Hard", 25, 21, 21, "lion"),
    (40, "Spotted Terrier", "Hard", 28, 22, 22, "dog"),
    (41, "Fire Dragon", "Hard", 26, 22, 22, "dragon"),
    (42, "Cobweb Spider", "Hard", 28, 22, 22, "spider"),
    (43, "Golden Phoenix", "Hard", 28, 23, 23, "phoenix"),
    (44, "Minotaur Maze", "Hard", 30, 23, 23, "maze"),
    (45, "Greek Key Meander", "Hard", 30, 24, 24, "meander"),
    (46, "Viking Longship", "Hard", 32, 24, 24, "ship"),
    (47, "Pirate Skull", "Hard", 32, 24, 24, "skull"),
    (48, "Monarch Butterfly", "Hard", 34, 25, 25, "butterfly"),
    (49, "Rock Guitar", "Hard", 34, 25, 25, "guitar"),
    (50, "Grand Labyrinth Master", "Hard", 36, 26, 26, "labyrinth")
]

def generate_solvable_level(target_count, W, H, seed_val):
    random.seed(seed_val)
    for attempt in range(100):
        grid = {} # (x, y) -> segment or used
        paths = []
        occupied_edges = set() # ((x1, y1), (x2, y2))
        occupied_nodes = set()

        def edge_key(p1, p2):
            return tuple(sorted([p1, p2]))

        # Generate paths in reverse: each path ends at an escape border or free corridor
        for p_idx in range(target_count):
            # Pick a free exit direction & start position along an edge or corridor
            best_path = None
            for trial in range(60):
                # Random exit direction
                dir_exit = random.choice(DIRS)
                # Pick head position inside [1, W-2], [1, H-2]
                hx = random.randint(1, W - 2)
                hy = random.randint(1, H - 2)
                head = (hx, hy)
                if head in occupied_nodes:
                    continue

                # Check if head in dir_exit has clean ray to edge
                cur = paths + [{'points': [head, head], 'dir': dir_exit}]
                cur_active = set(range(len(cur)))
                if not is_arrow_free(cur, len(cur) - 1, cur_active):
                    continue

                # Now grow backwards from head for 1 to 4 steps
                pts = [head]
                curr_node = head
                rev_dir = OPPOSITE[dir_exit]
                num_steps = random.randint(1, 4)

                failed = False
                for step in range(num_steps):
                    # Choose a direction (either straight or 90 deg turn)
                    possible_dirs = [d for d in DIRS if d != OPPOSITE[rev_dir]]
                    random.shuffle(possible_dirs)
                    step_taken = False
                    for d in possible_dirs:
                        length = random.randint(1, 3)
                        nx = curr_node[0] + d[0] * length
                        ny = curr_node[1] + d[1] * length
                        if 1 <= nx <= W - 2 and 1 <= ny <= H - 2:
                            # Verify all intermediate points and edges are free
                            conflict = False
                            test_edges = []
                            for step_i in range(1, length + 1):
                                step_node = (curr_node[0] + d[0] * step_i, curr_node[1] + d[1] * step_i)
                                e = edge_key((curr_node[0] + d[0] * (step_i - 1), curr_node[1] + d[1] * (step_i - 1)), step_node)
                                if e in occupied_edges or (step_node in occupied_nodes and step_i < length):
                                    conflict = True
                                    break
                                test_edges.append(e)
                            if not conflict:
                                curr_node = (nx, ny)
                                pts.append(curr_node)
                                rev_dir = d
                                step_taken = True
                                break
                    if not step_taken:
                        break

                if len(pts) >= 2:
                    # Reverse points so path goes: start -> ... -> head
                    real_pts = list(reversed(pts))
                    best_path = {
                        'id': p_idx,
                        'points': real_pts,
                        'dir': list(dir_exit)
                    }
                    # Mark occupied
                    for i in range(len(real_pts) - 1):
                        occupied_edges.add(edge_key(real_pts[i], real_pts[i+1]))
                        occupied_nodes.add(real_pts[i])
                        occupied_nodes.add(real_pts[i+1])
                    break

            if best_path:
                paths.append(best_path)
            else:
                break

        if len(paths) >= max(3, target_count - 2):
            # Test solvability
            solvable, order = solve_level(paths)
            if solvable:
                return paths, order

    # Fallback guaranteed grid generator
    paths = []
    # Simple concentric loops
    for i in range(target_count):
        ring = i % 4 + 1
        d = DIRS[i % 4]
        head = (W // 2 + d[0] * ring, H // 2 + d[1] * ring)
        tail = (head[0] - d[0] * 2, head[1] - d[1] * 2)
        paths.append({
            'id': i,
            'points': [tail, head],
            'dir': list(d)
        })
    return paths, list(range(len(paths)))

def main():
    levels = []
    print("Generating 50 verified solvable levels...")
    for idx, name, diff, target_arrows, W, H, shape in LEVEL_META:
        seed = 1000 + idx * 73
        paths, solve_order = generate_solvable_level(target_arrows, W, H, seed)
        solvable, test_order = solve_level(paths)
        assert solvable, f"Level {idx} must be solvable!"

        # Scale coordinates for beautiful rendering
        # Center the shape within normalized coordinates
        min_x = min(p[0] for path in paths for p in path['points'])
        max_x = max(p[0] for path in paths for p in path['points'])
        min_y = min(p[1] for path in paths for p in path['points'])
        max_y = max(p[1] for path in paths for p in path['points'])

        lvl_data = {
            "id": idx,
            "name": name,
            "difficulty": diff,
            "shape": shape,
            "arrows_count": len(paths),
            "drops": 3 if diff == "Simple" else (4 if diff == "Medium" else 5),
            "bounds": {
                "min_x": min_x,
                "max_x": max_x,
                "min_y": min_y,
                "max_y": max_y,
                "width": max_x - min_x + 1,
                "height": max_y - min_y + 1
            },
            "solve_order": solve_order,
            "paths": paths
        }
        levels.append(lvl_data)
        print(f"Level {idx:2d} ({diff:6s}): '{name:22s}' - {len(paths)} arrows, Solvable: {solvable}")

    out_file = "/Users/dws-mac001/amaze-go!/data/levels.json"
    with open(out_file, "w") as f:
        json.dump(levels, f, indent=2)
    print(f"Successfully wrote all 50 levels to {out_file}!")

if __name__ == "__main__":
    main()
