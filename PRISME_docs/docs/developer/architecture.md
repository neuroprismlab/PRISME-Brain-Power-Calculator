

# Architecture Overview

Repetition Calculation 

PRISME's architecture organizes computation across four hierarchical levels, each with a dedicated script. 

## Four Levels of Organization

### 1. Study-Level Organization

The outermost level loops over all studies defined in the `outcome` structure. For each study, PRISME automatically infers the test type by analyzing the data structure:

- **One-sample t-test**: When contrasts between conditions are available
- **Two-sample t-test**: When categorical data exists for exactly two groups
- **Correlation analysis**: When continuous measures are present

This specification spares manual definition and ensures each analysis is compatible with the data supplied. See [Input Data Format](../user_guide/input_format.md#test-type-inference) for details on the inference logic.

### 2. Subject-Level Sampling

Within each study, this level loops over the sample sizes specified in `Params.list_of_nsubset`. Since PRISME generates one output file per study and sample size, this level handles file-based checkpointing for resumption after interruptions. If the file for this study and subject-level has all repetitions completed, it skips to the next loop.

Overall, for each sample size:

- Manages subject identifiers for subsampling
- Constructs appropriate design matrices for each repetition 
- Tracks completion status by checking existing output files
- Resumes from checkpoints when calculations are interrupted



### 3. Batch-Level Management

This level organizes repetitions into configurable batches (set by `Params.batch_size`). Batching helps with memory management and checkpointing. Trade-off: Larger batches require more RAM but reduce disk I/O overhead. Smaller batches use less RAM but save to disk more frequently.

The batch manager:
- Group repetitions into processing units
- Balances memory efficiency
- Implements the checkpoint system - When a batch is completed, the repetitions are saved to the file
- Saves results incrementally after each batch completes



### 4. Parallel Execution Level

The innermost level distributes computational workload across available CPU cores. PRISME parallelizes at the repetition level because:

- GLM fitting and statistical method inference are the most computationally intensive parts of the code
- Each repetition is independent (no communication overhead)
- With 500 recommended repetitions, parallelization enables near-linear scaling

Each worker processes a complete repetition independently, including:
- GLM fitting for original and permuted data
- Applying all statistical inference methods
- Computing p-values

Set `Params.parallel = true` and `Params.n_workers` to the number of available cores to enable parallel execution.

## Computational Flow
```
Study Loop (Study 1, Study 2, ...)
  └─ Sample Size Loop (n=40, n=80, ...)
      └─ Batch Loop (Batch 1, Batch 2, ...)
          └─ Parallel Execution (Rep 1, Rep 2, ... Rep batch_size)
              ├─ Subsample subjects
              ├─ Fit GLM + permutations
              ├─ Apply statistical methods
              └─ Return p-values
          └─ Save batch results (checkpoint)
```

Ground Truth Calculation

## Unified Pipeline

Although the algorithm describes two computational paths (repetitions and ground truth), the architecture implements both within a unified framework. The ground truth calculation is a special case of the repetition workflow where:
- Only one repetition is performed
- The entire dataset (N subjects) is used
- A dummy statistical inference method maintains code consistency
- Only the GLM fit results are extracted

This unification simplifies maintenance. One code changes automatically affect both workflows.

