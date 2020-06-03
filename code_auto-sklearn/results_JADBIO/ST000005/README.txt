
#### Overall description.

This folder presents the results of two separate JADBIO runs on the omonym dataset.

#### Analysis protocol.

Dataset samples are first divided into two splits ("split1" and "split2") which are in turn used as training and hold-out set. That means that the first JADBIO run uses split1 and training and split2 as hold-out set, and vice versa for the second run.
During each run, JADBIO's AI automatically identifies the evaluation protocol to use, as well as the algorithms to try and the ranges across which the hyperparameters of these algorithms will be optimized. A specific combination of algorithm and hyperparameters values is named "configuration". Given the size of the datasets involved in the study, repeated cross-validation was used as evaluation protocol for all runs. AUC is the metric of choice for the optimization search, however many other metrics are computed as well (accuracy, sensitivity, specificity, etc.). For each run, the best configuration is chosen across all candidate configuaration, as well as restrcting the search across configuration involving / excluding feature selection and involving / excluding interpretable models.

#### Description of the files in the folder.

This section describes the files contained in the folder. Each subfolder has a further description in the "Description of the files in the subfolders" section below.

- 1_overall: folder containing the results for the best model chosen across all configurations.

- 2_overall_interpretable: folder containing the results obtained by considering only configurations with interpretable models.

- 3_NOFS: folder containing the results obtained by considering only configurations without feature selection.

- 4_NOFS_interpretable: folder containing the results obtained by considering only configurations without feature selection and with interpretable models.

- 5_FS: folder containing the results obtained by considering only configurations with feature selection.

- 6_FS_interpretable: folder containing the results obtained by considering only configurations with feature selection and with interpretable models.

- predictions_matrix_split1, predictions_matrix_split2: folder containing the cross-validated, single-sample predictions for each configuration.

- analysis_info.csv: file containing general information on the two runs as execution time, sample size, best configuration, etc.

- conf_times_split1.csv, conf_times_split2.csv: computational time spent for training each configuration.

- feature_selector_times_split1.csv, feature_selector_times_split1.csv: computational time spent for feature selection.

- indices.csv: indices of the samples populating split1 and split2.

- indices_split1.csv, indices_split2.csv: indices denoting the folds split1 and split2 were partitioned during the repeated cross-validation protocol.

- model_trainer_times_split1.csv, model_trainer_times_split2.csv: computational time spent for modelling algorithms.

- model_trainer_vars_split1.csv, model_trainer_vars_split2.csv: number of variable employed by each modelling algorithm.

original_outcome_split1.csv, original_outcome_split2.csv, outcome_split1.csv, outcome_split2.csv: the outcome column for the two splits. The "original_" ones are useful in regression settings, where the outcome can be normalized.

#### Description of the files in the subfolders.

Each of the folders denoted by a number 1 to 6 contains (a subset of) the following files:

- cis_split1.csv, cis_split2.csv: bootstrapped performance values on the training set.

- estimates_split1.csv, estimates_split2.csv: bootstrap-corrected performance estimates from the training set, along with confidence intervals from the training set, and hold-out performance estimates for several metrics.

- holdout_bootstrap_estimates_split1.csv, holdout_bootstrap_estimates_split2.csv: bootstrapped performance values on the hold-out set.

- holdout_msignatures_split1.csv, holdout_msignatures_split2.csv: predictions of each signature on the hold-out set.

- insample_msignatures_split1.csv, insample_msignatures_split2.csv: predictions of each signature on the training set.

- msignatures_split1.csv, msignatures_split2.csv: performance achieved by each signature.

- repeated_estimates_split1.csv, repeated_estimates_split2.csv: AUC value achieved on each fold of the repeated cross-validation.

- uncorrected_estimates_split1.csv, uncorrected_estimates_split2.csv: non-corrected performance estimates from the training set, along with confidence intervals from the training set, and hold-out performance estimates for several metrics.

The predictions_matrix_split1 and predictions_matrix_split2 folders contain one file for each repetition of the repeated cross validation. Each of these files reports the cross-validated, single-sample predictions for each configuration.