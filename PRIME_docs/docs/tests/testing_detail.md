# PRISME testing framework

This document lists the tests in `test_scripts/`. It is organized as follows:

- Each `##` section is a main test script, named after its first (entry) function.
- **Test Description** says what the script tests.
- For scripts that run a full pipeline, **Tests Pipeline** names the pipeline and the use case.
- For scripts with subtests, each subtest is a `###` section with a **Subtest Description** and a **Coverage** line listing the functions it tests.
- Fixtures, helpers, dataset generators and other non-test files are not listed.

---

## `test_statistical_methods`

**Test Description**: Unit tests for the statistical inference methods. Each method runs on a small hand-built problem (5 nodes, 10 edges, 10 permutations), and its p-values are compared with hard-coded expected values (tolerance 1e-5).

### `test_Parametric`

**Subtest Description**: FWER p-values for 10 hard-coded t-statistics (df = 20) match hard-coded Bonferroni-corrected values.

**Coverage**: `Parametric`

### `test_Size_cpp`

**Subtest Description**: Per-edge p-values from the cluster-size method on 5-node data with a 3.1 threshold match hard-coded values.

**Coverage**: `Size_cpp`

### `test_Fast_TFCE_cpp`

**Subtest Description**: Per-edge TFCE p-values on the same 5-node data match hard-coded values.

**Coverage**: `Fast_TFCE_cpp`

### `test_Constrained`

**Subtest Description**: FWER and FDR network-level p-values (5 networks) match hard-coded values.

**Coverage**: `Constrained`

### `test_Constrained_cpp`

**Subtest Description**: FWER and FDR network-level p-values (5 networks) match the same hard-coded values as `test_Constrained`.

**Coverage**: `Constrained_cpp`

### `test_Omnibus_cNBS`

**Subtest Description**: The whole-brain omnibus p-value (4 networks) matches a hard-coded value.

**Coverage**: `Omnibus_cNBS`

---

## `test_nbsglm_smn`

**Test Description**: Unit tests for the GLM fit, t-test branch only. Each subtest builds the GLM struct the way the pipeline does (design matrix, data, contrast) and compares the returned t-statistics with known or closed-form values.

### `test_one_sample`

**Subtest Description**: One-sample design on null data: output size is `1 × n_GLMs`, and t-statistics are bounded.

**Coverage**: `NBSglm_setup_smn`, `NBSglm_smn`

### `test_one_sample_effect`

**Subtest Description**: One-sample design with known effect sizes: t / √n recovers each effect size.

**Coverage**: `NBSglm_setup_smn`, `NBSglm_smn`

### `test_two_sample`

**Subtest Description**: Two-sample design with known group differences: t matches the closed-form value, and reversing the contrast flips the sign.

**Coverage**: `NBSglm_setup_smn`, `NBSglm_smn`

### `test_correlation`

**Subtest Description**: Correlation design with known ρ: t matches the closed-form value.

**Coverage**: `NBSglm_setup_smn`, `NBSglm_smn`

### `test_invariances`

**Subtest Description**: t changes sign when Y is negated. It is unchanged by scaling Y, shifting Y, an affine transform of the score, or reordering subjects. Fitting one column alone gives the same t as the joint fit.

**Coverage**: `NBSglm_setup_smn`, `NBSglm_smn`

---

## `test_type_inference_tests`

**Test Description**: Unit tests for test-type inference. Each subtest covers one branch of the inference logic, using minimal test and brain data structs.

### `test_correlation`

**Subtest Description**: Continuous score → `r`.

**Coverage**: `infer_test_from_data`

### `test_two_sample_score`

**Subtest Description**: Score with two unique values → `t2`.

**Coverage**: `infer_test_from_data`

### `test_single_sample_score`

**Subtest Description**: Score with one unique value → `t`; the second output (test type origin) is assigned.

**Coverage**: `infer_test_from_data`

### `test_contrast_single`

**Subtest Description**: Contrast with one condition → `t`.

**Coverage**: `infer_test_from_data`

### `test_contrast_paired`

**Subtest Description**: Contrast with two conditions and full subject overlap → `t`.

**Coverage**: `infer_test_from_data`

### `test_contrast_unpaired`

**Subtest Description**: Contrast with two conditions and no subject overlap → `t2`.

**Coverage**: `infer_test_from_data`

### `test_contrast_too_many`

**Subtest Description**: Contrast with more than two conditions → error.

**Coverage**: `infer_test_from_data`

