# Verification Plan — "Can Validated Data Stop RAG Poisoning?"

Goal: decide how far the claims in `report.md` can be trusted, by (a) auditing code and data
statically, (b) reproducing the run locally, and (c) testing whether the conclusions survive
fixes and variations of the method.

Status: **draft v2** (phases revised after the provenance findings), branch `verify/plan`, 2026-11-15.

---

## 0. Findings from the first pass (static audit, nothing executed yet)

| # | Severity | Finding | Evidence |
|---|---|---|---|
| F1 | **Critical** | Arm 7 ("content verification") rejects poison **by its ID**, not its content: `if "poison" in d["id"]: return False`. The 0/20 headline result for arm 7 is therefore true by construction. Whether real content checking would catch the poison is never tested. | `run_experiment.py` (`verified()`) |
| F2 | High | Arm 2 (the allowlist) is also true by construction: the poison is simply never added to the corpus. That is a fair description of an allowlist, but "0/20" here does not measure anything about the attack. | `arms["2_allowlist"]` |
| F3 | High | The "compromised source" is only relabeled poison sitting next to the real Wikipedia chunks. The scenario in which content verification would actually be tested, where the canonical source itself is edited, is not modeled. If the attacker controls the source, re-fetching it returns the poison. | Report §6 admits the relabeling |
| F4 | Medium | The corpus covers **45** articles, not the 50 claimed: the `ARTICLES` list has 45 entries and `corpus.json` contains 45 distinct titles. | `build_corpus.py`, `corpus.json` |
| F5 | Medium | Arm 7 kept 596/859 docs. That means **163 trusted chunks (21%) were dropped**, which is more than the single Great Barrier Reef failure the report mentions. The drops could come from failed re-fetches or from Wikipedia text changing since ingestion. The report's claim that this causes "no measurable accuracy cost" rests on only 10 control questions. | `results.json` |
| F6 | Medium | Poison quality is uneven. 19/100 poison docs are under 20 words (one-line Q&A). `poison::1971::3` actually states the **correct** answer (1969). 5/100 never mention the attacker's answer. | `poisons.json` |
| F7 | Medium | Scoring is a raw substring match. The report acknowledges the β-lactam/beta-lactam case. Correctness on the target questions in the defended arms is never reported: the allowlist arm answers polio → "Maurice Hilleman", and only 18/20 target answers are correct. | `results.json` |
| F8 | Medium | n=20 targets, one poison generation (temperature 0.7, unseeded), one generator model (0.5B) and no confidence intervals. The differences of 16, 17 and 18 out of 20 between arms 3–6 are noise-level. | `gen_poison.py` |
| F9 | Low | The hybrid RRF uses `1/(rank+1)` (k=0) instead of the usual k=60. `texts.index()` maps duplicate texts to the first occurrence. Either could bias the "hybrid doesn't help" result. | `HybridRetriever` |
| F10 | Low | The corroboration gate marks 806/817 docs as uncorroborated, so it is effectively a no-op rather than evidence that "corroboration fails". τ=0.75 was never tuned. | `results.json` |
| F11 | Low | The near-duplicate filter keeps the first doc of every cluster by design, so one poison per cluster always survives. That is consistent with the report's "one survivor suffices" result, but it is partly an artifact of the design. | `screen()` |
| F12 | Low | Housekeeping: the docstring says 5 arms (the code has 7). `trusted_corpus` in the screening info is actually the full corpus size of 859. The report says the code lives in a `rag-poisoning/` directory that does not exist. | — |
| F13 | ? | Two cited sources need existence checks: arXiv 2603.18034 and arXiv 2607.10712 (the "Distributed Denial of Science" study). The INSS memo URL also needs checking. | report §8 |

### 0b. Provenance findings (from the Perplexity transcript)

Source: [`verification/context/perplexity-thread.md`](verification/context/perplexity-thread.md). This is the shared Perplexity "Computer" session that designed the experiment, ran it, wrote the report and pushed this repo.

