#!/usr/bin/env python

import numpy as np
from matplotlib import pyplot as plt
from matplotlib.collections import PatchCollection
import shutil
from pathlib import Path
import gmsh
import json


def calculate_volfrac(props, matrix_density):
    for type, prop in props.items():
        ws = []
        rhos = []
        for fiber, fiber_props in prop.items():
            ws.append(fiber_props["weightfrac"])
            rhos.append(fiber_props["density"])
        ws.append(1 - np.sum(ws))
        ws = np.array(ws)
        rhos.append(matrix_density)
        rhos = np.array(rhos)
        vs = ws / rhos
        vs /= np.sum(vs)
        for i, (fiber, fiber_props) in enumerate(prop.items()):
            fiber_props["volfrac"] = vs[i]


def sample(x, y, props, r=0.8, max_attempt=100000):
    fibers = []
    vfs = []
    ds = []
    for fiber, fiber_props in props.items():
        fibers.append(fiber)
        vfs.append(fiber_props["volfrac"])
        ds.append(fiber_props["diameter"])

    idx = np.argsort(ds)[::-1]
    fibers = np.array(fibers)[idx]
    vfs = np.array(vfs)[idx]
    ds = np.array(ds)[idx]

    dx = x[1] - x[0]
    dy = y[1] - y[0]
    A = dx * dy
    positions = {}
    for i, fiber in enumerate(fibers):
        vf = vfs[i]
        d = ds[i]
        a = np.pi * d**2 / 4
        p0 = np.array([x[0] + d / 2, y[0] + d / 2])
        ps = np.array([dx - d, dy - d])
        p = np.random.rand(1, 2) * ps + p0
        attempt = 0
        while len(p) * a < vf * A and attempt < max_attempt:
            attempt += 1
            pnew = np.random.rand(1, 2) * ps + p0
            collide = False
            for j in range(i):
                dist = np.linalg.norm(positions[fibers[j]] - pnew, axis=-1)
                if np.any(dist <= r * (ds[j] / 2 + d / 2)):
                    collide = True
                    break
            if not collide:
                dist = np.linalg.norm(p - pnew, axis=-1)
                if np.all(dist > r * d):
                    p = np.concatenate([p, pnew])
        positions[fiber] = p
    return positions


def generate_matrix_mesh(outdir, RVE_X, RVE_Y, RVE_Z):
    gmsh.initialize()
    gmsh.option.setNumber("General.Verbosity", 0)

    resin = gmsh.model.occ.addBox(0, 0, 0, RVE_X, RVE_Y, RVE_Z)
    gmsh.model.occ.synchronize()
    edges = gmsh.model.getEntities(1)
    surfs = gmsh.model.getEntities(2)
    vols = gmsh.model.getEntities(3)
    for dim, edge in edges:
        gmsh.model.mesh.setTransfiniteCurve(edge, 11)
    gmsh.model.mesh.setTransfiniteAutomatic(surfs + vols, recombine=True)
    eps = 1e-3
    resin_left = gmsh.model.getEntitiesInBoundingBox(
        -eps, -eps, -eps, eps, RVE_Y + eps, RVE_Z + eps, 2
    )
    resin_right = gmsh.model.getEntitiesInBoundingBox(
        RVE_X - eps, -eps, -eps, RVE_X + eps, RVE_Y + eps, RVE_Z + eps, 2
    )

    gmsh.model.addPhysicalGroup(3, [resin], tag=100, name="resin")
    gmsh.model.addPhysicalGroup(
        2, [tag for _, tag in resin_left], tag=101, name="resin_left"
    )
    gmsh.model.addPhysicalGroup(
        2, [tag for _, tag in resin_right], tag=102, name="resin_right"
    )
    gmsh.model.mesh.generate(3)
    gmsh.write(str(outdir / "matrix.msh"))
    gmsh.finalize()


def generate_fiber_mesh(outdir, RVE_X, RVE_Y, RVE_Z, positions):
    for count, (fiber, pos) in enumerate(positions.items()):
        gmsh.initialize()
        gmsh.option.setNumber("General.Verbosity", 0)

        ltags = []
        pleft = []
        pright = []
        for y, z in pos:
            p1 = gmsh.model.occ.addPoint(RVE_X * 0.02, y, z, 0.25)
            p2 = gmsh.model.occ.addPoint(RVE_X * 0.98, y, z, 0.25)
            l = gmsh.model.occ.addLine(p1, p2)
            ltags.append(l)
            pleft.append(p1)
            pright.append(p2)

        gmsh.model.occ.synchronize()

        gmsh.model.addPhysicalGroup(1, ltags, tag=count + 1, name=fiber)
        gmsh.model.mesh.generate(3)
        gmsh.write(str(outdir / "{}.msh".format(fiber)))
        gmsh.finalize()


if __name__ == "__main__":
    RVE_X = 0.5  # mm
    RVE_Y = 0.1  # mm
    RVE_Z = 0.1  # mm
    nsample = 3

    # Make this reproducible
    np.random.seed(0)

    # Fibers properties
    props_file = Path("props.json")
    if not props_file.exists():
        print("Can't find props.json")
        exit()
    with open(props_file) as f:
        props = json.load(f)

    # Calculate volume fractions
    calculate_volfrac(props, matrix_density=1.26)

    for type, prop in props.items():

        # Base output directory
        basedir = Path("RVE")
        if basedir.exists():
            shutil.rmtree(basedir)
        basedir.mkdir(parents=True)

        for id in range(nsample):
            print("-" * 79)
            print(type, "RVE", id)

            outdir = basedir / str(id)
            outdir.mkdir(parents=True)

            # Matrix mesh
            print("-" * 79)
            print("Generating matrix mesh")
            generate_matrix_mesh(outdir, RVE_X, RVE_Y, RVE_Z)

            # Sample fiber packing
            print("Generating fiber packing...")
            positions = sample((0, RVE_Y), (0, RVE_Z), prop)

            # Checking fiber volfrac
            for fiber, p in positions.items():
                a = np.pi * prop[fiber]["diameter"] ** 2 / 4
                print(
                    "  {} volume fraction: target = {:.3f}, sampled = {:.3f}".format(
                        fiber, prop[fiber]["volfrac"], len(p) * a / RVE_Y / RVE_Z
                    )
                )

            # Write positions
            print("Writing fiber packing...")
            for fiber, p in positions.items():
                np.savetxt(outdir / (fiber + ".txt"), p)

            # Plot sampled fiber packing
            print("Plotting fiber packing...")
            fig, ax = plt.subplots()
            for fiber, p in positions.items():
                ax.scatter(p[:, 0], p[:, 1], label=fiber)
                circles = [
                    plt.Circle((xi, yi), radius=prop[fiber]["diameter"] / 2, fill=False)
                    for xi, yi in p
                ]
                collection = PatchCollection(circles, match_original=True)
                ax.add_collection(collection)
            ax.set(aspect="equal", xlim=[0, 0.1], ylim=[0, 0.1])
            ax.legend()
            fig.savefig(outdir / "packing.png")

            # Generate fiber mesh
            print("Generating fiber mesh...")
            generate_fiber_mesh(outdir, RVE_X, RVE_Y, RVE_Z, positions)
