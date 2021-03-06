rm(list=ls(all=TRUE))
set.seed(454)

source("fn-density.R")

den <- read.table("pdensity.dat", header=TRUE)
N <- nrow(den)

pdf("dat.pdf")
plot(den[, 2], den[, 3])

par(mfrow=c(2,2))
for(i in 1:10)
{
    ind <- (1:N)[den[,1]==i]
    plot(den[ind, 2], den[ind, 3])
}
dev.off()

### preparing data
mydat <- NULL
mydat$X <- as.matrix(cbind(den$density, (den$density)^2))
mydat$y <- den$yield
mydat$I <- 10
mydat$J <- 8
mydat$plot <- den$plot
mydat$IJ <- mydat$I*mydat$J
mydat$sum_x2 <- sum(mydat$X[,2])
mydat$sum_x4 <- sum((mydat$X[,2])^2)

#### fixed hyperparameters
hyper <- NULL
hyper$a_sig <- 0.1
hyper$b_sig <- 0.1
hyper$a_t0 <- 0.1
hyper$b_t0 <- 0.1
hyper$v2_0 <- 100
hyper$tau2_1 <- 100
hyper$tau2_2 <- 100

### initialize the chain - used OLS estimates
cur_sam <- NULL
cur_sam$sig2 <- (0.9822)^2
cur_sam$b0 <- rep(2.86875, mydat$I)
cur_sam$b1 <- 1.85485
cur_sam$b2 <- -0.15925
cur_sam$mu0 <- 0
cur_sam$tau2_0 <- 1

### MCMC parameters
N_burn <- 3000
N_sam <- 5000
MCMC_sam <- NULL
MCMC_sam$sig2 <- MCMC_sam$b1 <- MCMC_sam$b2 <- MCMC_sam$tau2_0 <- MCMC_sam$mu0 <- rep(0, N_sam)
MCMC_sam$b0 <- array(NA, dim=c(N_sam, mydat$I))

### for burn-in
for(i_iter in 1:N_burn)
{
    cur_sam$sig2 <- fn.update.sig2(mydat, cur_sam$b0, cur_sam$b1, cur_sam$b2, hyper$a_sig, hyper$b_sig )
    cur_sam$tau2_0 <- fn.update.tau2.0(hyper$a_t0, hyper$b_t0, cur_sam$b0, cur_sam$mu0, mydat$I)
    cur_sam$b0 <- fn.update.b0(mydat, cur_sam$sig2, cur_sam$tau2_0, cur_sam$mu0, cur_sam$b1, cur_sam$b2)
    cur_sam$b1 <- fn.update.b1(mydat, cur_sam$sig2, hyper$tau2_1, cur_sam$b0, cur_sam$b2)
    cur_sam$b2 <- fn.update.b2(mydat, cur_sam$sig2, hyper$tau2_2, cur_sam$b0, cur_sam$b1)
    cur_sam$mu0 <- fn.update.mu0(mydat$I, cur_sam$tau2_0, hyper$v2_0, cur_sam$b0)
} ## for(i_iter in 1:N_burn)

### after burn-in
for(i_iter in 1:N_sam)
{
    cur_sam$sig2 <- fn.update.sig2(mydat, cur_sam$b0, cur_sam$b1, cur_sam$b2, hyper$a_sig, hyper$b_sig )
    cur_sam$tau2_0 <- fn.update.tau2.0(hyper$a_t0, hyper$b_t0, cur_sam$b0, cur_sam$mu0, mydat$I)
    
    cur_sam$b0 <- fn.update.b0(mydat, cur_sam$sig2, cur_sam$tau2_0, cur_sam$mu0, cur_sam$b1, cur_sam$b2)
    
    cur_sam$b1 <- fn.update.b1(mydat, cur_sam$sig2, hyper$tau2_1, cur_sam$b0, cur_sam$b2)
    cur_sam$b2 <- fn.update.b2(mydat, cur_sam$sig2, hyper$tau2_2, cur_sam$b0, cur_sam$b1)
    
    cur_sam$mu0 <- fn.update.mu0(mydat$I, cur_sam$tau2_0, hyper$v2_0, cur_sam$b0)
    
    MCMC_sam$sig2[i_iter] <- cur_sam$sig2
    MCMC_sam$b1[i_iter] <- cur_sam$b1
    MCMC_sam$b2[i_iter] <- cur_sam$b2
    MCMC_sam$tau2_0[i_iter] <- cur_sam$tau2_0
    MCMC_sam$mu0[i_iter] <- cur_sam$mu0
    MCMC_sam$b0[i_iter, ] <- cur_sam$b0
} ## for(i_iter in 1:N_sam)



pdf("para.pdf")
par(mfrow=c(2,2))
hist(MCMC_sam$sig2)
hist(MCMC_sam$b1)
hist(MCMC_sam$b2)

hist(MCMC_sam$mu0)

hist(MCMC_sam$tau2_0)

for(i in 1:mydat$I)
{
    hist(MCMC_sam$b0[,i], main=i)
}
dev.off()


b0_hat <- apply(MCMC_sam$b0, 2, mean)
b0_1 <- apply(MCMC_sam$b0, 2, quantile, 0.025)
b0_2 <- apply(MCMC_sam$b0, 2, quantile, 0.975)

cbind(b0_1, b0_hat, b0_2)


tmp <- lm(mydat$y ~ 1 + mydat$X)


x <- 8

pdf("pred-8.pdf")
par(mfrow=c(2,2))
for(i in 1:mydat$I)
{
    y1 <- rnorm(N_sam, MCMC_sam$b0[,i] + MCMC_sam$b1*x + MCMC_sam$b2*(x^2), sqrt(MCMC_sam$sig2))
    hist(y1)
    qq <- mydat$y[(mydat$X[,1]==x)&(mydat$plot==i)]
    points(qq, c(0, length(qq)), cex=4, pch=3, col=2, lwd=3)
}
dev.off()




