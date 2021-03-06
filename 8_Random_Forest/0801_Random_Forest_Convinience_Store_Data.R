#####1 Convenience data analysis by RF#####
#Set your own folder you put the data in
setwd("C:/Users/Hirotoshi/Documents/100_OTL/110_DSL/141220_DSL_Seminer/")

####1-1 Package install####
#install.packages("randomForest")
library(randomForest)

####1-2 Data install & preparation####
data <- read.csv("convenience-store.csv")
colnames(data) 
head(data) #2nd column is "evaluation"
#DATA DESCRIPTION (unit is shown in paratheses)
#ealuation: when this value equals "1", it is a store whose revenue is increased. Otherwise when this value is "0", a store's revenue is decreased
#carSpace: car parking space (cars)
#floorSpace: floor space in store (meter^2)
#storeFrontTraffic: traffic in front of store (persons/day)
#frontage: frontage of store (meter)

data <- data[,-1] #Delete the 1st column(NO)

#Confrim the data type
for(i in 1:ncol(data)) {
  print(paste(i,colnames(data)[i],class(data[,i])))
}

y <- data[,1] #Extract the campaign result from the data
y <- as.factor(y)

#Confrim the data type
for(i in 1:ncol(data)) {
  print(paste(i,colnames(data)[i],class(data[,i])))
}

data <- data[,-1] #Delete the 1st column because the column is redundant

####1-3 Divide the data into train and test data####
set.seed(50)
trainNO <- sample(nrow(data),round(nrow(data)*0.50,0),replace=FALSE)
#replace=TRUE:Extract sample NO from uniform distribution of without replacement

#Divide the data into train data and test data
train_dat <- data[trainNO,]
test_dat <- data[-trainNO,]

train.x <- train_dat
train.y <- y[trainNO]
test.x <- test_dat
test.y <- y[-trainNO]

####1-4 Choose the parameters(mtry and ntree)####
ntree <- seq(50,500,by=50)
mtry <- c(2:ncol(data))
cm <- NULL
accuracy <- matrix(0,nrow=length(ntree),ncol=length(mtry))
FPR <- matrix(0,nrow=length(ntree),ncol=length(mtry))
FNR <- matrix(0,nrow=length(ntree),ncol=length(mtry))
k <- 1

for(i in 1:length(ntree)) {
  for(j in 1:length(mtry)){
    set.seed(50)
    train.rf <- randomForest(x=train.x,y=train.y,ntree=ntree[i],mtry=mtry[j])
    predicted <- predict(train.rf,test.x)
    cm[[k]] <- table(test.y, predicted)
    if(ncol(cm[[k]])==1) {
      cm[[k]] <- cbind(cm[[k]],rep(0,2))
    }
    if(nrow(cm[[k]])==1) {
      cm[[k]] <- rbind(cm[[k]],rep(0,2))
    }
    accuracy[i,j] <- sum(diag(cm[[k]]))/sum(cm[[k]]) #Accuracy
    FNR[i,j] <- cm[[k]][2,1]/sum(cm[[k]][2,]) #False negative rate (Rate of "1" in data predicted "0")
    FPR[i,j] <- cm[[k]][1,2]/sum(cm[[k]][1,]) #False positive rate (Rate of "0" in data predicted "1")
    print(paste("Mtry =",mtry[i],"Number of trees =",ntree[j]))
    print(paste("Accuracy of the model is",round(accuracy[i,j],2)))
    print(paste("FNR of the model is",round(FNR[i,j],2)))
    print(paste("FPR of the model is",round(FPR[i,j],2)))
    k <- k + 1
  }
}

#Check accuracy, FNR and FPR by heatmap
rownames(accuracy) <- ntree
colnames(accuracy) <- mtry
rownames(FNR) <- ntree
colnames(FNR) <- mtry
rownames(FPR) <- ntree
colnames(FPR) <- mtry

library(gplots)
heatmap.2(accuracy,col = redgreen(256),dendrogram="none",Rowv = NA,Colv = NA,
          xlab="Number of variables",ylab="Number of trees",main="Accuracy")
heatmap.2(FNR,col = redgreen(256),dendrogram="none",Rowv = NA,Colv = NA,
          xlab="Number of variables",ylab="Number of trees",main="FNR")
