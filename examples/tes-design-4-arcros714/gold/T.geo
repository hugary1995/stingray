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

// Medium + container + insulation
Cylinder(1) = {0, 0, 0, 0, 0, container_H/2+container_t+insul_t, R, Pi/2};
Cylinder(2) = {0, 0, 0, 0, 0, container_H/2+container_t, medium_R+container_t, Pi/2};
Cylinder(3) = {0, 0, 0, 0, 0, container_H/2, medium_R, Pi/2};
Cylinder(4) = {0, 0, 0, 0, 0, medium_H/2, medium_R, Pi/2};
v() = BooleanFragments{ Volume{1}; Delete; }{ Volume{2:4}; Delete; };

// Mesh size
MeshSize{ PointsOf{ Volume{5}; } } = 10;
MeshSize{ PointsOf{ Volume{4}; } } = 4;
MeshSize{ PointsOf{ Volume{6}; } } = 4;

// Groups
Physical Volume("insulation") = {5};
Physical Volume("container") = {6};
Physical Volume("medium") = {4};
Physical Surface("insulation_outer") = {1};
