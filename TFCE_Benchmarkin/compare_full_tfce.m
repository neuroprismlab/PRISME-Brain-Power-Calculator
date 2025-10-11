% Test script to compare the two TFCE implementations
% Creates a simple symmetric matrix with sequential values for easy debugging
% Each edge will have a unique value incrementing by 0.1

% Create a test matrix (symmetric connectivity matrix)
n = 268; % Full connectivity matrix for 268 ROIs (35,778 edges)
img = zeros(n, n);

% Create random functional connectivity values between -1 and 1
% Fill the upper triangular part of the matrix with random FC values
for i = 1:n
    for j = (i+1):n
        img(i,j) = (rand() * 2) - 1;  % Random value between -1 and 1
    end
end


% Make it symmetric
img = img + img';

% Display matrix info
fprintf('Matrix size: %dx%d\n', n, n);
fprintf('Number of unique edges: %d\n', n*(n-1)/2);
fprintf('Max edge value: %.1f\n', max(img(:)));

% Run the first implementation
tfced1 = matlab_tfce_transform(img); % Explicitly set dh=0.10

% Run the second implementation
% [tfced2, comps, comp_sizes] = matlab_tfce_transform(img); % Explicitly set dh=0.10
tfced2 = apply_tfce(img);

% Compare results
disp('Comparison of results:');
disp(['Mean absolute difference: ', num2str(mean(abs(tfced1(:) - tfced2(:))))]);
disp(['Maximum absolute difference: ', num2str(max(abs(tfced1(:) - tfced2(:))))]);
disp(['Correlation between outputs: ', num2str(corr(tfced1(:), tfced2(:)))]);

% Visualize differences
figure('Color', 'white', 'Position', [100, 100, 1200, 1000]);

% Set default font sizes
set(0, 'DefaultAxesFontSize', 14);
set(0, 'DefaultTextFontSize', 16);

% Note: If 'redblue' colormap is not available, you can use:
% - colormap(redblue()) if you have a custom redblue function
% - colormap(diverging_map()) for a custom diverging map
% - colormap([linspace(0,1,128)' linspace(0,0,128)' linspace(1,0,128)'; ...
%             linspace(1,1,128)' linspace(0,1,128)' linspace(0,0,128)']) for custom red-white-blue
% - colormap('coolwarm') or colormap('jet') as alternatives
figure('Color', 'white', 'Position', [100, 100, 1200, 1000]);

% Set default font sizes
set(0, 'DefaultAxesFontSize', 14);
set(0, 'DefaultTextFontSize', 16);

subplot(2,2,1);
imagesc(img);
title('Input Matrix', 'FontSize', 18, 'FontWeight', 'bold');
colormap(gca, redblue());  % or use 'coolwarm' if redblue is not available
colorbar('FontSize', 12);
set(gca, 'FontSize', 14);
xlabel('ROI', 'FontSize', 14);
ylabel('ROI', 'FontSize', 14);

subplot(2,2,2);
imagesc(tfced1);
title('Traditional TFCE Output', 'FontSize', 18, 'FontWeight', 'bold');
colormap(gca, 'redblue');
colorbar('FontSize', 12);
set(gca, 'FontSize', 14);
xlabel('ROI', 'FontSize', 14);
ylabel('ROI', 'FontSize', 14);

subplot(2,2,3);
imagesc(tfced2);
title('Incremental Cluster TFCE Output', 'FontSize', 18, 'FontWeight', 'bold');
colormap(gca, 'redblue');
colorbar('FontSize', 12);
set(gca, 'FontSize', 14);
xlabel('ROI', 'FontSize', 14);
ylabel('ROI', 'FontSize', 14);

subplot(2,2,4);
imagesc(abs(tfced1 - tfced2));
title('Absolute Difference', 'FontSize', 18, 'FontWeight', 'bold');
colormap(gca, 'redblue');
colorbar('FontSize', 12);
set(gca, 'FontSize', 14);
xlabel('ROI', 'FontSize', 14);
ylabel('ROI', 'FontSize', 14);