%% IC-TFCE Speed Benchmark: Synthetic FC Data Across ROI Counts
% Generates synthetic FC data with a realistic cluster signal,
% computes t-statistics, and benchmarks IC-TFCE vs TFCE.
%
% No PRISME needed — speed test operates directly on t-stat matrices.

%% Configuration
% sigma_max - kernel size at largest N - other sides ajust as fractions
n_roi_values = [200, 500, 1000];  
n_reps       = 500;      
dh_values    = [0.01, 0.05, 0.1, 0.25];
sigma_max    = 50;  
H            = 2;
E            = 0.5;

rng(42);  % Reproducibility - Same results for validation

%% Pre-allocate results
% results(i, j, :) = [ic_time, tfce_time] for roi_idx i, dh_idx j
results = zeros(numel(n_roi_values), numel(dh_values), 2);

%% Main benchmark loop
for ri = 1:numel(n_roi_values)
    N = n_roi_values(ri);

    fprintf('\n--- N = %d ROIs ---\n', N);

    % --- Generate synthetic t-statistic matrix ---

    for di = 1:numel(dh_values)
        dh = dh_values(di);

        ic_times   = zeros(1, n_reps);
        tfce_times = zeros(1, n_reps);
            
        for rep = 1:n_reps
            
            t_mat = generate_synthetic_tstat(N, ...
                ceil(sigma_max*(N / max(n_roi_values))));

            tic; 
            apply_tfce_cpp(t_mat, dh, H, E);       
            ic_times(rep)   = toc;

            tic; 
            traditional_tfce_cpp(t_mat, H, E, dh); 
            tfce_times(rep) = toc;

        end

        results(ri, di, 1) = mean(ic_times);
        results(ri, di, 2) = mean(tfce_times);

       fprintf('  dh=%.2f  IC-TFCE: %.1fms  TFCE: %.1fms  Speedup: %.1fx\n', ...
        dh, results(ri,di,1)*1000, results(ri,di,2)*1000, ...
        results(ri,di,2)/results(ri,di,1));
    end
end

%% Print summary table
fprintf('\n\n=== Speedup Table (TFCE / IC-TFCE) ===\n');

header = sprintf('%6s', '');
for di = 1:numel(dh_values)
    header = [header sprintf('  dh=%.2f', dh_values(di))]; %#ok<AGROW>
end

fprintf('%s\n', header);

for ri = 1:numel(n_roi_values)

    row = sprintf('N=%4d', n_roi_values(ri));

    for di = 1:numel(dh_values)
        speedup = results(ri,di,2) / results(ri,di,1);
        row = [row sprintf('   %5.1fx', speedup)]; %#ok<AGROW>
    end

    fprintf('%s\n', row);

end

%%% Generate random t-statistics and apply a normalizing filter
function t_mat = generate_synthetic_tstat(N, sigma)

    raw = randn(N);

    ksize  = 2 * ceil(3 * sigma) + 1;
    kernel = fspecial('gaussian', ksize, sigma);

    smoothed = imfilter(raw, kernel, 0, 'same');
    smoothed = smoothed / std(smoothed(:)) * 3;

    t_mat = (smoothed + smoothed') / 2;
    t_mat(1:N+1:end) = 0;

end