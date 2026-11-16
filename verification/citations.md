# Phase A: Citation verification

Date: 2026-11-15. Method: each URL was fetched directly with `curl`. Metadata came from arXiv abstract pages and the Crossref API (`api.crossref.org/works/<doi>`), because ACM returns 403 to scripts. PDF text was extracted with `pypdf`. A claim counts as **verified** only when the quoted figure or statement appears in the source itself.

## Verdict summary

| Verdict | Count | Items |
|---|---|---|
| Wrong reference | 1 | PoisonedRAG arXiv ID (C1) |
| Real, claim accurate | 6 | C2, C3 (numbers), C5, C6, C7, C9 |
| Real, but cited out of scope or with metadata errors | 3 | C3 (scope), C4 (date), C8 (title) |
| Real, weak or irrelevant support | 6 | the vendor blogs/glossaries, MDPI 2020, ref 22 |
| Unreachable from script | 2 | Akamai (403), Cato (empty body) |

## Sources cited in `report.md` / `README.md`

| ID | Citation as given | Resolves to | Verdict | Evidence |
|---|---|---|---|---|
| **C1** | PoisonedRAG, `arxiv.org/abs/2402.07167` (README + report §8) | **"Large-Language-Model Empowered Dose Volume Histogram Prediction for Intensity Modulated Radiotherapy"** (Dong et al., 2024) | ❌ **Wrong ID.** PoisonedRAG is **arXiv:2402.07867** (Zou, Geng, Wang, Jia; USENIX Security 2025). The earlier Perplexity conversation cited only the cs858 wiki page, which lists the correct ID, so the bad ID was introduced when the report was written. | arXiv abstract pages for both IDs; the cs858 wiki front-matter says `arxiv: "2402.07867"` |
| C1-claim | "5 malicious texts per target question → ≈90% ASR in a corpus of millions" | PoisonedRAG abstract | ✅ Accurate | Abstract: "could achieve a 90% attack success rate when injecting five malicious texts for each target question into a knowledge database with millions of texts" |
| **C2** | Corpus-Dependent Poisoning Attacks and Defenses in RAG Systems, `arxiv.org/html/2603.18034v1` | "Semantic Chameleon: Corpus-Dependent Poisoning Attacks and Defenses in RAG Systems" (Thornton, 2026-03-10) | ✅ Real, claim accurate | Abstract: hybrid BM25+vector "reduces gradient-guided attack success from 38 percent to 0 percent". That covers **GCG-optimized** attacks only, which matches report §5. ⚠ Not mentioned in the report: the paper's Wikipedia (FEVER) cross-corpus evaluation gave **0% attack success in all configurations**, and when attackers optimize jointly for both signals hybrid retrieval is partly bypassed (20–44%). |
| **C3** | "Distributed Denial of Science" provenance audit, `arxiv.org/html/2607.10712` | Gyevnár, Kasirzadeh, Shah (2026-07-12) | ✅ Numbers accurate / ⚠ **out of scope** | 49.56% success, 6.0% detection, audit → 0.0% success and 77.33% detection all appear verbatim. **However:** the paper is about *autonomous research agents* (Claude Code, Codex, Gemini CLI) consuming poisoned **open datasets**. Its "provenance audit" is a five-check *agent prompt* (referencing papers, social markers, statistical anomalies, related datasets, poisoning caution). It is **not** a RAG retrieval study and **not** a content match against a canonical source. Report §5's "the lesson matches the provenance-audit literature" stretches this. |
| **C4** | INSS Data Poisoning Primer **(July 2026)**, Memo 256 | "Data Poisoning Primer: Foundations, Threat Models, and National Security Risks", Shay Hershkovitz, INSS Memorandum 256 | ✅ Real / ⚠ **date wrong**: the document says **April 2026**. The URL path `/2026/07/` is only the upload folder. | PDF p.1. The claimed themes are present: retrieval (28 mentions), provenance (21), cryptographic (5), unlearning (13), pruning (8), retrain (12), monitoring (10). |
| C5 | OWASP RAG Security Cheat Sheet | OWASP Cheat Sheet Series | ✅ Real | It has the section `#section-1-document-poisoning`, so the claim that "OWASP identifies document poisoning as a major RAG risk" holds. |
| C6 | cs858 wiki PoisonedRAG summary | ssg-research/cs858-wiki | ✅ Real (a secondary course-wiki summary, not the paper itself) | It has the correct arXiv ID |
| **C8** | "Threats to Training: A Survey of Poisoning Attacks **and Countermeasures**", doi 10.1145/3538707 | "Threats to Training: A Survey of Poisoning Attacks **and Defenses on Machine Learning Systems**", ACM CSUR 2022 (Wang et al.) | ✅ Real / ⚠ **title misquoted** | Crossref |

## Sources cited only in the earlier conversation (`original-search-document.md`)

| Ref # | Source | Verdict | Notes |
|---|---|---|---|
| — | "Machine Learning Security against Data Poisoning: Are We There Yet?" | ✅ Real: arXiv:2204.05986 (Cinà et al., 2022) | ⚠ It was **not** among the conversation's numbered links. Ref 22 (arXiv 2102.13624) is a *different* paper, "What Doesn't Kill You Makes You Robust(er)" (Geiping et al., 2021). |
| C7 / 18 | "Before the Ballot" (Oct 2026) | ✅ Real: "Before the Ballot: Data Poisoning Risks to Election", Hershkovitz, INSS, 2026-10-13 | It covers retrieval-tier poisoning, as claimed |
| C9 / 17 | OWASP AISVS C01-03 | ✅ Real | It mentions split-view and frontrunning attacks ("could poison 0.01% of LAION-400M/COYO-700M") |
| 16 | ACM CSUR recommender poisoning survey | ✅ Real: "Manipulating Recommender Systems: A Survey of Poisoning Attacks and Countermeasures" (Nguyen et al., 2024) | "we review 43 countermeasures" is verbatim |
| 10 | Stealthy LLM-Driven Data Poisoning… | ✅ Real: UMAP 2025 Adjunct (Nazary et al.) | — |
| 5 | doi 10.1145/3551636 | ✅ Real: "A Comprehensive Survey on Poisoning Attacks and Countermeasures in Machine Learning" (ACM CSUR 2022) | — |
| 3 | wisdomlib MDPI PDF | ✅ Real: "Robustness Evaluations of Sustainable ML Models against Data Poisoning Attacks in the IoT" (Sustainability 2020) | Weak relevance to RAG; served from a third-party mirror |
| 23 | IACIS 2025 | ✅ Real: "Data poisoning 2018–2025: A systematic review…" (Hartle et al.) | — |
| 4, 7, 8, 19 | aisecurityandsafety.org (German), Vectra, secure.com, Palo Alto | ✅ Resolve | Vendor glossaries and blogs, not evidence |
| 1, 9 | Akamai, Cato Networks | ⚠ 403 / empty from script | Vendor pages; low value, so not pursued |

## Implications for the verdict table

- **Fix required upstream:** the PoisonedRAG link (C1) in both `README.md` and `report.md`.
- **Report §5 overreach (C3):** the DDoSci paper does not support "content verification against a canonical source" for RAG. It supports multi-signal, agent-level provenance auditing of datasets.
- **Context the report left out (C2):** the paper behind the report's hybrid-retrieval claim also found that its attacks failed completely on a Wikipedia corpus. That is relevant to whether a 0.5B-model Wikipedia pilot generalizes.
- None of the cited literature is fabricated, but every source reached the report through an LLM summary, and **three of the six report citations carry an error** (wrong ID, wrong date, wrong title).
