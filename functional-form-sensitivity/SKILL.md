---
name: functional-form-sensitivity
description: Bound how far an estimate can move under other functional forms that fit the data as well as the assumed one, with the DirectedSensitivity workflow. Use for demand, welfare, or structural estimates.
compatibility: Needs a local coding agent with git, Python 3.11+, and network access to github.com. Not runnable from an uploaded zip without network or over the MCP connector.
metadata:
  upstream: https://github.com/JMSLab/DirectedSensitivity
  upstream-license: MIT
---

# Functional form sensitivity

An estimate such as consumer surplus often rests on an assumed functional form
(linear demand, exponential durations). This skill answers: among all functions
in a wider class the user accepts, which fit the data at least as well as the
assumed one, how far can the estimate move up and down?

The method is Andrews, Essig Aberg and Shapiro, "An LLM Workflow for Functional
Form Sensitivity Analysis" (NBER w35947, 2026). Their repository supplies the
procedure (`workflow/WORKFLOW.md`) and a Python package that checks every
answer. This skill sets it up, frames the problem with the user, runs their
procedure unchanged, and checks the result by a second route.

## Vocabulary

- **Working model**: the assumed form, e.g. linear demand. Finite-dimensional.
- **Nesting model**: the wider class of functions the user accepts as
  economically possible, e.g. any continuous decreasing demand curve.
- **Object of interest** `c`: the number reported, e.g. consumer surplus.
- **Criterion** `q`: the fit measure the estimator minimizes; lower is better.
- **Budget**: the working model's best fit. A function is feasible when its fit
  is within budget and it lies in the nesting model.
- **Certificate**: a specific feasible function and its value of `c`. Reported
  bounds are certificates, so each one is an achievable value, not a guess.

## When not to use

- Sampling uncertainty. The bounds are in-sample; they say nothing about
  standard errors.
- Choosing covariates or samples. That is specification search, not functional
  form.
- No explicit fit criterion. Without `q` there is no budget; build one first
  (`design-analysis`) or stop.

## Setup

Pinned to commit `ebd0e8c3cd19b79a9090e9a97f91a788f3d8a01a` (2026-10-14). The
package is not on PyPI. Tell the user you are installing the authors' package
from GitHub at that commit, then install the clone into the project's own
environment:

```sh
DS=~/.cache/directed-sensitivity/ebd0e8c
test -d "$DS" || git clone https://github.com/JMSLab/DirectedSensitivity "$DS"
git -C "$DS" checkout -q ebd0e8c3cd19b79a9090e9a97f91a788f3d8a01a
uv pip install --python .venv/bin/python "$DS"   # the project's own venv
.venv/bin/python -c "import DirectedSensitivity"
```

Read every file under `$DS/workflow/` and `$DS/AGENTS.md` from that clone. The
procedure links to them by relative path; resolve those links inside `$DS`.

## Steps

1. **Fill the template with the user.** Copy `$DS/workflow/TEMPLATE.md` to
   `sensitivity/<name>/filled_template.md` in the project. Draft sections 2
   (working model), 3 (object), 4 (criterion) and 6 (locations) from the
   user's code and paper; these are facts. Section 1, the nesting model, is the
   user's assumption and it decides the answer. Too wide (any function) and the
   bounds are uninformative; too narrow and they restate the working model.
   Propose restrictions with a reason for each (monotone because demand
   slopes down, bounded because shares lie in [0, 1]) and get the user's
   agreement before running. Set section 5 limits if `c` or `q` is slow, and
   section 8 Lean to "No" unless the user wants proofs.
2. **Run the template's section 7 checklist.** Fix failures in the factual
   sections; for a failure in an agreed section, report it and ask rather than
   edit. A deviance or likelihood criterion that is infinite only at
   boundary values (shares of 0 or 1) is acceptable; say so. Confirm the user's
   code reproduces the template's baseline estimate and fit, and state the gap
   to the published estimate if the working model differs from the paper's.
3. **Run the procedure** in the main agent: it writes `report.md`, which some
   harnesses block subagents from doing. Follow `$DS/workflow/WORKFLOW.md` on
   the filled template, start to finish, with `sensitivity/<name>/output/` as
   the run directory. Read `$DS/workflow/examples/` first, as it instructs.
   Two additions:
   - In `certificates.json`, store each primitive in a form the user's code
     can evaluate without the run's code (knot values, or values on a stated
     grid), beside the basis-model parameters.
   - `SensitivityProblem` checks restrictions with zero tolerance, so a
     grid-difference shape check can reject the working model itself; check
     shape exactly where the primitive allows it. A target read off a grid is
     a step function with zero finite-difference gradient; give the solver an
     analytic gradient or a continuous version of the target.
4. **Check by a second route.** Load `output/certificates.json`. Recompute `c`
   and `q` for the baseline and both certificates with the user's code from
   section 6, not the code the run wrote, and confirm each `q` is within
   budget. Where the report claims an exact solution, recompute it: plug the
   numbers into a closed form, or re-solve a characterization (a KKT system,
   a root) with a different solver. Perturb one certificate so it should fail
   and confirm the check catches it. A certificate that fails is not reported.
5. **Present.** Open `output/certificates.png` for the user. Show the results
   table and the second-route check beside it. `REPORT.md` limits the report
   to essential judgment calls and has no slot for sensitivity to the nesting
   model, so give both in your reply: every choice the run made, and what
   happens to each bound when a restriction is dropped or the cap moves.

## Reading the result

The interval is a lower bound on sensitivity. The true range over the nesting
model is at least this wide. A wide interval shows the estimate is fragile; a
narrow one shows robustness only on sides the report marks as an exact infimum
or supremum. A side that reaches the edge of `c`'s allowed range (a cap set to
keep `c` finite) is unbounded in substance, whatever its exactness label.

## Updating

To move the pin, read the upstream diff of `workflow/` and the package, rerun
`$DS/workflow/examples/exponential/` and compare its `certificates.json` with
the committed one, then change the commit here.
