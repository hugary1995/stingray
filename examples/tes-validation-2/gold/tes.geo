SetFactory("OpenCASCADE");

// Axisymmetry, unit: inch
pipe_t = 0.028;
pipe_Ri = 0.444/2;
pipe_Ro = pipe_Ri+pipe_t;
pipe_H = 1.25+6.3125+1.25;
insul_t = 0.5;
container_y = 1.25;
container_H = 6.3125;
container_Ro = 4.5/2;
container_t = container_Ro-pipe_Ri-pipe_t;
top_t = 3/16;
bottom_t = 1/4;
medium_R = 3.8064/2;
medium_H = 5;

// HT pipe
Rectangle(1) = {0, 0, 0, pipe_Ri, pipe_H, 0};
Rectangle(2) = {pipe_Ri, 0, 0, pipe_t, pipe_H, 0};

// Insulation
Rectangle(3) = {pipe_Ro, 0, 0, insul_t, pipe_H, 0};
Rectangle(4) = {pipe_Ro+insul_t, container_y-insul_t, 0, container_t, container_H+insul_t*2, 0};

// Container
Rectangle(5) = {pipe_Ro, container_y, 0, container_t, container_H, 0};
Rectangle(6) = {pipe_Ro, container_y+bottom_t, 0, medium_R, container_H-top_t-bottom_t, 0};

// Medium
Rectangle(7) = {pipe_Ro, container_y+bottom_t, 0, medium_R, medium_H, 0};

// Fragments
s() = BooleanFragments{ Surface{1}; Delete; }{ Surface{2:7}; Delete; };

// Mesh size
MeshSize{ PointsOf{ Surface{:}; }} = 0.2;

// // Groups
Physical Surface("fluid") = {1};
Physical Surface("pipe") = {2};
Physical Surface("insulation") = {3, 8, 9};
Physical Surface("container") = {4, 7, 10};
Physical Surface("medium") = {5, 11};
Physical Surface("air") = {6, 12};
Physical Line("wall") = {34};
Physical Line("inlet") = {33};
Physical Line("outlet") = {35};
Physical Line("insulation_outer") = {20, 25, 26, 27, 4};
