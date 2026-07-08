classdef Multivariate_CNBS

    properties (Constant)
        level = 'multivariate';          % multivariate marker
        permutation_based = true;
        submethod = {'FWER', 'FDR'};
    end

    methods
        function pvals = run_method(~, varargin)
            params     = struct(varargin{:});
            STATS      = params.statistical_parameters;
            edge_stats = params.edge_stats;            
            perm_stats = params.permuted_edge_data;  
            
            % Get number of groups and perms
            G        = STATS.multivariate_group;      
            n_groups = size(G, 1);
            n_perms  = size(perm_stats, 2);

            group_p = zeros(n_groups, 1);

            for g = 1:n_groups
                idx    = find(G(g, :));                % edges in this group
                V_perm = perm_stats(idx, :);           % k x n_perms
                v_obs  = edge_stats(idx);              % k x 1

                % average (null centroid) across permutations
                m = mean(V_perm, 2);                   % k x 1

                % euclidean distance of each permutation from the centroid
                d_perm = sqrt(sum((V_perm - m).^2, 1));   % 1 x n_perms
                d_obs  = sqrt(sum((v_obs  - m).^2));       % scalar

                % permutation p-value with +1 correction
                group_p(g) = (sum(d_perm >= d_obs) + 1) / (n_perms + 1);
            end

            pvals = struct();
            if STATS.submethods.FWER
                pvals.FWER = min(group_p * n_groups, 1);   % Bonferroni over groups
            end
            if STATS.submethods.FDR
                try
                    pvals.FDR = mafdr(group_p);
                    assert(sum(pvals.FDR) > 1e-15)
                catch
                    pvals.FDR = mafdr(group_p, 'BHFDR', true);
                end
            end
        end
    end
end