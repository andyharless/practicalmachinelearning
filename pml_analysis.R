# SCRIPT TO RUN PML ANALYSIS AND SAVE CONFUSION MATRICES FOR LATER REFERENCE
# (I didn't run this all at once the first time around.)

sink("pml_output.txt")


# READ AND PROCESS INPUT DATA

# Read in data.
library(readr)
pml_training <- read_csv("pml-training.csv")
data1 <- as.data.frame(pml_training)

# Most of the columns are summary statistics, which are NA for most individual rows.
# Get rid of them.
goodcols <- !is.na(data1[1,])
data1 <- data1[,goodcols]
pml_data <- data1[,8:ncol(data1)]

# Check for rows that still have missing data.
sum(is.na(pml_data))

# Not much remaining missing data, so let's just eliminate those cases.
goodrows = rowSums(is.na(pml_data))==0
pml = pml_data[goodrows,]
dim(pml)
head(pml)

# Divide data into training, cross-validation, and test sets
library("caret")
set.seed(999)
inTrain <- createDataPartition(y=pml$classe, p=0.8, list=FALSE)
training <- pml[inTrain,]
testing <- pml[-inTrain,]
inTrain1 <- createDataPartition(y=training$classe, p=0.75, list=FALSE)
train1 <- training[inTrain1,]
validate <- training[-inTrain1,]


# FIT THE MODELS ON THE INITIAL TRAINING SET

# Set up to run fits on multiple cores
library(parallel)
library(doParallel)
cluster <- makeCluster(detectCores() - 1) # convention to leave 1 core for OS
registerDoParallel(cluster)

# Train the models
modelnames = c("lda", "qda", "rda", "rf", "nnet", "pcaNNet", "AdaBag",
            "svmRadial", "multinom", "kknn")
modelfits = list()

for (m in modelnames) {
     print ( paste("Training model:", m) )
     fit <- train(classe ~., data=train1, method=m, 
                  preProcess="BoxCox", allowParallel=TRUE)
     modelfits = c(modelfits, list(fit))
}

# End parallel processing environment
stopCluster(cluster)
registerDoSEQ()

# Clean up environment
rm(data1)
rm(pml_data)
rm(pml_training)


# EVALUTE MODELS (INCLUDING "VOTED" MODEL) ON VALIDATION SET

# Predict for validation set
confuse <- list()
predicted <- list()
for (f in modelfits) {
    writeLines ( paste("\n\n\nPredicting validation set for model:", f[[1]]) )
    p <- predict(f, newdata=validate)
    predicted <- c(predicted, list(p))
    c <- confusionMatrix(p, validate$classe)
    print(c)
    confuse <- c(confuse, list(c))
}
kappas <- sapply(confuse, function(co) co[[3]]["Kappa"])
names(kappas) <- modelnames
names(confuse) <- modelnames
names(predicted) <- modelnames
bestmods <- names(sort(kappas,decreasing=TRUE)[1:3])
print(bestmods)  # 3 best models

# Calculate "voted" predictions, giving best model an extra tie-breaking vote.
choices = c()
m = length(validate$classe)
for (i in 1:m) {
    p1 <- unlist(predicted[bestmods[[1]]])[[i]]
    p2 <- unlist(predicted[bestmods[[2]]])[[i]]
    p3 <- unlist(predicted[bestmods[[3]]])[[i]]
    choice <- if (p3==p2) p2 else p1
    choices = c(choices, as.character(choice))
}
choices = as.factor(choices)
confuse_voted_1stpass = confusionMatrix(choices, validate$classe)
confuse_voted_1stpass
confuse["rf"]
# Here make a decision.
# The decision is to defer the "voted vs RF" decision to the next evaluation step.


# RE-FIT BEST MODELS INCLUDING ORIGINAL VALIDATION SET

# Set up to run fits on multiple cores
cluster <- makeCluster(detectCores() - 1) # convention to leave 1 core for OS
registerDoParallel(cluster)

# Go through the 3 best models and re-fit including original validation data
set.seed(998)
fits = list()
for (m in bestmods) {
  print ( paste("Training model:", m) )
  fit <- train(classe ~., data=training, method=m, 
               preProcess="BoxCox", allowParallel=TRUE)
  fits = c(fits, list(fit))
}

# End parallel processing environment
stopCluster(cluster)
registerDoSEQ()


# EVALUATE MODELS ON INITIAL TEST SET

# Predict for initial test set
conf <- list()
pred <- list()
for (f in fits) {
  writeLines ( paste("\n\n\nPredicting initial test set for model:", f[[1]]) )
  p <- predict(f, newdata=testing)
  pred <- c(pred, list(p))
  c <- confusionMatrix(p, testing$classe)
  print(c)
  conf <- c(conf, list(c))
}
bestkappas <- sapply(conf, function(co) co[[3]]["Kappa"])
names(bestkappas) <- bestmods
names(conf) <- bestmods
names(pred) <- bestmods

# Calculate "Voted" predictions for initial test set
voted = c()
m = length(testing$classe)
for (i in 1:m) {
    p1 <- unlist(pred[bestmods[[1]]])[[i]]
    p2 <- unlist(pred[bestmods[[2]]])[[i]]
    p3 <- unlist(pred[bestmods[[3]]])[[i]]
    choice <- if (p3==p2) p2 else p1
    voted = c(voted, as.character(choice))
}
voted = as.factor(voted)
confuse_voted_2ndpass = confusionMatrix(voted, testing$classe)
save( confuse, conf, confuse_voted_1stpass, confuse_voted_2ndpass, file="confusion.dat" )
confuse_voted_2ndpass
conf["rf"]
# Here make a decision.
# The decision is to use the RF model and throw out the others.


# FIT BEST MODEL ON FULL DATA SET

# Set up to run fits on multiple cores
library(parallel)
library(doParallel)
cluster <- makeCluster(detectCores() - 1) # convention to leave 1 core for OS
registerDoParallel(cluster)

# Fit the best model
fit <- train(classe ~., data=pml, method="rf", preProcess="BoxCox", allowParallel=TRUE)

# End parallel processing environment
stopCluster(cluster)
registerDoSEQ()


# GENERATE PREDICTIONS FOR UNLABELLED TEST DATA

# Read in unlabelled test cases.
pml_testing <- read_csv("pml-testing.csv")
data2 <- as.data.frame(pml_testing)

# Most of the columns are summary statistics, which are NA for most individual rows.
# Get rid of them.
goodcols <- !is.na(data2[1,])
data2 <- data2[,goodcols]
pml_testdata <- data2[,8:ncol(data2)]

# Predict the test cases
p <- predict(fit, newdata=pml_testdata)

sink()

# Got them all right, it turns out
print(p)
