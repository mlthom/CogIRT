#' Simulated Data for a Signal Detection IRT Model
#'
#' Data and parameters were simulated based on the example provided in the
#' sim_dich_response.R function. This dataset is for a sample size of 50.
#'
#' @format A list with the following elements:
#' \describe{
#'   \item{y}{Matrix of dichotomous responses.}
#'   \item{ystar}{Matrix of latent response variates.}
#'   \item{nu}{Mean of the item intercept parameters (scalar).}
#'   \item{lambda}{Matrix of item structure parameters.}
#'   \item{gamma}{Matrix of experimental structure parameters.}
#'   \item{omega}{Subject-level effects of the experimental manipulation.}
#'   \item{zeta}{Condition-level prediction errors.}
#'   \item{omega_mu}{Vector of means for the subject-level effects of the
#' experimental manipulation (1 by K * M).}
#'   \item{omega_sigma2}{Covariance matrix for the subject-level effects of the
#' experimental manipulation (K * M by K * M).}
#'   \item{zeta_mu}{Vector of means for the condition-level prediction errors
#' (1 by J * M).}
#'   \item{zeta_sigma2}{Covariance matrix for the condition-level prediction
#' errors (J * M by J * M).}
#'   ...
#' }
"sdirt"

#' Simulated Data for a Signal Detection IRT Model (Single Subject)
#'
#' Data and parameters were simulated based on the example provided in the
#' sim_dich_response.R function. This data set is for a sample size of 1.
#'
#' @format A list with the following elements:
#' \describe{
#'   \item{y}{Matrix of dichotomous responses.}
#'   \item{ystar}{Matrix of latent response variates.}
#'   \item{nu}{Mean of the item intercept parameters (scalar).}
#'   \item{lambda}{Matrix of item structure parameters.}
#'   \item{gamma}{Matrix of experimental structure parameters.}
#'   \item{omega}{Subject-level effects of the experimental manipulation.}
#'   \item{zeta}{Condition-level prediction errors.}
#'   \item{omega_mu}{Vector of means for the subject-level effects of the
#' experimental manipulation (1 by K * M).}
#'   \item{omega_sigma2}{Covariance matrix for the subject-level effects of the
#' experimental manipulation (K * M by K * M).}
#'   \item{zeta_mu}{Vector of means for the condition-level prediction errors
#' (1 by J * M).}
#'   \item{zeta_sigma2}{Covariance matrix for the condition-level prediction
#' errors (J * M by J * M).}
#'   ...
#' }
"sdirtSS"
