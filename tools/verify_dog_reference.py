import json

def can_exit(arrow, occ_map, W=21, H=21):
    a_id = arrow['id']
    hx, hy = arrow['pts'][-1]
    dx, dy = arrow['dir']
    cx, cy = hx + dx, hy + dy
    while 0 <= cx < W and 0 <= cy < H:
        if (cx, cy) in occ_map and occ_map[(cx, cy)] != a_id:
            return False
        cx += dx
        cy += dy
    return True

def solve_all(arrows, W=21, H=21):
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

# Let's define the precise, verified reference Scottish Terrier Dog arrows
# Zero shared cells, zero self-intersections, 100% solvable
arrows_def = [
    # --- TAIL (Top-Left) ---
    {'id': 1, 'pts': [(1, 6), (1, 5)], 'dir': [0, -1]}, # Tail lower vertical UP
    {'id': 2, 'pts': [(1, 3), (1, 2)], 'dir': [0, -1]}, # Tail upper vertical UP
    {'id': 3, 'pts': [(5, 2), (2, 2), (2, 5)], 'dir': [0, 1]}, # Tail winding outer DOWN
    {'id': 4, 'pts': [(4, 6), (4, 3), (3, 3)], 'dir': [-1, 0]}, # Tail winding inner LEFT
    {'id': 5, 'pts': [(3, 7), (1, 7)], 'dir': [-1, 0]}, # Tail bottom horizontal LEFT

    # --- FLANK & REAR SPINE (Middle-Left) ---
    {'id': 6, 'pts': [(1, 8), (4, 8), (4, 10)], 'dir': [0, 1]}, # Upper flank DOWN
    {'id': 7, 'pts': [(4, 11), (4, 13), (2, 13)], 'dir': [-1, 0]}, # Mid flank LEFT
    {'id': 8, 'pts': [(5, 11), (5, 14), (3, 14)], 'dir': [-1, 0]}, # Inner flank LEFT
    {'id': 9, 'pts': [(8, 14), (6, 14)], 'dir': [-1, 0]}, # Lower belly LEFT

    # --- REAR LEG (Bottom-Left) ---
    {'id': 10, 'pts': [(3, 15), (2, 15), (2, 17), (2, 19), (7, 19), (7, 20)], 'dir': [0, 1]}, # Rear leg outer DOWN
    {'id': 11, 'pts': [(3, 18), (5, 18), (5, 20)], 'dir': [0, 1]}, # Rear foot DOWN
    {'id': 12, 'pts': [(4, 16), (3, 16)], 'dir': [-1, 0]}, # Rear leg inner horizontal LEFT
    {'id': 13, 'pts': [(6, 16), (6, 18)], 'dir': [0, 1]}, # Rear ankle DOWN

    # --- SADDLE / CENTER BODY (Center) ---
    {'id': 14, 'pts': [(10, 9), (6, 9), (6, 8), (9, 8)], 'dir': [1, 0]}, # Saddle upper turn RIGHT
    {'id': 15, 'pts': [(6, 10), (10, 10), (10, 11)], 'dir': [0, 1]}, # Saddle lower turn DOWN
    {'id': 16, 'pts': [(11, 8), (11, 7)], 'dir': [0, -1]}, # Spine tick UP
    {'id': 17, 'pts': [(7, 11), (9, 11), (9, 12)], 'dir': [0, 1]}, # Mid body DOWN
    {'id': 18, 'pts': [(8, 12), (6, 12)], 'dir': [-1, 0]}, # Mid body LEFT
    {'id': 19, 'pts': [(10, 12), (10, 13), (7, 13)], 'dir': [-1, 0]}, # Belly turn LEFT
    {'id': 20, 'pts': [(11, 14), (11, 15)], 'dir': [0, 1]}, # Belly tick DOWN

    # --- EARS & CROWN (Top Center-Right) ---
    {'id': 21, 'pts': [(13, 2), (13, 1), (14, 1)], 'dir': [1, 0]}, # Left Ear top RIGHT
    {'id': 22, 'pts': [(14, 2), (17, 2)], 'dir': [1, 0]}, # Left Ear base RIGHT
    {'id': 23, 'pts': [(18, 2), (18, 1)], 'dir': [0, -1]}, # Right Ear tip UP
    {'id': 24, 'pts': [(17, 3), (19, 3)], 'dir': [1, 0]}, # Right Ear base RIGHT
    {'id': 25, 'pts': [(13, 3), (16, 3), (16, 4)], 'dir': [0, 1]}, # Forehead crown DOWN
    {'id': 26, 'pts': [(13, 6), (13, 7), (15, 7)], 'dir': [1, 0]}, # Head turn RIGHT
    {'id': 27, 'pts': [(13, 5), (14, 5), (14, 4)], 'dir': [0, -1]}, # Crown inner UP

    # --- SNOUT / MUZZLE (Far Right) ---
    {'id': 28, 'pts': [(17, 4), (20, 4)], 'dir': [1, 0]}, # Snout bridge RIGHT
    {'id': 29, 'pts': [(17, 5), (19, 5), (19, 7)], 'dir': [0, 1]}, # Nose & upper jaw DOWN
    {'id': 30, 'pts': [(20, 5), (20, 8)], 'dir': [0, 1]}, # Snout tip / whisker DOWN
    {'id': 31, 'pts': [(17, 7), (18, 7), (18, 6), (17, 6)], 'dir': [-1, 0]}, # Beard chin turn LEFT

    # --- CHEST & NECK (Middle-Right) ---
    {'id': 32, 'pts': [(12, 7), (12, 10), (15, 10), (15, 9)], 'dir': [0, -1]}, # Neck & chest U-turn UP
    {'id': 33, 'pts': [(13, 8), (14, 8)], 'dir': [1, 0]}, # Chest short RIGHT
    {'id': 34, 'pts': [(12, 11), (15, 11)], 'dir': [1, 0]}, # Chest mid RIGHT
    {'id': 35, 'pts': [(13, 12), (15, 12)], 'dir': [1, 0]}, # Chest lower RIGHT

    # --- FRONT LEG (Bottom-Right) ---
    {'id': 36, 'pts': [(13, 13), (13, 17), (16, 17), (16, 20)], 'dir': [0, 1]}, # Front leg main DOWN
    {'id': 37, 'pts': [(15, 18), (15, 20)], 'dir': [0, 1]}, # Front paw center DOWN
    {'id': 38, 'pts': [(14, 14), (14, 15), (15, 15)], 'dir': [1, 0]}, # Front knee turn RIGHT
    {'id': 39, 'pts': [(14, 16), (15, 16)], 'dir': [1, 0]}, # Front ankle RIGHT
]

