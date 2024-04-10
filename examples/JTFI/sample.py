#!/usr/bin/env python

import numpy as np
import torch
from matplotlib import pyplot as plt
from matplotlib.collections import PatchCollection
import shutil
from pathlib import Path
import json
import pandas as pd


def calculate_volfrac(props, porosity):
    for type, prop in props.items():
        ws = []
        rhos = []
        for comp, comp_props in prop.items():
            ws.append(comp_props["weightfrac"])
            rhos.append(comp_props["density"])
        ws = np.array(ws)
        rhos = np.array(rhos)
        vs = ws / rhos
        vs /= np.sum(vs) / (1 - porosity)
        for i, (comp, comp_props) in enumerate(prop.items()):
            comp_props["volfrac"] = vs[i]


def particle_distance(x, RVEx, RVEy):
    N = x.shape[0]
    dx = x.reshape((N, 1, 2)) - x.reshape((1, N, 2))
    dx = dx.reshape(N * N, 2)
    dxp = torch.empty_like(dx)
    xp = torch.abs(dx[:, 0]) > RVEx
    yp = torch.abs(dx[:, 1]) > RVEy
    dxp[~xp, 0] = dx[~xp, 0]
    dxp[xp, 0] = RVEx - torch.abs(dx[xp, 0])
    dxp[~yp, 1] = dx[~yp, 1]
    dxp[yp, 1] = RVEy - torch.abs(dx[yp, 1])
    dxp = dxp.reshape(N, N, 2)
    dxn = torch.linalg.norm(dxp, dim=-1)
    return dxn


def packing_potential(x, d, rho, RVEx, RVEy, k, m, F, g):
    x = x.detach().clone().requires_grad_(True)

    N = x.shape[0]
    mm = m.reshape((N, 1)) * m.reshape((1, N))

    dxn = particle_distance(x, RVEx, RVEy)
    dxc = (d.reshape((N, 1)) + d.reshape((1, N))) / 2
    tau = (dxn - dxc) / dxc
    phi_collision = F * torch.sum(torch.triu(torch.exp(-mm * k * tau), 1))
    phi_gravity = torch.sum(rho * g * x[:, 0])

    phi = phi_collision + phi_gravity
    phi.backward()

    return phi.detach(), phi_collision.detach(), x.grad


def move_periodic(x, p, RVEx, RVEy):
    xn = x + p

    left = xn[:, 0] < 0
    right = xn[:, 0] > RVEx
    bottom = xn[:, 1] < 0
    top = xn[:, 1] > RVEy

    xn[left, 0] = xn[left, 0] + torch.ceil(-xn[left, 0] / RVEx) * RVEx
    xn[right, 0] = xn[right, 0] - torch.ceil((xn[right, 0] - RVEx) / RVEx) * RVEx
    xn[bottom, 1] = xn[bottom, 1] + torch.ceil(-xn[bottom, 1] / RVEy) * RVEy
    xn[top, 1] = xn[top, 1] - torch.ceil((xn[top, 1] - RVEy) / RVEy) * RVEy

    return xn


def should_accept(phin, phi, beta):
    dphi = phin - phi
    thres = torch.tensor(1.0) if dphi < 0 else np.exp(-beta * (phin - phi))
    v = torch.rand(1)
    return v < thres, thres


def particle_gap(x, RVEx, RVEy, d):
    N = x.shape[0]
    dxn = particle_distance(x, RVEx, RVEy)
    dxn += torch.eye(N) * 1e6
    dxc = (d.reshape((N, 1)) + d.reshape((1, N))) / 2
    dxg = dxn - dxc
    dxr = dxg / dxc
    ij = torch.argmin(dxr, dim=-1)
    return dxg, dxr, ij


