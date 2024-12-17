SetFactory("OpenCASCADE");

// Quarter symmetry is used
// Unit: mm

// Storage medium (graphite foam and PCM)
medium_H = 5*25.4; // height
medium_R = (4.5/2-0.34)*25.4; // radius

// Container, basically a fat pipe
// 30 inch, standard
container_H = 6*25.4; // height
container_t = 0.34*25.4; // thickness

// Insulation
insul_t = 0.5*25.4; // thickness

// Total radius
R = medium_R + container_t + insul_t;

// Induction coils
n_coil = 6; // number of coils
coil_R = R + 10; // coil turns radius, assuming a 5 mm gap
coil_w = 25; // coil cross section width
coil_t = 8; // coil cross section thickness
coil_L = 8*25.4; // span of n coil turns
coil_S = (coil_L - n_coil * coil_w) / (n_coil - 1);
coil_npts = 20; // number of points along the coil extrusion path

// Control volume (for EM)
air_H = 10*25.4; // height
air_R = coil_R + 50; // radius

// Medium + container + insulation
Cylinder(1) = {0, 0, 0, 0, 0, container_H/2+container_t+insul_t, R, Pi/2};
Cylinder(2) = {0, 0, 0, 0, 0, container_H/2+container_t, medium_R+container_t, Pi/2};
Cylinder(3) = {0, 0, 0, 0, 0, container_H/2, medium_R, Pi/2};
Cylinder(4) = {0, 0, 0, 0, 0, medium_H/2, medium_R, Pi/2};
v() = BooleanFragments{ Volume{1}; Delete; }{ Volume{2:4}; Delete; };

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
v() = BooleanFragments{ Volume{100}; Delete; }{ Volume{4:10}; Delete; };

// Mesh size
MeshSize{ PointsOf{ Volume{7, 11}; }} = 30;
MeshSize{ PointsOf{ Volume{4}; } } = 20;
MeshSize{ PointsOf{ Volume{5}; } } = 10;
MeshSize{ PointsOf{ Volume{8:10}; }} = 5;
MeshSize{ PointsOf{ Volume{6}; } } = 4;

// // Groups
Physical Volume("air") = {7, 11};
Physical Volume("coils") = {8:10};
Physical Volume("insulation") = {5};
Physical Volume("container") = {6};
Physical Volume("medium") = {4};
