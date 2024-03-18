SetFactory("OpenCASCADE");

// Quarter symmetry is used (and so we only mesh 2 out of 4 coil turns)
// Unit: mm

susceptor_L = 295; // susceptor length
susceptor_W = 25.4; // susceptor width
susceptor_H = 25; // susceptor height

crucible_L = 160; // crucible length
crucible_W = 40; // crucible width
crucible_H = 15; // crucible height
crucible_t1 = 4; // crucible thickness
crucible_t2 = 6; // crucible thickness

n_coil = 4; // number of coils
coil_R = 70; // coil turns radius
coil_w = 25; // coil cross section width
coil_t = 3; // coil cross section thickness
coil_L = 180; // span of n coil turns
coil_S = (coil_L - n_coil * coil_w) / (n_coil - 1);
coil_z = 50; // coil shift in the z direction
coil_npts = 20; // number of points along the coil extrusion path

air_L = 360; // length of the control volume, should be larger than all the components
air_W = 180; // length of the control volume, should be larger than all the components
air_H = 180; // length of the control volume, should be larger than all the components

e_susceptor = 10;
e_crucible = 4;
e_coil = 5;
e_air = 50;

// The graphite susceptor
Box(1) = {0, 0, 0, susceptor_L/2, susceptor_W/2, susceptor_H};

// The 1st graphite crucible
Box(2) = {0, 0, susceptor_H, crucible_L/2, crucible_W/2, crucible_H};
Box(3) = {0, 0, susceptor_H+crucible_t1, crucible_L/2-crucible_t2, crucible_W/2-crucible_t1, crucible_H-crucible_t1};
BooleanDifference(4) = { Volume{2}; Delete; }{ Volume{3}; Delete; };

// The 2nd graphite crucible
Box(5) = {0, 0, susceptor_H+crucible_H, crucible_L/2, crucible_W/2, crucible_H};
Box(6) = {0, 0, susceptor_H+crucible_H+crucible_t1, crucible_L/2-crucible_t2, crucible_W/2-crucible_t1, crucible_H-crucible_t1};
BooleanDifference(7) = { Volume{5}; Delete; }{ Volume{6}; Delete; };

// The 1st coil loop
p = 1000;
s1 = news;
coil_x = coil_S/2+coil_w/2;
Point(p) = {coil_x, 0, coil_z};
Point(p+1) = {coil_x, 0, -coil_R+coil_z};
Point(p+2) = {coil_x, coil_R, coil_z};
Point(p+3) = {coil_x, 0, coil_R+coil_z};
Circle(p) = {p+1, p, p+2};
Circle(p+1) = {p+2, p, p+3};
Wire(p) = {p, p+1};
Rectangle(s1) = {coil_x-coil_w/2, 0, -coil_R+coil_z-coil_t/2, coil_w, coil_t};
Rotate{ {1, 0, 0}, {coil_x-coil_w/2, 0, -coil_R+coil_z-coil_t/2}, Pi/2 } { Surface{s1}; }
Extrude { Surface{s1}; } Using Wire {p}
Delete{ Surface{s1}; }

// The 2nd coil loop
p = 2000;
s2 = news;
coil_x = coil_S/2+coil_w+coil_S+coil_w/2;
Point(p) = {coil_x, 0, coil_z};
Point(p+1) = {coil_x, 0, -coil_R+coil_z};
Point(p+2) = {coil_x, coil_R, coil_z};
Point(p+3) = {coil_x, 0, coil_R+coil_z};
Circle(p) = {p+1, p, p+2};
Circle(p+1) = {p+2, p, p+3};
Wire(p) = {p, p+1};
Rectangle(s2) = {coil_x-coil_w/2, 0, -coil_R+coil_z-coil_t/2, coil_w, coil_t};
Rotate{ {1, 0, 0}, {coil_x-coil_w/2, 0, -coil_R+coil_z-coil_t/2}, Pi/2 } { Surface{s2}; }
Extrude { Surface{s2}; } Using Wire {p}
Delete{ Surface{s2}; }

// Air
Box(10) = {0, 0, coil_z-air_H/2, air_L/2, air_W/2, air_H};

// Fragment everything
v() = BooleanFragments{ Volume{10}; Delete; }{ Volume{1, 4, 7, 8, 9}; Delete; };

// // Mesh size
MeshSize{ PointsOf{ Volume{10, 11}; } } = e_air;
MeshSize{ PointsOf{ Volume{1}; } } = e_susceptor;
MeshSize{ PointsOf{ Volume{4, 7}; } } = e_crucible;
MeshSize{ PointsOf{ Volume{8, 9}; } } = e_coil;

// Groups
Physical Volume("air") = {10, 11};
Physical Volume("susceptor") = {1};
Physical Volume("crucible") = {4, 7};
Physical Volume("coil") = {8, 9};
