# Sources

Names are routing devices, not appeals to authority. Every entry below earned its place by
supplying a check, a number, a bound, or a named failure mode — not by being well known. Where a
claim in the skill carries a number, the number comes from here.

## The source paper

- Sood, G. (2023). *Problem Solving*. https://gsood.com/research/papers/problem_solving.pdf —
  the spine. See [diff-from-paper.md](diff-from-paper.md) for what this skill changes.

## Problem framing

- Gause, D. & Weinberg, G. (1982). *Are Your Lights On? How to Figure Out What the Problem Really
  Is*. https://geraldmweinberg.com/Site/AYLO.html — a problem is a difference between things as
  desired and things as perceived. Four questions before diagnosis: what is it, **whose** is it,
  where did it come from, do you actually want to solve it.
- Minto, B. (1987). *The Pyramid Principle* — the source of MECE, and stricter than the usual
  citation: each level must be MECE *and* ordered by a single logic.
- Snowden, D. & Boone, M. (2007). "A Leader's Framework for Decision Making." *HBR*.
  https://hbr.org/2007/11/a-leaders-framework-for-decision-making — complicated vs complex; the
  gate on whether analytic diagnosis is the right method at all.

## Specification and eliminative logic

- Kepner, C. & Tregoe, B. (1965). *The Rational Manager*. — IS/IS-NOT along What/Where/When/Extent;
  candidate causes tested against the whole grid under non-contradiction.
- Mill, J. S. (1843). *A System of Logic*, Book III. https://en.wikipedia.org/wiki/Mill%27s_methods —
  Agreement, Difference, Joint, Residues, Concomitant Variation. "Similar Others" is the Method of
  Difference; Residues is the ancestor of variance decomposition.
- Van Evera, S. (1997); Collier, D. (2011). "Understanding Process Tracing." *PS* 44(4).
  https://polisci.berkeley.edu/sites/default/files/people/u3827/Understanding%20Process%20Tracing.pdf —
  straw-in-the-wind / hoop / smoking gun / doubly decisive. The vocabulary for what a test can prove.
- Heuer, R. (1999). *Psychology of Intelligence Analysis*, ch. 8 (ACH).
  https://www.cse.sc.edu/~mgv/BNSeminar/ACHAlgorithms-v12.pdf — select on fewest inconsistencies,
  not most support; weight evidence by diagnosticity; list evidence absent but expected.
- Halpern, J. (2016). *Actual Causality*. MIT Press, open access.
  https://direct.mit.edu/books/oa-monograph/3451/Actual-Causality — which of several necessary
  conditions is called "the" cause depends on a normality baseline the analyst supplies.

## Search, prioritisation, stopping

- Heckerman, D., Breese, J. & Rommelse, K. (1995). "Decision-theoretic troubleshooting." *CACM*
  38(3). https://link.springer.com/chapter/10.1007/978-1-4615-5089-1_15 — the optimal repair order
  is descending P(faulty)/cost. This is the prioritisation matrix done correctly.
- Howard, R. (1966). "Information Value Theory." *IEEE Trans. SSC* 2(1).
  https://ieeexplore.ieee.org/document/4082064 — value of information is zero if it cannot change
  the action.
- Stone, L. et al. (2014). "Search for the Wreckage of Air France Flight AF 447." *Statistical
  Science* 29(1). https://arxiv.org/abs/1405.4720 — the posterior-after-failed-search update, and
  the lesson that a missing signal may be evidence about the instrument.
- Weitzman, M. (1979). "Optimal Search for the Best Alternative." *Econometrica* 47(3).
  https://scholar.harvard.edu/files/weitzman/files/optimalsearchbestalternative.pdf — reservation
  values; upside variance, not just mean, determines search order.
- Ng, A. (2018). *Machine Learning Yearning*, ch. 53–57.
  https://home-wordpress.deeplearning.ai/wp-content/uploads/2022/03/andrew-ng-machine-learning-yearning.pdf —
  ceiling analysis (face detector 0.1% vs eye segmentation 5.0%); and the Eyeball/Blackbox dev-set
  split, which is the cheapest form of hypothesis lock.
- MIL-STD-1629A; AIAG-VDA FMEA Handbook — severity × occurrence × **detection**. The detectability
  column.
- Bezos, J. (2015). Amazon shareholder letter.
  https://www.sec.gov/Archives/edgar/data/1018724/000119312516530910/d168744dex991.htm — one-way
  vs two-way doors; the gate on how much diagnosis is warranted.

