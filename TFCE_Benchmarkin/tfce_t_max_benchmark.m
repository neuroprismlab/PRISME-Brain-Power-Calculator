%% Speed comparison: traditional TFCE (C++) vs IC-TFCE (C++) across t_max values
% t_max is set from Cohen's d and sample size (one-sample/paired: t = d*sqrt(n)).
% Each synthetic matrix is rescaled so that its maximum equals the target t_max.
% Reports mean and max absolute difference between the two outputs.
%
% Requires: apply_tfce_cpp and traditional_tfce_cpp compiled and on the
% path, and the Image Processing Toolbox (fspecial, imfilter).

clear;
clc;

%% Configuration
seed       = 777;                 % RNG seed
n_reps     = 1000;                 % Repetitions per condition
n_rois     = 268;
n_dec      = 4;
dh         = 0.01;
H          = 3.0;
E          = 0.4;
sigma_frac = [0.005, 0.10];      % Range of the Gaussian sigma (fraction of n_rois)

% Effect sizes (Cohen's d)
effects = struct( ...
    'name', {'Weak', 'Mid', 'Strong'}, ...
    'd',    {0.1,    0.5,   0.8});
% Sample sizes normally used in neuroimaging
n_subj_list = [40 80 120];

rng(seed);
edge_mask  = triu(true(n_rois), 1);

% Function to generate a random parameter based on the number of ROIs
draw_sigma = @() (sigma_frac(1) + rand() * (sigma_frac(2) - sigma_frac(1))) * n_rois;

%% Build the conditions (keys carry the actual values)
fmt = @(x) strrep(sprintf('%.*f', n_dec, x), '.', 'p');

conds = struct();
for e = 1:numel(effects)
    for s = 1:numel(n_subj_list)
        n    = n_subj_list(s);
        tmax = effects(e).d * sqrt(n);
        key  = sprintf('d%s_nsubs%d_tmax%s', fmt(effects(e).d), n, fmt(tmax));
        conds.(key) = struct();
    end
end


%% Main loop
keys = fieldnames(conds);

for c = 1:numel(keys)
    key = keys{c};
    [~, ~, tmax] = l_parse_key(key);     % rounded t_max from the key

    t_ic   = zeros(n_reps, 1);
    t_trad = zeros(n_reps, 1);
    mean_e = zeros(n_reps, 1);
    max_e  = zeros(n_reps, 1);

    for rep = 1:n_reps
        % New random smoothing parameter for every matrix
        t_mat = l_generate_synthetic_tstat(n_rois, draw_sigma());

        % Rescale 
        t_mat = t_mat * (tmax / max(t_mat(:)));

        in_trad = t_mat + 0;   % copies made outside the timed region
        in_ic   = t_mat + 0;

      
        tic; 
        out_trad = traditional_tfce_cpp(in_trad, H, E, dh); 
        t_trad(rep) = toc;

        tic; 
        out_ic = apply_tfce_cpp(in_ic, dh, H, E);         
        t_ic(rep) = toc;
          
        d_abs = abs(out_trad(edge_mask) - out_ic(edge_mask));
        mean_e(rep) = mean(d_abs);
        max_e(rep)  = max(d_abs);
    end

    conds.(key).t_ic     = mean(t_ic) * 1e3;      % ms
    conds.(key).t_trad   = mean(t_trad) * 1e3;    % ms
    conds.(key).speedup  = conds.(key).t_trad / conds.(key).t_ic;
    conds.(key).mean_err = mean(mean_e);
    conds.(key).max_err  = max(max_e);            % worst case over all reps

    fprintf('%s | IC %.3f ms | TFCE %.3f ms | %.2fx\n', ...
        key, conds.(key).t_ic, conds.(key).t_trad, conds.(key).speedup);
end

%% LaTeX table
fprintf('\n%% ===== LaTeX table (n_rois = %d, dh = %.2f, %d repetitions per row) =====\n', ...
    n_rois, dh, n_reps);
fprintf('\\begin{tabular}{rrrrrrrr}\n\\hline\n');
fprintf('$d$ & $n$ & $t_{max}$ & IC-TFCE (ms) & TFCE (ms) & Speedup & Mean err. & Max err. \\\\\n\\hline\n');
for c = 1:numel(keys)
    key = keys{c};
    [d, n, tmax] = l_parse_key(key);
    fprintf('%.1f & %d & %.3f & %.3f & %.3f & %.2f$\\times$ & %.2e & %.2e \\\\\n', ...
        d, n, tmax, conds.(key).t_ic, conds.(key).t_trad, conds.(key).speedup, ...
        conds.(key).mean_err, conds.(key).max_err);
end
fprintf('\\hline\n\\end{tabular}\n');

%% Local functions
% Generate random t-statistics and apply a Gaussian smoothing filter
function t_mat = l_generate_synthetic_tstat(n_rois, sigma)
    raw = randn(n_rois);
    ksize  = 2 * ceil(3 * sigma) + 1;
    kernel = fspecial('gaussian', ksize, sigma);
    smoothed = imfilter(raw, kernel, 0, 'same');
    smoothed = smoothed / std(smoothed(:)) * 3;
    t_mat = (smoothed + smoothed') / 2;
    t_mat(1:n_rois+1:end) = 0;
end

% Recover d, n and (rounded) t_max from a condition key
function [d, n, tmax] = l_parse_key(key)
    % Regex to find the numbers in the key
    tok  = regexp(key, '^d(\w+?)_nsubs(\d+)_tmax(\w+)$', 'tokens', 'once');
    d    = str2double(strrep(tok{1}, 'p', '.'));
    n    = str2double(tok{2});
    tmax = str2double(strrep(tok{3}, 'p', '.'));
end