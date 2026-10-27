import json, random, math
from shape_masks import get_shape_mask

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

def generate_hard_level(shape_name, target_arrows, W, H, seed=42):
    mask = get_shape_mask(shape_name, W, H)
    print(f"Mask '{shape_name}' on {W}x{H} has {len(mask)} cells. Target: {target_arrows} arrows.")

    best_arrows = []
    best_order = []

    for attempt in range(120):
        rng = random.Random(seed + attempt * 277)
        occ_map = {}
        arrows = []
        arrow_id = 0

        # In reverse generation: arrows placed first can exit with currently placed arrows.
        # Max steps
        for step in range(target_arrows * 3):
            # Find candidate cells for arrowhead that can exit cleanly to boundary
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

                # We want multi-segment meandering arrows: 2 to 5 segments
                num_segments = rng.choices([2, 3, 4, 5], weights=[20, 40, 30, 10])[0]

                pts_from_head = [head]
                curr = head
                cur_growth_dir = rev_dir
                path_valid = True

                for seg_idx in range(num_segments):
                    # Segment length
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

                    # Turn 90 degrees for next segment
                    perp_dirs = [(-cur_growth_dir[1], cur_growth_dir[0]), (cur_growth_dir[1], -cur_growth_dir[0])]
                    rng.shuffle(perp_dirs)
                    # Pick direction that has free mask cells
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

                # Ensure minimum length of 2 cells and no collisions
                if len(cells) < 2 or any(c in occ_map for c in cells):
                    continue

                # Valid arrow!
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
                print(f"  Attempt {attempt}: generated {len(arrows)} solvable arrows (target: {target_arrows})")
                if len(arrows) >= target_arrows - 2:
                    return best_arrows, best_order

    return best_arrows, best_order

if __name__ == "__main__":
    for s in ["trophy", "anchor", "dog", "butterfly"]:
        arrows, order = generate_hard_level(s, 42, 22, 24, seed=1234)
        print(f"Result for {s}: {len(arrows)} arrows, solved={len(order) == len(arrows)}")
