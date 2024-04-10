#!/usr/bin/env python

import shutil
from pathlib import Path
import gmsh


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