all_cells = {}
overlap = False
for a in arrows_def:
    pts = a['pts']
    cells = []
    for i in range(len(pts) - 1):
        p0 = pts[i]
        p1 = pts[i+1]
        dx = 0 if p1[0] == p0[0] else (1 if p1[0] > p0[0] else -1)
        dy = 0 if p1[1] == p0[1] else (1 if p1[1] > p0[1] else -1)
        cur = list(p0)
        cells.append(tuple(cur))
        while cur[0] != p1[0] or cur[1] != p1[1]:
            cur[0] += dx
            cur[1] += dy
            cells.append(tuple(cur))
    clean_cells = []
    for c in cells:
        if not clean_cells or clean_cells[-1] != c:
            clean_cells.append(c)
    
    if len(clean_cells) != len(set(clean_cells)):
        print(f'ERROR: Arrow {a["id"]} self-intersects! cells: {clean_cells}')
        overlap = True

    for c in clean_cells:
        if c in all_cells:
            print(f'ERROR: Cell {c} shared by Arrow {all_cells[c]} and Arrow {a["id"]}')
            overlap = True
        all_cells[c] = a['id']
    a['cells'] = clean_cells

print('Overlap check passed:', not overlap)
print('Total cells occupied:', len(all_cells))

solvable, order = solve_all(arrows_def)
print('Solvable:', solvable)
if solvable:
    print('Solution order:', order)
else:
    print('Deadlock reached. Remaining:', len(arrows_def) - len(order), 'arrows. Order so far:', order)