| # | Severity | Finding | Evidence |
|---|---|---|---|
| P1 | **High** | **AI-generated end to end, with no human review of the method.** The research framing, the code, the run, the report and the git push were all done by Perplexity's agent in one session (about 34 min of runtime). The user's only inputs were "ok, lets see what you've got", then questions about where the files are and a request to push to GitHub. | Transcript; upstream commits carry `Co-authored-by: Perplexity <noreply@perplexity.ai>` |
| P2 | **High** | **Arms 6 and 7 were added after the results came in (post-hoc).** The plan written before the run had 5 arms and *expected* arms 4/5 to "partially recover". They didn't (17/20). The agent then added arm 6 ("Before writing up, I'm adding a sixth arm…"). When arm 6 also failed, it added arm 7 ("one more cheap, realistic defense worth test[ing]"). The report presents all 7 as the design from the start, and its hypotheses were reworded to fit. This is a textbook garden-of-forking-paths problem. | Transcript, the "One-Day Testable Framing" turn vs the run narrative |
| P3 | High | **`results.json` mixes outputs from different code versions.** Arms 1–3 ran first, then the script crashed (`'list' object has no attribute 'sum'`). The code was edited and the script resumed with `already done, skipping`. It was edited again for arms 6 and 7, and the earlier arms were never rerun. The shipped `run_experiment.py` is therefore *not* the exact code that produced arms 1–6. | Transcript tool output; the resume logic in `main()` |
| P4 | High | **Arm 7 first kept 0/859 docs.** The verification was then "fixed" (retries and pacing). Whether the `"poison" in id` shortcut (F1) was added in that fix or existed from the start is not visible, but either way the shortcut is what produces the final result. | Transcript: `content verification: kept 0/859 docs` |
| P5 | Medium | The agent noticed that a poison doc stated the correct answer ("Note v3 of the Moon landing question says 'July…'") but neither removed it nor disclosed it. | Transcript; F6 |
| P6 | Medium | The "50 articles" figure was reported without being checked. The script prints per-article chunk counts and a total, never an article count. The corpus actually has 45 titles. "Light bulb" was redirected to "Electric light". There is no "Johannes Gutenberg" article, even though one target question is about him. | `corpus.json` titles |
| P7 | Medium | Every citation and claim in the report traces back to an earlier Perplexity research conversation, now recovered as [`original-search-document.md`](verification/context/original-search-document.md) (+ PDF). Its claims include the "Distributed Denial of Science" figures (49.56% success, 6.0% detection; a five-part provenance audit → 0.0% success / 77.33% detection) and "Before the Ballot" (INSS special publication, Oct 2026). Its 23 sources mix papers with vendor blogs and glossaries (Akamai, Vectra, Palo Alto, Cato, secure.com). All of it needs independent checking, because LLM research summaries can fabricate or distort sources. | Original search doc, refs 1–23 |
| P10 | **High** | **The research question was confirmation-framed from the start.** The user's opening prompt was "search some paper on how data poisoning can be minimised by provided real data from validated resources". The question already presumes the answer, and the agent then built an experiment to demonstrate it. The earlier conversation itself concluded that "**no single control eliminates it**", yet the final report claims that one control (arm 7) took ASR to 0/20, which is exactly the result F1 shows to be produced by the code itself. | Original search doc p.1 and p.4 vs report §5 |
| P11 | Medium | The earlier conversation framed hybrid retrieval as a mitigation for **gradient-guided** poisoning (citing arXiv 2603.18034). The report's statement that "hybrid did not help" against keyword poison is consistent with that, but it is then presented as a novel negative finding rather than the expected outcome of the cited source. | Original search doc p.2 |
| P8 | Low | The chart was made by inline code that isn't in the repo. The original environment: Python 3.14.8, 2 CPU cores, no GPU, llama.cpp `b12389` CPU build, `Qwen/Qwen2.5-0.5B-Instruct-GGUF` q4_k_m (491,400,032 bytes), `--threads 2 -c 4096`, run on 2026-11-15 around 03:44 UTC. | Transcript tool output |
| P9 | Info | The planning turn promised a "publishable-grade result" and predicted the outcome in advance ("Arms 2 and 5 should show ASR near zero"). The README now presents the work as validated research. | Transcript |
| C1 | **High** | The PoisonedRAG link in README and report (`arXiv 2402.07167`) points to an unrelated radiotherapy paper. The correct ID is **2402.07867**. | [`verification/citations.md`](verification/citations.md) |
| C3 | Medium | The DDoSci paper (the "provenance-audit literature") studies research agents consuming poisoned datasets, not RAG. Its audit is an agent prompt, not content matching. It does not support report §5's lesson. | `verification/citations.md` |
| C4/C8 | Low | The INSS memo is dated April 2026 (the report says July). The "Threats to Training" title is misquoted. | `verification/citations.md` |

