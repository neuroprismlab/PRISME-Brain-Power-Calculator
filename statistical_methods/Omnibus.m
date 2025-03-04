function pval = Omnibus(varargin)
    % Computes Omnibus test statistics using different submethods.
    %
    % Inputs:
    %   - STATS: Structure containing statistical parameters.
    %   - edge_stats: Raw test statistics for edges.
    %   - permuted_edge_data: Precomputed permutation edge statistics.
    %   - omnibus_type: String specifying the Omnibus submethod.
    %
    % Outputs:
    %   - pval: P-values computed using the selected Omnibus method.

    params = struct(varargin{:});

    % Extract relevant inputs
    STATS = params.statistical_parameters;
    edge_stats = params.edge_stats;
    permuted_edge_stats = params.permuted_edge_data;  % Precomputed permutation data

    % Ensure permutation data is available
    if isempty(permuted_edge_stats)
        error('Permutation data is missing. Ensure precomputed permutations are provided.');
    end

    % Select appropriate Omnibus method
    switch STATS.omnibus_type
        case 'Multidimensional_cNBS'
            pval = Multidimensional_cNBS(edge_stats, permuted_edge_stats);
        case 'Threshold_Positive'
            pval = Threshold_Omnibus(STATS, edge_stats, permuted_edge_stats, 'positive');
        case 'Threshold_Both_Dir'
            pval = Threshold_Omnibus(STATS, edge_stats, permuted_edge_stats, 'both');
        case 'Average_Positive'
            pval = Average_Omnibus(STATS, edge_stats, permuted_edge_stats, 'positive');
        case 'Average_Both_Dir'
            pval = Average_Omnibus(STATS, edge_stats, permuted_edge_stats, 'both');
        case 'Multidimensional_all_edges'
            pval = Multidimensional_all_edges(STATS, edge_stats, permuted_edge_stats);
        otherwise
            error('Omnibus type "%s" not recognized.', omnibus_type);
    end

end