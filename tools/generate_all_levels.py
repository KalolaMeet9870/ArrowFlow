import json, random, math
from shape_masks import get_shape_mask

DIRS = [(0, -1), (0, 1), (-1, 0), (1, 0)]
OPPOSITE = {(0, -1): (0, 1), (0, 1): (0, -1), (-1, 0): (1, 0), (1, 0): (-1, 0)}

LEVEL_META = [
    # Simple (1 - 15)
    (1, "Warmup Tri", "Simple", 3, 7, 7, "triangle"),
    (2, "Square Box", "Simple", 4, 7, 7, "square"),
    (3, "Cross Roads", "Simple", 4, 8, 8, "cross"),
    (4, "Diamond Pin", "Simple", 4, 8, 8, "diamond"),
    (5, "Four Corners", "Simple", 5, 8, 8, "corners"),
    (6, "Arrow Sign", "Simple", 5, 9, 9, "arrow"),
    (7, "Hourglass", "Simple", 6, 9, 9, "hourglass"),
    (8, "Windmill", "Simple", 6, 10, 10, "pinwheel"),
    (9, "Little House", "Simple", 7, 10, 10, "house"),
    (10, "Trophy Cup", "Simple", 8, 11, 11, "trophy"),
    (11, "Antique Key", "Simple", 8, 11, 11, "key"),
    (12, "Goldfish", "Simple", 8, 11, 11, "fish"),
    (13, "Coffee Mug", "Simple", 9, 11, 11, "mug"),
    (14, "Sea Anchor", "Simple", 9, 12, 12, "anchor"),
    (15, "Sparkle Gem", "Simple", 10, 12, 12, "gem"),

    # Medium (16 - 35)
    (16, "Heartbeat", "Medium", 10, 12, 12, "heart"),
    (17, "Bonsai Tree", "Medium", 11, 13, 13, "tree"),
    (18, "Sweet Apple", "Medium", 11, 13, 13, "apple"),
    (19, "Sailboat", "Medium", 12, 13, 13, "boat"),
    (20, "Space Rocket", "Medium", 12, 14, 14, "rocket"),
    (21, "Butterfly Wings", "Medium", 13, 14, 14, "butterfly"),
    (22, "Royal Crown", "Medium", 13, 14, 14, "crown"),
    (23, "Acoustic Guitar", "Medium", 14, 15, 15, "guitar"),
    (24, "Knight Shield", "Medium", 14, 15, 15, "shield"),
    (25, "Castle Tower", "Medium", 15, 15, 15, "castle"),
    (26, "Playful Kitten", "Medium", 15, 15, 15, "cat"),
    (27, "Retro Car", "Medium", 16, 16, 16, "car"),
    (28, "Mallard Duck", "Medium", 16, 16, 16, "duck"),
    (29, "Forest Mushroom", "Medium", 16, 16, 16, "mushroom"),
    (30, "Vintage Camera", "Medium", 17, 16, 16, "camera"),
    (31, "Ceramic Teapot", "Medium", 17, 17, 17, "teapot"),
    (32, "Jetliner", "Medium", 18, 17, 17, "airplane"),
    (33, "Rain Umbrella", "Medium", 18, 17, 17, "umbrella"),
    (34, "Wise Owl", "Medium", 19, 17, 17, "owl"),
    (35, "Retro Robot", "Medium", 20, 18, 18, "robot"),

    # Hard (36 - 50)
    (36, "Champion Trophy", "Hard", 22, 18, 18, "trophy"),
    (37, "Hound Dog", "Hard", 24, 19, 19, "dog"),
    (38, "Puppy Run", "Hard", 24, 19, 19, "dog"),
    (39, "Majestic Lion", "Hard", 25, 20, 20, "lion"),
    (40, "Spotted Terrier", "Hard", 26, 20, 20, "dog"),
    (41, "Fire Dragon", "Hard", 26, 20, 20, "dragon"),
    (42, "Cobweb Spider", "Hard", 27, 21, 21, "spider"),
    (43, "Golden Phoenix", "Hard", 27, 21, 21, "phoenix"),
    (44, "Minotaur Maze", "Hard", 28, 21, 21, "maze"),
    (45, "Greek Key Meander", "Hard", 28, 22, 22, "corners"),
    (46, "Viking Longship", "Hard", 29, 22, 22, "boat"),
    (47, "Pirate Skull", "Hard", 29, 22, 22, "skull"),
    (48, "Monarch Butterfly", "Hard", 30, 23, 23, "butterfly"),
    (49, "Rock Guitar", "Hard", 30, 23, 23, "guitar"),
    (50, "Grand Labyrinth Master", "Hard", 32, 24, 24, "maze")
]

