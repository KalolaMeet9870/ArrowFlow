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

def build_shape_mask(shape_name, N):
    mask = set()
    cx, cy = N / 2.0, N / 2.0

    for y in range(1, N - 1):
        for x in range(1, N - 1):
            nx = (x - cx) / (N / 2.0) # -1.0 to 1.0
            ny = (y - cy) / (N / 2.0) # -1.0 to 1.0
            in_shape = False

            if shape_name == "dog":
                # Scottish Terrier Dog (exact match to user prompt image)
                # Head: nx in [0.15, 0.75], ny in [-0.75, -0.15]
                # Ears: nx in [0.15, 0.45], ny in [-0.92, -0.55]
                # Snout: nx in [0.55, 0.94], ny in [-0.55, -0.12]
                # Torso/Back: nx in [-0.75, 0.45], ny in [-0.2, 0.45]
                # Tail: nx in [-0.9, -0.55], ny in [-0.75, -0.1]
                # Front leg: nx in [0.15, 0.52], ny in [0.45, 0.92]
                # Rear leg: nx in [-0.75, -0.32], ny in [0.45, 0.92]
                if 0.15 <= nx <= 0.75 and -0.75 <= ny <= -0.15:
                    in_shape = True
                elif 0.12 <= nx <= 0.48 and -0.92 <= ny <= -0.55: # ears
                    in_shape = True
                elif 0.55 <= nx <= 0.94 and -0.55 <= ny <= -0.12: # snout
                    in_shape = True
                elif -0.75 <= nx <= 0.45 and -0.2 <= ny <= 0.45: # body
                    in_shape = True
                elif -0.9 <= nx <= -0.55 and -0.75 <= ny <= -0.1: # tail
                    in_shape = True
                elif 0.15 <= nx <= 0.52 and 0.45 <= ny <= 0.92: # front leg
                    in_shape = True
                elif -0.75 <= nx <= -0.32 and 0.45 <= ny <= 0.92: # rear leg
                    in_shape = True

            elif shape_name == "trophy":
                # Grand Championship Trophy
                if -0.9 <= ny <= -0.65 and abs(nx) <= 0.82:
                    in_shape = True
                elif -0.65 <= ny <= 0.15 and abs(nx) <= 0.68:
                    in_shape = True
                elif -0.58 <= ny <= -0.05 and (0.55 <= abs(nx) <= 0.94):
                    in_shape = True
                elif 0.15 < ny <= 0.55 and abs(nx) <= 0.28:
                    in_shape = True
                elif 0.55 < ny <= 0.9 and abs(nx) <= min(0.88, 0.4 + (ny - 0.55) * 1.4):
                    in_shape = True

            elif shape_name == "anchor":
                # Deep Ocean Anchor
                dist_ring = nx*nx + (ny + 0.68)**2
                if 0.02 <= dist_ring <= 0.18 and ny <= -0.48:
                    in_shape = True
                elif -0.52 <= ny <= -0.32 and abs(nx) <= 0.82:
                    in_shape = True
                elif -0.32 < ny <= 0.72 and abs(nx) <= 0.26:
                    in_shape = True
                elif 0.15 <= ny <= 0.88 and (0.30 <= (nx*1.15)**2 + (ny - 0.15)**2 <= 0.88):
                    in_shape = True
                elif 0.15 <= ny <= 0.45 and (0.65 <= abs(nx) <= 0.88):
                    in_shape = True

            elif shape_name == "butterfly":
                # Golden Monarch Butterfly
                if abs(nx) <= 0.22 and -0.85 <= ny <= 0.85:
                    in_shape = True
                elif -0.85 <= ny <= 0.15 and 0.2 <= abs(nx) <= (0.92 - abs(ny + 0.35) * 0.4):
                    in_shape = True
                elif 0.15 < ny <= 0.85 and 0.2 <= abs(nx) <= (0.8 - (ny - 0.15) * 0.45):
                    in_shape = True
                elif -0.95 <= ny <= -0.75 and abs(nx) <= 0.38:
                    in_shape = True

            elif shape_name == "square_maze":
                # Full square labyrinth
                if abs(nx) <= 0.88 and abs(ny) <= 0.88:
                    in_shape = True

            elif shape_name == "crown":
                if 0.35 <= ny <= 0.75 and abs(nx) <= 0.88:
                    in_shape = True
                elif -0.75 <= ny <= 0.35:
                    if abs(nx) <= 0.28 or abs(abs(nx) - 0.62) <= 0.25:
                        in_shape = True

            elif shape_name == "heart":
                hx = nx * 1.25
                hy = -ny * 1.25 + 0.25
                val = (hx*hx + hy*hy - 1.0)**3 - (hx*hx) * (hy*hy*hy)
                if val <= 0.22 and ny <= 0.88:
                    in_shape = True

            elif shape_name == "rocket":
                if abs(nx) <= 0.32 and -0.75 <= ny <= 0.6:
                    in_shape = True
                elif ny < -0.75 and abs(nx) <= max(0.0, (1.0 + ny) * 1.3):
                    in_shape = True
                elif ny > 0.4 and abs(nx) <= (0.32 + (ny - 0.4) * 1.2):
                    in_shape = True

            elif shape_name == "sword":
                if ny >= 0.6 and abs(nx) <= 0.18:
                    in_shape = True
                elif 0.45 <= ny <= 0.6 and abs(nx) <= 0.75:
                    in_shape = True
                elif -0.85 <= ny < 0.45 and abs(nx) <= 0.24:
                    in_shape = True
                elif ny < -0.85 and abs(nx) <= (1.0 + ny) * 1.6:
                    in_shape = True

            elif shape_name == "guitar":
                if ny < -0.25 and abs(nx) <= 0.18:
                    in_shape = True
                elif -0.25 <= ny <= 0.15 and (nx*nx + (ny + 0.05)**2 <= 0.45):
                    in_shape = True
                elif 0.15 < ny <= 0.8 and (nx*nx + (ny - 0.45)**2 <= 0.65):
                    in_shape = True

            elif shape_name == "shield":
                if -0.8 <= ny <= 0.15 and abs(nx) <= 0.8:
                    in_shape = True
                elif 0.15 < ny <= 0.85 and abs(nx) <= (0.8 - (ny - 0.15) * 1.15):
                    in_shape = True

            elif shape_name == "dragon":
                if abs(nx) <= 0.25 and abs(ny) <= 0.8:
                    in_shape = True
                elif -0.35 <= ny <= 0.35 and abs(nx) <= 0.88:
                    in_shape = True
                elif ny < -0.5 and 0.0 <= nx <= 0.65:
                    in_shape = True
                elif ny > 0.45 and -0.85 <= nx <= -0.15:
                    in_shape = True

            elif shape_name == "lion":
                if ny <= 0.0 and (nx*nx + (ny + 0.35)**2 <= 0.65):
                    in_shape = True
                elif ny > 0.0 and abs(nx) <= 0.65:
                    in_shape = True

            elif shape_name == "castle":
                if 0.1 <= ny <= 0.8 and abs(nx) <= 0.82:
                    in_shape = True
                elif -0.8 <= ny < 0.1:
                    if abs(nx) <= 0.24 or abs(abs(nx) - 0.6) <= 0.22:
                        in_shape = True

            elif shape_name == "cat":
                if ny < -0.2:
                    if nx*nx + (ny + 0.45)**2 <= 0.42:
                        in_shape = True
                    elif -0.8 <= ny <= -0.35 and 0.3 <= abs(nx) <= 0.65:
                        in_shape = True
                elif ny >= -0.2:
                    if abs(nx) <= 0.65 or (nx > 0.65 and ny <= 0.35):
                        in_shape = True

            elif shape_name == "tree":
                if ny < 0.25 and (nx*nx + (ny + 0.25)**2 <= 0.72):
                    in_shape = True
                elif 0.25 <= ny <= 0.65 and abs(nx) <= 0.26:
                    in_shape = True
                elif ny > 0.65 and abs(nx) <= 0.72:
                    in_shape = True

            elif shape_name == "gem":
                if -0.75 <= ny <= -0.15 and abs(nx) <= 0.85:
                    in_shape = True
                elif -0.15 < ny <= 0.85 and abs(nx) <= max(0.0, (0.85 - ny) * 0.95):
                    in_shape = True

            elif shape_name == "skull":
                if ny <= 0.15 and (nx*nx + (ny + 0.2)**2 <= 0.68):
                    in_shape = True
                elif 0.15 < ny <= 0.75 and abs(nx) <= 0.48:
                    in_shape = True

            elif shape_name == "owl":
                if -0.4 <= ny <= 0.75 and abs(nx) <= 0.65:
                    in_shape = True
                elif ny < -0.4:
                    if abs(nx) <= 0.55 or (-0.85 <= ny <= -0.5 and 0.35 <= abs(nx) <= 0.68):
                        in_shape = True

            else:
                if abs(nx) <= 0.85 and abs(ny) <= 0.85:
                    in_shape = True

            if in_shape:
                mask.add((x, y))

    return mask

