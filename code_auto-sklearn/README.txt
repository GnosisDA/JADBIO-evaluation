
#### Overall description.

This folder contains scripts for running the auto-sklearn analyses described in the paper "Just Add Data: Automated Predictive Modeling and BioSignature Discovery" bioRxiv 2020.05.04.075747 (Preprint, 2020).

#### Hardware and software requirements.

Repeating the analyses requires a working installation of Python and R, as well as a Linux based system. We used Red Hat Enterprise Linux Server release 6.10 in our experimentation.

Python:
Python 3.6.5
auto-sklearn 0.5.2

R:
See the "session_info.txt" file.

The analyses were originally run on the ARIS supercomputer, deployed and operated by GRNET S.A. (National Infrastructures for Research and Technology S.A.). A description of the system is available at 
http://doc.aris.grnet.gr/system/hardware/.
Particularly, the analyses were submitted through the Slurm workload manager. Slurm can be optionally used for repeating the analyses by satisfying the following software requirements:

slurm/16.05.11
gnu/4.9.2
intel/15.0.3
intelmpi/5.0.3

#### Installation

Installing R, Python, and respective packages / modules usually takes about two hours. R is available at https://cran.r-project.org/, while its packages can be installed following their respective instructions. We recommend installing Python through Anaconda (https://www.anaconda.com/), while auto-sklearn is available at https://automl.github.io/auto-sklearn/master/.

Installation of slurm requires significant experience in system administration, and the installation time varies considerably depending on local hardware and settings.
https://slurm.schedmd.com/

#### Instructions.

1) Download the datasets to analyze from https://www.jadbio.com/extensive_evaluation/datasets_results.html (preprocessed data), and copy them in the folder "datasets". One of such datasets (ST000005.csv) is already present as a demo.

2) Download the corresponding JADBIO results, unzip them and copy the folders in the "results_JADBIO" folder. Results for dataset "ST000005" are already present as a demo.

3) Run the "script.R" file contained in the "code" folder. The auto-sklearn results will appear in the "code/tmp/results" folder. See the README file in the folder "code/tmp/results" for a decription of the auto-sklearn output files. The expected running time for dataset "ST000005" alone on a "powerful" computer (e.g., 128GB RAM and 4 Intel(R) Xeon(R) CPU E5-2640 v2) is about 20 minutes. If slurm is available on your system, the "script_slurm.R" file can be used instead of "script.R".

4) In order to run the code on user's own data, it is required to:

4a) copy the user's data in the "datasets" folder. The data must be formatted as a matrix with samples for rows and measurements for columns. All measurements should be numerical. The binary (0,1 encoding) outcome to predict should be contained in a column named "target". The samples' names should be contained in the first column and this first column should be named "sample"

4b) have a file named "indices.csv" in the folder "results_JADBIO/<dataset_name>", where <dataset_name> should be replaced with the name of the file copied in the "datasets" folder (for example, for the "ST000005.csv" dataset we have the "results_JADBIO/ST000005/indices.csv" file).
This "indices.csv" file should contain two rows, which describe how to split the samples in training and holdout sets. Particularly, each row contains the row numbers of samples that will populate the respective set. See the "results_JADBIO/ST000005/indices.csv" file for an example.

4c) run the "script.R" or the "script_slurm.R" files contained in the "code" folder.