heatmap.2(FPR,col = redgreen(256),dendrogram="none",Rowv = NA,Colv = NA,
          xlab="Number of variables",ylab="Number of trees",main="FPR")

op.row <- which(accuracy==max(accuracy),arr.ind=TRUE)[1,1]
op.col <- which(accuracy==max(accuracy),arr.ind=TRUE)[1,2]
op.ntree <- as.numeric(rownames(accuracy)[op.row])
op.mtry <- as.numeric(colnames(accuracy)[op.col])
#Choose ntree=50, mtry=2 to maximize accuracy

####1-5 Set ntree=50 and mtry=2 and conduct RF analysis####
set.seed(50)
rf <- randomForest(x=train.x,y=train.y,
                   ntree=op.ntree,  #Number of trees
                   mtry=op.mtry,    #Number of variables
                   prob.model=TRUE) #When you want probability prediction set this TRUE

###Accuracy analysis###
#(A) Prediction based on test data
predicted1 <- predict(rf,test.x,type="prob")
predicted2 <- predict(rf,test.x,type="response")

#(B) Mixing matrix
(cm <- table(test.y, predicted2))

#Calucaltion of accracy of the model
(accuracyTraining <- sum(diag(cm))/sum(cm)) #Accuracy
(FNR <- cm[2,1]/sum(cm[2,])) #False negative rate (Rate of "1" in data predicted "0")
(FPR <- cm[1,2]/sum(cm[1,])) #False positive rate (Rate of "0" in data predicted "1")

#(C) HISTGRAM
#DEVIDE DATA BY evaluation VALUE (0 or 1)
test_dat <- cbind(test.x,test.y)
head(test_dat)

test_dat0 <- subset(test_dat, test.y==0)
test_dat1 <- subset(test_dat, test.y==1)

test.x_dat0 <- test_dat0[,-ncol(test_dat0)]
test.x_dat1 <- test_dat1[,-ncol(test_dat1)]

#PREDICT ON EACH DATA SET TO ADAPT fit2 MODEL
test_dat0$P <- predict(rf, newdata=test.x_dat0, type="prob") 
test_dat1$P <- predict(rf, newdata=test.x_dat1, type="prob")
#type="prob" OPTION IS TO PREDICT POSSIBILITY OF OBJECTIVE VARIABLES

#DRAW HISTGRAM
breaks <- seq(0,1,by=0.1)
head(test_dat1$P) #CONFIRM DATA TYPE
hist(test_dat1$P[,"1"], col = "#ff00ff40", border = "#ff00ff",
     xlab="possibility of success", xlim=c(0,1), ylim=c(0,10),
     breaks=breaks,main="Possibility of success in test data")
hist(test_dat0$P[,"1"], col = "#0000ff40", border = "#0000ff",add = TRUE,
     breaks=breaks)
legend("topright", legend=c("success", "failure"), fill=c("#ff00ff40","#0000ff40")) 
# #ff00ff40,#0000ff40 IS TRANSLUCENCE

##(D) ROC/AUC
#DRAW ROC CURVE test_dat USING PREDICTION RESULT
library(ROCR) #PACKAGE TO DRAW ROC CURVE
predicted.p <- predict(rf,test.x,type="prob")
predObj <- prediction(predicted.p[,2],test.y)
rocObj <- performance(predObj, measure="tpr", x.measure="fpr")
aucObj <- performance(predObj, measure="auc")
(auc <- aucObj@y.values[[1]])

plot(rocObj,main ="ROC curve", col="red")
par(new=T)
y <- function(x) x
plot(y ,0, 1, xlab="", ylab="")
legend("bottomright", legend=c("Random forest"), col=c("red"), lty=c(1))

## (E) R-squared
library(polycor)
predicted.p_class <- predict(rf, newdata=test.x, type="response")

#Calculate correlation coefficient among categorical variables by using polychor function
R <- polychor(predicted.p_class, test.y, ML=TRUE)
#ML=maximally likelyfood
R_sq <- R^2 #CALCULATE R-SQUARED
sprintf("R: %4.3f, R^2: %4.3f", R, R_sq)  #PRINT R AND R-SQUARED

## (F) Variable of Importance
varImpPlot(rf,main="Variable importance") #Variable Improtance‚ÌƒOƒ‰ƒt
