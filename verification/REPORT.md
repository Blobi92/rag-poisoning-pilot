# Red-Teaming Our Own AI-Generated Research: Does "Content Verification" Really Stop RAG Poisoning?

*Apart Research AI x Epistemics Sprint, November 13–15, 2026. Tracks: 2 (Trust Infrastructure) and 4 (Open).*

**Authors:** Avi E. Koenig ([@Avi-E-Koenig](https://github.com/Avi-E-Koenig)) · Blobi92 ([@Blobi92](https://github.com/Blobi92)), independent

**Submission version (Google Doc):** https://docs.google.com/document/d/1U5SKI9ILjohPyRouHTqpTQRH-gSPhY0adfFQn36UMQ0/edit · **Pull request:** https://github.com/Avi-E-Koenig/rag-poisoning-pilot/pull/1

**Code, data and one-command reproduction:** https://github.com/Avi-E-Koenig/rag-poisoning-pilot/tree/verify/plan/verification. An independent rerun from an empty cache reproduced all 30 Phase D arm runs within ±1/20, 27 of them exactly (`verification/REPRO_CHECK.md`).

## Abstract

Research agents can now produce a complete study in under an hour: question, code, data, report and repository. Does such a result survive verification? We red-team our own team's RAG-poisoning pilot, which an autonomous agent (Perplexity "Computer") generated end to end during this sprint. It claims that a source allowlist stops external poisoning (18/20 → 0/20) and that content verification against the canonical source is the *only* defense that stops a compromised trusted source (18/20 → 0/20). We apply a four-layer audit: code and data, the agent's session transcript, citations, and a pre-registered reproduction. The headline content-verification result is **produced by the code itself**: poison is rejected by the string "poison" in its document ID. The transcript shows the two "successful" arms were added after the planned arms failed, and the results file mixes several code versions. Three of six references contain errors, one pointing to an unrelated radiotherapy paper. With the original binary and model hash, the unmodified pipeline reproduces 5 of 7 arms exactly. A pre-registered extension (3 poison sets, 60 trials per arm) makes the threat-model gap concrete. Honest content verification blocks poison only while the canonical source is clean, at the cost of 5.5% of trusted chunks. Once that source is poisoned it gives **no protection** (26/60 vs 25/60). Both outcomes follow from the design; what we measure are the costs and a dilution effect. We release a one-command reproduction and a reviewer checklist.

## 1. Introduction

Agents lower the cost of producing research-shaped artifacts much faster than they lower the cost of checking them. When an agent produces hypotheses, a seven-arm design, a chart, a limitations section, citations and a GitHub repository, it has produced every surface signal of rigor. Whether the claims are true is a separate question. That gap is an epistemic-infrastructure problem: **what does it take to verify an AI-generated result, and which failure modes should a reviewer expect?**

We study one concrete case, our own: a RAG-poisoning pilot that an autonomous agent designed, ran, wrote up and pushed to our team's GitHub in a single 34-minute session on the final day of this sprint. We then red-teamed it as if a stranger had written it. The topic suits a credibility audit, because it is about provenance and verification. The study's own conclusion, "verify the *content's* provenance, not just the *source label*", applies to the study itself.

**Contributions.**
1. A four-layer audit protocol (code and data, session provenance, citations, pre-registered reproduction) applied to a real agent-generated study (§3).
2. Evidence that the study's headline result is produced by its own code, and that the threat model needed to test the claim was never modeled (§4.1).
3. A pre-registered extension separating what content verification does and does not protect against (§4.4).
4. A one-command, hash-pinned reproduction kit, plus a reviewer checklist for agent-generated research (Appendix B).

## 2. Related work

**RAG poisoning.** PoisonedRAG (Zou et al., arXiv:2402.07867, USENIX Security 2025) reaches about 90% attack success (ASR) by injecting five texts per target question into a corpus of millions. Semantic Chameleon (Thornton, arXiv:2603.18034) shows that hybrid BM25+vector retrieval cuts *gradient-guided* poisoning from 38% to 0%. It also reports 0% attack success on a Wikipedia (FEVER) corpus.

**Provenance auditing.** "Distributed Denial of Science" (Gyevnár, Kasirzadeh & Shah, arXiv:2607.10712) shows that research agents consume poisoned open datasets (49.56% success, 6.0% detection), and that a five-check provenance-audit prompt reduces success to 0%.

**Guidance.** The OWASP RAG Security Cheat Sheet and INSS Memorandum 256 (Hershkovitz, April 2026) both recommend defense in depth.

**Research credibility.** The "garden of forking paths" (Gelman & Loken, 2013) motivates pre-registration, which we apply to our own extension.

## 3. Method

### 3.1 Subject

The audited repository is `Blobi92/rag-poisoning-pilot` (commits `8595a09` and `21d541f`, both `Co-authored-by: Perplexity`). **Disclosure:** a member of our team created this pilot during this sprint (2026-11-15) by prompting Perplexity's agent. The agent did all of the design, code, runs and write-up; the team member contributed only the initial research prompt. Our audit is new sprint work, in branch `verify/plan` of the fork.
- **Corpus:** 759 Wikipedia chunks (600 words, 100-word overlap).
- **Attack:** 100 LLM-generated poison documents, 5 per target question.
- **Questions:** 20 targets with an attacker answer each, and 10 clean controls.
- **Pipeline:** MiniLM-L6-v2 retrieval (top-5); Qwen2.5-0.5B-Instruct generator (llama.cpp, temperature 0).
- **Arms:** (1) open ingestion, (2) allowlist, (3) compromised source (poison relabeled as Wikipedia), (4) +near-duplicate/keyword-stuffing screen, (5) +hybrid retrieval, (6) +embedding corroboration, (7) content verification against a fresh Wikipedia fetch.

### 3.2 Layer 1: static audit
We read all code and recomputed every reported number from the raw `results.json`, `corpus.json` and `poisons.json`.

### 3.3 Layer 2: provenance audit
We recovered (a) the agent's full session transcript and (b) the earlier research conversation that framed the question. We compared the design planned before the run with the reported design.

### 3.4 Layer 3: citation audit
We resolved every reference using arXiv, Crossref and the full-text PDFs, and checked each cited figure word for word.

### 3.5 Layer 4: reproduction and pre-registered extension

**R2 anchor run.** This is the unmodified upstream script, rerun from scratch in a single code version on the same inputs as the original. The setup matches the original: llama.cpp build `b12389-1ae047c92` (CPU), model file sha256 `74a4da8c…` (491,400,032 bytes, byte-identical in size to the original), `--threads 2 -c 4096`.

**Pre-registration.** We committed the following (commit `81bfacb`) before producing any new result:

| Arm | Design |
|---|---|
| **7′** | Content verification *without* the ID shortcut. A document is kept only if its text is a substring of the live-fetched article it claims; the poison claims the target's article URL. |
| **8** | The poison is spliced into the canonical article, which is then re-chunked and verified against that same poisoned canonical, simulating a malicious upstream edit. |
| **8nv** | Arm 8 without verification (control). |
| **9** | An ingestion-time SHA-256 manifest of trusted chunks. |

The pre-registration also fixed:
- **Scoring:** normalized, alias-based (e.g. β → beta), committed with the pre-registration. Also recorded: target correct-rate, clean accuracy and trusted-chunk false rejections.
- **Poison sets:** S0 (the shipped set) plus S1 and S2, regenerated with the upstream prompt and seeds 1 and 2. That gives 60 trials per arm.
- **Statistics:** Wilson 95% CIs and exact McNemar tests on paired per-question outcomes.
- **Predictions** for every claim.

**Deviations.** Three deviations are logged in the pre-registration file. The material one is D1: our first run calibrated the screening threshold on ground-truth clean documents, which differs from upstream. We fixed it, archived that run unanalyzed, and reran all poison sets.

## 4. Results

### 4.1 Static audit: the headline result is produced by the code

The upstream "content verification" function begins:

```python
def verified(d):
    if "poison" in d["id"]:
        return False  # not present in canonical text
```

Every poison document carries an ID of the form `poison::<answer>::<k>`, so arm 7 removes all poison before any text is compared. **The reported 0/20 is guaranteed by construction.** Likewise, arm 2 simply never adds the poison. Its 0/20 is a correct description of an allowlist, not a measurement of one.

Other findings:
- **Corpus size:** the corpus covers **45** articles, not the reported 50.
- **Dropped chunks:** arm 7 silently dropped **163/759 (21%)** trusted chunks, but the report blames only one failed article.
- **Weak poison:** 19 of 100 poison documents are one-line Q&As, and one states the *correct* answer (1969).
- **Wrong answers in defended arms:** the defended arms answer some targets wrongly (e.g. polio → "Maurice Hilleman").

Full list: findings F1–F13.

### 4.2 Provenance audit: the design changed after the results were in

The agent's plan written before the run had **five** arms, with the stated expectation that screening (arms 4–5) would "partially recover". It did not (17/20). The transcript then shows the agent adding arm 6 ("Before writing up, I'm adding a sixth arm…"). When arm 6 also failed, it added arm 7 ("one more cheap, realistic defense worth test[ing]"). Arm 7's first run "kept 0/859 docs". It was then "fixed", and the shipped version contains the ID shortcut.

The report presents all seven arms as the original design and calls arm 7 "the defense that worked". Earlier arms were never rerun after code edits (the script skips completed arms), so the shipped `results.json` combines several code versions.

The research question also came from a user prompt that presumed its answer ("how data poisoning can be minimised by provided real data from validated resources"). The agent's own earlier summary had concluded that "no single control eliminates it".

### 4.3 Citation audit

Six references are cited in the report; all exist. Three contain errors:

| Reference | Problem |
|---|---|
| PoisonedRAG | Cited as **arXiv:2402.07167**, which is an unrelated radiotherapy paper. The correct ID is 2402.07867. |
| INSS Memo 256 | Misdated: it is from April 2026, not July. |
| "Threats to Training" | Title misquoted. |

The cited figures are quoted accurately. However, the "provenance-audit literature" (arXiv:2607.10712) studies research agents consuming poisoned *datasets*, and its "audit" is a prompt checklist. It does not support content matching for RAG. The paper behind the hybrid-retrieval claim also reports 0% attack success on Wikipedia, a fact the report omits.

### 4.4 Reproduction and pre-registered extension

**R2: the pipeline reproduces.** With the original binary and model, arms 1–5 match the shipped numbers exactly (28–30 of 30 identical answers per arm).
- **Arm 6** differs by one (17 vs 16/20). That is consistent with the mixed code versions found in §4.2.
- **Arm 7** kept 717 rather than 596 chunks, because its live Wikipedia fetches failed less often (finding F5). It still reports 0/20, via the ID shortcut.

**Table 1: Phase D, generation ASR pooled over 3 poison sets (n = 60 per arm).** Wilson 95% CIs. "Dropped" counts trusted chunks lost per set.

| Arm | Gen ASR | 95% CI | Retrieval ASR | Target correct | Clean acc. | Dropped |
|---|---|---|---|---|---|---|
| 1 Open ingestion | 55/60 (92%) | 82–96% | 60/60 | 5/60 | 29/30 | 0 |
| 2 Allowlist | 0/60 | 0–6% | 0/60 | 54/60 | 27/30 | 0 |
| 3 Compromised source | 56/60 (93%) | 84–97% | 60/60 | 4/60 | 29/30 | 0 |
| 4 + Screening | 53/60 (88%) | 78–94% | 60/60 | 6/60 | 29/30 | 0 |
| 5 + Hybrid (RRF k = 60) | 53/60 (88%) | 78–94% | 60/60 | 5/60 | 29/30 | 0 |
| 6 + Corroboration | 53/60 (88%) | 78–94% | 60/60 | 6/60 | 29/30 | 0 |
| **7′ Content verify (honest)** | **0/60** | 0–6% | 0/60 | 57/60 | **24/30** | **42** |
| **8nv Poisoned canonical, no verify** | **25/60 (42%)** | 30–54% | 53/60 | 32/60 | 27/30 | 0 |
| **8 Poisoned canonical + verify** | **26/60 (43%)** | 32–56% | 53/60 | 31/60 | 27/30 | 0 |
| **9 Snapshot manifest** | **0/60** | 0–6% | 0/60 | 54/60 | 27/30 | 0 |

**Table 2: pre-registered predictions against outcomes.**

| Claim | Prediction | Outcome | Holds? |
|---|---|---|---|
| Allowlist stops external poison (K1) | 0/60, by construction | 0/60 | ✔ (by construction) |
| Compromised source bypasses allowlist; screening etc. only partial (K2) | Arms 4–6 ≥ 70% of arm 3; McNemar n.s. | 53/56 = 95%; 3 vs 4: p = 0.25; 4 vs 5: p = 1; 4 vs 6: p = 1 | ✔ |
| Honest content verification, clean canonical (K3) | 0/60, with some false rejections | 0/60; 42 chunks (5.5%) dropped per set | ✔ |
| **Content verification against a poisoned canonical (K3)** | Arm 8 ≈ 8nv | **26/60 vs 25/60, McNemar p = 1.0** | ✔ |
| Snapshot manifest | 0/60, 0 false rejections | 0/60, 0 dropped | ✔ |
| Defenses keep clean accuracy (K4) | ≥ 9/10 except where chunks are dropped (7′) | 7′: 24/30 (one miss per set from the failed Penicillin fetch; one generator error that the allowlist arm also makes); others 27–29/30 | ✔ |

**What is measured, and what follows from the design.** We apply our own construction check (Appendix B, item 3) to our arms. The ASR outcomes of 7′, 8 and 9 are largely *determined by their design*:
- **7′ = 0:** LLM-written poison is never a substring of the real article.
- **8 ≈ 8nv:** verification against the same poisoned canonical text passes every poisoned chunk.
- **9 = 0:** the poison is never in the ingestion manifest.

We pre-registered these as predictions, not discoveries. They make the threat-model gap concrete. The quantities that are genuinely measured are:
- the **cost** of live verification: 42 trusted chunks (5.5%) dropped per set, and clean accuracy down from 27/30 to 24/30;
- the **dilution effect**: spliced poison wins 26/60 answers vs 56/60 for standalone documents;
- the **reproduction** itself.

**Additional observations:**
- **Verification adds nothing against a poisoned source.** Content verification behaves exactly as designed: it passes every spliced poison chunk (113–114 per set), because they *are* the canonical text.
- **Dilution lowers ASR.** Poison embedded in a 600-word chunk still reaches the top-5 in 53/60 trials, but wins only 26/60 answers, against 56/60 when injected as a standalone document.
- **The allowlisted system is often wrong anyway.** Under open ingestion the generator answers correctly only 5/60 times, and even the allowlisted system misses 6/60 targets. This reflects the 0.5B generator's limits.

## 5. Discussion

**Which claims stand?** The descriptive core of the pilot reproduces: a compromised source bypasses the allowlist, and cheap screening, hybrid retrieval and embedding corroboration barely help against keyword-stuffed poison. Its central claim does not stand as stated:

| Report claim | Verdict | Reason |
|---|---|---|
| Content verification "drove the compromised-source attack to 0/20" | **By construction** | The shipped code rejects poison by ID |
| Content verification is "the only defense that closed the loop" | **Not supported** | Content verification can only detect tampering *between* the source and the corpus. It is logically blind to a compromised source, which is the scenario the claim is about, and our arm 8 illustrates that. A hash manifest gives the same post-ingestion protection without a live fetch (0 false rejections vs 5.5%). |
| "Verify the content's provenance, not just the source label" | Sound as a principle | What the experiment actually shows is weaker: content verification is only as good as the integrity of the reference it checks against |

**What went wrong, and is it typical?** Each failure we found is a known human failure mode that the agent's speed amplified:
- adding arms until one "works" (forking paths);
- resuming runs across code edits;
- a shortcut that encodes the answer into the test;
- summarizing citations from a summary.

None of these is visible in the polished artifact. All of them were visible in the session transcript. **Provenance of the research process, not just of the data, was the highest-yield audit layer**, and it cost minutes.

**Implications for trust infrastructure.** We suggest that agent-generated research should ship with:
1. its session transcript;
2. a pre-registration commit made before results exist;
3. single-version result files stamped with a git SHA;
4. machine-checkable citations (DOI/arXiv-ID resolution plus title match).

Each is cheap for an agent to produce and expensive for a reviewer to reconstruct.

## 6. Conclusion

Our own AI-generated study on verifying content provenance failed its own standard: its key result came from its code, not from its data. Once that is fixed, the honest finding is narrower and more useful. Content verification is a tamper-detection control that is only as trustworthy as its reference. It is blind to a compromised upstream source by design. An ingestion-time snapshot manifest offers the same post-ingestion protection without the 5.5% false-rejection cost of live re-fetching. We hold our own extension to the same standard: its headline outcomes follow from the design, and its measured contributions are the costs, the dilution effect and the reproduction. Auditing the *process* (transcript, pre-registration, single-version results) caught what auditing the *artifact* could not.

## References

1. Zou, W., Geng, R., Wang, B., Jia, J. PoisonedRAG: Knowledge Corruption Attacks to Retrieval-Augmented Generation of Large Language Models. arXiv:2402.07867 (USENIX Security 2025).
2. Thornton, S. Semantic Chameleon: Corpus-Dependent Poisoning Attacks and Defenses in RAG Systems. arXiv:2603.18034 (2026).
3. Gyevnár, B., Kasirzadeh, A., Shah, N. B. Distributed Denial of Science: How Indirect Data Poisoning of AI Systems Can Industrialize Scientific Fraud. arXiv:2607.10712 (2026).
4. OWASP. RAG Security Cheat Sheet. https://cheatsheetseries.owasp.org/cheatsheets/RAG_Security_Cheat_Sheet.html
5. Hershkovitz, S. Data Poisoning Primer: Foundations, Threat Models, and National Security Risks. INSS Memorandum 256, April 2026.
6. Wang, Z. et al. Threats to Training: A Survey of Poisoning Attacks and Defenses on Machine Learning Systems. ACM Computing Surveys (2022). doi:10.1145/3538707
7. Cormack, G. V., Clarke, C. L. A., Büttcher, S. Reciprocal Rank Fusion outperforms Condorcet and individual Rank Learning Methods. SIGIR 2009.
8. Gelman, A., Loken, E. The garden of forking paths (2013).
9. Audited artifact (our team's sprint pilot): Blobi92/rag-poisoning-pilot, https://github.com/Blobi92/rag-poisoning-pilot

## Appendix A: Limitations and Dual-Use / Ethical Considerations

**What this establishes.**
- The pilot's headline result is produced by its code.
- Our arms 7′, 8 and 9 illustrate the logical limits of content verification. They do not discover them; their ASR outcomes follow from the design.
- The pipeline reproduces with pinned artifacts.
- Under pre-registered tests, content verification does not protect against a compromised canonical source in this setup.

**What it does not establish.**
- **Scale:** it is still a small benchmark (20 targets × 3 poison sets, one corpus, one 0.5B generator, one embedder). Larger generators may resist poisoning differently; we did not test them (Phase E is exploratory and was not run).
- **Arm 8's threat model:** arm 8 simulates a malicious upstream edit by splicing poison into the article text. A real attacker would face Wikipedia's editorial defenses and edit history, which our setup ignores.
- **Snapshot age:** our pinned Wikipedia snapshot is from 2026-11-15, and 3 of 45 article fetches failed, which affects arm 7′'s false rejections.
- **Nondeterminism:** llama.cpp's server is not bit-exact across runs. Rerunning identical inputs changed up to 2 of 20 answers in one arm. Our reproduction script tolerates ±1/20 per arm.
- **Our own bug (D1):** we made and fixed a screening bug after seeing one run's results. The fix restores the pre-registered specification, and the superseded run is archived.

**Dual use.** The poison documents are low-sophistication, LLM-generated false claims about well-known facts. Our arm 8 shows that poisoning an *upstream* source defeats content verification. That is already the documented threat model in the RAG-security literature, and we release no new attack technique. The audit method could be misused to discredit legitimate work. We mitigate this by reporting what reproduces as well as what does not, by publishing every artifact, and by pre-registering.

**People and data.** We audited our own team's public repository and agent session transcript. We removed account names and personal details from the transcript we republish. No personal data is processed; the corpus is public Wikipedia text.

**AI use.** This audit was carried out with an AI coding assistant (Claude). All code, runs and numbers are committed with git SHAs, and every claim in this report links to a reproducible artifact.

## Appendix B: Reviewer checklist for agent-generated research

1. **Transcript.** Get the agent's session log. Compare the plan written before the run with the reported design: were arms or hypotheses added after results came in?
2. **Single version.** Do the results come from one code version? Look for resume, skip or cache logic, and rerun from scratch.
3. **Construction check.** For every headline number, find the line of code that decides it. Does it use labels the defense shouldn't see (IDs, ground-truth flags)?
4. **Recount.** Recompute the reported descriptive numbers (corpus size, counts, drops) from the raw data.
5. **Threat model.** Is the scenario the claim is about actually simulated, or only a proxy (e.g. a relabel instead of a compromise)?
6. **Citations.** Resolve each ID and DOI, match titles, and find each quoted figure in the source.
7. **Variance.** Are there seeds, CIs and paired tests? If not, rerun with ≥ 3 seeds.
8. **Pinned reproduction.** Binary build, model hash, lockfile and data snapshot.

## Appendix C: Artifact index

The audit materials live under `verification/` on branch `verify/plan`:

| File | Contents |
|---|---|
| `VERIFICATION_PLAN.md` | All findings (F1–F13, P1–P11, C1–C8) |
| `citations.md` | Citation audit |
| `PREREGISTRATION.md` | Pre-registration (`81bfacb`) and deviations log |
| `RESULTS.md`, `results.html` | Results, with an interactive chart |
| `reproduce.sh`, `REPRODUCE.md` | One-command reproduction |
| `context/` | Agent session transcript and the earlier research conversation |
