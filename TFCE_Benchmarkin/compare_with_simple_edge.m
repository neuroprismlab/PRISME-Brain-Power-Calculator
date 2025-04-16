% Test script to compare the two TFCE implementations
% Creates a simple symmetric matrix with sequential values for easy debugging
% Each edge will have a unique value incrementing by 0.1

% Create a test matrix (symmetric connectivity matrix)
n = 4; % 5x5 matrix
img = zeros(n, n);

% Create values with exact 0.10 increments - starting at 0.1 and going up
% This makes it extremely easy to track which edges are included at each threshold

% Fill the upper triangular part of the matrix with sequential values
counter = 0.1;
for i = 1:n
    for j = (i+1):n
        img(i,j) = counter;
        counter = counter + 0.1;
    end
end

% Make it symmetric
img = img + img';

% Display the input matrix
%disp('Input Matrix:');
%disp(img);

tfced1 = apply_tfce(img); % Explicitly set dh=0.10

% Run the second implementation
[tfced2, comps, comp_sizes] = matlab_tfce_transform(img, 'matrix'); % Explicitly set dh=0.10

% Compare results
disp('Comparison of results:');
disp(['Mean absolute difference: ', num2str(mean(abs(tfced1(:) - tfced2(:))))]);
disp(['Maximum absolute difference: ', num2str(max(abs(tfced1(:) - tfced2(:))))]);
disp(['Correlation between outputs: ', num2str(corr(tfced1(:), tfced2(:)))]);

% Test thresholds to verify which edges exist at each threshold
disp('Verifying threshold behavior:');
test_thresholds = [0.05, 0.15, 0.25, 0.35, 0.45, 0.55, 0.65, 0.75, 0.85, 0.95];
for i = 1:length(test_thresholds)
    th = test_thresholds(i);
    edges_above = (img > th) & ~eye(n);
    num_edges = sum(sum(edges_above))/2; % Divide by 2 due to symmetry
    
    % Show which edges are above the threshold
    [row, col] = find(triu(edges_above)); % Only upper triangle to avoid duplicates
    edge_list = '';
    for e = 1:length(row)
        edge_list = [edge_list, sprintf('(%d,%d)=%.1f ', row(e), col(e), img(row(e),col(e)))];
    end
    
    disp(['Threshold ', num2str(th), ': ', num2str(num_edges), ' edges: ', edge_list]);
end

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