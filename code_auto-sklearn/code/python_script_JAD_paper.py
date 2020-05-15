# -*- encoding: utf-8 -*-
"""
====================
Parallel Script
====================

This script run autosklearn in parallel so that to be comparable with JAD

Sources:
https://github.com/automl/auto-sklearn/blob/master/examples/example_parallel_manual_spawning.py
https://github.com/automl/auto-sklearn/issues/600
https://github.com/automl/auto-sklearn/issues/203
https://github.com/automl/auto-sklearn/issues/712
https://github.com/automl/auto-sklearn/issues/712

"""

#importing modules
import sys
import getopt
import multiprocessing
import shutil
import pandas
import copy
import pickle
import glob
import time

import sklearn.model_selection
import sklearn.datasets
import sklearn.metrics

import autosklearn.metrics
from autosklearn.classification import AutoSklearnClassifier
from autosklearn.constants import *
import warnings
warnings.filterwarnings("ignore", "Mean of empty slice")

# small constant to avoid the problem reported in 
# https://github.com/automl/auto-sklearn/issues/203
small_constant = 2

# function for spawning sub-processes
def get_spawn_classifier(
  X_train, 
  y_train,
  dataset_name,
  time_left_for_this_task,
  tmp_folder,
  output_folder,
  ):
    
  # this function is the actual subprocess
  def spawn_classifier(seed):
    """Spawn a subprocess.

    auto-sklearn does not take care of spawning worker processes. This
    function, which is called several times in the main block is a new
    process which runs one instance of auto-sklearn.
    """

    # Use the initial configurations from meta-learning only in one out of
    # the four processes spawned. This prevents auto-sklearn from evaluating
    # the same configurations in different processes.
    if seed == small_constant:
      initial_configurations_via_metalearning = 25
      smac_scenario_args = {}
    else:
      initial_configurations_via_metalearning = 0
      smac_scenario_args = {'initial_incumbent': 'RANDOM'}

    # Arguments which are different to other runs of auto-sklearn:
    # 1. all classifiers write to the same output directory
    # 2. shared_mode is set to True, this enables sharing of data between
    # models.
    # 3. all instances of the AutoSklearnClassifier must have a different seed!
    # setting up the automl object
    automl = autosklearn.classification.AutoSklearnClassifier(
      time_left_for_this_task=time_left_for_this_task, # sec., how long should this seed fit process run
      tmp_folder=tmp_folder,
      output_folder=output_folder,
      seed=seed,
      initial_configurations_via_metalearning=initial_configurations_via_metalearning,
      smac_scenario_args=smac_scenario_args,
      shared_mode=True, # tmp folder will be shared between seeds
      delete_tmp_folder_after_terminate=False,
      ensemble_size=0, # ensembles will be built when all optimization runs are finished
    )
    
    try:
    
        # fitting the models
        automl.fit(X_train.copy(), y_train.copy(), dataset_name=dataset_name, metric = autosklearn.metrics.roc_auc)

        # accessing cv_results_ as described in 
        # https://github.com/automl/auto-sklearn/issues/203
        cvRes = automl.cv_results_
        cvRes = pandas.DataFrame.from_dict(cvRes)

        # printing the results
        cvRes.to_csv('./tmp/results/' + dataset_name + '/cvRes_' + str(seed) + '.csv')
     
    except:
    
        pass
    
  
  # returning the sub-process
  return spawn_classifier

