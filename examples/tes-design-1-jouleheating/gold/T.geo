SetFactory("OpenCASCADE");

// Quarter symmetry is used (and so we only mesh 2 out of 4 coil turns)
// Unit: mm

// Storage medium (graphite foam and PCM)
medium_H = 1000; // height
medium_R = 371.475; // radius

// Heat transfer pipe, DN 20, schedule 10
pipe_H = 1500; // height
pipe_t = 2.11; // thickness
pipe_Ro = 26.7/2; // outer radius
pipe_Ri = pipe_Ro - pipe_t; // inner radius
pipe_Rh = 200; // Hexagon radius for pipe arrangement

// Container, basically a fat pipe
// 30 inch, standard
container_H = medium_H; // height
container_t = 9.525; // thickness

// Insulation
insul_t = 25.4; // thickness

// Total radius
R = medium_R + container_t + insul_t;

// Induction coils
n_coil = 10; // number of coils
coil_R = R + 5; // coil turns radius, assuming a 5 mm gap
coil_w = 50; // coil cross section width
coil_t = 4; // coil cross section thickness
coil_L = 800; // span of n coil turns
coil_S = (coil_L - n_coil * coil_w) / (n_coil - 1);
coil_npts = 20; // number of points along the coil extrusion path

// Control volume (for EM)
air_H = pipe_H; // height
air_R = coil_R + 100; // radius

// Medium + container + insulation
Cylinder(1) = {0, 0, 0, 0, 0, medium_H/2+container_t+insul_t, medium_R+container_t+insul_t, Pi/2};
Cylinder(2) = {0, 0, 0, 0, 0, medium_H/2+container_t, medium_R+container_t, Pi/2};
Cylinder(3) = {0, 0, 0, 0, 0, medium_H/2, medium_R, Pi/2};

// Center pipe
Cylinder(4) = {0, 0, 0, 0, 0, pipe_H/2, pipe_Ro, Pi/2};
Cylinder(5) = {0, 0, 0, 0, 0, pipe_H/2, pipe_Ri, Pi/2};

// Other pipes
Cylinder(6) = {pipe_Rh*Cos(Pi/3), pipe_Rh*Sin(Pi/3), 0, 0, 0, pipe_H/2, pipe_Ro};
Cylinder(7) = {pipe_Rh*Cos(Pi/3), pipe_Rh*Sin(Pi/3), 0, 0, 0, pipe_H/2, pipe_Ri};
Cylinder(8) = {pipe_Rh, 0, 0, 0, 0, pipe_H/2, pipe_Ro, Pi};
Cylinder(9) = {pipe_Rh, 0, 0, 0, 0, pipe_H/2, pipe_Ri, Pi};

v() = BooleanFragments{ Volume{1}; Delete; }{ Volume{2:9}; Delete; };

// Mesh size
MeshSize{ PointsOf{ Volume{1}; } } = 20;
MeshSize{ PointsOf{ Volume{5}; } } = 10;
MeshSize{ PointsOf{ Volume{12}; } } = 25;
MeshSize{ PointsOf{ Volume{2, 3, 4, 7, 9, 11, 14, 16, 18, 22, 24, 26}; } } = 10;

// Groups
Physical Volume("insulation") = {1};
Physical Volume("container") = {5};
Physical Volume("medium") = {12};
Physical Volume("pipe") = {2, 3, 4, 7, 9, 11, 14, 16, 18, 22, 24, 26};
Physical Surface("insulation_outer") = {1, 2};
Physical Surface("pipe_outer") = {85, 93, 97};
Physical Surface("pipe_inner") = {101, 14, 39, 65, 89, 19, 47, 72, 95, 23, 52, 76};
Physical Surface("pipe_end") = {88, 94, 100};
Physical Surface("medium_inner") = {56};
Physical Surface("medium_outer") = {27};