def smooth_packing(x, RVEx, RVEy, d, cluster, p=0.01, mit=20):
    d0 = d.clone()
    N = x.shape[0]

    itr = 0
    ind = np.arange(N - 1)
    np.random.shuffle(ind)
    while True:
        itr += 1
        dxg, dxr, ij = particle_gap(x, RVEx, RVEy, d)
        niso = 0
        npen = 0
        for i in ind:
            j = ij[i]
            gap = dxr[i, j]
            if gap > 0:
                niso += 1
            else:
                npen += 1
        print("{} isolated particles, {} penetrated particles".format(niso, npen))

        for i in ind:
            j = ij[i]
            gap = dxr[i, j]
            if gap > 0:
                d[i] *= 1 + p
            elif cluster[i] == cluster[j]:
                d[i] /= 1 + p

        rel = np.linalg.norm(d - d0) / np.linalg.norm(d0)
        print("Diameter relative change {:.2%}".format(rel))
        print("-" * 79)
        if itr > mit:
            break
        if rel < 1e-3:
            break
        else:
            d0 = d.clone()

    # Final pass
    dxg, dxr, ij = particle_gap(x, RVEx, RVEy, d)
    for i in ind:
        j = ij[i]
        gap = dxg[i, j]
        ri = d[i] / 2
        if gap > 0:
            d[i] *= (ri + gap) / ri * (1 + p)

    dxg, dxr, ij = particle_gap(x, RVEx, RVEy, d)
    keep = torch.full((N,), True)
    niso = 0
    npen = 0
    for i in ind:
        j = ij[i]
        gap = dxg[i, j]
        ri = d[i] / 2
        if gap > 0:
            niso += 1
        else:
            npen += 1
        if ri + gap < 0:
            keep[i] = False
    print(
        "After final pass, {} isolated particles, {} penetrated particles, {} removed particles".format(
            niso, npen, torch.sum(~keep).item()
        )
    )

    return d, keep


def sample(
    RVEx,
    RVEy,
    props,
    deltas=[(1e-6, 1000), (1e-7, 500), (1e-8, 50)],
    beta=0.05,
    k=10,
    F=0.001,
    g=9810,
):
    # Area
    A = RVEx * RVEy

    # NMC particles
    vf1 = props["NMC"]["volfrac"]
    d1 = props["NMC"]["diameter"]
    rho1 = props["NMC"]["density"]
    A1 = np.pi * d1**2 / 4
    N1 = int(A * vf1 / A1)
    m1 = 1.2

    # LPSCI particles
    vf2 = props["LPSCI"]["volfrac"]
    d2 = props["LPSCI"]["diameter"]
    rho2 = props["NMC"]["density"]
    A2 = np.pi * d2**2 / 4
    N2 = int(A * vf2 / A2)
    m2 = 0.8

    x = torch.rand(N1 + N2, 2) * torch.tensor([RVEx, RVEy])
    d = torch.cat([torch.full((N1, 1), d1), torch.full((N2, 1), d2)])
    rho = torch.cat([torch.full((N1, 1), rho1), torch.full((N2, 1), rho2)])
    m = torch.cat([torch.full((N1, 1), m1), torch.full((N2, 1), m2)])

    plot_packing(
        ["LPSCI", "NMC"],
        [x[N1:], x[:N1]],
        [d[N1:], d[:N1]],
        ["r", "b"],
        ["none", "none"],
        [1, 0.8],
        RVEx,
        RVEy,
        "before.png".format(k),
    )

    phi, phic, dphi = packing_potential(x, d, rho, RVEx, RVEy, k, m, F, g)
    x_best = x.clone()
    phi_best = phi.clone()
    for delta, niter in deltas:
        print("delta = {:.2E}".format(delta))
        x = x_best.clone()
        for i in range(niter):
            p = -dphi * torch.rand(1) * delta
            xn = move_periodic(x, p, RVEx, RVEy)
            phin, phic, dphin = packing_potential(xn, d, rho, RVEx, RVEy, k, m, F, g)
            accept, thres = should_accept(phin, phi, beta)
            if accept:
                x = xn
                phi = phin
                dphi = dphin

                if phi < phi_best:
                    x_best = x.clone()
                    phi_best = phi.clone()

                print(
                    "{}, potential (best) = {:.3f} ({:.3f}), collision potential fraction = {:.2%} accepted with probability of {:.2%}".format(
                        i,
                        phi.item(),
                        phi_best.item(),
                        (phic / phi).item(),
                        thres.item(),
                    )
                )

    plot_packing(
        ["LPSCI", "NMC"],
        [x_best[N1:], x_best[:N1]],
        [d[N1:], d[:N1]],
        ["r", "b"],
        ["none", "none"],
        [1, 0.8],
        RVEx,
        RVEy,
        "k={}.png".format(k),
    )

    cluster = torch.full((N1 + N2,), 0, dtype=torch.int64)
    cluster[N1:] += 1
    d, keep = smooth_packing(x, RVEx, RVEy, d, cluster)

    plot_packing(
        ["LPSCI", "NMC"],
        [x_best[N1:][keep[N1:]], x_best[:N1][keep[:N1]]],
        [d[N1:][keep[N1:]], d[:N1][keep[:N1]]],
        ["r", "b"],
        ["none", "none"],
        [1, 0.8],
        RVEx,
        RVEy,
        "k={}_smooth.png".format(k),
    )

    return {"LPSCI": x_best[N1:][keep[N1:]], "NMC": x_best[:N1][keep[:N1]]}, {
        "LPSCI": d[N1:][keep[N1:]].squeeze(),
        "NMC": d[:N1][keep[:N1]].squeeze(),
    }