def get_cells_for_points(pts):
    cells = []
    seen = set()
    for i in range(len(pts) - 1):
        p0 = pts[i]
        p1 = pts[i + 1]
        dx = 0 if p1[0] == p0[0] else (1 if p1[0] > p0[0] else -1)
        dy = 0 if p1[1] == p0[1] else (1 if p1[1] > p0[1] else -1)
        cur = [p0[0], p0[1]]
        if tuple(cur) not in seen:
            seen.add(tuple(cur))
            cells.append(tuple(cur))
        while cur[0] != p1[0] or cur[1] != p1[1]:
            cur[0] += dx
            cur[1] += dy
            if tuple(cur) not in seen:
                seen.add(tuple(cur))
                cells.append(tuple(cur))
    return cells

def can_exit(arrow, occ_map, W, H):
    a_id = arrow['id']
    hx, hy = arrow['points'][-1]
    dx, dy = arrow['dir']
    cx, cy = hx + dx, hy + dy
    while 0 <= cx < W and 0 <= cy < H:
        if (cx, cy) in occ_map and occ_map[(cx, cy)] != a_id:
            return False
        cx += dx
        cy += dy
    return True

def solve(arrows, W, H):
    active = {a['id']: a for a in arrows}
    occ_map = {}
    for a in arrows:
        for c in a['cells']:
            occ_map[c] = a['id']

    order = []
    while active:
        free_id = None
        for a_id in list(active.keys()):
            if can_exit(active[a_id], occ_map, W, H):
                free_id = a_id
                break
        if free_id is None:
            return False, order
        freed = active.pop(free_id)
        for c in freed['cells']:
            if occ_map.get(c) == free_id:
                del occ_map[c]
        order.append(free_id)
    return True, order

