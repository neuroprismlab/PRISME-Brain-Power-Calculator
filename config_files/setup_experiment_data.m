function Params = setup_experiment_data(Params, Dataset)
    %
    % Description:
    %   This functions take the necessary data from an experiment data set
    %   for the power calculation - for now only the subject data and mask
    %   are needed
    %
    % Input Arguments:
    %   Params - Parameter struct for power calculation
    %   data - experimental data in the correct dataset format
    %
    %
    % Ouput Arguments:
    %   Params - Parameter struct for power calculation with the data from
    %   the experiment added
    %
    
    % Extract study mask
    % Typeset to logical
    Params.mask = logical(Dataset.study_info.mask);
    
    % Extract number of variables - change for multivariable methods
    Params.n_var = sum(Params.mask(:));

    % Extract number of nodes 
    Params.n_nodes = size(Params.mask, 1);
end