def generate_square_level(shape_name, target_arrows, N, initial_seed):
    mask = build_shape_mask(shape_name, N)
    best_arrows = []
    best_order = []

    for attempt in range(150):
        rng = random.Random(initial_seed + attempt * 277)
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
                    while 0 <= cx < N and 0 <= cy < N:
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

                # We want multi-segment winding paths (2 to 4 segments)
                num_segments = rng.choices([2, 3, 4], weights=[35, 45, 20])[0]

                pts_from_head = [head]
                curr = head
                cur_growth_dir = rev_dir
                arrow_cells = {head} # STRICT SET OF ALL CELLS IN THIS ARROW
                path_valid = True

                for seg_idx in range(num_segments):
                    max_len = rng.randint(2, 4) if seg_idx > 0 else rng.randint(1, 3)
                    seg_pts = []
                    for step_len in range(1, max_len + 1):
                        nx = curr[0] + cur_growth_dir[0] * step_len
                        ny = curr[1] + cur_growth_dir[1] * step_len
                        # STRICT CHECK: must be in mask, NOT in occ_map, and NOT in arrow_cells (ZERO SELF-INTERSECTION)
                        if (nx, ny) not in mask or (nx, ny) in occ_map or (nx, ny) in arrow_cells:
                            break
                        seg_pts.append((nx, ny))

                    if not seg_pts:
                        if seg_idx == 0:
                            path_valid = False
                        break

                    # Add all intermediate cells to arrow_cells to prevent self-crossing
                    for pt in seg_pts:
                        arrow_cells.add(pt)

                    curr = seg_pts[-1]
                    pts_from_head.append(curr)

                    # 90-degree turn
                    perp_dirs = [(-cur_growth_dir[1], cur_growth_dir[0]), (cur_growth_dir[1], -cur_growth_dir[0])]
                    rng.shuffle(perp_dirs)
                    chosen_perp = None
                    for pd in perp_dirs:
                        test_p = (curr[0] + pd[0], curr[1] + pd[1])
                        if test_p in mask and test_p not in occ_map and test_p not in arrow_cells:
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
            solvable, order = solve(arrows, N, N)
            if solvable:
                best_arrows = arrows
                best_order = order
                if len(arrows) >= target_arrows - 2:
                    return best_arrows, best_order

    return best_arrows, best_order

print("Square level engine ready")
