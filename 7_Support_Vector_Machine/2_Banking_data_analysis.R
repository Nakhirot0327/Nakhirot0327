#####2 Banking data analysis by SVM#####
#Set your own folder you put the data in
setwd("C:/Users/Hirotoshi/Documents/100_OTL/110_DSL/141122_DSL_Seminer/")

####2-1 Package install####
#install.packages("kernlab")
library(kernlab) #ksvm
#install.packages("dummies")
library(dummies)

####2-2 Data install & preparation####
data <- read.csv("bank.csv")
colnames(data) #2nd column is "campaign_result"
head(data)
#DATA DESCRIPTION (unit or category example is shown in paratheses)
#age: customer's age (years)
#occupation: customer's occupation
#(administrator:1, technician:2, management:3, blue collar:4, entrepreneur:5, student:6,
#services:7, unemployed:8, housemaid:10, self employed:11, retired:12, unknown:9)
#marriage: customer's marriage status (1=single, 2=marriage, 3=divorced, unknown:9)
#academic_background: customer's academic background (high-school:1, college:2, graduate-college:3, unknown:9)
#debt_default: customer has debt default whether or not (default:1, not:0)
#credit: customer's credit (yen)
#house_loan: customer has house loan whether or not (loan:1, not:0)
#personal_loan: customer has personal loan whether or not (loan:1, not:0)
#duration_time: duration time in last campaign (sec)
#contact_count: count to contact customer (count)
#previous_campaign: success of previous campaign (success:1, failure:2, other:3, unknown:9)

data <- data[,-1] #Delete the 1st column(id)

#Confrim the data type
for(i in 1:ncol(data)) {
  print(paste(i,colnames(data)[i],class(data[,i])))
}

#Change part of data from integer to factor
factor.num <- c(1,3,4,5,6,8,9,12)
for(i in factor.num) {
  data[,i] <- as.factor(data[,i])
}

y <- data[,1] #Extract the campaign result from the data
data <- dummy.data.frame(data) #make categorical variables to dummy variables

#Confrim the data type
for(i in 1:ncol(data)) {
  print(paste(i,colnames(data)[i],class(data[,i])))
}

#Reject 1st and 2nd columns because the columns are redundant
data <- data[,-(1:2)]

####2-3 Divide the data into train and test data####
set.seed(50)
trainNO <- sample(nrow(data),round(nrow(data)*0.80,0),replace=FALSE)
#replace=TRUE:Extract sample NO from uniform distribution of without replacement

#Divide the data into train data and test data
train_dat <- data[trainNO,]
test_dat <- data[-trainNO,]

train.x <- scale(as.matrix(train_dat))
train.y <- y[trainNO]
test.x <- scale(as.matrix(test_dat))
test.y <- y[-trainNO]

####2-4 Choose the parameters cost penalty C and standard deviation s####
C <- c(0.03,0.3,3,30)*100 #omit some of parameters because the class time is limited
s <- c(0.03,0.3,3,30)
cm <- NULL
accuracy <- matrix(0,ncol=length(C),nrow=length(s))
FPR <- matrix(0,ncol=length(C),nrow=length(s))
FNR <- matrix(0,ncol=length(C),nrow=length(s))
k <- 1
  
for(i in 1:length(C)) {
  for(j in 1:length(s)){
    rbfsvm <- ksvm(train.x,train.y,type="C-svc",
                   kernel="rbfdot",scale="FALSE",
                   C=C[i],kpar=list(sigma=s[j]))
    predicted <- predict(rbfsvm,test.x,type="response")
    cm[[k]] <- table(test.y, predicted)
    accuracy[i,j] <- sum(diag(cm[[k]]))/sum(cm[[k]]) #Accuracy
    FNR[i,j] <- cm[[k]][2,1]/sum(cm[[k]][2,]) #False negative rate (Rate of "1" in data predicted "0")
    FPR[i,j] <- cm[[k]][1,2]/sum(cm[[k]][1,]) #False positive rate (Rate of "0" in data predicted "1")
    print(paste("C =",C[i],"sigma =",s[j]))
    print(paste("Accuracy of the model is",round(accuracy[i,j],2)))
    print(paste("FNR of the model is",round(FNR[i,j],2)))
    print(paste("FPR of the model is",round(FPR[i,j],2)))
    k <- k + 1
  }
}

#Check accuracy, FNR and FPR by heatmap
colnames(accuracy) <- s
rownames(accuracy) <- C
colnames(FNR) <- s
rownames(FNR) <- C
colnames(FPR) <- s
rownames(FPR) <- C