### `test_contrast_nan`

**Subtest Description**: Contrast `{NaN}` → error.

**Coverage**: `infer_test_from_data`

### `test_uninferable`

**Subtest Description**: No usable score and no cell contrast → error.

**Coverage**: `infer_test_from_data`

---

## `test_subs_score_retrieval`

**Test Description**: Unit tests for extracting the design matrix and brain data from score-based tests (`r` and `t2`).

### `test_r_basic_alignment`

**Subtest Description**: `r` case with the same subject order in test and brain data: X/Y shapes, subject count, X/Y alignment.

**Coverage**: `subs_data_from_score_condition`

### `test_r_shuffled_brain_order`

**Subtest Description**: `r` case with a different subject order in brain data: X and Y stay aligned.

**Coverage**: `subs_data_from_score_condition`

### `test_r_nan_removal`

**Subtest Description**: `r` case with a NaN score: that subject is dropped and the rest stay aligned.

**Coverage**: `subs_data_from_score_condition`

### `test_r_subject_not_in_brain_data`

**Subtest Description**: `r` case where a subject is missing from brain data: that subject is dropped.

**Coverage**: `subs_data_from_score_condition`

### `test_t2_basic`

**Subtest Description**: `t2` case: group design matrix X and data Y are correct.

**Coverage**: `subs_data_from_score_condition`

### `test_duplicate_sub_ids_error`

**Subtest Description**: Duplicate subject IDs → error.

**Coverage**: `subs_data_from_score_condition`

---

## `test_check_calculation_status`

**Test Description**: Unit tests for the repetition resume logic, which reads an existing repetition file and returns how many repetitions are done per method.

### Test 1: fresh start

**Subtest Description**: No repetition file → 0 repetitions per method; the sampled subject IDs have the right size.

**Coverage**: `check_calculation_status`

### Test 2: partial repetitions

**Subtest Description**: File with stored repetition counts → those counts are returned.

**Coverage**: `check_calculation_status`

### Test 3: dataset mismatch

**Subtest Description**: The file's dataset differs from the requested dataset → error.

**Coverage**: `check_calculation_status`

### Test 4: subject count mismatch

**Subtest Description**: The file's subject count differs from the requested count → error.

**Coverage**: `check_calculation_status`

### Test 5: recalculate flag

**Subtest Description**: `recalculate = 1` → counts reset to 0.

**Coverage**: `check_calculation_status`

---

## `data_inference_from_contrast_test`

**Test Description**: Unit tests for contrast-based test-type inference and data extraction. Both subtests run on four TASK/REST subject-ID overlap scenarios: full, high, partial and none.

### `test_test_type_inference`

**Subtest Description**: Inferred test type (`t` or `t2`, from the subject overlap) and the condition subject IDs.

**Coverage**: `infer_test_from_data`

### `test_data_retrieval`

**Subtest Description**: Design matrix X, data Y, selected subject IDs, and Y values (TASK − REST for `t`, [TASK, REST] for `t2`).

**Coverage**: `subs_data_from_contrast`

---

## `edge_based_tests`

**Test Description**: Runs the repetition calculation on a synthetic dataset where edges 1–6 have an effect and edges 7–10 don't. It checks that effect edges are detected in all repetitions, null edges are not, and the result metadata is correct.

**Tests Pipeline**: Repetition calculation (`rep_cal_function`) with edge-level methods: by default `Parametric` (FWER, FDR), `Size_cpp` and `Fast_TFCE_cpp`. The dataset is passed as an argument. Both `full_file` and `compact_file` output are supported.

---

## `network_based_tests`

**Test Description**: Runs the repetition calculation on a synthetic dataset where network 1 has an effect and network 2 doesn't. It checks that network 1 is detected in all repetitions, network 2 is not, and the result metadata is correct.

**Tests Pipeline**: Repetition calculation (`rep_cal_function`) with the network-level method `Constrained_cpp` (FWER, FDR). The dataset is passed as an argument. `full_file` output.

---

## `test_power_calculation_from_gt_and_data`

**Test Description**: Generates synthetic repetition results (designed power of 25%) and synthetic ground truth, runs the power calculation, and checks that the computed TPR is 25% at ground-truth positive and negative elements and 0% elsewhere.

**Tests Pipeline**: Power calculation (`calculate_power`) from repetition and ground-truth files, for edge-level methods (`Parametric` FWER/FDR, `Size`, `TFCE`) and network-level methods (`Constrained` FWER/FDR).
