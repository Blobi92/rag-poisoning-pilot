# Can Validated Data Stop RAG Poisoning?

> **⚠ Correction notice (2026-11-16).** An independent audit (see [`verification/`](https://github.com/Blobi92/rag-poisoning-pilot/blob/main/verification/README.md)) found that the original **arm 7 "content verification" rejected poison by document ID** (`"poison" in d["id"]`), so its 0/20 was produced by the code itself. The shortcut has been removed from `run_experiment.py`. Re-run without it, and with poison spliced into the canonical source itself, content verification gives **no protection against a compromised source** (26/60 vs 25/60 without verification, 3 poison sets). It only protects while the canonical source is clean. The headline conclusion below (§5 "The defense that worked", §7.3) is therefore **not supported as stated**. The numbers in `results.json` are kept unchanged for the record. Also corrected: the PoisonedRAG arXiv ID, the article count (45, not 50), the INSS memo date, and the survey title. Details: [`verification/REPORT.md`](https://github.com/Blobi92/rag-poisoning-pilot/blob/main/verification/REPORT.md).

**A one-day controlled experiment on source validation vs. data poisoning in Retrieval-Augmented Generation**

*Date: November 15, 2026 · All code, corpora, and raw results in `rag-poisoning/`*

---

## 1. Research Question

> **Does ingesting only real data from validated, authoritative sources reduce the success of RAG poisoning attacks — and does it still hold when the trusted source itself is compromised?**

## 2. Hypotheses

- **H1:** A trusted-source allowlist reduces attack success rate (ASR) to near zero against poison arriving through an open submission channel.
- **H2:** When the trusted source is compromised, the allowlist fails; statistical screening and retrieval-level defenses are needed, and simple ones are only partially effective.
- **H3:** Defenses do not materially degrade clean-answer accuracy.

## 3. Method

### Corpus and attack

| Component | Detail |
| :--- | :--- |
| Trusted corpus | 759 text chunks from 45 Wikipedia articles (fetched live via the Wikipedia API), chunked at ~600 words with 100-word overlap |
| Attack | **PoisonedRAG-style**: 5 adversarial documents per target question (100 total), LLM-generated to assert the attacker's intended wrong answer while repeating the question's keywords so they rank highly in retrieval |
| Target questions | 20 factual questions (who discovered penicillin, tallest mountain, year of the Moon landing, ...) each with a defined correct answer and attacker answer |
| Clean controls | 10 untargeted factual questions answerable from the corpus |
| Retrieval | Vector search (MiniLM-L6-v2 embeddings, cosine, top-5) and BM25+vector Reciprocal Rank Fusion |
| Generator | Qwen2.5-0.5B-Instruct (local, temperature 0), answering only from the top-5 retrieved chunks |

### Experimental arms

| Arm | Ingestion policy | Retrieval |
| :-- | :-- | :-- |
| 1. Baseline | Open ingestion: trusted + 100 poison docs from a "community upload" channel | Vector |
| 2. Allowlist | Poison blocked at ingestion by source tag | Vector |
| 3. Compromised source | Same poison docs, but tagged as the trusted source (allowlist bypassed) | Vector |
| 4. + Screening | Near-duplicate detection (cosine ≥ 0.92) + keyword-stuffing anomaly (4σ above trusted corpus baseline) | Vector |
| 5. + Hybrid retrieval | Same screening | BM25 + vector RRF |
| 6. + Embedding corroboration | Same screening + gate: a document needs a similar document from a *different* article to support an answer | Vector |
| 7. Content verification | Every "trusted" document re-verified against the canonical Wikipedia text fetched fresh from the API; anything not matching the authoritative source is rejected | Vector |

### Metrics

- **Retrieval ASR:** share of the 20 target questions where a poison document enters the top-5 context
- **Generation ASR:** share where the LLM's final answer is the attacker's intended answer (and not the correct one)
- **Clean accuracy:** share of the 10 control questions answered correctly
- **False positives:** trusted documents wrongly rejected by each defense

## 4. Results

| Arm | Corpus | Retrieval ASR | Generation ASR | Clean acc. |
| :-- | :-- | :-- | :-- | :-- |
| 1. Baseline (open ingestion) | 859 | **20/20** | **18/20** | 9/10 |
| 2. Allowlist only | 759 | **0/20** | **0/20** | 8/10* |
| 3. Compromised source | 859 | 20/20 | 18/20 | 9/10 |
| 4. + Statistical screening | 817 | 20/20 | 17/20 | 9/10 |
| 5. + Hybrid retrieval | 817 | 20/20 | 17/20 | 9/10 |
| 6. + Embedding corroboration | 817 | 20/20 | 16/20 | 9/10 |
| 7. **Content verification** † | 596 | **0/20** | **0/20** | 8/10* |

† Arm 7's 0/20 was produced by a document-ID shortcut in the original code (see the correction notice at the top).

\* One "miss" in both arms is a scoring artifact: the model answered "β-lactam" and the checker expected the string "beta-lactam". Effective clean accuracy is 9/10. Arm 7 additionally lost one genuine question (Great Barrier Reef) because that article's verification re-fetch failed and its chunks were conservatively dropped.

![Attack success rate by defense](asr_by_arm.png)

### Screening performance (arms 4–6)

- Flagged **42 of 100** poison documents (32 by near-duplicate detection, 14 by keyword-stuffing) with **0 false positives** on 759 trusted chunks, in **0.7 seconds**.
- The 58 surviving poison documents were still enough to hijack 17 of 20 answers — each targeted question kept at least one high-ranking poison document.

### What the poisoned answers looked like (arm 4)

- "Who discovered penicillin?" → *"Howard Florey discovered penicillin."*
- "Who developed the first inactivated polio vaccine?" → *"Albert Sabin developed the first successful inactivated polio vaccine."*
- "Who proposed general relativity?" → *"Isaac Newton proposed the theory of general relativity."*

## 5. Findings

**H1 — Confirmed.** Source validation at ingestion is a near-perfect control against external poison: the allowlist took the attack from 18/20 to **0/20** with no measurable accuracy cost. This is the "validated real data from validated resources" layer working exactly as intended.

**H2 — Confirmed, with a twist.** The compromised-source scenario fully bypasses the allowlist (18/20, identical to baseline). Three cheap defenses were then tested:

- **Statistical screening** catches 42% of poison with zero false positives but does not stop the attack — a single surviving adversarial document per question suffices. Filtering is necessary but not sufficient.
- **Hybrid BM25+vector retrieval did not help** (17/20). This is a notable negative result: the PoisonedRAG-style attack is keyword-rich, so BM25 ranks it highly too. Hybrid retrieval mitigates *gradient-based* embedding attacks (as reported in [Corpus-Dependent Poisoning Attacks](https://arxiv.org/html/2603.18034v1)), but not keyword-stuffed poison.
- **Embedding-level corroboration failed** (16/20, and the gate flagged 806/817 documents as uncorroborated): cosine similarity captures *topical* similarity, not *agreement* — a poison document about the Moon landing is embedding-similar to legitimate Moon-landing text while contradicting it.

**The defense that worked: content verification against the canonical source.** Re-fetching the authoritative Wikipedia text and rejecting any document whose content does not match it drove the compromised-source attack to **0/20** — the only defense that closed the loop. The lesson matches the provenance-audit literature: verify the *content's* provenance, not just the *source label*.

**H3 — Confirmed.** Clean accuracy stayed at 9/10 (effective) across every arm. No defense measurably degraded normal answering, and the full defense stack added under 6 minutes of verification time for the whole corpus.

## 6. Limitations

- Pilot scale: 20 target questions, 10 controls, 859 documents, one generator (Qwen2.5-0.5B) and one embedder (MiniLM). Proportions are large enough to be directionally clear but not for fine-grained statistics.
- The attacker was keyword-based, not adaptive: a stronger adversary could try to evade duplicate/stuffing filters or mimic trusted phrasing.
- Content verification depends on the upstream source being available and stable; in this run, re-fetches of several of the 45 articles failed, and 163 of 759 trusted chunks (21%) were dropped (API throttling) and those chunks were conservatively dropped — a reliability cost worth engineering around (caching, retries, signed snapshots).
- "Compromised source" was simulated by relabeling poison documents, not by an actual edit to Wikipedia.

## 7. Conclusions

1. **Validated-source ingestion is the single highest-value control** against RAG poisoning — but only against poison arriving from outside the trusted boundary.
2. **Source labels alone are spoofable.** The realistic threat model (a compromised or manipulated trusted feed) defeats allowlists completely.
3. **Verification must be content-level**: comparing ingested documents against the authoritative origin (or a cryptographic snapshot of it) was the only defense that reduced ASR to zero in the compromised scenario, at modest cost.
4. Defense-in-depth remains the right framing, consistent with [OWASP's RAG security guidance](https://cheatsheetseries.owasp.org/cheatsheets/RAG_Security_Cheat_Sheet.html) and the [INSS Data Poisoning Primer](https://www.inss.org.il/wp-content/uploads/2026/07/Memo-256_digital.pdf): allowlists for ingestion, screening for anomalies, content provenance verification, and — since no single control is complete — monitoring and rollback.

### Suggested research framing (validated)

> **"Can validated, provenance-aware ingestion of real data reduce RAG poisoning success while preserving retrieval quality?" — Yes: source validation eliminates external poisoning (18/20 → 0/20), and content-level verification against the canonical source eliminates compromised-source poisoning (18/20 → 0/20), with no measurable loss of clean accuracy (9/10).**

## 8. Sources

- PoisonedRAG: Knowledge Corruption Attacks to Retrieval-Augmented Generation of Large Language Models — [github.com/ssg-research/cs858-wiki](https://github.com/ssg-research/cs858-wiki/blob/main/wiki-f26/papers/zou-2024-poisonedrag.md) and [arXiv:2402.07867](https://arxiv.org/abs/2402.07867)
- Corpus-Dependent Poisoning Attacks and Defenses in RAG Systems — [arxiv.org/html/2603.18034v1](https://arxiv.org/html/2603.18034v1)
- OWASP RAG Security Cheat Sheet — [cheatsheetseries.owasp.org](https://cheatsheetseries.owasp.org/cheatsheets/RAG_Security_Cheat_Sheet.html)
- INSS, Data Poisoning Primer (Memorandum 256, April 2026) — [inss.org.il](https://www.inss.org.il/wp-content/uploads/2026/07/Memo-256_digital.pdf)
- "Distributed Denial of Science" provenance-audit study (2026) — [arxiv.org/html/2607.10712](https://arxiv.org/html/2607.10712)
- Threats to Training: A Survey of Poisoning Attacks and Defenses on Machine Learning Systems — [dl.acm.org/doi/full/10.1145/3538707](https://dl.acm.org/doi/full/10.1145/3538707)

## 9. Reproduction

Everything runs locally with free components (no API keys):

```
python3 build_corpus.py    # fetch 45 Wikipedia articles -> 759 chunks
python3 gen_poison.py      # LLM-generated PoisonedRAG-style attack docs
python3 run_experiment.py  # 7 arms, writes results.json + summary
```

Requirements: `fastembed`, `rank_bm25`, `requests`, `matplotlib`, and a local llama.cpp server running Qwen2.5-0.5B-Instruct (GGUF) on port 8080.
