data {
  int<lower=1> N;                       // Number of observations
  array[N] int<lower=0> behavior_count;       // Outcome variable (behavior count)
  int<lower=1> K_mu;                    // Number of fixed effect parameters for the mean model
  matrix[N, K_mu] X_mu;                 // Design matrix for the mean model (mu)
  int<lower=1> J_calf;                  // Number of unique calves (calfID)
  array[N] int<lower=1, upper=J_calf> calfID; // Index for calfID random effect
  int<lower=1> T_max;                   // Number of unique timepoints
  array[N] int<lower=1, upper=T_max> timepoint_f; // Index for timepoint factor (for random effect structure)
  array[T_max] real times; 
}

parameters {
  vector[K_mu] beta_mu;                 // Fixed effects for the mean model
  
  // Zero-Inflation Model Parameters
  real phi;                        // Intercept for the zero-inflation probability (logit scale)
  
  // Random Effects Parameters (CalfID)
  // Corresponds to toep(timepoint + 0 | calfID)
  // This is a vector of random intercepts, one per calf, *at each timepoint*.
  // It's structured as a matrix: J_calf rows (calves) x T_max columns (timepoints).
  // The columns are NOT independent; their covariance is Toeplitz.
  matrix[J_calf, T_max] z;
  
  // Toeplitz Covariance Parameters (for the random effects structure)
  real<lower=0> sigma_calf;             // Standard deviation of the random effects
  real<lower=-1, upper=1> rho_toep;     // Autoregressive/Correlation parameter for Toeplitz structure
}

transformed parameters {
  // Linear predictor for the Poisson mean (log scale)
  vector[N] log_lambda = X_mu * beta_mu;
  
  // Add random effects
  for (n in 1:N) {
    log_lambda[n] = log_lambda[n] + z[calfID[n], timepoint_f[n]];
  }
}

model {
  // --- Priors ---
  
  // Fixed effects
  beta_mu ~ normal(0, 5);           // Weakly informative prior
  
  // Zero-inflation intercept
  phi ~ beta(1, 1);          // Prior for logit(phi)
  
  sigma_calf ~ gamma(2, 1);        // Prior for standard deviation
  rho_toep ~ normal(0, 0.5);        // Prior for correlation (truncated by bounds)
  
  // Toeplitz covariance matrix
  matrix[T_max, T_max] Sigma_T;
  for (i in 1:T_max) {
    for (j in 1:T_max) {
      Sigma_T[i, j] = sigma_calf^2 * pow(rho_toep, abs(times[i] - times[j]));
    }
  }
  
  // Put a multivariate normal prior on the random effects (z) for each calf
  for (j in 1:J_calf) {
    // Each row of 'z' (i.e., the T_max observations for a single calf)
    // is drawn from a MVN with the Toeplitz covariance structure.
    z[j, ] ~ multi_normal(rep_vector(0, T_max), Sigma_T);
  }
  
  // Zero-Inflated Poisson
  
  // The zero-inflated Poisson likelihood for each observation
  for (n in 1:N) {
    // Convert logit_phi and log_lambda to their natural scales
    real lambda = exp(log_lambda[n]);
    
    if (behavior_count[n] == 0) {
      // P(y=0) = phi + (1-phi) * P(Poisson(lambda)=0)
      target += log_sum_exp(bernoulli_logit_lpmf(1 | phi),
                            bernoulli_logit_lpmf(0 | phi) + poisson_log_lpmf(0 | log_lambda[n]));
    } else {
      // P(y>0) = (1-phi) * P(Poisson(lambda)=y)
      target += bernoulli_logit_lpmf(0 | phi) + poisson_log_lpmf(behavior_count[n] | log_lambda[n]);
    }
  }
}
