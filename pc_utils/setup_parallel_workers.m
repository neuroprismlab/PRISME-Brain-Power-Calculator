function run_parallel = setup_parallel_workers(flag, worker_number)
    %% setup_parallel_workers
    % **Description**
    % Initializes or adjusts the parallel processing setup based on the specified 
    % number of workers. If running in GitHub Actions (`testing_yml_workflow`), 
    % parallel execution is disabled to ensure compatibility.
    %
    % **Inputs**
    % - `flag` (logical): Enable (`true`) or disable (`false`) parallel execution.
    % - `worker_number` (integer): Number of parallel workers to initialize.
    %
    % **Outputs**
    % - `run_parallel` (logical): Indicates whether parallel execution is enabled.
    %
    % **Workflow**
    % 1. If `testing_yml_workflow` is set (GitHub CI/CD), force serial execution.
    % 2. If parallel execution is requested:
    %    - Close any existing parallel pool.
    %    - Limit workers to the maximum available.
    %    - Start a new parpool
    %
    % **Author**: Fabricio Cravo  
    % **Date**: March 2025

    global testing_yml_workflow;
    
    if exist('testing_yml_workflow', 'var')
        git_work_flow = testing_yml_workflow;
    end

    % If running in GitHub Actions, force serial execution
    if git_work_flow
        fprintf('Running in GitHub CI/CD: Forcing serial execution.\n');
        run_parallel = false;
        return; % Skip parallel execution
    else
        run_parallel = flag;
    end

    if flag
        % **Ensure Any Existing Parallel Pool is Closed**
        delete(gcp('nocreate')); % Closes any open parallel pool

        c = parcluster('local'); 
        
        % Limit workers to the maximum available
        if worker_number > c.NumWorkers
            fprintf('Specified %d workers but only %d available. Setting to max available.\n', ...
                worker_number, c.NumWorkers);
            worker_number = c.NumWorkers;
        end
        
        % Create a new parallel pool
        fprintf('Starting parallel pool with %d workers...\n', worker_number);
        parpool(worker_number);
    end
end
