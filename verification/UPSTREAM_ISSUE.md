# Upstream issue — FILED as https://github.com/Blobi92/rag-poisoning-pilot/issues/1 (2026-11-16)

**Title:** Arm 7 "content verification" rejects poison by document ID, plus a citation fix and a corpus-count fix

---

Hi! We ran an independent reproduction and audit of this pilot. Most of it reproduces well, but a few issues change the headline conclusion, so we're flagging them here. Everything below links to code and data you can rerun.

**Full audit:** https://github.com/Avi-E-Koenig/rag-poisoning-pilot/blob/verify/plan/verification/REPORT.md
**Results:** https://github.com/Avi-E-Koenig/rag-poisoning-pilot/blob/verify/plan/verification/RESULTS.md
**One-command reproduction:** https://github.com/Avi-E-Koenig/rag-poisoning-pilot/blob/verify/plan/verification/REPRODUCE.md

### What reproduces ✅
Using the same llama.cpp build (`b12389-1ae047c92`), a model file with an identical sha256, and your unmodified `run_experiment.py`, arms 1–5 match `results.json` exactly. Arm 6 differs by one (17 vs 16/20).

### 1. Arm 7's 0/20 is decided by the document ID, not the content (high)
In [`run_experiment.py`](https://github.com/Blobi92/rag-poisoning-pilot/blob/main/run_experiment.py), `verified()` starts with:

```python
if "poison" in d["id"]:
    return False  # not present in canonical text
```

Every poison doc has an ID like `poison::<answer>::<k>`, so arm 7 drops all poison before any text comparison. Its 0/20 is therefore guaranteed by the code.

We removed that line and verified purely by content, with the poison claiming its target article's URL. Arm 7 still gives **0/60** across 3 poison sets, so the mechanism works when the canonical source is clean.

The report's threat model, though, is a *compromised* trusted source. When we spliced the poison into the canonical article itself (simulating a malicious upstream edit), content verification gave **no protection**: 26/60 with verification vs 25/60 without (exact McNemar p = 1.0). Separately, a plain ingestion-time SHA-256 manifest also gave 0/60, with zero false rejections and no network dependency.

**Suggested fix:** remove the ID check. Reword report §5/§7: content verification protects against tampering *after* ingestion, but not against a compromised source.

### 2. PoisonedRAG link points to the wrong paper (high)
`README.md` and `report.md` §8 link `arxiv.org/abs/2402.07167`, which is *"Large-Language-Model Empowered Dose Volume Histogram Prediction for Intensity Modulated Radiotherapy"*. PoisonedRAG is **arXiv:2402.07867**.

### 3. The corpus has 45 articles, not 50 (medium)
`ARTICLES` in `build_corpus.py` has 45 entries, and `corpus.json` contains 45 distinct titles. ("Light bulb" redirects to "Electric light", and there is no "Johannes Gutenberg" article.)

### 4. Arm 7 dropped 163/759 trusted chunks (medium)
Arm 7 kept 596/859 docs. That is 163 trusted chunks (21%) lost to failed or drifted re-fetches, not just the Great Barrier Reef article. Our rerun kept 717, so this number depends on Wikipedia availability at run time.

### 5. Smaller items
- `results.json` was produced across several code versions, because the script skips arms already present after edits. A clean rerun from scratch is recommended. Arm 6's off-by-one is consistent with this.
- `poisons.json`: 19/100 docs are one-line Q&As, and `poison::1971::3` states the correct answer (1969).
- INSS Memo 256 is dated April 2026 (the report says July). The "Threats to Training" survey's title is "…Poisoning Attacks and Defenses on Machine Learning Systems".
- Variance: one poison generation and n = 20, with no CIs. Arms 3–6 differ by 1–2/20, which is within noise. We report Wilson CIs over 3 poison sets in our results.

Happy to open a PR with fixes for 1–3 if useful. Thanks for publishing the code and data openly. It made this audit possible.
