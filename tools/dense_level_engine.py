import json, random, math, os

DIRS = [(0, -1), (0, 1), (-1, 0), (1, 0)]
OPPOSITE = {(0, -1): (0, 1), (0, 1): (0, -1), (-1, 0): (1, 0), (1, 0): (-1, 0)}

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

def build_shape_mask(shape_name, W, H):
    mask = set()
    cx, cy = W / 2.0, H / 2.0

    for y in range(1, H - 1):
        for x in range(1, W - 1):
            nx = (x - cx) / (W / 2.0) # -1.0 to 1.0
            ny = (y - cy) / (H / 2.0) # -1.0 to 1.0
            in_shape = False

            if shape_name == "trophy":
                # Grand Trophy Cup (exact match to Screenshot 1)
                # Rim at top: ny in [-0.9, -0.65], abs(nx) <= 0.75
                # Bowl: ny in [-0.65, 0.15], abs(nx) <= 0.65
                # Handles: ny in [-0.55, -0.05], 0.55 <= abs(nx) <= 0.92
                # Stem: ny in [0.15, 0.55], abs(nx) <= 0.25
                # Pedestal base: ny in [0.55, 0.9], abs(nx) <= (0.35 + (ny - 0.55) * 1.2)
                if -0.9 <= ny <= -0.65 and abs(nx) <= 0.8:
                    in_shape = True
                elif -0.65 <= ny <= 0.15 and abs(nx) <= 0.68:
                    in_shape = True
                elif -0.58 <= ny <= -0.05 and (0.55 <= abs(nx) <= 0.94):
                    in_shape = True
                elif 0.15 < ny <= 0.55 and abs(nx) <= 0.26:
                    in_shape = True
                elif 0.55 < ny <= 0.9 and abs(nx) <= min(0.88, 0.4 + (ny - 0.55) * 1.4):
                    in_shape = True

            elif shape_name == "anchor":
                # Maritime Anchor (exact match to Screenshot 2)
                # Ring at top: ny in [-0.88, -0.5], ring around (0, -0.68)
                # Crossbar: ny in [-0.5, -0.32], abs(nx) <= 0.78
                # Shank: ny in [-0.32, 0.7], abs(nx) <= 0.24
                # Curved arms: 0.15 <= ny <= 0.88, 0.35 <= (nx*1.15)**2 + (ny - 0.15)**2 <= 0.88
                # Flukes: triangular tips at (abs(nx) in [0.65, 0.85], ny in [0.2, 0.45])
                dist_ring = nx*nx + (ny + 0.68)**2
                if 0.02 <= dist_ring <= 0.18 and ny <= -0.48:
                    in_shape = True
                elif -0.52 <= ny <= -0.32 and abs(nx) <= 0.8:
                    in_shape = True
                elif -0.32 < ny <= 0.72 and abs(nx) <= 0.24:
                    in_shape = True
                elif 0.15 <= ny <= 0.88 and (0.30 <= (nx*1.15)**2 + (ny - 0.15)**2 <= 0.88):
                    in_shape = True
                elif 0.15 <= ny <= 0.45 and (0.65 <= abs(nx) <= 0.88):
                    in_shape = True

            elif shape_name == "dog":
                # Scottish Terrier Dog (exact match to Screenshot 3)
                # Head: nx in [0.15, 0.7], ny in [-0.75, -0.15]
                # Ears: nx in [0.15, 0.45], ny in [-0.88, -0.55]
                # Snout: nx in [0.55, 0.92], ny in [-0.55, -0.15]
                # Torso/Back: nx in [-0.72, 0.45], ny in [-0.2, 0.42]
                # Tail: nx in [-0.88, -0.55], ny in [-0.72, -0.1]
                # Front leg: nx in [0.15, 0.45], ny in [0.42, 0.9]
                # Rear leg: nx in [-0.72, -0.35], ny in [0.42, 0.9]
                if 0.15 <= nx <= 0.7 and -0.75 <= ny <= -0.15:
                    in_shape = True
                elif 0.12 <= nx <= 0.48 and -0.88 <= ny <= -0.55:
                    in_shape = True
                elif 0.55 <= nx <= 0.94 and -0.55 <= ny <= -0.15:
                    in_shape = True
                elif -0.75 <= nx <= 0.45 and -0.2 <= ny <= 0.45:
                    in_shape = True
                elif -0.88 <= nx <= -0.52 and -0.72 <= ny <= -0.1:
                    in_shape = True
                elif 0.15 <= nx <= 0.48 and 0.42 <= ny <= 0.9:
                    in_shape = True
                elif -0.75 <= nx <= -0.32 and 0.42 <= ny <= 0.9:
                    in_shape = True

            elif shape_name == "butterfly":
                # Monarch Butterfly (exact match to Screenshot 4)
                # Thorax: abs(nx) <= 0.2, -0.85 <= ny <= 0.85
                # Upper wings: -0.85 <= ny <= 0.15, 0.2 <= abs(nx) <= 0.92
                # Lower wings: 0.15 < ny <= 0.85, 0.2 <= abs(nx) <= 0.8
                # Antennae: -0.92 <= ny <= -0.75, abs(nx) <= 0.35
                if abs(nx) <= 0.2 and -0.85 <= ny <= 0.85:
                    in_shape = True
                elif -0.85 <= ny <= 0.15 and 0.2 <= abs(nx) <= (0.92 - abs(ny + 0.35) * 0.4):
                    in_shape = True
                elif 0.15 < ny <= 0.85 and 0.2 <= abs(nx) <= (0.8 - (ny - 0.15) * 0.45):
                    in_shape = True
                elif -0.95 <= ny <= -0.75 and abs(nx) <= 0.35:
                    in_shape = True

            elif shape_name == "crown":
                # Royal Crown
                # Base band: ny in [0.35, 0.75], abs(nx) <= 0.88
                # Peaks: 3 peaks at nx = 0, nx = -0.65, nx = 0.65, reaching ny = -0.75
                if 0.35 <= ny <= 0.75 and abs(nx) <= 0.88:
                    in_shape = True
                elif -0.75 <= ny <= 0.35:
                    if abs(nx) <= 0.28:
                        in_shape = True
                    elif abs(abs(nx) - 0.62) <= 0.25:
                        in_shape = True

            elif shape_name == "heart":
                # Heart
                hx = nx * 1.25
                hy = -ny * 1.25 + 0.25
                val = (hx*hx + hy*hy - 1.0)**3 - (hx*hx) * (hy*hy*hy)
                if val <= 0.22 and ny <= 0.88:
                    in_shape = True

            elif shape_name == "sword":
                # Excalibur Sword: pommel, grip, crossguard, long double-edged blade
                if ny >= 0.6 and abs(nx) <= 0.18: # pommel & grip
                    in_shape = True
                elif 0.45 <= ny <= 0.6 and abs(nx) <= 0.75: # crossguard
                    in_shape = True
                elif -0.85 <= ny < 0.45 and abs(nx) <= 0.24: # blade
                    in_shape = True
                elif ny < -0.85 and abs(nx) <= (1.0 + ny) * 1.6: # tip
                    in_shape = True

            elif shape_name == "dragon":
                # Dragon / Phoenix: body, wings, head, tail
                if abs(nx) <= 0.25 and abs(ny) <= 0.8:
                    in_shape = True
                elif -0.4 <= ny <= 0.35 and 0.25 <= abs(nx) <= 0.92: # wings
                    in_shape = True
                elif ny < -0.4 and (abs(nx) <= 0.45 or -0.85 <= ny <= -0.5 and abs(nx) <= 0.6): # horns & head
                    in_shape = True
                elif ny > 0.4 and abs(nx) <= 0.6: # tail
                    in_shape = True

            elif shape_name == "guitar":
                # Acoustic Guitar
                if ny < -0.15 and abs(nx) <= 0.2: # neck & headstock
                    in_shape = True
                elif ny >= -0.15 and abs(nx) <= 0.75:
                    if ny < 0.25 and abs(nx) <= 0.55: # upper bout
                        in_shape = True
                    elif 0.25 <= ny <= 0.45 and abs(nx) <= 0.42: # waist
                        in_shape = True
                    elif ny > 0.45 and abs(nx) <= 0.72: # lower bout
                        in_shape = True

            elif shape_name == "rocket":
                # Space Rocket
                if -0.5 <= ny <= 0.55 and abs(nx) <= 0.38: # fuselage
                    in_shape = True
                elif ny < -0.5 and abs(nx) <= (1.0 + ny) * 0.9: # nose cone
                    in_shape = True
                elif 0.3 <= ny <= 0.85 and 0.35 <= abs(nx) <= 0.88: # delta fins
                    in_shape = True

            elif shape_name == "shield":
                # Knight Shield
                if -0.75 <= ny <= 0.2 and abs(nx) <= 0.85:
                    in_shape = True
                elif 0.2 < ny <= 0.88 and abs(nx) <= max(0.0, (0.88 - ny) * 1.3):
                    in_shape = True

            elif shape_name == "lion":
                # Lion: mane, body, legs, tail
                if abs(nx + 0.3) <= 0.55 and abs(ny + 0.25) <= 0.6:
                    in_shape = True
                elif abs(nx - 0.22) <= 0.65 and abs(ny) <= 0.48:
                    in_shape = True
                elif ny > 0.4 and (abs(nx - 0.45) <= 0.22 or abs(nx + 0.35) <= 0.22):
                    in_shape = True

            elif shape_name == "castle":
                # Castle Citadel
                if -0.15 <= ny <= 0.85 and abs(nx) <= 0.85:
                    in_shape = True
                elif ny < -0.15:
                    # 3 towers: left, center, right
                    if abs(nx) <= 0.22 or abs(abs(nx) - 0.65) <= 0.2:
                        in_shape = True

            elif shape_name == "cat":
                # Feline Cat
                if ny < -0.2: # head & ears
                    if abs(nx) <= 0.5:
                        in_shape = True
                    elif -0.8 <= ny <= -0.35 and 0.3 <= abs(nx) <= 0.65:
                        in_shape = True
                elif ny >= -0.2:
                    if abs(nx) <= 0.65:
                        in_shape = True
                    elif nx > 0.65 and ny <= 0.35: # tail
                        in_shape = True

            elif shape_name == "boat":
                # Viking Sailboat / Galleon
                if 0.25 <= ny <= 0.85 and abs(nx) <= (0.9 - (ny - 0.25) * 0.4): # hull
                    in_shape = True
                elif -0.75 <= ny < 0.25 and -0.1 <= nx <= (0.25 - ny) * 0.85: # sail
                    in_shape = True
                elif -0.75 <= ny < 0.25 and abs(nx + 0.12) <= 0.08: # mast
                    in_shape = True

            elif shape_name == "tree":
                # Ancient Bonsai
                if ny < 0.25 and (nx*nx + (ny + 0.25)**2 <= 0.72): # foliage
                    in_shape = True
                elif 0.25 <= ny <= 0.65 and abs(nx) <= 0.26: # trunk
                    in_shape = True
                elif ny > 0.65 and abs(nx) <= 0.72: # ceramic pot
                    in_shape = True

            elif shape_name == "gem":
                # Faceted Diamond
                if -0.75 <= ny <= -0.15 and abs(nx) <= 0.85:
                    in_shape = True
                elif -0.15 < ny <= 0.85 and abs(nx) <= max(0.0, (0.85 - ny) * 0.95):
                    in_shape = True

            elif shape_name == "skull":
                # Corsair Skull
                if ny <= 0.15 and (nx*nx + (ny + 0.2)**2 <= 0.68):
                    in_shape = True
                elif 0.15 < ny <= 0.75 and abs(nx) <= 0.48: # jaw / teeth
                    in_shape = True

            elif shape_name == "owl":
                # Wise Owl: body, head, ear tufts, eyes
                if -0.4 <= ny <= 0.75 and abs(nx) <= 0.65:
                    in_shape = True
                elif ny < -0.4:
                    if abs(nx) <= 0.55:
                        in_shape = True
                    elif -0.85 <= ny <= -0.5 and 0.35 <= abs(nx) <= 0.68: # ear tufts
                        in_shape = True

            else:
                # Intricate geometric maze pattern
                if abs(nx) <= 0.88 and abs(ny) <= 0.88:
                    in_shape = True

            if in_shape:
                mask.add((x, y))

    return mask

