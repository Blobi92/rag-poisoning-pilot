# Reproducing the verification

> **Verified:** an independent run of this script from an empty cache reproduced every Phase D arm within ±1/20 (27/30 exactly). See [`REPRO_CHECK.md`](REPRO_CHECK.md).

One command reruns everything from a clean clone:

```bash
git clone https://github.com/Avi-E-Koenig/rag-poisoning-pilot && cd rag-poisoning-pilot
git checkout verify/plan
bash verification/reproduce.sh            # about 1–1.5 h on a laptop CPU, no GPU needed
```

The script:

1. downloads llama.cpp **b12389** (CPU build) and checks the server fingerprint `b12389-1ae047c92`;
2. downloads `qwen2.5-0.5b-instruct-q4_k_m.gguf` and **verifies its sha256** (`74a4da8c…a9db`);
3. builds a Python 3.12 venv from `verification/requirements.lock` using `uv`;
4. runs **R2**, the *unmodified* upstream `run_experiment.py` with the original settings (`--threads 2 -c 4096`);
5. runs **Phase D** ([`exp_v2.py`](exp_v2.py)) on the poison sets S0, S1 and S2;
6. compares each arm's summary against our committed results and prints `OK` or `DIFF`.

Outputs go to `verification/repro/<timestamp>/`. The committed results are never overwritten.

Requirements: Linux x86-64 (WSL2 works), `curl`, `git`, [`uv`](https://docs.astral.sh/uv/), ≥ 6 GB free RAM, ~1 GB disk. The steps run **one at a time on purpose**: two embedding processes at once ran out of memory on an 8 GB machine.

## What is pinned and what isn't

| Input | Pinned how |
|---|---|
| Generator | llama.cpp b12389 CPU build and the model sha256. Temperature 0. |
| Embedder | `sentence-transformers/all-MiniLM-L6-v2` via `fastembed` at the version in `requirements.lock` |
| Trusted corpus | Upstream `corpus.json` (committed) |
| Poison sets | S0 = upstream `poisons.json`. S1/S2 = `verification/runs/phaseD/poisons_S{1,2}.json` (committed; regenerate with `gen_poison_seeded.py <seed>`) |
| Canonical Wikipedia text (arm 7′) | **Snapshot** `verification/runs/phaseD/live_canon.json` (fetched 2026-11-15). `--fresh` fetches it again live. |
| Answer scoring | `verification/aliases.json`, pre-registered in `PREREGISTRATION.md` |

## Known sources of difference

- **llama-server is not bit-exact across runs**, even with the same build, threads and inputs at temperature 0. Rerunning S0 with identical code changed 2 of 20 answers in arm 8 and 1 in arm 8nv, by a few trailing tokens. Arm 8 moved from 9 to 10/20; arms 1, 3, 7′ and 9 were identical. `reproduce.sh` therefore counts a difference of **±1/20 per arm** as reproduced and prints per-question agreement.

- **Thread count and CPU type.** llama.cpp at temperature 0 is deterministic for a fixed build, thread count and CPU instruction set, but it can differ by a token across machines. Phase D used `--threads 8`; set it with `--threads-d`.
- **R2 arm 7** (upstream code) always fetches Wikipedia live, so its trusted-chunk count drifts as articles are edited. This is finding F5. Our arm 7′ uses the pinned snapshot.
- **`--fresh`** changes the canonical text for arm 7′, so expect differences in trusted false-rejections.

## Pausing and resuming

Stop the run at any time (Ctrl-C). Completed arms are saved after each arm. To continue:

```bash
bash verification/reproduce.sh --resume verification/repro/<timestamp>
```

## Regenerating the reports only

```bash
.venv/bin/python -I verification/analyze.py   # rebuilds RESULTS.md and results.html from verification/runs/
```
