#!/usr/bin/env python

import gmsh


if __name__ == "__main__":
    gmsh.initialize()
    elyte = gmsh.model.occ.addRectangle(0, 0, 0, 50, 50)
    cam = gmsh.model.occ.addDisk(30, 25, 0, 10, 10)
    gmsh.model.occ.cut([(2, elyte)], [(2, cam)])
    gmsh.model.occ.synchronize()
    edges = gmsh.model.getEntities(1)
    surfs = gmsh.model.getEntities(2)
    gmsh.model.mesh.setSize(gmsh.model.getEntities(0), 1)
    gmsh.model.mesh.generate(2)
    gmsh.write("elyte.msh")
    gmsh.finalize()

    gmsh.initialize()
    elyte = gmsh.model.occ.addRectangle(0, 0, 0, 50, 50)
    cam = gmsh.model.occ.addDisk(30, 25, 0, 10, 10)
    gmsh.model.occ.fragment([(2, elyte)], [(2, cam)])
    gmsh.model.occ.synchronize()
    gmsh.model.addPhysicalGroup(2, [2], tag=100, name="cam")
    gmsh.model.addPhysicalGroup(2, [3], tag=200, name="elyte")
    edges = gmsh.model.getEntities(1)
    surfs = gmsh.model.getEntities(2)
    gmsh.model.mesh.setSize(gmsh.model.getEntities(0), 1)
    gmsh.model.mesh.generate(2)
    gmsh.write("cell.msh")
    gmsh.finalize()
