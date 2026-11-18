# PRISME Documentation

## **Power Reproducibility and Inference for Statistical Method Evaluation**

PRISME is a MATLAB toolbox for empirical power estimation in neuroimaging. The goal of PRISME is to provide a generic power calculator tool applicable to most situations, addressing some of the limitations in power calculation within the field. 

## What PRISME Does

PRISME calculates statistical power through repeated subsampling. The algorithm:

1. Samples n subjects from your full dataset (N subjects)
2. Fits a GLM to generate t-statistics for each brain variable
3. Applies statistical inference methods to produce p-values and detect an effect if the obtained p-value is below a significance threshold
4. Repeats this process R times 
5. Compares detected effects against an estimated ground truth from the full dataset
6. Returns power estimates for each variable and method

Power is defined as the proportion of repetitions where an inference method correctly detects these effects.

## Key Features

**Method-agnostic**: Compare any statistical inference method that produces p-values from t-statistics. Currently implements 7 methods: Parametric (FDR/FWER), cNBS (FDR/FWER), Cluster Size, TFCE, and mv-cNBS. Please check the user guide for exact method names. More methods can be added by developers by following our specified API, please check the developer guide.

**Data-agnostic**: Designed to work with multiple data types. For example, functional connectivity and voxel activation data

**Computational efficiency**: Permutations are recycled to speed up power calculation comparisons over multiple methods. 

**Test type support**: Handles one-sample t-tests, two-sample t-tests, and correlation analyses with behavioral/clinical measures. Test types are automatically inferred from the input data.

## Installation
Simply clone the repository and open the scripts in MATLAB.
```bash
# Requirements: MATLAB (recommended version R2024a or later)
git clone https://github.com/neuroprismlab/PRISME-Brain-Power-Calculator.git
```

## Quick Start

Configure parameters in `setparams.m`, then run the three-step workflow:
```matlab
% 1. Edit setparams.m with minimal required parameters:

% Dataset path (required)
Params.data_dir = './data/your_dataset.mat';

% Output naming (optional - defaults to dataset name - this will name the directory storing the results)
Params.output = 'my_power_analysis';

% Sample sizes to test (required)
Params.list_of_nsubset = {40, 80, 120, 200};

% Number of repetitions 
Params.n_repetitions = 100;

% Statistical inference methods to compare (required - which methods to use for this analysis)
Params.all_cluster_stat_types = {'Parametric', 'Fast_TFCE', 'Size'};

% 2. Run the workflow
Params = setparams();  % Load all parameters
repetition_calculator(Params);  % Generate power samples
calculate_gt(Params);           % Compute ground truth
calculate_power_per_method(Params);  % Calculate power estimates
```

Results are saved to `./power_calculator_results/` by default under a directory named Params.output.

See [Configuration Parameters](user_guide/parameters.md) for all available `setparams.m` options and [Running Workflows](user_guide/workflows.md) for detailed execution instructions.

See [Quick Start Guide](getting_started/quickstart.md) for a complete tutorial.

## Documentation Structure

**For Users:**
- [Input Data Format](user_guide/input_format.md) - Describes the PRISME dataset input structure
- [Configuration Parameters](user_guide/parameters.md) - Describes how to `setparams.m` for your own analysis
- [Running Workflows](user_guide/workflows.md) - Step-by-step execution guide

**For Developers:**
- [Adding New Methods](developer/adding_methods.md) - Describes how to add a new method, how methods receive data from the code upstream, and how they must return the p-values

- [Architecture Overview](developer/architecture.md) - Code organization and design principles
- [C++ Integration](developer/cpp_integration.md) - How to optimize your method with C++ 

## Testing

PRISME includes unit tests and full pipeline tests, located in `test_scripts/`. The unit tests check the statistical inference methods (Parametric, Size, TFCE, cNBS and its C++ version, and the omnibus cNBS) against hard-coded p-values on small hand-built networks. They also check that the GLM fit matches closed-form t-statistics for one-sample, two-sample and correlation designs, the automatic inference of the test type (`t`, `t2`, `r`) from the input data, the extraction of design matrices and brain data from contrast-based and score-based tests, and the logic that resumes repetition calculations from existing result files. The goal of the tests is to assure calculations are correct and remain correct at each update. The tests run automatically on every pull request into `main`. See [Testing](tests/testing_detail.md) for a per-test breakdown of what is checked and which functions are covered.

## Contributing

To contribute, first open an issue in the [Issues tab](https://github.com/neuroprismlab/PRISME-Brain-Power-Calculator/issues) describing the change you plan to make. 
Once it has been discussed, open a pull request into `main` that references the issue (e.g. `Closes #12`).

The `main` branch is rule-protected:
- No direct pushes to `main`. All changes must result from a PR.
- Automated tests must pass before a pull request can be merged.
- One approving review from someone with write access is required.

New inference methods must follow the API in [Adding New Methods](developer/adding_methods.md). 
If a new method is added, please add a test (see [Testing](tests/testing_detail.md)).


## License

MIT License - see GitHub repository for details.

## Support

- **GitHub Issues**: [Report bugs or request features](https://github.com/neuroprismlab/PRISME-Brain-Power-Calculator/issues)
