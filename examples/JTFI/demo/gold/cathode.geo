a = 0.05;
R = 0.01;
e = 0.002;

Point(1) = {0, 0, 0, e};
Point(2) = {0, a, 0, e};
Point(3) = {a, a, 0, e};
Point(4) = {a, 0, 0, e};

Point(5) = {a/2, a/2, 0, e};
Point(6) = {a/2+R, a/2, 0, e};
Point(7) = {a/2, a/2+R, 0, e};
Point(8) = {a/2-R, a/2, 0, e};
Point(9) = {a/2, a/2-R, 0, e};

Line(1) = {1, 2};
Line(2) = {2, 3};
Line(3) = {3, 4};
Line(4) = {4, 1};

Circle(5) = {6, 5, 7};
Circle(6) = {7, 5, 8};
Circle(7) = {8, 5, 9};
Circle(8) = {9, 5, 6};

Line Loop(1) = {1, 2, 3, 4};
Line Loop(2) = {5, 6, 7, 8};

Plane Surface(1) = {1, 2};
Plane Surface(2) = {2};

Physical Line("left") = {1};
Physical Line("right") = {3};
Physical Line("top") = {2};
Physical Line("bottom") = {4};
Physical Surface("SSE") = {1};
Physical Surface("CAM") = {2};