def plot_packing(comps, positions, diameters, fcs, ecs, alphas, x, y, ofile):
    fig, ax = plt.subplots()
    for comp, p, d, fc, ec, alpha in zip(comps, positions, diameters, fcs, ecs, alphas):
        circles = [
            plt.Circle((xi, yi), radius=di / 2, fill=False)
            for (xi, yi), di in zip(p, d)
        ]
        circles_left = [
            plt.Circle((xi - x, yi), radius=di / 2, fill=False)
            for (xi, yi), di in zip(p, d)
        ]
        circles_right = [
            plt.Circle((xi + x, yi), radius=di / 2, fill=False)
            for (xi, yi), di in zip(p, d)
        ]
        circles_bottom = [
            plt.Circle((xi, yi - y), radius=di / 2, fill=False)
            for (xi, yi), di in zip(p, d)
        ]
        circles_top = [
            plt.Circle((xi, yi + y), radius=di / 2, fill=False)
            for (xi, yi), di in zip(p, d)
        ]
        collection = PatchCollection(
            circles + circles_left + circles_right + circles_bottom + circles_top,
            match_original=True,
            facecolor=fc,
            edgecolor=ec,
            alpha=alpha,
        )
        ax.add_collection(collection)
    ax.set(aspect="equal", xlim=[0, x], ylim=[0, y])
    fig.savefig(ofile)
    plt.close()


if __name__ == "__main__":
    RVE_X = 0.05  # mm
    RVE_Y = 0.05  # mm
    nsample = 1

    # Make this reproducible
    torch.manual_seed(0)

    # Fibers properties
    props_file = Path("props.json")
    if not props_file.exists():
        print("Can't find props.json")
        exit()
    with open(props_file) as f:
        props = json.load(f)

    # Calculate volume fractions
    calculate_volfrac(props, porosity=0.1)

    print(props)

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

            # Sample particle packing
            print("Generating packing...")
            position, diameter = sample(RVE_X, RVE_Y, prop)

            NMC = pd.DataFrame(
                {
                    "x": position["NMC"][:, 0],
                    "y": position["NMC"][:, 1],
                    "d": diameter["NMC"],
                }
            )
            LPSCI = pd.DataFrame(
                {
                    "x": position["LPSCI"][:, 0],
                    "y": position["LPSCI"][:, 1],
                    "d": diameter["LPSCI"],
                }
            )
            NMC.to_csv(outdir / "NMC.csv", index=False)
            LPSCI.to_csv(outdir / "LPSCI.csv", index=False)
