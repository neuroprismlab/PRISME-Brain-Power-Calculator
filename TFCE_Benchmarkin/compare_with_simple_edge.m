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

[tfced1, cc_size] = apply_tfce(img); % Explicitly set dh=0.10

% Run the second implementation
% [tfced2, comps, comp_sizes] = matlab_tfce_transform(img); % Explicitly set dh=0.10
tfced2 = apply_tfce_cpp(img, 0.1, 3, 0.4);

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