library(gplots)
heatmap.2(accuracy,col = redgreen(256),dendrogram="none",Rowv = NA,Colv = NA,
          xlab="sigma",ylab="Cost parameter C",main="Accuracy")
heatmap.2(FNR,col = redgreen(256),dendrogram="none",Rowv = NA,Colv = NA,
          xlab="sigma",ylab="Cost parameter C",main="FNR")
heatmap.2(FPR,col = redgreen(256),dendrogram="none",Rowv = NA,Colv = NA,
          xlab="sigma",ylab="Cost parameter C",main="FPR")

op.row <- which(FNR==min(FNR),arr.ind=TRUE)[1,1]
op.col <- which(FNR==min(FNR),arr.ind=TRUE)[1,2]
op.C <- as.numeric(rownames(FNR)[op.row])
op.sigma <- as.numeric(colnames(FNR)[op.col])
#Choose C=300, sigma=0.03 to minimize FNR

####2-5 Set C=300 and sigma =0.03 and conduct SVM analysis####
rbfsvm <- ksvm(train.x,train.y, #Data
               type="C-svc",    #C-svc is classification svm
               kernel="rbfdot", #Kernel function(rbfdot means Gaussian Kernel)
               scale="FALSE",   #When data is sparse set "scale" FALSE
               C=op.C,           #Cost parameter
               kpar=list(sigma=op.sigma), #Standard deviation of Gaussian Kernel
               prob.model=TRUE) #When you want probability prediction set this TRUE

###Accuracy analysis###
#(A) Prediction based on test data
predicted <- predict(rbfsvm,test.x,type="response")

#(B) Mixing matrix
(cm <- table(test.y, predicted))

#Calucaltion of accracy of the model
(accuracyTraining <- sum(diag(cm))/sum(cm)) #Accuracy
(FPR <- cm[2,1]/sum(cm[2,])) #False negative rate (Rate of "1" in data predicted "0")
(FNR <- cm[1,2]/sum(cm[1,])) #False positive rate (Rate of "0" in data predicted "1")

#(C) HISTGRAM
#DEVIDE DATA BY evaluation VALUE (0 or 1)
test_dat <- cbind(test.x,test.y)
head(test_dat)

test_dat0 <- subset(test_dat, test.y==0)
test_dat1 <- subset(test_dat, test.y==1)

test.x_dat0 <- test_dat0[,-ncol(test_dat0)]
test.x_dat1 <- test_dat1[,-ncol(test_dat1)]

#PREDICT ON EACH DATA SET TO ADAPT fit2 MODEL
test_dat0$P <- predict(rbfsvm, newdata=test.x_dat0, type="prob") 
test_dat1$P <- predict(rbfsvm, newdata=test.x_dat1, type="prob")
#type="prob" OPTION IS TO PREDICT POSSIBILITY OF OBJECTIVE VARIABLES

#DRAW HISTGRAM
breaks <- seq(0,1,by=0.1)
head(test_dat1$P) #CONFIRM DATA TYPE
hist(test_dat1$P[,"1"], col = "#ff00ff40", border = "#ff00ff",
     xlab="possibility of success", xlim=c(0,1), ylim=c(0,1000),
     breaks=breaks,main="Possibility of campaign success in test data")
hist(test_dat0$P[,"1"], col = "#0000ff40", border = "#0000ff",add = TRUE,
     breaks=breaks)
legend("topright", legend=c("success", "failure"), fill=c("#ff00ff40","#0000ff40")) 
# #ff00ff40,#0000ff40 IS TRANSLUCENCE

##(D) ROC/AUC
#DRAW ROC CURVE test_dat USING PREDICTION RESULT
library(ROCR) #PACKAGE TO DRAW ROC CURVE
predicted.p <- predict(rbfsvm,test.x,type="prob")
predObj <- prediction(predicted.p[,2],test.y)
rocObj <- performance(predObj, measure="tpr", x.measure="fpr")
aucObj <- performance(predObj, measure="auc")
(auc <- aucObj@y.values[[1]])

plot(rocObj,main ="ROC curve", col="red")
par(new=T)
y <- function(x) x
plot(y ,0, 1, xlab="", ylab="")
legend("bottomright", legend=c("SVM"), col=c("red"), lty=c(1))

## (E) R-squared
library(polycor)
predicted.p_class <- predict(rbfsvm, newdata=test.x, type="response")

#Calculate correlation coefficient among categorical variables by using polychor function
R <- polychor(predicted.p_class, test.y, ML=TRUE)
#ML=maximally likelyfood
R_sq <- R^2 #CALCULATE R-SQUARED
sprintf("R: %4.3f, R^2: %4.3f", R, R_sq)  #PRINT R AND R-SQUARED