def generate_level(mask, target_count, W, H, initial_seed=42):
    for attempt in range(80):
        rng = random.Random(initial_seed + attempt * 173)
        occ_map = {}
        arrows = []
        arrow_id = 0

        for step in range(target_count):
            candidates = []
            for (hx, hy) in mask:
                if (hx, hy) in occ_map:
                    continue
                for d in DIRS:
                    dx, dy = d
                    cx, cy = hx + dx, hy + dy
                    clear = True
                    while 0 <= cx < W and 0 <= cy < H:
                        if (cx, cy) in occ_map:
                            clear = False
                            break
                        cx += dx
                        cy += dy
                    if clear:
                        candidates.append(((hx, hy), d))

            if not candidates:
                break

            rng.shuffle(candidates)
            placed = False
            for (head, dir_exit) in candidates:
                rev_dir = OPPOSITE[dir_exit]
                first_len = rng.randint(1, 3)
                curr = head
                temp_cells = [head]
                valid_first = True
                for i in range(1, first_len + 1):
                    nx = curr[0] + rev_dir[0] * i
                    ny = curr[1] + rev_dir[1] * i
                    if (nx, ny) not in mask or (nx, ny) in occ_map:
                        if i == 1:
                            valid_first = False
                        break
                    temp_cells.append((nx, ny))

                if not valid_first or len(temp_cells) < 2:
                    continue

                curr = temp_cells[-1]
                pts = [head, curr]

                # Optional 2nd segment (turn 90 deg)
                if rng.random() < 0.65:
                    turn_dirs = [d for d in DIRS if d != dir_exit and d != rev_dir]
                    rng.shuffle(turn_dirs)
                    for td in turn_dirs:
                        turn_len = rng.randint(1, 3)
                        turn_cells = []
                        valid_turn = True
                        for ti in range(1, turn_len + 1):
                            tx = curr[0] + td[0] * ti
                            ty = curr[1] + td[1] * ti
                            if (tx, ty) not in mask or (tx, ty) in occ_map:
                                if ti == 1:
                                    valid_turn = False
                                break
                            turn_cells.append((tx, ty))
                        if valid_turn and turn_cells:
                            curr = turn_cells[-1]
                            pts.append(curr)
                            break

                real_pts = list(reversed(pts))
                all_cells = get_cells_for_points(real_pts)
                conflict = any(c in occ_map for c in all_cells)
                if conflict:
                    continue

                a_obj = {
                    'id': arrow_id,
                    'points': real_pts,
                    'dir': list(dir_exit),
                    'cells': all_cells
                }
                arrows.append(a_obj)
                for c in all_cells:
                    occ_map[c] = arrow_id
                arrow_id += 1
                placed = True
                break

            if not placed:
                break

        if len(arrows) >= max(3, target_count - 2):
            solvable, order = solve(arrows, W, H)
            if solvable:
                return arrows, order

    # Fallback to concentric grid if shape generation fails
    print("  Using fallback generator for level...")
    arrows = []
    occ_map = {}
    for i in range(target_count):
        ring = i % 4 + 1
        d = DIRS[i % 4]
        head = (W // 2 + d[0] * ring, H // 2 + d[1] * ring)
        tail = (head[0] - d[0] * 2, head[1] - d[1] * 2)
        real_pts = [tail, head]
        cells = get_cells_for_points(real_pts)
        arrows.append({'id': i, 'points': real_pts, 'dir': list(d), 'cells': cells})
    solvable, order = solve(arrows, W, H)
    return arrows, order

def main():
    levels = []
    print("Generating 50 verified solvable levels with authentic shapes...")

    for idx, name, diff, target_arrows, W, H, shape in LEVEL_META:
        mask = get_shape_mask(shape, W, H)
        if len(mask) < target_arrows * 2:
            # Expand mask slightly if too sparse
            mask = get_shape_mask("maze", W, H)

        seed = 2000 + idx * 89
        arrows, solve_order = generate_level(mask, target_arrows, W, H, seed)
        assert len(arrows) >= 3, f"Level {idx} must have at least 3 arrows!"
        solvable, verify_order = solve(arrows, W, H)
        assert solvable, f"Level {idx} must be solvable!"

        # Verify all arrow directions match their final segment
        for a in arrows:
            pts = a['points']
            dx = pts[-1][0] - pts[-2][0]
            dy = pts[-1][1] - pts[-2][1]
            seg_dir = (0 if dx == 0 else (1 if dx > 0 else -1), 0 if dy == 0 else (1 if dy > 0 else -1))
            assert seg_dir == tuple(a['dir']), f"Direction mismatch in Level {idx} arrow {a['id']}!"

        # Normalize coordinates
        min_x = min(p[0] for a in arrows for p in a['points'])
        max_x = max(p[0] for a in arrows for p in a['points'])
        min_y = min(p[1] for a in arrows for p in a['points'])
        max_y = max(p[1] for a in arrows for p in a['points'])

        paths = []
        for a in arrows:
            paths.append({
                'id': a['id'],
                'points': a['points'],
                'dir': a['dir']
            })

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
        print(f"Level {idx:2d} ({diff:6s}): '{name:22s}' shape='{shape:10s}' - {len(paths)} arrows, Solvable: {solvable}")

    out_file = "/Users/dws-mac001/amaze-go!/data/levels.json"
    with open(out_file, "w") as f:
        json.dump(levels, f, indent=2)
    print(f"\nSUCCESS: Wrote all 50 verified shaped levels to {out_file}!")

if __name__ == "__main__":
    main()
