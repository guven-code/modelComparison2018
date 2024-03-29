
#title: "GaussianNoises and Delta_LL of model comparison project"
#author: "e guven"
#date: "May 3, 2016"
#output: html_document


#EG started this on 20160403 
#how does the noise effect the loglikelihood 
#Weibull model->theta is a scale, gamma is a shape parameter >0
#Gompertz Model-> beta(G) is a scale, alpha(R) is a shape parameter>0 

#difference function of loglikelihood function of gompertz and weibull p.d.fs
#test if L(Weibull,X)>L(Gompertz,X) for parameters Weibull model->theta is a scale, gamma is a shape parameter >0
#Gompertz Model-> beta is a scale, alpha is a shape parameter>0 

#For additive Gaussian noise e ~ N (0, sigma^2) with known variance sigma^2
#sd of gaussian noise function
#max sd would be = 3*mean(inverse.gomp.CDF)
#min sd would be mean(inverse.gomp.CDF)



#fix the paramaters of weibull model

require(flexsurv)

gamma=0.01
theta=0.25
#test G and R in nested for loops
R=0.01
G=0.2
#R should be in [0, 0.05], and G should be [0.05, 0.3].  
N=2000 # population size


#rgompertz(alpha,beta,N) gives random Gompertz numbers from inverse CDF of Gompertz
#where alpha and beta are 2 parameters, N is number of population
#generate gompertz random numbers by using inverse CDF
#generate random number with a given distribution of Gompertz
#prediction





rgompertz = function(R,G, N){
  x.uniform = runif(N)
  #inverse of Gompertz CDF
  inverse.gomp.CDF = function(R,G,y) {  (1/G)*log(1 - (G/R)*log(1-y)  ) }
  x.gompertz = inverse.gomp.CDF(R,G, x.uniform)
  return(x.gompertz)
}




rweibull= function(theta,gamma,N)
{
  x.uniform= runif(n)
  inverse.wei.CDF=function(theta,gamma,y) { theta*(-log(1-y))^(1/gamma)}
  x.weibull=inverse.wei.CDF(theta,gamma,x.uniform)
  return(x.weibull)
}

#create a function that calculates noise of lifespan
calculate.noise = function(i){
  
  #lifespan
  gaussian<-rnorm(N, mean = 0, sd=i)
  #observation
  #X<- gompertz.random +gaussian to be used in simulation later.
  #noise
  noise=sd(gaussian)
  
  return(noise)
}




