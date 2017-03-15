# Pracical Machine Learning Course Project
Andy Harless  
March 14, 2017  

# Human Activity Recognition: Weight Lifting


## Backgound

As described in [this paper](http://groupware.les.inf.puc-rio.br/public/papers/2013.Velloso.QAR-WLE.pdf), Velloso, Bulling, Gellersen, Ugulino, and Fuks built a data set of body sensor data for weight lifting exercises performed in various ways.  Lifters were asked to perform the exercise either correctly (label A) or with one of four common incorrect variations (labels B, C, D, and E).  The objective of this study is to predict the labels based on the sensor data in the data set.


## Initial Data Processing

Many of the columns in the data set refer to summary statistics which are available only once for each data collection window.  These statistics are also not present in the test cases provided for this course and thus would not be useful for this study.  Accordingly I deleted those columns from the training set.  Once those columns were deleted, there were only three pieces of data missing, and I deleted the cases that contained them.  The resulting set of training data had 19621 labelled observations of 52 potential predictor variables.  Lacking any particular substantive knowledge of the material, I decided, at least as a first cut, to use all 52 predictors without any feature-specific preprocessing.  For fitting purposes, I preprocessed all variables using the Box-Cox procedure, as offered via the "caret" R package.


```r
library(caret)
```

```
## Loading required package: lattice
```

```
## Loading required package: ggplot2
```

## Modeling and Cross-Validation Strategy

I modeled the data using a variety of approaches available in the "caret" R package.  I divided the data into three subsets:  an initial training set (60%), an initial validation set (20%), and a preliminary test set (20%).  The overall strategy was as follows:

1. Use initial training set to fit alternative models.

2. Compare models' performance on the validation set.

3. Combine the best performing models using a "weighted majority vote" strategy.

4. Re-fit the models on an augmented training set that includes the validation data.

5. Use the preliminary test set to estimate performance and to make a final model choice if not resolved in the previous step.

6. Re-fit the chosen model(s) to the entire data set to generate parameters for prediction on the unlabeled test cases.

It should be noted that many of the models available in the "caret" package do their own cross-validation during the fitting process, so there are several levels of cross-validation involved in the overall strategy described here.

## Choice of Models

I chose models according to the following criteria:

- Represent a broad variety of approaches.

- Canned version of model available in the "caret" package will run on this data set on my computer without major errors.

- Canned version trains in less than an hour on this data set on my computer (using 3 of the i7's 4 cores in parallel).

- Stuff that looked interesting.

- Random trial and error.

Here is the final list:

- Linear Discriminant Analysis ("lda"") 

- Quadratic Discriminant Analysis ("qda")

- Regularized Discriminant Analysis ("rda") 

- Random Forest ("rf") 

- Neural Network ("nnet")

- Neural Networks with Feature Extraction ("pcaNNet")

- Bagged AdaBoost ("AdaBag")

- Support Vector Machines with Radial Basis Function Kernel ("svmRadial")

- Penalized Multinomial Regression ("multinom") 

- k-Nearest Neighbors ("kknn")

There are numerous possibilities for tuning many of these models, but I didn't do any tuning.

## Files

I have placed all the code to run this project in a file called [pml_analysis.R](pml_analysis.R), which produces the output in [pml_output.txt](pml_output.txt) (as well as cut and pasted console messages in [pml_messages.txt](pml_messages.txt)).  It uses the input data in [pml-training.csv](pml-training.csv) and [pml-testing.csv](pml-testing.csv) and produces an output data file (not human readable) [confusion.dat](confusion.dat), which I will use in presenting my results.  The full analysis took about 3 hours to run on my 2013-vintage MacBook Pro (with a QuadCore i7 chip).

## Results

On the initial validation data, some of the models performed well, and some didn't.  Here's what the kappa statistics look like for the 10 models, in decreasing order.


```r
load("confusion.dat")
kappas <- sapply(confuse, function(co) co[[3]]["Kappa"])
names(kappas) <- names(confuse)
print(sort(kappas,decreasing=TRUE))
```

```
##        rf      kknn svmRadial       qda       rda       lda   pcaNNet 
## 0.9883902 0.9813012 0.9011796 0.8697797 0.8697797 0.6131210 0.5663629 
##  multinom    AdaBag      nnet 
## 0.5413663 0.2229744 0.0000000
```

The two most successful models, Random Forest and k-Nearest Neighbors, performed almost unbelievably well, and the Support Vector Machine model also performed very well.  The Quadratic Discriminant Analysis model also performed well.  (It appears from the more detailed results, available in [pml_output.txt](pml_output.txt), that the Regularized Discriminant Analysis has selected an exactly equivalent model.)

I combined the 3 best-performing models in a "weighted majority vote" setup which chooses any label with 2 votes and allows the Random Forest model to break ties (i.e., when all three disagree).  On the initial validation set, the performance of the combined model was as follows:


```r
print(confuse_voted_1stpass)
```

```
## Confusion Matrix and Statistics
## 
##           Reference
## Prediction    A    B    C    D    E
##          A 1116    6    0    0    0
##          B    0  749    3    0    0
##          C    0    4  679   16    5
##          D    0    0    0  626    4
##          E    0    0    2    1  712
## 
## Overall Statistics
##                                           
##                Accuracy : 0.9895          
##                  95% CI : (0.9858, 0.9925)
##     No Information Rate : 0.2845          
##     P-Value [Acc > NIR] : < 2.2e-16       
##                                           
##                   Kappa : 0.9868          
##  Mcnemar's Test P-Value : NA              
## 
## Statistics by Class:
## 
##                      Class: A Class: B Class: C Class: D Class: E
## Sensitivity            1.0000   0.9868   0.9927   0.9736   0.9875
## Specificity            0.9979   0.9991   0.9923   0.9988   0.9991
## Pos Pred Value         0.9947   0.9960   0.9645   0.9937   0.9958
## Neg Pred Value         1.0000   0.9968   0.9984   0.9948   0.9972
## Prevalence             0.2845   0.1935   0.1744   0.1639   0.1838
## Detection Rate         0.2845   0.1909   0.1731   0.1596   0.1815
## Detection Prevalence   0.2860   0.1917   0.1795   0.1606   0.1823
## Balanced Accuracy      0.9989   0.9929   0.9925   0.9862   0.9933
```

This is not clearly better than the performance of the Random Forest model alone:

```r
print(confuse["rf"])
```

```
## $rf
## Confusion Matrix and Statistics
## 
##           Reference
## Prediction    A    B    C    D    E
##          A 1116    7    0    0    0
##          B    0  750    4    0    0
##          C    0    2  677   12    4
##          D    0    0    3  630    3
##          E    0    0    0    1  714
## 
## Overall Statistics
##                                           
##                Accuracy : 0.9908          
##                  95% CI : (0.9873, 0.9936)
##     No Information Rate : 0.2845          
##     P-Value [Acc > NIR] : < 2.2e-16       
##                                           
##                   Kappa : 0.9884          
##  Mcnemar's Test P-Value : NA              
## 
## Statistics by Class:
## 
##                      Class: A Class: B Class: C Class: D Class: E
## Sensitivity            1.0000   0.9881   0.9898   0.9798   0.9903
## Specificity            0.9975   0.9987   0.9944   0.9982   0.9997
## Pos Pred Value         0.9938   0.9947   0.9741   0.9906   0.9986
## Neg Pred Value         1.0000   0.9972   0.9978   0.9960   0.9978
## Prevalence             0.2845   0.1935   0.1744   0.1639   0.1838
## Detection Rate         0.2845   0.1912   0.1726   0.1606   0.1820
## Detection Prevalence   0.2863   0.1922   0.1772   0.1621   0.1823
## Balanced Accuracy      0.9988   0.9934   0.9921   0.9890   0.9950
```

However, it's not really fair to compare an alternative procedure with the best performing single model on the same data set where it has just shown itself to be the best performing single model.  Also, the combined model is (slightly) better at distinguishing Class A from the other classes.  They got the same number of true positives but RF has one more false positive.  This is important because A vs. the other classes represents "the right way" vs. "the wrong way" of performing the exercise.  Presumably we care more about "right way" vs. "wrong way" than about "Which wrong way?"  So I gave the combined model one more chance on the preliminary test set.

Here is the preliminary test set performance of the combined model (using fits that include the validation data):


```r
print(confuse_voted_1stpass)
```

```
## Confusion Matrix and Statistics
## 
##           Reference
## Prediction    A    B    C    D    E
##          A 1116    6    0    0    0
##          B    0  749    3    0    0
##          C    0    4  679   16    5
##          D    0    0    0  626    4
##          E    0    0    2    1  712
## 
## Overall Statistics
##                                           
##                Accuracy : 0.9895          
##                  95% CI : (0.9858, 0.9925)
##     No Information Rate : 0.2845          
##     P-Value [Acc > NIR] : < 2.2e-16       
##                                           
##                   Kappa : 0.9868          
##  Mcnemar's Test P-Value : NA              
## 
## Statistics by Class:
## 
##                      Class: A Class: B Class: C Class: D Class: E
## Sensitivity            1.0000   0.9868   0.9927   0.9736   0.9875
## Specificity            0.9979   0.9991   0.9923   0.9988   0.9991
## Pos Pred Value         0.9947   0.9960   0.9645   0.9937   0.9958
## Neg Pred Value         1.0000   0.9968   0.9984   0.9948   0.9972
## Prevalence             0.2845   0.1935   0.1744   0.1639   0.1838
## Detection Rate         0.2845   0.1909   0.1731   0.1596   0.1815
## Detection Prevalence   0.2860   0.1917   0.1795   0.1606   0.1823
## Balanced Accuracy      0.9989   0.9929   0.9925   0.9862   0.9933
```

Compare the performance of the Random Forest model alone:


```r
print(conf["rf"])
```

```
## $rf
## Confusion Matrix and Statistics
## 
##           Reference
## Prediction    A    B    C    D    E
##          A 1113    4    0    0    0
##          B    1  754    4    0    0
##          C    1    1  679    2    1
##          D    0    0    1  640    0
##          E    0    0    0    1  720
## 
## Overall Statistics
##                                           
##                Accuracy : 0.9959          
##                  95% CI : (0.9934, 0.9977)
##     No Information Rate : 0.2843          
##     P-Value [Acc > NIR] : < 2.2e-16       
##                                           
##                   Kappa : 0.9948          
##  Mcnemar's Test P-Value : NA              
## 
## Statistics by Class:
## 
##                      Class: A Class: B Class: C Class: D Class: E
## Sensitivity            0.9982   0.9934   0.9927   0.9953   0.9986
## Specificity            0.9986   0.9984   0.9985   0.9997   0.9997
## Pos Pred Value         0.9964   0.9934   0.9927   0.9984   0.9986
## Neg Pred Value         0.9993   0.9984   0.9985   0.9991   0.9997
## Prevalence             0.2843   0.1935   0.1744   0.1639   0.1838
## Detection Rate         0.2838   0.1922   0.1731   0.1632   0.1836
## Detection Prevalence   0.2848   0.1935   0.1744   0.1634   0.1838
## Balanced Accuracy      0.9984   0.9959   0.9956   0.9975   0.9992
```

Both perform excellently, but this seems to be an unambiguous win for the Random Forest model alone.  No need to waste time fitting the other models if they don't help.  (One might consider investigating whether a 4-model ensemble, with much more weight given to the Random Forest model, might perform better still, but I didn't do that.)

With 99.6% accuracy, the Random Forest model produced classification results that could be characterized as nearly perfect.  Allowing for the remaining degree of freedom on the preliminary test set (i.e. the choice between the Random Forest model and the combined model), I'd expect about 99% accuracy (mirroring the combined model's performance here) on any subsequent test data.
