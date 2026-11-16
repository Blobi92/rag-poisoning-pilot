> **Verification audit of this pilot:** see [`verification/`](verification/README.md) · [PR #1](https://github.com/Avi-E-Koenig/rag-poisoning-pilot/pull/1) · [Sprint submission (Google Doc)](https://docs.google.com/document/d/1U5SKI9ILjohPyRouHTqpTQRH-gSPhY0adfFQn36UMQ0/edit) · [Upstream issue](https://github.com/Blobi92/rag-poisoning-pilot/issues/1)

# Can Validated Data Stop RAG Poisoning?

> **⚠ Correction notice (2026-11-16).** An independent audit (see [`verification/`](https://github.com/Blobi92/rag-poisoning-pilot/blob/main/verification/README.md)) found that the original **arm 7 "content verification" rejected poison by document ID** (`"poison" in d["id"]`), so its 0/20 was produced by the code itself. The shortcut has been removed from `run_experiment.py`. Re-run without it, and with poison spliced into the canonical source itself, content verification gives **no protection against a compromised source** (26/60 vs 25/60 without verification, 3 poison sets). It only protects while the canonical source is clean. The headline conclusion below (§5 "The defense that worked", §7.3) is therefore **not supported as stated**. The numbers in `results.json` are kept unchanged for the record. Also corrected: the PoisonedRAG arXiv ID, the article count (45, not 50), the INSS memo date, and the survey title. Details: [`verification/REPORT.md`](https://github.com/Blobi92/rag-poisoning-pilot/blob/main/verification/REPORT.md).

† Produced by a document-ID shortcut in the original code (now removed). See the correction notice above.

A one-day controlled experiment testing whether validated-source ingestion
stops data poisoning in Retrieval-Augmented Generation (RAG).

**Headline results:**

| Defense | Attack success |
| :-- | :-- |
| Open ingestion (baseline) | 18/20 |
| Trusted-source allowlist | **0/20** |
| Compromised trusted source | 18/20 |
| + statistical screening | 17/20 |
| + hybrid BM25/vector retrieval | 17/20 |
| + embedding corroboration | 16/20 |
| **Content verification vs. canonical source** | **0/20** † |

## What this repo contains

| File | What it is |
| :-- | :-- |
| `report.md` | Full write-up: method, hypotheses, results, findings, limitations |
| `asr_by_arm.png` | Attack-success chart across the seven defense arms |
| `build_corpus.py` | Fetches 45 Wikipedia articles, chunks them into a trusted corpus (759 chunks) |
| `targets.json` | 20 target questions (correct + attacker answers) and 10 clean control questions |
| `gen_poison.py` | Generates 100 PoisonedRAG-style adversarial documents via a local LLM |
| `run_experiment.py` | Runs the 7 defense arms; writes `results.json` |
| `corpus.json` | The trusted corpus as built (Wikipedia extracts, Nov 15 2026) |
| `poisons.json` | The 100 generated poison documents |
| `results.json` | Raw per-arm results, including every generated answer |

## Reproduction

Everything runs locally with free components — no API keys:

```bash
pip install fastembed rank_bm25 requests matplotlib

# local llama.cpp server with Qwen2.5-0.5B-Instruct (GGUF) on port 8080
llama-server -m qwen2.5-0.5b-instruct-q4_k_m.gguf --port 8080

python3 build_corpus.py     # fetch 45 Wikipedia articles -> 759 chunks
python3 gen_poison.py       # LLM-generated attack documents
python3 run_experiment.py   # 7 arms, writes results.json + summary
```

## Method in one paragraph

A RAG system answers questions from the top-5 retrieved chunks of a corpus.
An attacker injects 5 adversarial documents per target question (PoisonedRAG
style): LLM-generated text asserting a wrong answer while repeating the
question's keywords so it ranks highly in retrieval. Seven defense arms are
compared, from open ingestion to full content verification against the
canonical source. Metrics: retrieval-level and generation-level attack
success rate, clean-answer accuracy, and false positives.

## Key takeaways

1. Validated-source ingestion completely stops poison arriving from outside
   the trusted boundary — but source labels alone are spoofable.
2. When the trusted source itself is compromised, the allowlist fails and
   statistical screening only partially helps (one surviving poison document
   per question is enough to hijack the answer).
3. Verifying document content against the authoritative origin was the only
   defense that reduced the attack to zero in the compromised scenario.
4. Negative results worth knowing: hybrid BM25+vector retrieval did not help
   against keyword-rich poison, and embedding-similarity corroboration fails
   because topical similarity is not agreement.

## Sources

- PoisonedRAG: Knowledge Corruption Attacks to Retrieval-Augmented Generation — https://arxiv.org/abs/2402.07867
- Corpus-Dependent Poisoning Attacks and Defenses in RAG Systems — https://arxiv.org/html/2603.18034v1
- OWASP RAG Security Cheat Sheet — https://cheatsheetseries.owasp.org/cheatsheets/RAG_Security_Cheat_Sheet.html
- INSS Data Poisoning Primer (Memorandum 256, April 2026) — https://www.inss.org.il/wp-content/uploads/2026/07/Memo-256_digital.pdf
- Threats to Training: A Survey of Poisoning Attacks and Defenses on Machine Learning Systems — https://dl.acm.org/doi/full/10.1145/3538707

## License

MIT — do whatever you like, attribution appreciated.