#put the variable values from loops into lists
sderr<- list()
Delta_LL<-list() 
G<-list()
R<-list()
LWei<-list()
LGomp<-list()
MeanLF<-list()
sdLS<-list()
Delta_LL.flex<-list()
LWei.flex<-list()
LGomp.flex<-list()
G.flex.estimated<-list()
R.flex.estimated<-list()
LLG.par<-list()
LLR.par<-list()
gamma.flex.estimated<-list()
theta.flex.estimated<-list()


  for (R_in in c(1E-3, 0.002,0.003, 0.005,0.008, 0.01,0.03, 0.05)){ #fix alpha or in other words R shape parameter
    for (G_in in c(0.05,0.08, 0.1,0.12,0.15,0.17, 0.2, 0.25)){
    #for (sd in seq(round.lifespan,3*round.lifespan,by=1)){
    for (i in c(0, 0.5, 1, 1.5, 2,3,4, 5)){ 
      #for (i in c(0)){ 
      
      #generate gompertz random numbers (lifespan) 
      #prediction
      set.seed(123)
      gompertz.random<-rgompertz(R_in,G_in,N)
      average.lifespan=mean(gompertz.random)
      
      #store average.lifespan into MeanLF list
      MeanLF[[length(MeanLF)+1]]=average.lifespan
      
      #check the sd by using calculate.noise() function
      sd.gaussian=calculate.noise(i)
      
      #generate gaussion random numbers 
      #rgompertz + rnorm(mean=0)*scale/average lifespan
      set.seed(123)
      gaussian<-rnorm(N, mean = 0, sd=i)
      
      #standard deviation of gompertz.random
      sd.lifespan=sd(gompertz.random)
      
      #store sd of lifespan into SdLS list
      sdLS[[length(sdLS)+1]] =sd.lifespan
      
      #add gaussian random numbers to gompertz random numbers
      #rgompertz + rnorm(mean=0)*scale/average lifespan
      scale=35;
      lifespan<- gompertz.random +gaussian*(scale/average.lifespan)
      #lifespan<- gompertz.random +gaussian*7
      summary(lifespan)
      lifespan[lifespan < 0] <- 0.01
      lifespan2=gompertz.random +rnorm(N,mean=2*average.lifespan,sd=i)/10
      summary(lifespan2)
      
      
      #Log likelihood function for the Weibull model
      
      weib.likl<-function(param,y){
        theta<- param[1] #take exponential to avoid NaNs when taking log(theta)
        gamma<- param[2] # avoid NaNs when taking log(gamma)
        delta=1; # delta is 1 for right censored data which is our case; lifespan>0
        y=lifespan[!is.na(lifespan)]
        
        logl<-sum(delta*(log(gamma) + gamma*log(theta) + (gamma-1)*log(y) -
                           (theta*y)^gamma )) -sum((1-delta)*(theta*y)^gamma)
        
        return(-logl)
      }
      # take log(param) since you take exponential above to avoid NaN values above
      weib=optim(c(0.03,0.001),weib.likl,y=lifespan)
      weib$value
      LWei[[length(LWei)+1]] = -weib$value
      
      
      
      gomp.likl <- function (param,y){
        
        G_in<-param[1]
        R_in<-param[2]
        delta=1
        y=lifespan[!is.na(lifespan)]
        logl<-sum(delta*(log(G_in)+R_in*y+(-(G_in/R_in)*(exp(R_in*y)-1)))) +
          sum((1-delta)*(-(G_in/R_in)*(exp(R_in*y)-1)))
        return(-logl)
      }
      gomp<-optim(c(G_in,R_in),gomp.likl,y=lifespan)
      #c(0.01,0.01) (best one)
      #c(0.025,0.03)
      #R should be in [0, 0.05], and G should be [0.05, 0.3].  
      
      gomp$value
      
      #store loglikelihood values of gompertz optimized results into LGomp list
      LGomp[[length(LGomp)+1]] = -gomp$value
      
      # store R and G estimation from optim of likl functions in Gompertz
      LLG.par[[length(LLG.par)+1]] =gomp$par[1]
      LLR.par[[length(LLR.par)+1]]=gomp$par[2]
      
      delta.likelihood.wei<- (-weib$value-(-gomp$value))
      
      #calculate LL and noise change
      sderr[[length(sderr)+1]] = i       
      Delta_LL[[length(Delta_LL)+1]] = delta.likelihood.wei
      G[[length(G)+1]]=G_in
      #switch to alpha.seq when for fixed beta
      R[[length(R)+1]]=R_in
      
      #todo use flexsurv to calculate the LL
      
      #flexsurv only works with positive variables.
      #fix gaussian std to 0
      
      set.seed(123)
      
      gaussian.flex= rnorm(N, mean = 0, sd=i)
      X.flex= gompertz.random +gaussian.flex*(scale/average.lifespan)
      #X.flex= gompertz.random +gaussian.flex*7
      
      X.flex[X.flex < 0] <- 0.01
      fitGomp = flexsurvreg(formula = Surv(X.flex) ~ 1, dist="gompertz")
      fitWei = flexsurvreg(formula = Surv(X.flex) ~ 1, dist="weibull")
      
      
      LWei.flex[[length(LWei.flex)+1]]=fitWei$loglik
      
      LGomp.flex[[length(LGomp.flex)+1]]=fitGomp$loglik
      
      param.Gomp<-fitGomp$res; R.flex<-param.Gomp[2]; G.flex<-param.Gomp[1];
      
      R.flex.estimated[[length(R.flex.estimated)+1]]<-R.flex
      G.flex.estimated[[length(G.flex.estimated)+1]]<-G.flex
      
      param.Wei<-fitWei$res; gamma.flex<-param.Wei[1]; theta.flex<-param.Wei[2];
      
      gamma.flex.estimated[[length(gamma.flex.estimated)+1]]<-gamma.flex; 
      theta.flex.estimated[[length(theta.flex.estimated)+1]]<-theta.flex
      
      delta_flexsurv=fitWei$loglik-fitGomp$loglik 
      
      #fitWei$loglik
      
      Delta_LL.flex[[length(Delta_LL.flex)+1]]=delta_flexsurv
      
    }
  }
}




