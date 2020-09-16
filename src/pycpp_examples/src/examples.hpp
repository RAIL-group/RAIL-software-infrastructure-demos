#include <Eigen/Dense>

Eigen::Vector2d eval_mat_mul(Eigen::Matrix2d in_mat, Eigen::Vector2d in_vec) {
  return in_mat * in_vec;
}

double sqrt_sum_vec(const Eigen::VectorXd vec) {
  return vec.cwiseSqrt().sum();
}
