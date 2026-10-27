import json, random, math

DIRS = [(0, -1), (0, 1), (-1, 0), (1, 0)]
OPPOSITE = {(0, -1): (0, 1), (0, 1): (0, -1), (-1, 0): (1, 0), (1, 0): (-1, 0)}

def get_shape_mask(shape_name, W, H):
    mask = set()
    cx, cy = W / 2.0, H / 2.0

    for y in range(1, H - 1):
        for x in range(1, W - 1):
            nx = (x - cx) / (W / 2.0) # -1 to 1
            ny = (y - cy) / (H / 2.0) # -1 to 1

            in_shape = False
            if shape_name == "triangle":
                # Triangle pointing up
                prog = (y - 1) / max(1.0, float(H - 3)) # 0 at top, 1 at bottom
                half_w = prog * (W / 2.0 - 0.5)
                if abs(x - cx) <= half_w + 0.6:
                    in_shape = True

            elif shape_name == "square":
                # Square box with nice margin
                if abs(nx) <= 0.8 and abs(ny) <= 0.8:
                    in_shape = True

            elif shape_name == "cross":
                # Plus / cross sign
                if abs(nx) <= 0.35 or abs(ny) <= 0.35:
                    if abs(nx) <= 0.85 and abs(ny) <= 0.85:
                        in_shape = True

            elif shape_name == "diamond":
                # Rhombus diamond
                if abs(nx) + abs(ny) <= 0.95:
                    in_shape = True

            elif shape_name == "corners":
                # Four corners / concentric box
                if (abs(nx) >= 0.45 or abs(ny) >= 0.45) and abs(nx) <= 0.85 and abs(ny) <= 0.85:
                    in_shape = True
                elif abs(nx) <= 0.25 and abs(ny) <= 0.25:
                    in_shape = True

            elif shape_name == "arrow":
                # Big arrow pointing up
                if ny >= 0 and abs(nx) <= 0.35:
                    in_shape = True
                elif ny < 0 and abs(nx) <= (1.0 + ny) * 1.1:
                    in_shape = True

            elif shape_name == "hourglass":
                # Hourglass shape
                if abs(nx) <= (abs(ny) * 0.75 + 0.22):
                    in_shape = True

            elif shape_name == "pinwheel":
                # Pinwheel
                if abs(nx) <= 0.8 and abs(ny) <= 0.8:
                    if (nx > 0 and ny < 0) or (nx < 0 and ny > 0) or abs(nx) <= 0.3 or abs(ny) <= 0.3:
                        in_shape = True

            elif shape_name == "house":
                # House: roof at top, box at bottom
                if ny > -0.1 and abs(nx) <= 0.75:
                    in_shape = True
                elif ny <= -0.1 and abs(nx) <= (1.0 - (-ny)) * 0.9:
                    in_shape = True

            elif shape_name == "trophy":
                # Trophy Cup: rim, bowl, handles, stem, base
                if ny < -0.6 and abs(nx) <= 0.65: # rim
                    in_shape = True
                elif -0.6 <= ny <= 0.1 and abs(nx) <= 0.55: # bowl
                    in_shape = True
                elif -0.5 <= ny <= -0.05 and (0.55 <= abs(nx) <= 0.85): # handles
                    in_shape = True
                elif 0.1 < ny <= 0.55 and abs(nx) <= 0.22: # stem
                    in_shape = True
                elif ny > 0.55 and abs(nx) <= 0.75: # pedestal base
                    in_shape = True

            elif shape_name == "key":
                # Key: round loop, shaft, teeth
                if ny < -0.3 and (0.2 <= nx*nx + (ny + 0.6)*(ny + 0.6) * 1.5 <= 0.7):
                    in_shape = True
                elif -0.3 <= ny <= 0.8 and abs(nx) <= 0.2:
                    in_shape = True
                elif 0.2 <= ny <= 0.75 and 0.2 < nx <= 0.65: # teeth
                    in_shape = True

            elif shape_name == "fish":
                # Fish: oval body + tail fin
                if nx <= 0.4 and (nx*1.2)**2 + ny**2 <= 0.65:
                    in_shape = True
                elif nx > 0.4 and abs(ny) <= (nx - 0.4) * 1.6 and nx <= 0.9: # tail
                    in_shape = True

            elif shape_name == "mug":
                # Coffee mug: cup body + right handle
                if abs(nx + 0.15) <= 0.55 and abs(ny) <= 0.75:
                    in_shape = True
                elif abs(ny) <= 0.45 and (0.45 <= nx <= 0.85):
                    in_shape = True

            elif shape_name == "anchor":
                # Sea anchor: stock, crossbar, crescent
                if abs(nx) <= 0.18 and abs(ny) <= 0.75: # shank
                    in_shape = True
                elif abs(ny + 0.35) <= 0.15 and abs(nx) <= 0.75: # crossbar
                    in_shape = True
                elif ny >= 0.25 and (0.45 <= nx*nx + ny*ny <= 0.9): # crescent
                    in_shape = True

            elif shape_name == "gem":
                # Faceted gem
                if ny <= -0.2 and abs(nx) <= 0.85:
                    in_shape = True
                elif ny > -0.2 and abs(nx) <= (1.0 - ny) * 0.95:
                    in_shape = True

            elif shape_name == "heart":
                # Heart
                # (x^2 + y^2 - 1)^3 - x^2 * y^3 <= 0
                hx = nx * 1.2
                hy = -ny * 1.2 + 0.2
                val = (hx*hx + hy*hy - 1.0)**3 - (hx*hx) * (hy*hy*hy)
                if val <= 0.15 and ny <= 0.85:
                    in_shape = True

            elif shape_name == "tree":
                # Bonsai tree
                if ny < 0.2 and (nx*nx + (ny + 0.3)**2 <= 0.65): # canopy
                    in_shape = True
                elif ny >= 0.2 and abs(nx) <= 0.25: # trunk
                    in_shape = True
                elif ny >= 0.7 and abs(nx) <= 0.65: # pot
                    in_shape = True

            elif shape_name == "apple":
                # Apple
                if ny < -0.65 and abs(nx) <= 0.15: # stem
                    in_shape = True
                elif ny >= -0.65 and (nx*nx + ny*ny <= 0.75): # body
                    in_shape = True

            elif shape_name == "boat":
                # Sailboat
                if ny > 0.25 and abs(nx) <= 0.85 and (ny - 0.25) >= abs(nx) * 0.3: # hull
                    in_shape = True
                elif ny <= 0.25 and nx >= -0.1 and nx <= (0.25 - ny) * 0.9: # main sail
                    in_shape = True
                elif ny <= 0.25 and nx < -0.1 and -nx <= (0.25 - ny) * 0.65: # jib sail
                    in_shape = True

            elif shape_name == "rocket":
                # Space Rocket
                if abs(nx) <= 0.35 and abs(ny) <= 0.7: # body
                    in_shape = True
                elif ny < -0.5 and abs(nx) <= (1.0 + ny) * 0.9: # nose
                    in_shape = True
                elif ny > 0.3 and (0.35 <= abs(nx) <= 0.85): # fins
                    in_shape = True

            elif shape_name == "butterfly":
                # Butterfly wings
                if abs(nx) <= 0.18 and abs(ny) <= 0.75: # thorax
                    in_shape = True
                elif (0.2 <= abs(nx) <= 0.85) and (abs(ny) <= 0.8): # wings
                    if abs(ny) > 0.1 or abs(nx) > 0.4:
                        in_shape = True

            elif shape_name == "crown":
                # Royal Crown
                if ny > 0.35 and abs(nx) <= 0.85: # base band
                    in_shape = True
                elif -0.7 <= ny <= 0.35:
                    # 3 peaks: center (nx=0), left (nx=-0.65), right (nx=0.65)
                    if abs(nx) <= 0.25:
                        in_shape = True
                    elif abs(abs(nx) - 0.6) <= 0.25:
                        in_shape = True

            elif shape_name == "guitar":
                # Acoustic Guitar
                if ny < -0.2 and abs(nx) <= 0.2: # neck
                    in_shape = True
                elif ny >= -0.2 and (abs(nx) <= 0.65 and (abs(nx) <= 0.45 or abs(ny - 0.4) > 0.2)): # body
                    in_shape = True

            elif shape_name == "shield":
                # Knight Shield
                if ny <= 0.1 and abs(nx) <= 0.85:
                    in_shape = True
                elif ny > 0.1 and abs(nx) <= (1.0 - (ny - 0.1)) * 0.95:
                    in_shape = True

            elif shape_name == "castle":
                # Castle Tower
                if ny > -0.2 and abs(nx) <= 0.85: # walls
                    in_shape = True
                elif ny <= -0.2: # battlements / turrets
                    if abs(nx) <= 0.25 or abs(abs(nx) - 0.7) <= 0.2:
                        in_shape = True

            elif shape_name == "cat":
                # Cat
                if ny < -0.2: # head & ears
                    if abs(nx) <= 0.5:
                        in_shape = True
                    elif -0.7 <= ny <= -0.3 and (0.35 <= abs(nx) <= 0.65): # ears
                        in_shape = True
                elif ny >= -0.2: # body & tail
                    if abs(nx) <= 0.65:
                        in_shape = True
                    elif nx > 0.65 and ny <= 0.3: # tail
                        in_shape = True

            elif shape_name == "car":
                # Retro Car
                if ny > 0.05 and abs(nx) <= 0.9: # lower chassis
                    in_shape = True
                elif -0.55 <= ny <= 0.05 and abs(nx + 0.1) <= 0.5: # cabin
                    in_shape = True

            elif shape_name == "dog":
                # Scottish Terrier Dog (exact silhouette of reference)
                # Head: nx in [0.2, 0.7], ny in [-0.75, -0.2]
                # Ears: nx in [0.2, 0.45], ny in [-0.85, -0.6]
                # Snout: nx in [0.6, 0.9], ny in [-0.55, -0.2]
                # Back/body: nx in [-0.65, 0.35], ny in [-0.2, 0.35]
                # Tail: nx in [-0.85, -0.6], ny in [-0.6, -0.1]
                # Front legs: nx in [0.15, 0.45], ny in [0.35, 0.85]
                # Rear legs: nx in [-0.65, -0.35], ny in [0.35, 0.85]
                if 0.15 <= nx <= 0.7 and -0.75 <= ny <= -0.15: # head
                    in_shape = True
                elif 0.15 <= nx <= 0.45 and -0.85 <= ny <= -0.55: # ears
                    in_shape = True
                elif 0.55 <= nx <= 0.9 and -0.55 <= ny <= -0.15: # snout
                    in_shape = True
                elif -0.7 <= nx <= 0.45 and -0.2 <= ny <= 0.4: # torso
                    in_shape = True
                elif -0.85 <= nx <= -0.55 and -0.65 <= ny <= -0.1: # tail pointing up
                    in_shape = True
                elif 0.15 <= nx <= 0.45 and 0.4 <= ny <= 0.85: # front leg
                    in_shape = True
                elif -0.7 <= nx <= -0.35 and 0.4 <= ny <= 0.85: # rear leg
                    in_shape = True

            elif shape_name == "lion":
                # Lion: mane, body, legs, tail
                if abs(nx + 0.35) <= 0.55 and abs(ny + 0.25) <= 0.6: # mane & head
                    in_shape = True
                elif abs(nx - 0.2) <= 0.65 and abs(ny) <= 0.45: # body
                    in_shape = True
                elif ny > 0.4 and (abs(nx - 0.45) <= 0.2 or abs(nx + 0.35) <= 0.2): # legs
                    in_shape = True

            elif shape_name == "spider":
                # Spider
                if nx*nx + ny*ny <= 0.3: # body
                    in_shape = True
                elif abs(nx) > 0.3 and abs(ny) <= 0.75: # legs
                    in_shape = True

            elif shape_name in ("phoenix", "dragon"):
                # Dragon / Phoenix
                if abs(nx) <= 0.25 and abs(ny) <= 0.75:
                    in_shape = True
                elif abs(ny + 0.1) <= 0.5 and (0.25 <= abs(nx) <= 0.85): # wings
                    in_shape = True
                elif ny > 0.4 and abs(nx) <= 0.65: # tail
                    in_shape = True

            elif shape_name == "skull":
                # Skull
                if ny <= 0.15 and (nx*nx + (ny + 0.2)**2 <= 0.65): # cranium
                    in_shape = True
                elif 0.15 < ny <= 0.75 and abs(nx) <= 0.45: # teeth/jaw
                    in_shape = True

            else:
                # Default shape (maze / rectangle)
                if abs(nx) <= 0.88 and abs(ny) <= 0.88:
                    in_shape = True

            if in_shape:
                mask.add((x, y))

    return mask

print("Mask library ready")