## Reproduction and mechanical isolation

- Zeller, A. & Hildebrandt, R. (2002). "Simplifying and Isolating Failure-Inducing Input." *IEEE
  TSE* 28(2). https://www.cs.purdue.edu/homes/xyzhang/fall07/Papers/delta-debugging.pdf — ddmin,
  1-minimality, 896 lines of HTML to 1.
- Zeller, A. (2009). *Why Programs Fail: A Guide to Systematic Debugging*, 2e. — reproduce first;
  write the prediction before the experiment.
- Liblit, B. et al. (2005). "Scalable Statistical Bug Isolation." *PLDI*.
  https://www.cs.tufts.edu/comp/150CMP/papers/liblit05isolation.pdf — Increase(P) = Failure(P) −
  Context(P). Raw correlation with failure is confounded by how often the path is reached; and the
  iterative-elimination algorithm for multiple concurrent bugs.
- Bhagwan, R. et al. (2014). "Adtributor: Revenue Debugging in Advertising Systems." *NSDI*.
  https://www.usenix.org/system/files/conference/nsdi14/nsdi14-paper-bhagwan.pdf — explanatory
  power, succinctness, surprise; and the derived-measure caveat.

## Injecting the cause

- DeMillo, R., Lipton, R. & Sayward, F. (1978). "Hints on Test Data Selection: Help for the
  Practicing Programmer." *Computer* 11(4):34–41. — fault seeding and mutation testing: plant a
  known fault deliberately and check whether your procedure detects it. The oldest form of the
  argument that a detector you never saw fire is not a detector.
- Anduril (SOSP 2024). "Efficient Reproduction of Fault-Induced Failures in Distributed Systems
  with Feedback-Driven Fault Injection."
  https://web.eecs.umich.edu/~ryanph/paper/anduril-sosp24-preprint.pdf — every failure reproduced
  by injecting the root-cause fault, median eight minutes. The case for injection as the route to a
  reproducer when the failure will not recur on its own.
- Koopman, P. Fault injection survey, CMU.
  https://users.ece.cmu.edu/~koopman/des_s99/fault_injection/ — the taxonomy of where you can
  inject: hardware, software, protocol, data.
- Basiri, A. et al. (2016). "Chaos Engineering." *IEEE Software* 33(3):35–41.
  https://arxiv.org/pdf/1702.05843 — state the steady-state hypothesis before injecting, and
  **minimise the blast radius**. Also the proactive framing: break things on purpose to build the
  fault-mode catalogue before you need it.
- Card, A. (2017), above, is the reason the whys carry guardrails rather than a bare instruction.

## Measurement and metric validity

- Ehrenberg, A. S. C. (1975). *Data Reduction*. — Twyman's law in print.
- Kohavi, R., Tang, D. & Xu, Y. (2020). *Trustworthy Online Controlled Experiments*. Cambridge UP.
  https://experimentguide.com/ — and Kohavi et al. (2012), "Five Puzzling Outcomes Explained,"
  http://ai.stanford.edu/~ronnyk/puzzlingOutcomesInControlledExperiments.pdf — instrumentation
  confounded with the treatment; Simpson's paradox from ramp-up schedules.
- Fabijan, A. et al. (2019). "Diagnosing Sample Ratio Mismatch in Online Controlled Experiments."
  *KDD*. https://dl.acm.org/doi/10.1145/3292500.3330722 — ~6% of experiments; the stage-wise cause
  taxonomy (assignment / execution / log processing / analysis / interference).
- Northcutt, C., Athalye, A. & Mueller, J. (2021). "Pervasive Label Errors in Test Sets."
  *NeurIPS D&B*. https://arxiv.org/abs/2103.14749 — ≥3.3% mean label error across ten benchmarks,
  ≥6% in ImageNet validation; model rankings flip.
- Jacobs, A. & Wallach, H. (2021). "Measurement and Fairness." *FAccT*.
  https://arxiv.org/abs/1912.05511 — construct vs operationalisation; is the metric measuring the
  thing, and does it still after the intervention. Their validity criteria — face, content,
  convergent, predictive, consequential — plus reliability (test-retest, inter-rater) are what a
  metric you built for the occasion owes before you track improvement on it.