results = data.frame(cbind(sderr), cbind(R),cbind(LLR.par),cbind(R.flex.estimated),cbind(G),cbind(LLG.par),cbind(G.flex.estimated),cbind(Delta_LL) , cbind(Delta_LL.flex),
                     cbind(LWei),cbind(LWei.flex), cbind(LGomp),cbind(LGomp.flex),cbind(MeanLF), cbind(sdLS))

results_mat<-as.matrix(results)

write.csv(results_mat,file="Results.csv")

#write.csv(results_mat,file="noise_zero.csv")

dLL<-unlist(results$Delta_LL )
dLL.flex<-unlist(results$Delta_LL.flex)
LLGomp<-unlist(results$LGomp)
LLGomp.flex<- unlist(results$LGomp.flex)
LLWei<- unlist(results$LWei)
LLWei.flex<- unlist(results$LWei.flex)
simulated.G<-unlist(results$G)
estimated.G.flex<-unlist(results$G.flex.estimated)
simulated.R<-unlist(results$R)
estimated.R.flex<-unlist(results$R.flex.estimated)

estimatedLL.G<-unlist(results$LLG.par)
estimatedLL.R<-unlist(results$LLR.par)


#LLGomp.flex
#delta.output<-data.frame(dLL,dLL.flex,LLGomp,LLGomp.flex,LLWei,LLWei.flex)

summary( lm( dLL~ dLL.flex))
summary( lm( LLGomp ~ LLGomp.flex))
summary( lm( LLWei ~ LLWei.flex))
summary(lm(simulated.G~estimated.G.flex))
summary(lm(simulated.R~estimated.R.flex))


pdf(paste("plots/","simulated.G.vs.estimated.G.flex.batch.pdf", sep=''), width=5, height=5)
plot(simulated.G~estimated.G.flex)
dev.off()

pdf(paste("plots/","simulated.R.vs.estimated.R.flex.batch.pdf", sep=''), width=5, height=5)
plot(simulated.R~estimated.R.flex)
dev.off()


results.sub<-data.frame(cbind(sderr),cbind(R),cbind(G),cbind(Delta_LL),cbind(Delta_LL.flex))


R.els = unlist( unique(results.sub$R))
colnum = length(R.els)

tmp = unlist( unique(results.sub$sderr))
noise.els = tmp[order(tmp)]
rownum = length(noise.els)

mat = matrix( data=NA, nrow= rownum, ncol=colnum) #noise as row, alpha as columns
rownames(mat) = noise.els
colnames(mat) = R.els
for (k in  c(0.05,0.08, 0.1,0.12,0.15,0.17, 0.2, 0.25)){
     
  #R in c(1E-3, 0.002, 0.005,0.008, 0.01,0.03, 0.05)
  data = results.sub[results.sub[,3]==k, 4]
  
  
  
  
  data<-unlist(data)
  
  heat_mat<-matrix(data,ncol=colnum,nrow=rownum)
  
  #rownames(heat_mat, do.NULL = TRUE, prefix = "row")
  rownames(heat_mat) <- c("0","0.5","1","1.5","2","3","4","5")
  
  colnames(heat_mat) <- R.els
  library(gplots)
  hM <- format(round(heat_mat, 0))
  #data_mat<-scale(heat_mat,scale=TRUE,center=FALSE)
  
  
  #paste(file = "~/github/model.comparison/plots/heatplot_zero_noise_G",k,".jpeg",sep="") 
  jpeg(paste("plots/",k, ".fixed.G.jpg", sep=''))
  
  #paste(“myplot_”, i, “.jpeg”, sep=””)
  
  heatmap.2(heat_mat, cellnote=hM,col = cm.colors(256), scale="none", notecol="black",  margins=c(5,10),
            dendrogram='none', Rowv=FALSE, Colv=FALSE,trace='none',
            xlab     = "R parameters",
            ylab     = "noise", main = bquote(paste("R vs. sd dLL at" ~ G==.(k))),par(cex.main=.5),srtCol=315, adjCol = c(0,1),cexRow=0.8,cexCol=0.8)
  
  
  dev.off()
  
}