def main(argv):
	
  # reading the command line
  helpString = 'python python_script_JAD_paper -a <trainingSet> -b <testSet> -t <timeForEachWorker> -n <numWorkers>'
  try:
    opts, args = getopt.getopt(argv,"ha:b:t:n:")
  except getopt.GetoptError:
    print(helpString)
    sys.exit(2)
	
  # collecting the arguments
  for opt, arg in opts:
    if opt == '-h':
      print(helpString)
      sys.exit()
    elif opt == '-a':
      training_set = arg
    elif opt == '-b':
      test_set = arg
    elif opt == '-t':
      time_left_for_this_task = int(arg)
    elif opt == '-n':
      n_processes = int(arg)

  # starting counting the time
  start_time = time.time()
		
  # folders
  tmp_folder = './tmp/autosklearn_tmp/' + training_set
  output_folder = './tmp/autosklearn_out/' + training_set
	
  # ensuring the folders are empty (?)
  for tmpDir in [tmp_folder, output_folder]:
    try:
      shutil.rmtree(tmpDir)
    except OSError as e:
      pass

  # reading the training data
  trainingData = pandas.read_csv(filepath_or_buffer = './tmp/data/' + training_set + '.csv', index_col = False)
  y_train = trainingData['target']
  X_train = trainingData.drop('target', 1)

  # reading the test data
  testData = pandas.read_csv(filepath_or_buffer = './tmp/data/' + test_set + '.csv', index_col = False)
  y_test = testData['target']
  X_test = testData.drop('target', 1)
  
  # main block
  try:

    # creating the sub-process function   
    processes = []
    spawn_classifier = get_spawn_classifier(
      X_train, 
      y_train,
      training_set,
      time_left_for_this_task,
      tmp_folder,
      output_folder
    )
        
    # spawning the subprocesses
    for i in range(small_constant, small_constant + n_processes):
      p = multiprocessing.Process(
        target=spawn_classifier,
        args=[i]
      )
      p.start()
      processes.append(p)
    
    # waiting until all processes are done
    for p in processes:
      p.join()
    
    # retrieving the csRes and concatenating in a single data frame
    csvFiles = glob.glob('./tmp/results/' + training_set + '/*.csv')
    cvRes = pandas.read_csv(filepath_or_buffer = csvFiles[0], index_col = 0)
    for csvFile in csvFiles[1:]:
      cvRes_tmp = pandas.read_csv(filepath_or_buffer = csvFile, index_col = 0)
      cvRes = pandas.concat([cvRes, cvRes_tmp], axis=0, sort=False)
    
    # writing the cvRes on file
    cvRes.to_csv('./tmp/results/' + training_set + '/cvRes.csv', index = False)
   
    # building the ensemble
    automl_ensemble = AutoSklearnClassifier(
      time_left_for_this_task=time_left_for_this_task, # sec., how long should this seed fit process run
      delete_tmp_folder_after_terminate=False,
      delete_output_folder_after_terminate=False,
      seed=12345,
      shared_mode=True,
      ensemble_size=50,
      ensemble_nbest=50,
      tmp_folder=tmp_folder,
      output_folder=output_folder
    )
    automl_ensemble.fit_ensemble(
      y_train.copy(),
      task=BINARY_CLASSIFICATION,
      metric=autosklearn.metrics.roc_auc
    )
    
    # building the best model
    automl_bestModel = AutoSklearnClassifier(
      time_left_for_this_task=time_left_for_this_task, # sec., how long should this seed fit process run
      delete_tmp_folder_after_terminate=False,
      delete_output_folder_after_terminate=False,
      shared_mode=True,
      ensemble_size=1,
      ensemble_nbest=1,
      tmp_folder=tmp_folder,
      output_folder=output_folder
    )
    automl_bestModel.fit_ensemble(
      y_train.copy(),
      task=BINARY_CLASSIFICATION,
      metric=autosklearn.metrics.roc_auc
    )
    
    # refitting on the whole dataset
    automl_bestModel.refit(X_train.copy(), y_train.copy())
    automl_ensemble.refit(X_train.copy(), y_train.copy())
    
    # extracting the performances on test set
    automl_bestModel.target_type = 'multilabel-indicator'
    automl_ensemble.target_type = 'multilabel-indicator'
    predictions_bestModel = automl_bestModel.predict_proba(X_test.copy())
    predictions_ensemble = automl_ensemble.predict_proba(X_test.copy())
    
    # saving the results on file
    toSave = pandas.DataFrame({'outcome':y_test})
    toSave['prob_ensemble'] = predictions_ensemble[ : , 0]
    toSave['prob_bestModel'] = predictions_bestModel[ : , 0]
    toSave.to_csv('./tmp/results/' + training_set + '/holdoutRes.csv')
    
    # stopping counting the time
    end_time = time.time()
  
    # saving total time
    total_time = end_time - start_time
    time_file = open('./tmp/results/' + training_set + '/etime.txt',"w+")
    tmp = time_file.write('Total time in seconds: %d\n' % total_time)
    time_file.close()
  
  except Exception as e: 
    print(e)
    
  finally:
    
    # removing the tmp results folder
    shutil.rmtree(tmp_folder + '/.auto-sklearn/models')


# executing the script
if __name__ == '__main__':
  main(sys.argv[1:])
