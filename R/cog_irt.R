#-------------------------------------------------------------------------------
#' Fit Item Response Theory Models With or Without a Design Matrix
#'
#' This function estimates item response theory (IRT) model parameters. Users
#' can optionally choose to request estimates of person parameters representing
#' effects of the experimental contrast.
#'
#' @param data a matrix of item responses (K by IJ). Rows should contain
#' dichotomous responses (1 or 0) for the items indexed by each column.
#' @param model an IRT model name. The options are "1p" for the one-parameter
#' model, "2p" for the two parameter model, "3p" for the three-parameter, or
#' "sdt" for a signal detection-weighted model.
#' @param guessing either a single numeric guessing value or a matrix of item
#' guessing parameters (IJ by 1). This argument is only used when model = '3p'.
#' @param contrast_codes either a matrix of experimental structure parameters
#' (JM by MN) or the name in quotes of a R stats contrast function (i.e.,
#' "contr.helmert", "contr.poly", "contr.sum", "contr.treatment", or
#' "contr.SAS"). If using the R stats contrast function items in the data matrix
#' must be arranged by condition.
#' @param num_conditions the number of conditions (required if using the R stats
#' contrast function or when constraints = TRUE).
#' @param num_contrasts the number of contrasts including intercept (required if
#' using the R stats contrast function or when constraints = TRUE).
#' @param constraints either a logical (TRUE or FALSE) indicating that item
#' parameters should be constrained to be equal over the J conditions or a 1 by
#' I vector of items that should be constrained to be equal across conditions.
#' @param key an item key vector where 1 indicates target and 2 indicates
#' distractor (IJ). Required when model = 'sdt'.
#' @param link the name ("logit" or "probit") of the link function to be used in
#' the model.
#' @param ... additional arguments.
#'
#' @section Dimensions:
#' I = Number of items per condition; J = Number of conditions; K = Number of
#' examinees; M Number of ability (or trait) dimensions; N Number of contrasts
#' (should include intercept).
#'
#' @return List with elements for all parameters estimated, information values
#' for all parameters estimated, and the model log-likelihood value.
#'
#' @references
#' Embretson S. E., & Reise S. P. (2000). \emph{Item response theory for
#' psychologists.} Mahwah, N.J.: L. Erlbaum Associates.
#' Thomas, M. L., Brown, G. G., Patt, V. M., & Duffy, J. R. (2021). Latent
#' variable modeling and adaptive testing for experimental cognitive
#' psychopathology research.  \emph{Educational and Psychological Measurement,
#' 81}(1), 155-181.
#'
#' @examples
#'
#' oneparamfit <- cog_irt(data = ex1$y, model = "1p")
#' summary(oneparamfit)
#'
#' twoparamfit <- cog_irt(data = ex1$y, model = "2p")
#' summary(twoparamfit)
#'
#' threeparamfit <- cog_irt(data = ex1$y, model = "3p", guessing = .25)
#' summary(threeparamfit)
#'
#' lrt(oneparamfit, twoparamfit, threeparamfit)
#'
#' plot(twoparamfit)
#' plot(ex1$omega[, 1], twoparamfit$omega1[, 1])
#' abline(a = 0, b = 1)
#'
#' twoparamfitconstr <- cog_irt(data = ex4$y, model = '2p', contrast_codes =
#'                             "contr.treatment", num_conditions = 2,
#'                             num_contrasts = 2, constraints = TRUE)
#' summary(twoparamfitconstr)
#' plot(twoparamfitconstr)
#'
#' # Alternative way to specify constraints
#' constraints <- matrix(data = c(1,2, 0, 0, 0, 0, 0, 0, 0, 0), nrow = 1,
#'                  ncol = ncol(x = ex4$y) / 3)
#' twoparamfitconstr <- cog_irt(data = ex4$y, model = '2p',
#'                              contrast_codes = "contr.treatment",
#'                              num_conditions = 2, num_contrasts = 2,
#'                              constraints = constraints)
#'
#' # Real data example
#' sdirt <- cog_irt(data = sternberg$y, model = "sdt", key = sternberg$key)
#'
#' @export cog_irt
#-------------------------------------------------------------------------------

