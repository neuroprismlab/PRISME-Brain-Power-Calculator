function [obs, perms, p_size, p_tfce] = size_cpp_test_data()
%% size_cpp_test_data
% 5-node test data for Size_cpp. Statistics are written as upper triangles
% and symmetrized at the end. The test uses a first-level threshold of 3.1
% (strict >).
%
% Observed matrix: two components above threshold
%   A = {1,2,3}, triangle (1,2),(1,3),(2,3)  -> size 3
%   B = {4,5},   single edge (4,5)           -> size 1
%   (3,4) = 3.1 is exactly at threshold      -> NOT significant
%   (2,5) = -4.5 is strongly negative        -> NOT significant
%
% Permutations: maximum component size (number of edges) per permutation
%   k:    1  2  3  4  5  6  7  8  9  10
%   max:  1  1  2  1  3  3  4  4  10  3
% (a permutation with no suprathreshold edge counts as size 1 in the C++ code)

% p values if size method is applied to this data + permutations
p_size = [0.6; 0.6; 0.6; 1; 1; 1; 1; 1; 1; 1];
% p values if the tfce method is applied to this data + permutations
p_tfce = [0.4; 0.1; 0.3; 0.9; 0.9; 0.8; 1; 1; 0.9; 0.1];

obs_u = [0 3.5 4.0 2.0  0;
         0 0   3.8 2.5 -4.5;
         0 0   0   3.1  2.2;
         0 0   0   0    4.2;
         0 0   0   0    0];

perm_u = zeros(5, 5, 10);

% 1: no suprathreshold edge (all strongly negative) -> 1
perm_u(:,:,1) = [0 -4 -4 -4 -4;
                 0  0 -4 -4 -4;
                 0  0  0 -4 -4;
                 0  0  0  0 -4;
                 0  0  0  0  0];

% 2: one edge (2,4) -> 1
perm_u(:,:,2) = [0 1 1 1   1;
                 0 0 1 3.6 1;
                 0 0 0 1   1;
                 0 0 0 0   1;
                 0 0 0 0   0];

% 3: path (1,2),(2,3) -> 2
perm_u(:,:,3) = [0 3.5 0   0 0;
                 0 0   3.5 0 0;
                 0 0   0   0 0;
                 0 0   0   0 0;
                 0 0   0   0 0];

% 4: two disjoint edges (1,2),(3,4); (2,3) = 3.1 is at threshold, not
%    significant, so the edges do not join -> 1
perm_u(:,:,4) = [0 3.5 0   0   0;
                 0 0   3.1 0   0;
                 0 0   0   3.6 0;
                 0 0   0   0   0;
                 0 0   0   0   0];

% 5: path (2,3),(3,4),(4,5) -> 3
perm_u(:,:,5) = [0 0 0   0   0;
                 0 0 3.4 0   0;
                 0 0 0   3.4 0;
                 0 0 0   0   3.4;
                 0 0 0   0   0];

% 6: triangle (1,2),(1,3),(2,3) -> 3
perm_u(:,:,6) = [0 3.7 3.7 0 0;
                 0 0   3.7 0 0;
                 0 0   0   0 0;
                 0 0   0   0 0;
                 0 0   0   0 0];

% 7: path (1,2),(2,3),(3,4),(4,5) -> 4
perm_u(:,:,7) = [0 3.5 0   0   0;
                 0 0   3.5 0   0;
                 0 0   0   3.5 0;
                 0 0   0   0   3.5;
                 0 0   0   0   0];

% 8: (1,2),(1,3),(2,3),(2,4) -> 4
perm_u(:,:,8) = [0 3.8 3.8 0   0;
                 0 0   3.8 3.8 0;
                 0 0   0   0   0;
                 0 0   0   0   0;
                 0 0   0   0   0];

% 9: all 10 edges -> 10
perm_u(:,:,9) = [0 4 4 4 4;
                 0 0 4 4 4;
                 0 0 0 4 4;
                 0 0 0 0 4;
                 0 0 0 0 0];

% 10: triangle {1,3,4} plus separate edge (2,5) -> 3
perm_u(:,:,10) = [0 0 3.9 3.9 0;
                  0 0 0   0   3.9;
                  0 0 0   3.9 0;
                  0 0 0   0   0;
                  0 0 0   0   0];

obs   = obs_u + obs_u';
perms = perm_u + permute(perm_u, [2 1 3]);

end