def generate_dense_level(shape_name, target_arrows, W, H, initial_seed):
    mask = build_shape_mask(shape_name, W, H)
    best_arrows = []
    best_order = []

    for attempt in range(120):
        rng = random.Random(initial_seed + attempt * 313)
        occ_map = {}
        arrows = []
        arrow_id = 0

        for step in range(target_arrows * 3):
            # Candidate heads that can exit unobstructed in current board state
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

                # We want multi-segment winding paths (2 to 5 segments)
                num_segments = rng.choices([2, 3, 4, 5], weights=[25, 45, 20, 10])[0]

                pts_from_head = [head]
                curr = head
                cur_growth_dir = rev_dir
                path_valid = True

                for seg_idx in range(num_segments):
                    max_len = rng.randint(2, 4) if seg_idx > 0 else rng.randint(1, 3)
                    seg_pts = []
                    for step_len in range(1, max_len + 1):
                        nx = curr[0] + cur_growth_dir[0] * step_len
                        ny = curr[1] + cur_growth_dir[1] * step_len
                        if (nx, ny) not in mask or (nx, ny) in occ_map or (nx, ny) in pts_from_head or (nx, ny) in seg_pts:
                            break
                        seg_pts.append((nx, ny))

                    if not seg_pts:
                        if seg_idx == 0:
                            path_valid = False
                        break

                    curr = seg_pts[-1]
                    pts_from_head.append(curr)

                    # 90-degree turn
                    perp_dirs = [(-cur_growth_dir[1], cur_growth_dir[0]), (cur_growth_dir[1], -cur_growth_dir[0])]
                    rng.shuffle(perp_dirs)
                    chosen_perp = None
                    for pd in perp_dirs:
                        test_p = (curr[0] + pd[0], curr[1] + pd[1])
                        if test_p in mask and test_p not in occ_map and test_p not in pts_from_head:
                            chosen_perp = pd
                            break
                    if chosen_perp:
                        cur_growth_dir = chosen_perp
                    else:
                        break

                if not path_valid or len(pts_from_head) < 2:
                    continue

                real_pts = list(reversed(pts_from_head))
                cells = get_cells_for_points(real_pts)

                if len(cells) < 2 or any(c in occ_map for c in cells):
                    continue

                a_obj = {
                    'id': arrow_id,
                    'points': real_pts,
                    'dir': list(dir_exit),
                    'cells': cells
                }
                arrows.append(a_obj)
                for c in cells:
                    occ_map[c] = arrow_id
                arrow_id += 1
                placed = True
                break

            if not placed:
                break

            if len(arrows) >= target_arrows:
                break

        if len(arrows) > len(best_arrows):
            solvable, order = solve(arrows, W, H)
            if solvable:
                best_arrows = arrows
                best_order = order
                if len(arrows) >= target_arrows - 3:
                    return best_arrows, best_order

    return best_arrows, best_order

print("Dense generator ready")