---

## 1. Environment setup

Target machine: WSL2, Python 3.12, RTX 4050 Laptop GPU (6 GB).

1. Create `.venv` with **`uv`** (`python3 -m venv` is unavailable here because the `python3.12-venv` package is missing). Install pinned `fastembed rank_bm25 requests matplotlib numpy` and record them in `requirements.lock`.
2. Generator: use the **same build as the original**, llama.cpp `b12389` CPU (`llama-b12389-bin-ubuntu-x64.tar.gz`), with `--threads 2 -c 4096` and `qwen2.5-0.5b-instruct-q4_k_m.gguf` from the official Qwen HF repo. Check the file size is 491,400,032 bytes and record its sha256. A GPU build is only for the later model-sweep phases.
3. Record the llama.cpp version and the seed. Temperature 0 is only *mostly* deterministic across builds, which is another reason the anchor run uses the original's CPU build.
4. Isolation: run the scripts with `python -I` from the venv. Network egress goes only to `en.wikipedia.org` and `localhost:8080` (already confirmed by reading the code).

## 2. Reproduction tiers

| Tier | What | Pass criterion |
|---|---|---|
| R1 | Re-score the shipped `results.json` (no model) | The report's tables match the raw JSON. *Already matches, except F4 and F5.* |
| R2 | **Single-code-version anchor run** (P3): delete `results.json` and run all 7 arms from one commit on the **shipped** `corpus.json` + `poisons.json`, in the original environment. Log the git SHA, the model hash and the llama.cpp build in the output. | Not "match 18/20". The goal is a clean, attributable baseline. Report per-arm deltas against the shipped results and the per-question agreement. Any difference beyond ±2 on an arm gets investigated (code drift vs nondeterminism vs Wikipedia drift in arm 7). |
| R3 | Full rebuild: `build_corpus.py` with a fresh Wikipedia fetch, then `gen_poison.py` ×5 seeds, then run the experiment | Same qualitative ordering of the arms. Report the variance across seeds. |

## 3. Methodology stress tests (do the conclusions survive?)

1. **Honest arm 7**: remove the ID shortcut and verify by content only (substring match / hash against the canonical text). Expected result: still 0/20 when the source is clean. This turns a tautology into a measurement.
2. **Real compromised source (arm 8)**: inject the poison *into* the canonical text, i.e. a simulated malicious Wikipedia edit, and verify against that compromised canonical copy. Hypothesis: verification fails. If so, report §7 conclusion 3 is overstated.
3. **Snapshot verification (arm 9)**: verify against a signed or hashed ingestion-time snapshot instead of a live re-fetch. This fixes the F5 drift and isolates what verification actually protects against.
4. **Scoring**: normalize answers (β→beta, case, aliases). Add the target-question correct-rate metric. Add a blind manual review of all ~300 generated answers.
5. **Statistics**: Wilson 95% CIs per arm, McNemar's test between paired arms, 5 poison seeds × 3 generator seeds.
6. **Generator sensitivity**: Qwen2.5-0.5B vs Qwen2.5-7B / Llama-3.1-8B Q4 (these fit in 6 GB). A 0.5B model is unusually easy to hijack.
7. **Poison quality**: re-run with degenerate and self-defeating poisons filtered (F6), and with poison budgets of 1 and 3 per question.
8. **Defense parameters**: sweep τ_dup (0.85–0.95), σ for stuffing (2–5), and the corroboration τ (F10). Use the standard RRF with k=60 (F9).
9. **Citations**: check that every source in §8 resolves and actually says what it is cited for. Also check the claims carried over from the earlier conversation (P7): the "Distributed Denial of Science" figures, "Before the Ballot", OWASP AISVS, the ACM survey's "43 countermeasures", and PoisonedRAG's "≈90% with 5 texts".
10. **Pre-registered rerun (P2)**: decide the arms, the metrics and the stopping rule *before* running. Report every arm that is run.
11. **Single-code-version rerun (P3)**: delete `results.json` and run every arm with one commit. Record the git SHA in the results.
12. **Match the original environment (P8)**: use llama.cpp `b12389` on CPU with `--threads 2 -c 4096`, to separate environment effects from methodology effects.

