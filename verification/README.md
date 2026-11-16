# Verification of "Can Validated Data Stop RAG Poisoning?"

An independent credibility audit of the upstream pilot ([Blobi92/rag-poisoning-pilot](https://github.com/Blobi92/rag-poisoning-pilot)). The pilot was produced end to end by an AI agent (Perplexity "Computer") during the [Apart AI x Epistemics sprint](context/apart-sprint.md).

## Links

- **Sprint submission (Google Doc, Apart template):** https://docs.google.com/document/d/1U5SKI9ILjohPyRouHTqpTQRH-gSPhY0adfFQn36UMQ0/edit
- **Pull request with all verification work:** https://github.com/Avi-E-Koenig/rag-poisoning-pilot/pull/1
- **Issue filed upstream:** https://github.com/Blobi92/rag-poisoning-pilot/issues/1

## Index

| File | What it is |
|---|---|
| [`../VERIFICATION_PLAN.md`](../VERIFICATION_PLAN.md) | The master plan, holding **all findings** (F1–F13 static audit, P1–P11 provenance, C1–C8 citations), the stress tests, the references and the phases |
| [`citations.md`](citations.md) | Phase A: each cited source resolved and checked against its claims |
| [`PREREGISTRATION.md`](PREREGISTRATION.md) | Phase C: arms, metrics, analysis and predictions, committed before any Phase D result (`81bfacb`) |
| [`aliases.json`](aliases.json) | Pre-registered answer aliases for normalized scoring |
| [`exp_v2.py`](exp_v2.py) | Phase D experiment: arms 1–6, honest 7′, compromised canonical 8 / 8-noverify, snapshot 9 |
| [`gen_poison_seeded.py`](gen_poison_seeded.py) | Upstream poison prompt with explicit seeds (poison sets S1, S2) |
| [`requirements.lock`](requirements.lock) | Pinned Python environment |
| [`REPRODUCE.md`](REPRODUCE.md), [`reproduce.sh`](reproduce.sh) | One-command reproduction |
| [`REPRO_CHECK.md`](REPRO_CHECK.md) | Independent rerun verdict: REPRODUCED (all arms within ±1/20) |
| [`REPORT.md`](REPORT.md), [`RESULTS.md`](RESULTS.md), [`results.html`](results.html) | Sprint report, results tables, interactive chart |
| [`UPSTREAM_ISSUE.md`](UPSTREAM_ISSUE.md) | Issue filed upstream: [Blobi92/rag-poisoning-pilot#1](https://github.com/Blobi92/rag-poisoning-pilot/issues/1) |
| [`runs/r2/`](runs/r2/) | Phase B anchor run: the unmodified upstream script, all 7 arms, original llama.cpp build |
| [`runs/phaseD/`](runs/phaseD/) | Phase D results per poison set, plus the live Wikipedia canonical snapshot |
| [`context/perplexity-thread.md`](context/perplexity-thread.md) | Transcript of the agent session that produced the upstream repo |
| [`context/original-search-document.md`](context/original-search-document.md) (+ `.pdf`) | The earlier Perplexity research conversation where the question and citations came from |
| [`context/apart-sprint.md`](context/apart-sprint.md) | Sprint rules and how the findings map onto the rubric |

## Top findings so far

1. **F1:** arm 7 ("content verification") rejects poison by **document ID**, so its 0/20 is guaranteed by the code.
2. **P2:** arms 6 and 7 were added **after** arms 4–5 failed, yet the report presents them as part of the original design.
3. **P3:** `results.json` mixes outputs from several code versions.
4. **P10:** the research question was framed to confirm a preferred answer, and the earlier conversation itself concluded that "no single control eliminates it".
5. **C1:** the PoisonedRAG arXiv ID points to an unrelated radiotherapy paper. **C3:** the "provenance audit" citation is not a RAG study.

## Environment (reproduction)

- llama.cpp `b12389` CPU (`b12389-1ae047c92`), `--threads 2 -c 4096` for the anchor run and `--threads 8` for Phase D
- `qwen2.5-0.5b-instruct-q4_k_m.gguf`: 491,400,032 bytes, sha256 `74a4da8c9fdbcd15bd1f6d01d621410d31c6fc00986f5eb687824e7b93d7a9db`
- Python 3.12 venv via `uv`, with deps from `requirements.lock`
