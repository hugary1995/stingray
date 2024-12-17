import gmsh
import math

# All units in mm
MH = 3 * 25.4  # manifold height
MR = 7.5 * 25.4 / 2  # manifold radius
MT = 0.125 * 25.4  # manifold wall thickness
TH = 3 * 25.4  # Top tube extension length
TR = 2.5 * 25.4 / 2  # Top tube radius
TT = 0.25 * 25.4 / 2  # Top tube wall thickness
BH = 3 * 25.4  # Bottom tube extension length
BR = 1 * 25.4 / 2  # Bottom tube radius
BT = 0.2 * 25.4 / 2  # Bottom tube wall thickness
BL = 5 * 25.4 / 2  # Bottom hexagon side length

# Bottom tubes center positions
bot_ext_pos = [(0, 0)]
for i in range(6):
    angle = i * 60 / 180 * math.pi
    bot_ext_pos.append((BL * math.cos(angle), BL * math.sin(angle)))

gmsh.initialize()
ext_outer = []
ext_inner = []

# The manifold
manifold_outer = gmsh.model.occ.addCylinder(0, 0, 0, 0, 0, MH, MR)
manifold_inner = gmsh.model.occ.addCylinder(0, 0, MT, 0, 0, MH - 2 * MT, MR - MT)
manifold = 100
gmsh.model.occ.cut([(3, manifold_outer)], [(3, manifold_inner)], manifold)

# The top extension
outer = gmsh.model.occ.addCylinder(0, 0, MH, 0, 0, TH, TR)
inner = gmsh.model.occ.addCylinder(0, 0, MH - MT, 0, 0, TH + MT, TR - TT)
ext_outer.append((3, outer))
ext_inner.append((3, inner))

# The bottom extensions
for x, y in bot_ext_pos:
    outer = gmsh.model.occ.addCylinder(x, y, -BH, 0, 0, BH, BR)
    inner = gmsh.model.occ.addCylinder(x, y, -BH, 0, 0, BH + MT, BR - BT)
    ext_outer.append((3, outer))
    ext_inner.append((3, inner))

# Merge and cut
dimtags, _ = gmsh.model.occ.fragment([(3, manifold)], ext_outer)
gmsh.model.occ.cut(dimtags, ext_inner)

gmsh.model.occ.synchronize()
gmsh.write("manifold.stl")
