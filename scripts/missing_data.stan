data {
  int<lower=0> N;
  int<lower=0> W_num_missing;
  vector[N] W;
  vector[N] y;
  array[N] int W_missing;
}

parameters {
  real alpha;
  real beta;
  real<lower=0> sigma;
  vector[W_num_missing] W_impute;
  real mu_W;
  real<lower=0> sigma_W;
}

model {
  vector[N] W_merged;
  alpha ~ normal(50, 10);
  beta ~ normal(1, 2);
  sigma ~ gamma(10,2);
  
  mu_W ~ normal(10, 6);
  sigma_W ~ gamma(4, 1);
  
  
  for (i in 1:N) {
    W_merged[i] = W[i];
    if ( W_missing[i] > 0 ) W_merged[i] = W_impute[W_missing[i]];
    }
    // imputation
    W_merged ~ normal(mu_W, sigma_W);
    for (i in 1:N){
      y[i] ~ normal(alpha * W_merged[i]^beta, sigma);
      }
}