- Deng, A. & Shi, X. (2016). "Data-Driven Metric Development for Online Controlled Experiments:
  Seven Lessons Learned." *KDD*. https://www.kdd.org/kdd2016/papers/files/adf0853-dengA.pdf —
  validate a proposed metric against a corpus of historical experiments with known outcomes: does
  it move the right way on changes you already know were good and bad. A metric is a hypothesis
  about the business, not a given.
- Button, K. et al. (2013). "Power failure." *Nature Reviews Neuroscience* 14:365–376.
  https://www.nature.com/articles/nrn3475 — low power does not just fail to detect; any effect it
  *does* detect is an overestimate. The reason a topline metric needs a stated detectable effect
  size before it is used to verify a narrow fix, and the reason small slices flatter their own
  measured improvements.
- Manheim, D. & Garrabrant, S. (2018). "Categorizing Variants of Goodhart's Law."
  https://arxiv.org/abs/1803.04585 — regressional Goodhart is why the worst slice improves without
  a fix.
- Majors, C., Fong-Jones, L. & Miranda, G. (2022). *Observability Engineering*. — you cannot ask a
  question of a dimension you pre-aggregated away.

## Multiplicity in hypothesis generation

- Gelman, A. & Loken, E. (2013). "The garden of forking paths."
  https://sites.stat.columbia.edu/gelman/research/unpublished/p_hacking.pdf — multiplicity without
  a fishing expedition. The central threat to "find correlations with the error."
- Benjamini, Y. & Hochberg, Y. (1995). "Controlling the False Discovery Rate." *JRSS-B* 57(1).
- Chung, Y. et al. (2019). "Slice Finder: Automated Data Slicing for Model Validation." *ICDE*.
  https://arxiv.org/abs/1807.06068 — automating the slice scan required FDR control to be usable.
- Wu, T., Ribeiro, M., Heer, J. & Weld, D. (2019). "Errudite: Scalable, Reproducible, and Testable
  Error Analysis." *ACL*. https://aclanthology.org/P19-1073/ — precise error-group definitions;
  analyse the full population, not a sample of failures; test by counterfactual rewriting.
- Dwork, C. et al. (2015). "The reusable holdout." *Science* 349(6248).
  https://www.science.org/doi/10.1126/science.aaa9375 — how to iterate against a holdout and keep it.

## Diagnostic reasoning and its failure modes

- Elstein, A., Shulman, L. & Sprafka, S. (1978). *Medical Problem Solving*. — 4–5 hypotheses
  generated within seconds; expertise is case-specific knowledge, not general method.
- Graber, M., Franklin, N. & Gruman, R. (2005). "Diagnostic Error in Internal Medicine." *Arch
  Intern Med* 165(13). https://pubmed.ncbi.nlm.nih.gov/16009864/ — premature closure is the leading
  cognitive contributor; cognitive factors in 74% of 100 cases, system factors in 65%.
- Croskerry, P. (2003). "Cognitive Forcing Strategies in Clinical Decision Making." *Ann Emerg Med*
  41(1). — search satisficing; the diagnostic time-out. Note the honest caveat from Ely, Graber &
  Croskerry (2011): *content-specific* differential checklists help; generic debiasing prompts
  largely do not. That is the argument for domain signature libraries over general advice.
- Klein, G. (2007). "Performing a Project Premortem." *HBR*.
  https://hbr.org/2007/09/performing-a-project-premortem — prospective hindsight raises correctly
  identified causes ~30%.
- Sackett, D. et al. — likelihood ratios and post-test probability. LR near 1 means do not run the
  test; LR >10 or <0.1 is decisive.
- Gigerenzer, G. & Hoffrage, U. (1995). "How to improve Bayesian reasoning without instruction."
  *Psych Review* 102. https://sites.stat.columbia.edu/gelman/communication/Gigerenzer1991.pdf —
  natural frequencies beat percentages. State counts out of a fixed denominator.

## Systems, and the case against a single root cause

- Cook, R. (1998). "How Complex Systems Fail." https://how.complexsystems.fail/ — #3 catastrophe
  requires multiple failures; #7 post-accident attribution to a root cause is fundamentally wrong;
  #8 hindsight bias.
- Allspaw, J. (2014). "The Infinite Hows."
  https://www.kitchensoap.com/2014/11/14/the-infinite-hows-or-the-dangers-of-the-five-whys/ — ask
  how, not why; beware counterfactual statements describing a world that did not exist.
