import gmsh

W = 250
H = 300

CW = 90
CH = 4
CN = 4
CS = 16

ERX = 6
ERY = 3
EN = 5
EM = 5
ES = 8

eps = 1e-3

gmsh.initialize()
# gmsh.option.setNumber("General.Verbosity", 0)


hx = gmsh.model.occ.addRectangle(0, 0, 0, W, H)

CY0 = H / 2 - CS * (CN - 1) / 2 - CH * CN / 2
channels = []
for i in range(CN):
    c = gmsh.model.occ.addRectangle((W - CW) / 2, CY0 + CH * i + CS * i, 0, CW, CH)
    channels.append((2, c))

ECS = CS + CH - 2 * ERY
EY0 = H / 2 - ECS * (EN - 1) / 2 - ERY * (EN - 1)
EX0 = W / 2 - ES * (EM - 1) / 2 - ERX * (EM - 1)
for i in range(EN):
    for j in range(EM):
        c = gmsh.model.occ.addDisk(
            EX0 + ES * j + ERX * 2 * j, EY0 + ECS * i + ERY * 2 * i, 0, ERX, ERY
        )
        channels.append((2, c))

gmsh.model.occ.cut([(2, hx)], channels, 100)
gmsh.model.occ.synchronize()

# physical groups
gmsh.model.addPhysicalGroup(2, [100], name="all")
left = gmsh.model.getEntitiesInBoundingBox(-eps, -eps, -eps, eps, H + eps, eps, 1)
top = gmsh.model.getEntitiesInBoundingBox(-eps, H - eps, -eps, W + eps, H + eps, eps, 1)
right = gmsh.model.getEntitiesInBoundingBox(
    W - eps, -eps, -eps, W + eps, H + eps, eps, 1
)
bottom = gmsh.model.getEntitiesInBoundingBox(-eps, -eps, -eps, W + eps, eps, eps, 1)
gmsh.model.addPhysicalGroup(1, [id for _, id in left], name="left")
gmsh.model.addPhysicalGroup(1, [id for _, id in top], name="top")
gmsh.model.addPhysicalGroup(1, [id for _, id in right], name="right")
gmsh.model.addPhysicalGroup(1, [id for _, id in bottom], name="bottom")

# mesh size
p = gmsh.model.getEntitiesInBoundingBox(-eps, -eps, -eps, W + eps, H + eps, eps, 0)
gmsh.model.mesh.setSize(p, 4)

# structured mesh
gmsh.model.mesh.setRecombine(2, 100)

gmsh.model.mesh.generate(2)
gmsh.write("2D.msh")
gmsh.finalize()