## 4. References

Primary artifacts:
- Upstream repo: https://github.com/Blobi92/rag-poisoning-pilot (commits `a7e1074`, `8595a09`, `21d541f`)
- Generating session transcript: [`verification/context/perplexity-thread.md`](verification/context/perplexity-thread.md)
- Model: https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF (`qwen2.5-0.5b-instruct-q4_k_m.gguf`)
- llama.cpp build used: https://github.com/ggml-org/llama.cpp/releases/tag/b12389
- Embedder: https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2 (via `fastembed`)
- Wikipedia extracts API: https://www.mediawiki.org/wiki/Extension:TextExtracts

Literature cited by the report (to be checked in Phase A):
- PoisonedRAG: https://arxiv.org/abs/2402.07167
- Corpus-Dependent Poisoning Attacks and Defenses in RAG Systems: https://arxiv.org/html/2603.18034v1
- "Distributed Denial of Science" provenance audit: https://arxiv.org/html/2607.10712
- OWASP RAG Security Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/RAG_Security_Cheat_Sheet.html
- INSS Data Poisoning Primer (Memo 256): https://www.inss.org.il/wp-content/uploads/2026/07/Memo-256_digital.pdf
- Threats to Training (ACM CSUR): https://dl.acm.org/doi/full/10.1145/3538707
- Cited in the earlier conversation only: "Machine Learning Security against Data Poisoning: Are We There Yet?", "Before the Ballot" (Oct 2026), OWASP AISVS

Full source list of the earlier Perplexity conversation ([`original-search-document.md`](verification/context/original-search-document.md)), all to be checked in Phase A:

| # | URL | Type |
|---|---|---|
| 1 | https://www.akamai.com/resources/white-paper/data-poisoning | vendor white paper |
| 2, 13 | https://dl.acm.org/doi/full/10.1145/3538707 | ACM CSUR survey ("Threats to Training") |
| 3 | https://www.wisdomlib.org/uploads/journals/mdpi-sust/2020-volume-12-issue-16--2071-1050-12-16-6434-.pdf | MDPI Sustainability 2020 (relevance unclear) |
| 4 | https://aisecurityandsafety.org/de/guides/data-poisoning/ | guide |
| 5 | https://dl.acm.org/doi/10.1145/3551636 | ACM paper |
| 6, 20 | https://cheatsheetseries.owasp.org/cheatsheets/RAG_Security_Cheat_Sheet.html | OWASP |
| 7 | https://www.vectra.ai/topics/data-poisoning | vendor glossary |
| 8 | https://www.secure.com/blog/appsec/data-poisoning | vendor blog |
| 9 | https://www.catonetworks.com/glossary/data-poisoning/ | vendor glossary |
| 10 | https://dl.acm.org/doi/10.1145/3708319.3733675 | ACM paper (Stealthy LLM-driven RAG recommender poisoning?) |
| 11, 21 | https://arxiv.org/html/2603.18034v1 | Corpus-Dependent Poisoning Attacks and Defenses in RAG |
| 12 | https://github.com/ssg-research/cs858-wiki/blob/main/wiki-f26/papers/zou-2024-poisonedrag.md | course-wiki summary of PoisonedRAG (secondary) |
| 14 | https://www.inss.org.il/wp-content/uploads/2026/07/Memo-256_digital.pdf | INSS Memo 256 |
| 15 | https://arxiv.org/html/2607.10712 | "Distributed Denial of Science" |
| 16 | http://dl.acm.org/doi/abs/10.1145/3677328 | ACM CSUR recommender poisoning survey |
| 17 | https://github.com/OWASP/AISVS/blob/main/1.0/research/chapters/C01-Training-Data/C01-03-Training-Data-Quality-Security-Assurance.md | OWASP AISVS |
| 18 | https://www.inss.org.il/wp-content/uploads/2026/10/special-publication-15102026.pdf | INSS "Before the Ballot" |
| 19 | https://www.paloaltonetworks.com/cyberpedia/what-is-data-poisoning | vendor glossary |
| 22 | https://arxiv.org/html/2102.13624v2 | arXiv 2021 (check: is this "ML Security against Data Poisoning: Are We There Yet?") |
| 23 | https://iacis.org/iis/2025/4_iis_2025_433-442.pdf | IACIS 2025 |