- Card, A. (2017). "The problem with '5 whys'." *BMJ Qual Saf* 26(8).
  https://pubmed.ncbi.nlm.nih.gov/27590189/ — linear, non-reproducible, confirmation-biased. The
  direct critique of the paper's three-whys.
- Leveson, N. (2011). *Engineering a Safer World* (STAMP). MIT Press, open access.
  https://direct.mit.edu/books/oa-monograph/2908/Engineering-a-Safer-WorldSystems-Thinking-Applied —
  accidents from inadequate control and unsafe interactions among components that each worked.
- Kleppmann, M. (2017). *Designing Data-Intensive Applications*. — the configuration-errors-beat-
  hardware-faults evidence behind "obvious is underrated." Cited in the source paper.
- Beyer, B. et al. (2016). *SRE*, ch. 15. https://sre.google/sre-book/postmortem-culture/ —
  blamelessness as an epistemic instrument: if naming a cause assigns blame, the information you
  need gets concealed and the investigation stops at the first blameworthy human.

## ML-specific

- Moreno-Torres, J. et al. (2012). "A unifying view on dataset shift in classification." *Pattern
  Recognition* 45(1). https://rtg.cis.upenn.edu/cis700-2019/papers/dataset-shift/dataset-shift-terminology.pdf —
  the covariate / prior / concept partition.
- Zinkevich, M. *Rules of Machine Learning*. https://developers.google.com/machine-learning/guides/rules-of-ml —
  rules 29, 31, 32, 37: log serving features and train on them; the three-window skew-vs-drift
  decomposition.
- Rabanser, S., Günnemann, S. & Lipton, Z. (2019). "Failing Loudly." *NeurIPS*.
  https://arxiv.org/abs/1810.11953 — what detects shift, and shift *malignancy* — a difference that
  does not cost accuracy is not worth chasing.
- D'Amour, A. et al. (2020). "Underspecification Presents Challenges for Credibility in Modern
  Machine Learning." https://arxiv.org/abs/2011.03395 — equivalent held-out performance, different
  behaviour under shift; the random seed alone moves stress-test results.
- Geirhos, R. et al. (2020). "Shortcut Learning in Deep Neural Networks." *Nat Mach Intell* 2.
  https://www.nature.com/articles/s42256-020-00257-z — the causal generator behind a suspiciously
  good metric.
- Li, Z. et al. (2023). "A Whac-A-Mole Dilemma." *CVPR*. https://arxiv.org/abs/2212.04825 —
  mitigating one shortcut amplifies others.
- Adebayo, J. et al. (2018). "Sanity Checks for Saliency Maps." *NeurIPS*.
  https://papers.neurips.cc/paper/8160-sanity-checks-for-saliency-maps.pdf — the run-the-null rule.
- Sculley, D. et al. (2015). "Hidden Technical Debt in Machine Learning Systems." *NeurIPS*.
  https://papers.neurips.cc/paper/5656-hidden-technical-debt-in-machine-learning-systems.pdf —
  CACE, correction cascades, undeclared consumers.
- Yan, S. et al. (2021). "Positive-Congruent Training." *CVPR*. https://arxiv.org/abs/2011.09161 —
  negative flips at improved aggregate accuracy. Why Δmetric is not verification.
- Melis, G., Dyer, C. & Blunsom (2018). https://arxiv.org/abs/1707.05589; Dacrema, M. et al.
  (2019). https://arxiv.org/abs/1907.06902 — reported gains that were tuning budget. The ablation
  conditions.
- Sambasivan, N. et al. (2021). "Data Cascades in High-Stakes AI." *CHI*.
  https://dl.acm.org/doi/10.1145/3411764.3445518 — 92% of practitioners hit at least one; cascades
  are opaque and detected far downstream. The base rate behind "fix upstream."
- Perdomo, J. et al. (2020). "Performative Prediction." *ICML*. https://arxiv.org/abs/2002.06673 —
  when the model's own past output is in the data, correlating error with features is invalid.
- Husain, H. "LLM Evals FAQ." https://hamel.dev/blog/posts/evals-faq/ — open coding → axial coding
  → quantify → automate, with graders validated against human labels. The modern instantiation of
  "study your worst failures," and the criteria-drift caveat to naive pre-registration.

## Composes with

- `ocr-error-triage` — the operational fix-validation loop: fixed splits, recorded baselines, the
  four gates, and the failure modes of validation itself.
- `audit-analysis` — evidence rules for reporting findings, and `references/bug-taxonomy.md` for
  calibration on what counts as consequential.
