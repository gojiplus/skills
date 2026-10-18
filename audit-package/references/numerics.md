# Hand-rolled numerics, solvable programs, and copies

A package that writes its own version of a classical algorithm owns every bug in
it, and its tests usually check the version against itself. In one calibration
package, three private copies of pool-adjacent-violators lived side by side. One
expanded pooled blocks by their weight instead of their element count, which
corrupted every grouped-ties result and a public baseline. The test suite passed
throughout, because nothing compared those copies with an implementation they
did not share. The same package solved four convex programs with home-made
iterations, which stopped short of their optima while reporting convergence.

## Inventory what the package implements itself

List every algorithm the package computes with its own loop: isotonic
regression, simplex projection, root-finding and line search, IPF or Sinkhorn
scaling, proximal operators, and any `for it in range(max_iter)` or `while not
converged` that updates parameters. For each, ask in order:

1. **Is there a maintained implementation?** Check the version that introduced
   it, and raise the dependency floor to match. For example,
   `scipy.optimize.isotonic_regression` arrived in SciPy 1.12; confirm by
   importing it under the floor version, not from memory. Other common ones:
   `brentq`/`root_scalar`, `minimize_scalar`, `linear_sum_assignment`, `lsqr`,
   `np.linalg.lstsq`, and sklearn's `IsotonicRegression`.
2. **Is the loop solving an optimization problem that a solver can take
   whole?** Least squares, quadratic programs, hinge penalties and KL
   objectives with linear constraints are standard conic programs. Clarabel
   (QP, second-order and exponential cones) or a cvxpy formulation solves them
   to interior-point precision in one call, without step sizes, iteration caps
   or convergence heuristics.
3. **Is the private copy correct, merely slower, or wrong?** Measure it; the
   three outcomes need different responses.

## Evidence: oracle, profile, cap

- **Oracle.** Solve the same problem with something that shares no code with
  the package, usually cvxpy, and compare. Compare **objective values**, not
  only argmins: when the optimum is flat, the matrix is pinned only to roughly
  the square root of the solver's tolerance, so a 1e-5 difference in the
  solution can sit alongside a 1e-10 difference in the objective. When the
  oracle itself reports `optimal_inaccurate`, check its feasibility before
  trusting its lower objective; an infeasible point can look better.
- **Limiting cases.** A penalty weight of 0 should reproduce the unpenalized
  projection (for KL with row and column sums, that is IPF). A large weight
  should reproduce the hard-constrained solution. A slack of 0 should equal
  the strict problem.
- **Profile.** Find where the time goes before claiming a speed-up. In one
  package, a pure-Python PAV took 98% of a solver's runtime; scipy's was 150x
  faster per call with identical output.
- **Iteration caps.** A result that reaches `max_iters` at realistic sizes is
  a finding even when the output looks plausible. Record the objective gap to
  the oracle at the cap.

## Legitimate reasons to keep a private implementation

Keep a private implementation, with a comment at the definition that names the
reason, when:

- the maintained one cannot express the problem: weights spanning e^-760
  underflow as floats and need log-domain pooling, and scipy's PAVA rejects
  zero weights;
- the algorithm is the package's contribution, such as an exact O(n) dynamic
  program from the method's paper, or an online update rule that is the
  estimator itself;
- the problem is non-convex or combinatorial, and the loop is a documented
  heuristic rather than a stand-in for a solver.

"It was quicker to write" is not a reason. Neither is avoiding a dependency the
package already has.

## Duplicates

Run pylint's similarity checker (`pylint --disable=all --enable=duplicate-code
--min-similarity-lines=12 --ignore-imports=y --ignore-docstrings=y
--ignore-comments=y --ignore-signatures=y`) over package code. ruff has no
duplicate detector. At 12 lines the hits sampled across a 47-repository fleet
were all real copies; at 6, about half the fleet flagged boilerplate. pylint
reports a duplicate under whichever module it read last, so locate it by the two
blocks named in the message, not by its file and line. Three copies of one
algorithm is where the weights bug lived.

## Testing the replacement

- Pin the replacement to an independent oracle, never to the implementation it
  replaced. A test comparing a scipy wrapper with scipy cannot fail.
- Size threshold tests with literal values, not offsets from the constant under
  test: a test written as `threshold + 2` follows any change to the threshold.
- Mutation checks that edit and restore a source file must run with
  `PYTHONDONTWRITEBYTECODE=1`, or delete `__pycache__` after restoring. A
  same-length edit restored within the same second leaves stale bytecode
  running, and the correct code then appears to fail.
