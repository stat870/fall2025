data {
  int<lower=0> N;
  vector[N] W;
  vector[N] y;
}

parameters {
  real alpha;
  real beta;
  real<lower=0> sigma;
}

model {
  alpha ~ normal(50, 10);
  beta ~ normal(1, 2);
  sigma ~ gamma(10,2);
  for (i in 1:N){
    y[i] ~ normal(alpha * W[i]^beta, sigma);
    }
}

