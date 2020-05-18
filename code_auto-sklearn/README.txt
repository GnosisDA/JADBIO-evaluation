
#### Overall description.

This folder contains scripts for running auto-sklearn analyses as described in the paper "Just Add Data: Automated Predictive Modeling and BioSignature Discovery" bioRxiv 2020.05.04.075747 (Preprint, 2020).

#### Instructions.

1) Download the datasets you want to analyze from https://www.jadbio.com/extensive_evaluation/datasets_results.html (preprocessed data), and copy them in the folder "datasets".

2) Download the corresponding JADBIO results, unzip them and copy the folders in the "results_JADBIO" folder.

3) Run the "script.R" file contained in the "code" folder. The auto-sklearn results will appear in the "code/tmp/results" folder.

#### Hardware and software used for the analyses.

The analyses were run on the ARIS supercomputer, deployed and operated by GRNET S.A. (National Infrastructures for Research and Technology S.A.). A description of the system is available at 
http://doc.aris.grnet.gr/system/hardware/.

Particularly, the analyses were submitted through the Slurm workload manager. As such, the "script.R" file prepares and launch a Slurm job script for each analysis. The Slurm job scripts are written in the "code/tmp/scripts" folder. 

System software modules:
gnu/4.9.2
intel/15.0.3
intelmpi/5.0.3
python/3.6.5

Python:
Python 3.6.5
auto-sklearn 0.5.2

R:
See the "session_info.txt" file.