cog_irt <- function(data = NULL, model = NULL, guessing = NULL,
                    contrast_codes = NULL,  num_conditions = NULL,
                    num_contrasts = NULL, constraints = NULL, key = NULL,
                    link = "probit", ...) {
  y <- data
  if (is.null(x = model)) {
    stop("'model' argument not specified.",
         call. = FALSE)
  }
  if (! model %in% c("1p", "2p", "3p", "sdt")) {
    stop("'model' argument is not correctly specified.",
         call. = FALSE)
  }
  if (model == "3p" && is.null(guessing)) {
    stop("'model' = '3p' but 'guessing' is NULL.",
         call. = FALSE)
  }
  if (model != "3p" && !is.null(guessing)) {
    message("'model' is not '3p'. 'guessing' argument is ignored")
    guessing <- NULL
  }
  if (model %in% c("1p", "2p", "3p") && !is.null(x = key)) {
    message("'model' is not 'sdt'. 'key' argument is ignored")
  }
  if (model == "sdt") {
    if (is.null(x = key)) {
      stop("'model' sdt specified but key argument is missing.",
           call. = FALSE)
    }
    if (ncol(x = y) != length(x = key)) {
      stop("Key length does not match the number of columns in data.",
           call. = FALSE)
    }
  }
  if (model %in% c("2p", "3p")) {
    if (!is.null(x = num_conditions)) {
      if (num_conditions > 1) {
        if (is.null(x = constraints)) {
          stop("'constraints' must be TRUE when model is '2p' or '3p' and
               'num_conditions' > 1", call. = FALSE)
        } else if(is.logical(x = constraints)){
          if (constraints == FALSE) {
            stop("'constraints' must be TRUE when model is '2p' or '3p' and
               'num_conditions' > 1", call. = FALSE)
          }
        }
      }
    }
  }
  if (!is.null(num_conditions)) {
    J <- num_conditions
  } else {
    J <- 1
  }
  if (J == 1) I <- ncol(x = y) else I <- ncol(x = y) / J
  if (I %% 1 != 0) {
    stop("Number of items in y must be a multiple of J.",
         call. = FALSE)
  }
  if (!is.null(num_contrasts)) {
    N <- num_contrasts
  } else {
    N <- 1
  }
  ellipsis <- list(...)
  K <- nrow(x = y)
  if (model == "sdt") M <- 2 else M <- 1
  if (is.null(x = ellipsis$lambda0)) {
    lambda0 <- matrix(data = 0, nrow = I * J, ncol = J * M)
    if (model == "1p") {
      for (j in 1:J) {
        lambda0[(1 + (j - 1) * I):(j * I), (1 + (j - 1) * M):(j * M)] <- 1
      }
    } else if (model %in% c("2p", "3p")) {
      for (j in 1:J) {
        lambda0[(1 + (j - 1) * I):(j * I), (1 + (j - 1) * M):(j * M)] <- apply(
          X = y,
          MARGIN = 2,
          FUN = function(x) {
            cor(x = jitter(x),
                y = jitter(rowMeans(x = y, na.rm = TRUE)))
          }
        )[(1 + (j - 1) * I):(j * I)]
      }
      lambda0 <- lambda0 / sqrt(1 - (lambda0 ^ 2)) * ifelse(link == "logit",
                                                            yes = 1.0, no = 1.7)
    } else if (model == "sdt") {
      measure_weights <-
        matrix(data = c(0.5, -1.0, 0.5, 1.0), nrow = 2, ncol = M, byrow = TRUE)
      for (j in 1:J) {
        lambda0[(1 + (j - 1) * I):(j * I), (1 + (j - 1) * M):(j * M)] <-
          measure_weights[key, ][(1 + (j - 1) * I):(j * I), ]
      }
    }
  } else {
    lambda0 <- ellipsis$lambda0
    ellipsis <- ellipsis[-1 * which(x = names(x = ellipsis) == "lambda0")]
  }
  if (!is.null(x = contrast_codes)) {
    if (contrast_codes %in% c("contr.helmert", "contr.poly", "contr.sum",
                              "contr.treatment", "contr.SAS")) {
      codes <- cbind(1, get(x = contrast_codes)(n = J))[, 1:N]
      tmp <- matrix(data = 0, nrow = J * M, ncol = M * N)
      for (j in 1:J) {
        for (m in 1:M) {
          tmp[(m + M * (j - 1)), (((m - 1) * N + 1):((m - 1) * N + N))] <-
            codes[j, ]
        }
      }
      gamma0 <- tmp
    }
  } else {
    gamma0 <- diag(x = 1, nrow = J * M, ncol = M * N)
  }
  if (is.null(x = ellipsis$omega0)) {
    X <- t(t(gamma0) %*% t(lambda0))
    omega0 <- matrix(
      data = apply(X = y, MARGIN = 1, FUN = function(Y) {
        suppressWarnings(
          glm(formula = Y ~ 0 + X, family = binomial(link = link))$coefficients
        )
      }),
      nrow = K,
      ncol = M * N,
      byrow = TRUE
    )
    omega0 <- abs(x = omega0)^(1 / 2) * sign(x = omega0)
  } else {
    omega0 <- ellipsis$omega0
    ellipsis <- ellipsis[-1 * which(x = names(x = ellipsis) == "omega0")]
  }
  zeta0 <- array(data = 0, dim = c(K, J * M))
  if (is.null(x = ellipsis$nu0)) {
    nu0 <-  t(array(data = scale(x = colMeans(x = y, na.rm = TRUE)),
                    dim = c(1, I * J)))
  } else {
    nu0 <- ellipsis$nu0
    ellipsis <- ellipsis[-1 * which(x = names(x = ellipsis) == "nu0")]
  }
  if (model == "3p") {
    if (length(x = guessing) == 1) {
      kappa0 <- array(data = guessing, dim = c(I * J, 1))
    } else {
      kappa0 <- kappa0
    }
  } else {
    kappa0 <- array(data = 0, dim = c(I * J, 1))
  }
  if (is.null(x = ellipsis$omega_mu)) {
    omega_mu <- array(colMeans(x = omega0), dim = c(1, M * N))
  } else {
    omega_mu <- ellipsis$omega_mu
    ellipsis <- ellipsis[-1 * which(x = names(x = ellipsis) == "omega_mu")]
  }
  if (is.null(x = ellipsis$omega_sigma2)) {
    omega_sigma2 <- diag(x = c(5), nrow = M * N, ncol = M * N)
  } else {
    omega_sigma2 <- ellipsis$omega_sigma2
    ellipsis <- ellipsis[-1 * which(x = names(x = ellipsis) == "omega_sigma2")]
  }
  if (N > 1) {
    zeta_mu <- matrix(data = rep(x = 0, times = M * J), nrow = 1, ncol = J * M)
    zeta_sigma2 <- diag(x = .1, nrow = J * M, ncol = J * M)
  } else {
    zeta_mu <- NULL
    zeta_sigma2 <- NULL
  }
  if (is.null(x = ellipsis$lambda_mu)) {
    lambda_mu <- matrix(data = 0, nrow = 1, ncol = J * M)
  } else {
    lambda_mu <- ellipsis$lambda_mu
    ellipsis <- ellipsis[-1 * which(x = names(x = ellipsis) == "lambda_mu")]
  }
  if (is.null(x = ellipsis$lambda_sigma2)) {
    lambda_sigma2 <- diag(x = 2, nrow = J * M)
  } else {
    lambda_sigma2 <- ellipsis$lambda_sigma2
    ellipsis <- ellipsis[-1 * which(x = names(x = ellipsis) == "lambda_sigma2")]
  }
  if (is.null(x = ellipsis$nu_mu)) {
    nu_mu <- matrix(data = 0)
  } else {
    nu_mu <- ellipsis$nu_mu
    ellipsis <- ellipsis[-1 * which(x = names(x = ellipsis) == "nu_mu")]
  }
  if (is.null(x = ellipsis$nu_sigma2)) {
    nu_sigma2 <- matrix(data = 1)
  } else {
    nu_sigma2 <- ellipsis$nu_sigma2
    ellipsis <- ellipsis[-1 * which(x = names(x = ellipsis) == "nu_sigma2")]
  }
  if (is.null(x = ellipsis$est_omega)) {
    est_omega <- TRUE
  } else {
    est_omega <- ellipsis$est_omega
    ellipsis <- ellipsis[-1 * which(x = names(x = ellipsis) == "est_omega")]
  }
  if (is.null(x = ellipsis$est_lambda)) {
    if (model %in% c("2p", "3p")) {
      est_lambda <- TRUE
    } else {
      est_lambda <- FALSE
    }
  } else {
    est_lambda <- ellipsis$est_lambda
    ellipsis <- ellipsis[-1 * which(x = names(x = ellipsis) == "est_lambda")]
  }
  if (is.null(x = ellipsis$est_nu)) {
    est_nu <- TRUE
  } else {
    est_nu <- ellipsis$est_nu
    ellipsis <- ellipsis[-1 * which(x = names(x = ellipsis) == "est_nu")]
  }
  if (is.null(x = ellipsis$est_zeta)) {
    if (N > 1) {
      est_zeta <- TRUE
    } else {
      est_zeta <- FALSE
    }
  } else {
    est_zeta <- ellipsis$est_zeta
    ellipsis <- ellipsis[-1 * which(x = names(x = ellipsis) == "est_zeta")]
  }
  if (is.null(x = ellipsis$chains)) {
    chains <- 1
  } else {
    chains <- ellipsis$chains
    ellipsis <- ellipsis[-1 * which(x = names(x = ellipsis) == "chains")]
  }
  if (is.null(x = constraints)) {
    constraints <- NULL
  } else {
    if (is.logical(x = constraints)) {
      if (constraints == TRUE) {
        constraints <- matrix(data = 0, nrow = 1, ncol = I * J)
        for (j in 1:J) {
          for (i in 1:I) {
            constraints[i + I * (j - 1)] <- i
          }
        }
      } else {
        constraints <- NULL
      }
    } else {
      constraints <- matrix(data = rep(x = constraints, J), nrow = 1,
                            ncol = I * J)
    }
    uniq_constr <- unique(x = c(apply(X = constraints,
                                      MARGIN = 1,
                                      FUN = function(x) {
                                        x[x != 0]
                                      })))
    mat1 <- matrix(data = 0, nrow = length(x = uniq_constr), ncol = I * J)
    for (i in uniq_constr) {
      mat1[i, which(constraints == i)] <- i
    }
    mat2 <- matrix(data = 0, nrow = I * J, ncol = I * J)
    for (i in uniq_constr) {
      for (ii in seq_len(length.out = ncol(x = mat1))) {
        if (constraints[ii] == i) {
          mat2[which(constraints == i), ii] <- 1 / sum(constraints == i)
        }
      }
    }
    diag(x = mat2)[which(x = diag(x = mat2) == 0)] <- 1
    mat3 <- matrix(data = 0, nrow = length(x = uniq_constr) * M,
                   ncol = I * J * J * M)
    for (m in 1:M) {
      for (i in uniq_constr) {
        mat3[
          m + (i - 1) * M,
          seq(i, I * J * J * M, M * I * J) + I * J * (m - 1) + ((1:J) - 1) * I
        ] <- m + (i - 1) * M
      }
    }
    uniq_mat3 <- unique(x = c(apply(X = mat3, MARGIN = 1, FUN = function(x) {
      x[x != 0]
    })))
    mat4 <- matrix(data = 0, nrow = I * J * J * M, ncol = I * J * J * M)
    for (j in 1:J) {
      for (m in 1:M) {
        diag(mat4)[(1:I) + (m - 1) * (I * J) +
                     (j - 1) * (I * J * M) + (j - 1) * I] <- 1
      }
    }
    for (ii in seq_len(length.out = ncol(x = mat3))) {
      for (i in uniq_mat3) {
        if (any(mat3[, ii] == i)) {
          mat4[
            ii,
            mat3[which(mat3[, ii] == i), ] != 0
          ] <- 1 / sum(mat3 == i)
        }
      }
    }
    constraints <- list(mat1, mat2, mat3, mat4)
  }
  tmp_res <- do.call("mhrm", c(list(
    chains = chains,
    y = y,
    obj_fun = dich_response_model,
    link = link,
    est_omega = est_omega,
    est_lambda = est_lambda,
    est_zeta = est_zeta,
    est_nu = est_nu,
    omega0 = omega0,
    gamma0 = gamma0,
    lambda0 = lambda0,
    zeta0 = zeta0,
    nu0 = nu0,
    kappa0 = kappa0,
    omega_mu = omega_mu,
    omega_sigma2 = omega_sigma2,
    zeta_mu = zeta_mu,
    zeta_sigma2 = zeta_sigma2,
    lambda_mu = lambda_mu,
    lambda_sigma2 = lambda_sigma2,
    nu_mu = nu_mu,
    nu_sigma2 = nu_sigma2,
    constraints = constraints,
    J = J,
    M = M,
    N = N),
    ellipsis
  ))

  tmp_omega_deriv <- deriv_omega(
    y = y,
    omega = if (est_omega) tmp_res$omega1 else omega0,
    gamma = gamma0,
    lambda = if (est_lambda) tmp_res$lambda1 else lambda0,
    zeta = zeta0,
    nu = if (est_nu) tmp_res$nu1 else nu0,
    kappa = kappa0,
    omega_mu = omega_mu,
    omega_sigma2 = omega_sigma2,
    est_zeta = FALSE,
    link = link
  )

  tmp_nu_deriv <- deriv_nu(
    y = y,
    omega = if (est_omega) tmp_res$omega1 else omega0,
    gamma = gamma0,
    lambda = if (est_lambda) tmp_res$lambda1 else lambda0,
    zeta = zeta0,
    nu = if (est_nu) tmp_res$nu1 else nu0,
    kappa = kappa0,
    nu_mu = nu_mu,
    nu_sigma2 = nu_sigma2,
    link = link
  )

  tmp_lambda_deriv <- deriv_lambda(
    y = y,
    omega = if (est_omega) tmp_res$omega1 else omega0,
    gamma = gamma0,
    lambda = if (est_lambda) tmp_res$lambda1 else lambda0,
    zeta = zeta0,
    nu = if (est_nu) tmp_res$nu1 else nu0,
    kappa = kappa0,
    lambda_mu = lambda_mu,
    lambda_sigma2 = lambda_sigma2,
    link = link
  )

  par <- (K * M * N) +
    ifelse(
      test = est_nu == TRUE,
      yes = if (is.null(x = constraints)) {
        I * J
      } else {
        length(x = unique(x = constraints[[2]][which(
          constraints[[2]] != 0,
          arr.ind = TRUE
        )]))
      },
      no = 0
    ) + ifelse(
      test = est_lambda == TRUE,
      yes = if (is.null(x = constraints)) {
        I * J
      } else {
        length(x = unique(x = constraints[[2]][which(constraints[[2]] != 0,
                                                     arr.ind = TRUE)]))
      },
      no = 0
    )

  return(
    structure(.Data = list(
      "omega1" = if (est_omega) tmp_res$omega1 else omega0,
      "info1_omega" = tmp_omega_deriv$post_info,
      "nu1" = if (est_nu) tmp_res$nu1 else nu0,
      "info1_nu" = tmp_nu_deriv$post_info,
      "lambda1" = if (est_lambda) tmp_res$lambda1 else lambda0,
      "info1_lambda" = tmp_lambda_deriv$post_info,
      "log_lik" = tmp_res$log_lik,
      "y" = y,
      "par" = par
    ),
    class = c(model, "cog_irt")
    )
  )
}