G.els = unlist( unique(results.sub$G))
colnum = length(G.els)

R.els=unlist(unique(results.sub$R))
rownum = length(R.els)

mat = matrix( data=NA, nrow= rownum, ncol=colnum) #noise as row, alpha as columns
rownames(mat) = R.els
colnames(mat) = G.els
for (n in c(0, 0.5, 1,1.5,2,3,4,5) ){
#for (n in c(0)){
  data = results.sub[results.sub[,1]==n, 4]
  
  
  
  
  data<-unlist(data)
  
  heat_mat<-matrix(data,ncol=colnum,nrow=rownum)
  
  #rownames(heat_mat, do.NULL = TRUE, prefix = "row")
  rownames(heat_mat) <- R.els
  
  colnames(heat_mat) <- G.els
  library(gplots)
  hM <- format(round(heat_mat, 0))
  #data_mat<-scale(heat_mat,scale=TRUE,center=FALSE)
  
  
  #paste(file = "~/github/model.comparison/plots/heatplot_zero_noise_G",k,".jpeg",sep="") 
  jpeg(paste("plots/",n, ".fixed_noise.jpg", sep=''))
  
  #paste(“myplot_”, i, “.jpeg”, sep=””)
  
  heatmap.2(heat_mat, cellnote=hM,col = cm.colors(256), scale="none", notecol="black",  margins=c(5,10),
            dendrogram='none', Rowv=FALSE, Colv=FALSE,trace='none',
            xlab     = "R parameters",
            ylab     = "G parameters", main = bquote(paste("R vs G of dLL at" ~ sd==.(n))),par(cex.main=.5),srtCol=315, adjCol = c(0,1),cexRow=0.8,cexCol=0.8)
  
  
  dev.off()
  
}

G.els = unlist( unique(results.sub$G))
colnum = length(G.els)

tmp = unlist( unique(results.sub$sderr))
noise.els = tmp[order(tmp)]
rownum = length(noise.els)

mat = matrix( data=NA, nrow= rownum, ncol=colnum) #noise as row, alpha as columns
rownames(mat) = noise.els
colnames(mat) = G.els

#R should be in [0, 0.05], and G should be [0.05, 0.3].  
for (j in c(1E-3, 0.002, 0.003, 0.005,0.008, 0.01,0.03, 0.05) ){
  data = results.sub[results.sub[,2]==j, 4]
  
  
  
  
  data<-unlist(data)
  
  heat_mat<-matrix(data,ncol=colnum,nrow=rownum)
  
  #rownames(heat_mat, do.NULL = TRUE, prefix = "row")
  rownames(heat_mat) <- c("0","0.5","1","1.5","2","3","4","5")
  
  colnames(heat_mat) <- G.els
  library(gplots)
  hM <- format(round(heat_mat, 0))
  #data_mat<-scale(heat_mat,scale=TRUE,center=FALSE)
  
  
  #paste(file = "~/github/model.comparison/plots/heatplot_zero_noise_G",k,".jpeg",sep="") 
  jpeg(paste("plots/",j, ".fixed_R.jpg", sep=''))
  
  #paste(“myplot_”, i, “.jpeg”, sep=””)
  
  heatmap.2(heat_mat, cellnote=hM,col = cm.colors(256), scale="none", notecol="black",  margins=c(5,10),
            dendrogram='none', Rowv=FALSE, Colv=FALSE,trace='none',
            xlab     = "G parameters",
            ylab     = "noise", main = bquote(paste("G vs. sd of dLL at" ~ R==.(j))),par(cex.main=.5),srtCol=315, adjCol = c(0,1),cexRow=0.8,cexCol=0.8)
  
  
  dev.off()
  
}










