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
// container_t = 9.525; // thickness
container_t = 4.7625; // thickness

// Insulation
insul_t = 25.4; // thickness

// Total radius
R = medium_R + container_t + insul_t;

// Induction coils
n_coil = 10; // number of coils
coil_R = R + 5; // coil turns radius, assuming a 5 mm gap
coil_w = 50; // coil cross section width
coil_t = 4; // coil cross section thickness
coil_L = 1050; // span of n coil turns
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

// Induction coils
For i In {1:n_coil/2}
  p = i*1000;
  s = news;
  coil_z = (coil_S+coil_w)*i-coil_S/2-coil_w/2;
  Point(p) = {0, 0, coil_z};
  Point(p+1) = {coil_R, 0, coil_z};
  Point(p+2) = {0, coil_R, coil_z};
  Circle(p) = {p+1, p, p+2};
  Wire(p) = {p};
  Rectangle(s) = {coil_R-coil_t/2, 0, coil_z-coil_w/2, coil_t, coil_w};
  Rotate{ {1, 0, 0}, {coil_R-coil_t/2, 0, coil_z-coil_w/2}, Pi/2 } { Surface{s}; }
  Extrude { Surface{s}; } Using Wire {p}
  Delete{ Surface{s}; }
EndFor

// Air
Cylinder(100) = {0, 0, 0, 0, 0, air_H/2, air_R, Pi/2};

// Fragments
v() = BooleanFragments{ Volume{100}; Delete; }{ Volume{1:32}; Delete; };

// Mesh size
MeshSize{ PointsOf{ Volume{33}; }} = 100;
MeshSize{ PointsOf{ Volume{6, 8, 10, 13, 15, 17, 19, 20, 21, 23, 25, 27}; }} = 50;
MeshSize{ PointsOf{ Volume{1}; } } = 20;
MeshSize{ PointsOf{ Volume{5}; } } = 10;
MeshSize{ PointsOf{ Volume{12}; } } = 25;
MeshSize{ PointsOf{ Volume{2, 3, 4, 7, 9, 11, 14, 16, 18, 22, 24, 26}; } } = 10;
MeshSize{ PointsOf{ Volume{28:32}; } } = 20;

// Groups
Physical Volume("air") = {6, 8, 10, 13, 15, 17, 19, 20, 21, 23, 25, 27, 33};
Physical Volume("coils") = {28:32};
Physical Volume("insulation") = {1};
Physical Volume("container") = {5};
Physical Volume("medium") = {12};
Physical Volume("pipe") = {2, 3, 4, 7, 9, 11, 14, 16, 18, 22, 24, 26};
