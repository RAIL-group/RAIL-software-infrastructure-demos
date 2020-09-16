import numpy as np
import pycpp_examples
from pytest import approx
import time


def main():
    """Show how PyBind works with vectors/lists.
    Generates random data and sqrt-sum's in different ways."""

    # Generate some random data
    N = 5000000
    print(f"PyBind Demo: taking the sqrt & summing {N} elements.")
    vec = np.random.random(N)

    start = time.time()
    sum_np = np.sqrt(vec).sum()
    print(f"  Numpy Sum Time: {time.time() - start}")

    start = time.time()
    sum_cpp_eigen = pycpp_examples.sqrt_sum_vec(vec)
    print(f"  C++ Eigen Sum Time: {time.time() - start}")

    # Convert to a vector
    vec = list(vec)

    start = time.time()
    sum_loop = 0
    for v in vec:
        sum_loop += np.sqrt(v)
    print(f"  Python loop sum time: {time.time() - start}")

    start = time.time()
    sum_cpp_vec = pycpp_examples.sqrt_sum_vec(vec)
    print(f"  C++ vector sum time: {time.time() - start}")

    start = time.time()
    vec = np.array(vec)
    sum_np_from_vec = np.sqrt(vec).sum()
    print(f"  Numpy-from-vector sum time: {time.time() - start}")

    assert sum_np == approx(sum_cpp_eigen)
    assert sum_np == approx(sum_loop)
    assert sum_np == approx(sum_cpp_vec)
    assert sum_np == approx(sum_np_from_vec)


if __name__ == "__main__":
    main()
