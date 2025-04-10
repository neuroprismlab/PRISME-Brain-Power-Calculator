% Test script to compare the two TFCE implementations
% Creates a simple symmetric matrix and runs both implementations

% Create a test matrix (symmetric connectivity matrix)
n = 10; % 10x10 matrix
img = zeros(n, n);

% Create a pattern with values between 0-6
% We'll make a few clusters with different values
% Cluster 1: A stronger cluster (values around 4-5)
img(1:3, 1:3) = 4.5;
% Cluster 2: A medium strength cluster (values around 2-3)
img(5:7, 5:7) = 2.8;
% Cluster 3: A weaker but larger cluster (values around 1-2)
img(8:10, 8:10) = 1.5;

% Add connections between clusters with varying strengths
% Connect cluster 1 and 2
img(3, 5) = 3.2;
img(5, 3) = 3.2;
img(2, 5) = 2.5;
img(5, 2) = 2.5;
img(3, 6) = 1.8;
img(6, 3) = 1.8;

% Connect cluster 2 and 3
img(7, 8) = 2.1;
img(8, 7) = 2.1;
img(6, 8) = 1.9;
img(8, 6) = 1.9;
img(7, 9) = 1.6;
img(9, 7) = 1.6;

% Add some long-range connections
img(1, 8) = 0.8;
img(8, 1) = 0.8;
img(2, 9) = 0.7;
img(9, 2) = 0.7;
img(3, 10) = 0.6;
img(10, 3) = 0.6;

% Add some middle-strength scattered connections
img(1, 5) = 2.3;
img(5, 1) = 2.3;
img(4, 7) = 1.7;
img(7, 4) = 1.7;
img(4, 9) = 1.1;
img(9, 4) = 1.1;
img(2, 6) = 2.0;
img(6, 2) = 2.0;
img(4, 10) = 0.9;
img(10, 4) = 0.9;

% Make sure it's symmetric (though we've been careful to do this)
img = (img + img')/2;

% Set diagonal to zero (no self-connections)
img(logical(eye(n))) = 0;

% Display the input matrix
disp('Input Matrix:');
disp(img);

% Run the first implementation
disp('Running apply_tfce...');
tic;
tfced1 = apply_tfce(img);
t1 = toc;
disp(['apply_tfce took ', num2str(t1), ' seconds']);

% Run the second implementation
disp('Running matlab_tfce_transform...');
tic;
[tfced2, comps, comp_sizes] = matlab_tfce_transform(img, 'matrix');
t2 = toc;
disp(['matlab_tfce_transform took ', num2str(t2), ' seconds']);

% Compare results
disp('Comparison of results:');
disp(['Mean absolute difference: ', num2str(mean(abs(tfced1(:) - tfced2(:))))]);
disp(['Maximum absolute difference: ', num2str(max(abs(tfced1(:) - tfced2(:))))]);
disp(['Correlation between outputs: ', num2str(corr(tfced1(:), tfced2(:)))]);

% Visualize differences
figure;
subplot(2,2,1);
imagesc(img);
title('Input Matrix');
colorbar;

subplot(2,2,2);
imagesc(tfced1);
title('apply\_tfce output');
colorbar;

subplot(2,2,3);
imagesc(tfced2);
title('matlab\_tfce\_transform output');
colorbar;

subplot(2,2,4);
imagesc(abs(tfced1 - tfced2));
title('Absolute Difference');
colorbar;

% Fix for the issue in matlab_tfce_transform where it tries to compare 'fast_th' with 'threshs'
% This function creates a modified version of matlab_tfce_transform
function create_fixed_tfce_function()
    % Read the original function
    fid = fopen('paste-2.txt', 'r');
    content = fread(fid, '*char')';
    fclose(fid);
    
    % Remove the problematic comparison
    new_content = strrep(content, ...
        ['% Compare the arrays\nif isequal(fast_th, threshs)\n    disp(''The arrays are the same.'');\nelse\n    ' ...
        'disp(''The arrays are different.'');\nend\n\n'], '');
    
    % Write the fixed function
    fid = fopen('fixed_matlab_tfce_transform.m', 'w');
    fprintf(fid, '%s', new_content);
    fclose(fid);
    
    disp('Created fixed_matlab_tfce_transform.m with the comparison removed');
end

% Note: Before running this script, ensure that:
% 1. You h