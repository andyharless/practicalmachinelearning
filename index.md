# Pracical Machine Learning Course Project
Andy Harless  
March 14, 2017  

#Practical Machine Learning Course Project


##Backgound

As described in [this paper](http://groupware.les.inf.puc-rio.br/public/papers/2013.Velloso.QAR-WLE.pdf), Velloso, Bulling, Gellersen, Ugulino, and Fuks built a dataset of body sensor data for weight lifting exercises performed in various ways.  Weight lifters were asked to perform the exercise either correctly (label A) or with one of four specific common incorrect variations (labels B, C, D, and E).  The objective of this study is to predict the labels based on the sensor data in their data set.


##Initial Data Processing

Many of the columns in the data set refer to summary statistics which are available only once for each data collection window.  These statistics are also not present in the test cases provided for this course and thus would not be useful for this study.  Accordingly I deleted those columns from the training set.  Once those columns were deleted, there were only three pieces of data missing, and I deleted the cases that contained them.  The resulting set of training data had 19621 labelled observations of 52 potential predictor variables.  Lacking any particular substantive knowledge of the material, I decided, at least as a first cut, to use all 52 predictors without any feature-specific preprocessing.  For fitting purposes, I preprocessed all variables using the Box-Cox procedure, as performed via the Caret R package.

## Modeling and Cross-Validation Strategy

I modeled the data using a variety of approaches availble in the Caret R package.  I divided the data into three subsets:  an initial training set (60%), an initial validation set (20%), and a preliminary test set (20%).  The overall strategy was as follows:

1. Use initial training set to fit alternative models.

2. Compare models' performance on the validation set.

3. Combine the best performing models using a "weighted majority vote" strategy.

4. Re-fit the models on an augmented training set that includes the validation data.

5. Use the prelminary test set to estimate performance and to make a final model choice if not resolved in the previous step.

6. Re-fit the chosen model(s) to the entire data set to generate parameters for prediction on the unlabelled test cases.

It should be noted that many of the models available in the Caret package do their own cross-validation during the fitting process, so there are several levels of cross-validation involved in the overall strategy described here.

## Choice of Models

I chose some models...



# Other Stuff to Be Deleted Later







Read more: http://groupware.les.inf.puc-rio.br/har#ixzz4bLdgilO7
The goal of this project is to predict 



I've done the substance of the project, but now I have to write it up,
which probably means redoing much of it.  Maybe I can get away with not
rerunning stuff that takes hours to run while monopolizing 3 of the 4 cores
in my i7?  Maybe?

Anyhow, what follows is the default Rmd document created by RStudio.



## R Markdown

This is an R Markdown document. Markdown is a simple formatting syntax for authoring HTML, PDF, and MS Word documents. For more details on using R Markdown see <http://rmarkdown.rstudio.com>.

When you click the **Knit** button a document will be generated that includes both content as well as the output of any embedded R code chunks within the document. You can embed an R code chunk like this:


```r
summary(cars)
```

```
##      speed           dist       
##  Min.   : 4.0   Min.   :  2.00  
##  1st Qu.:12.0   1st Qu.: 26.00  
##  Median :15.0   Median : 36.00  
##  Mean   :15.4   Mean   : 42.98  
##  3rd Qu.:19.0   3rd Qu.: 56.00  
##  Max.   :25.0   Max.   :120.00
```

## Including Plots

You can also embed plots, for example:

![](index_files/figure-html/pressure-1.png)<!-- -->

Note that the `echo = FALSE` parameter was added to the code chunk to prevent printing of the R code that generated the plot.