Methodology references for the stress tests:
- RRF (k=60): Cormack, Clarke & Büttcher, SIGIR 2009, "Reciprocal Rank Fusion outperforms Condorcet and individual Rank Learning Methods"
- Wilson score interval and McNemar's test for paired proportions (standard)
- Garden of forking paths: Gelman & Loken (2013)

## 5. Deliverables

- `verification/` folder holding scripts, lockfile, model hash, the pre-registration, and the raw results from each phase
- `VERIFICATION_REPORT.md` with a **credibility verdict table**: one row per claim in `report.md` (H1, H2, H3, the §5 findings, the §7 conclusions and the headline framing). Each row gets one verdict:
  - **Confirmed**: reproduces, and survives the stress tests
  - **Partially supported**: the direction holds but the magnitude or generality is overstated
  - **By construction**: true only because of how the code is written (e.g. F1, F2)
  - **Not supported**: contradicted by our runs
  - **Unverifiable**: e.g. depends on a citation that doesn't resolve

  Each row links to its evidence (finding ID, run ID, citation check).
- Optional upstream issue/PR to Blobi92 covering F1, F4 and F12

## 6. Phases (revised after the provenance findings)

Ordering principle: cheap checks first, then a clean anchor run, then **commit the expectations before running any new arm**, so that we don't repeat P2.

| Phase | What | Covers | Exit criterion |
|---|---|---|---|
| **A. Citations** ✅ done | Check the 6 sources cited in `report.md` §8 plus the specific figures the report relies on: PoisonedRAG "≈90% with 5 texts", the DDoSci figures (49.56% / 6.0% / 0.0% / 77.33%), the INSS Memo 256 claims, and the hybrid-retrieval claim from 2603.18034. Do a light existence check on the other sources in the reference table; the vendor blogs only need to resolve. | P7, P11, F13, test 9 | `verification/citations.md`: for each source, whether it resolves, whether it says what it is cited for, and a quote/page |
| **B. Environment + anchor run** | §1 setup in the original environment, then R1 (done) and R2 as a single-code-version run | P3, P8, tests 11–12 | `verification/runs/r2/` with results and run metadata, plus a delta table against the shipped `results.json` |
| **C. Pre-registration** | Before any new arm runs, write and commit `verification/PREREGISTRATION.md`: hypotheses, arms 7′ (honest content verification), 8 (real compromised canonical source) and 9 (snapshot verification), metrics, the scoring rules (normalization, aliases, target correct-rate), the statistical tests, and the expected outcome for each arm. **Stopping rule:** every pre-registered arm is reported, and anything added later is labeled exploratory. | P2, P10, test 10 | The pre-registration commit SHA exists *before* any Phase D results |
| **D. Claim-deciding tests** | Stress tests 1, 2, 3 (arms 7′/8/9), 4 (scoring) and 5 (Wilson CIs, McNemar, 5 poison seeds × 3 generator seeds) | F1, F2, F3, F7, F8, P4, P5 | Pre-registered results for every arm, plus a verdict on report §7 conclusion 3 ("content verification is the only defense…") |
| **E. Robustness (exploratory)** | Stress tests 6 (bigger generators, GPU), 7 (poison quality/budget), 8 (defense parameter sweeps, RRF k=60), and R3 (fresh corpus rebuild) | F5, F6, F8–F11 | Results labeled as exploratory, showing whether any Phase D verdict flips |
| **F. Report** | `VERIFICATION_REPORT.md` with the verdict table, a methods section, and the open issues for upstream | all | PR ready for review |
