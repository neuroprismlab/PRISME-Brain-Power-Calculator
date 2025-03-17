classdef Constrained
    properties (Constant)
        level = "network";
        permutation_based = true;
    end
    
    methods

        function pval = run_method(~,varargin)
            % Applies Constrained (cNBS) method and computes p-values using permutation-based inference.
            %
            % Inputs:
            %   - STATS: Structure containing statistical parameters.
            %   - edge_stats: Raw test statistics for edges.
            %   - permuted_edge_data: Precomputed permutation edge statistics.
            %
            % Outputs:
            %   - pval: FWER- or FDR-corrected p-values.
        
            params = struct(varargin{:});
        
            % Extract relevant inputs
            STATS = params.statistical_parameters;
            edge_stats = params.edge_stats;
            permuted_edge_stats = params.permuted_edge_data; % Precomputed permutation data
        
            % Ensure permutation data is available
            if isempty(permuted_edge_stats)
                error('Permutation data is missing. Ensure precomputed permutations are provided.');
            end
        
            pval_uncorr = constrained_calculation(STATS, edge_stats, permuted_edge_stats);
        
            % Compute FWER- or FDR-corrected p-values
            %Simes procedure
            J = length(pval_uncorr);
            ind_srt = zeros(1,J); 
            [pval_uncorr_sorted, ind_srt]=sort(pval_uncorr);
            tmp=(1:J)/J*STATS.alpha;
            ind_sig = pval_uncorr_sorted<=tmp;
            
            % here, binary: 0 means significant (<alpha), 1 is not significant (>alpha) 
            pval=ones(1,J);
            pval(ind_srt(ind_sig))=0; 
    
        end
    end

end