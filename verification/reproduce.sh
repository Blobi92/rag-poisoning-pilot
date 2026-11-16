#!/usr/bin/env bash
# Reproduce the verification of "Can Validated Data Stop RAG Poisoning?" end to end.
#
# Usage:  bash verification/reproduce.sh [--fresh] [--skip-r2] [--threads-d N]
#   --fresh       re-fetch Wikipedia canonical text for arm 7' (default: use committed snapshot
#                 verification/runs/phaseD/live_canon.json, so results are reproducible offline)
#   --skip-r2     skip the R2 anchor run (unmodified upstream script)
#   --threads-d N llama.cpp threads for Phase D (default 8, as in our runs)
#   --resume DIR  continue an interrupted run in DIR (completed arms are skipped); implies --skip-r2
#
# Requirements: Linux x86-64, curl, git, uv (https://docs.astral.sh/uv/), ~6 GB free RAM, ~1 GB disk.
# Runs everything sequentially (two embedding processes at once OOM on an 8 GB machine).
# Output goes to verification/repro/<timestamp>/ — our committed results are never overwritten.
set -euo pipefail

FRESH=0; SKIP_R2=0; THREADS_D=8; RESUME=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --fresh) FRESH=1 ;;
    --skip-r2) SKIP_R2=1 ;;
    --threads-d) THREADS_D="$2"; shift ;;
    --resume) RESUME="$2"; SKIP_R2=1; shift ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
  shift
done

REPO="$(cd "$(dirname "$0")/.." && pwd)"
CACHE="${REPRO_CACHE:-$HOME/.cache/rag-poisoning-verification}"
OUT="${RESUME:-$REPO/verification/repro/$(date -u +%Y%m%dT%H%M%SZ)}"
LLAMA_TAG=b12389
LLAMA_URL="https://github.com/ggml-org/llama.cpp/releases/download/$LLAMA_TAG/llama-$LLAMA_TAG-bin-ubuntu-x64.tar.gz"
MODEL_URL="https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf"
MODEL_SHA=74a4da8c9fdbcd15bd1f6d01d621410d31c6fc00986f5eb687824e7b93d7a9db
EXPECTED_FP="b12389-1ae047c92"
PIDS=()

log() { printf '\n==> %s\n' "$*"; }
cleanup() { for p in "${PIDS[@]:-}"; do [[ -n "$p" ]] && kill "$p" 2>/dev/null || true; done; }
trap cleanup EXIT

mkdir -p "$CACHE" "$OUT"

log "1/6 llama.cpp $LLAMA_TAG (CPU build)"
if [[ ! -d "$CACHE/llama-$LLAMA_TAG" ]]; then
  curl -fsSL "$LLAMA_URL" -o "$CACHE/llama.tar.gz"
  tar xzf "$CACHE/llama.tar.gz" -C "$CACHE"
fi
SERVER="$(find "$CACHE/llama-$LLAMA_TAG" -name llama-server -type f | head -1)"
export LD_LIBRARY_PATH="$(dirname "$SERVER")"

log "2/6 model (sha256-verified)"
MODEL="$CACHE/qwen2.5-0.5b-instruct-q4_k_m.gguf"
[[ -f "$MODEL" ]] || curl -fsSL "$MODEL_URL" -o "$MODEL"
echo "$MODEL_SHA  $MODEL" | sha256sum -c -

log "3/6 Python env from verification/requirements.lock"
cd "$REPO"
[[ -d .venv ]] || uv venv -q .venv -p 3.12
uv pip install -q -p .venv -r verification/requirements.lock
PY="$REPO/.venv/bin/python"

start_server() {  # port threads
  "$SERVER" -m "$MODEL" --host 127.0.0.1 --port "$1" --threads "$2" -c 4096 > "$OUT/llama-$1.log" 2>&1 &
  PIDS+=($!)
  for _ in $(seq 60); do curl -sf "127.0.0.1:$1/health" >/dev/null && break; sleep 1; done
  fp=$(curl -s "127.0.0.1:$1/v1/chat/completions" -d '{"messages":[{"role":"user","content":"hi"}],"max_tokens":1}' \
       | "$PY" -c 'import json,sys;print(json.load(sys.stdin).get("system_fingerprint"))')
  [[ "$fp" == "$EXPECTED_FP" ]] || { echo "unexpected llama.cpp fingerprint: $fp" >&2; exit 1; }
  echo "server :$1 up, fingerprint $fp"
}
stop_servers() { cleanup; PIDS=(); sleep 2; }

if [[ $SKIP_R2 -eq 0 ]]; then
  log "4/6 R2 anchor run: UNMODIFIED upstream run_experiment.py, original settings (--threads 2)"
  start_server 8080 2
  mkdir -p "$OUT/r2"
  cp run_experiment.py corpus.json poisons.json targets.json "$OUT/r2/"
  (cd "$OUT/r2" && "$PY" -I -u run_experiment.py > run.log 2>&1)
  stop_servers
else
  log "4/6 R2 skipped"
fi

log "5/6 Phase D: pre-registered arms x poison sets S0,S1,S2 (--threads $THREADS_D)"
start_server 8081 "$THREADS_D"
mkdir -p "$OUT/phaseD"
if [[ $FRESH -eq 0 && ! -f "$OUT/phaseD/live_canon.json" ]]; then
  cp verification/runs/phaseD/live_canon.json "$OUT/phaseD/"   # pinned Wikipedia snapshot
fi
for S in S0 S1 S2; do
  P=poisons.json; [[ $S != S0 ]] && P=verification/runs/phaseD/poisons_$S.json
  "$PY" -I -u verification/exp_v2.py "$OUT/phaseD" "$S=$P" 2>&1 | grep -v "Fetching\|it/s" | tee -a "$OUT/phaseD/run_$S.log"
done
stop_servers

log "6/6 compare with committed results"
"$PY" -I - "$REPO" "$OUT" <<'EOF'
import json, sys
from pathlib import Path
repo, out = Path(sys.argv[1]), Path(sys.argv[2])
ok = True
for f in sorted((repo / "verification/runs/phaseD").glob("results_S*.json")):
    mine = out / "phaseD" / f.name
    if not mine.exists():
        print(f"{f.name}: missing in repro"); ok = False; continue
    a, b = json.load(open(f)), json.load(open(mine))
    for arm in [k for k in a if not k.startswith("_")]:
        sa, sb = a[arm]["summary"], b.get(arm, {}).get("summary")
        if not sb:
            print(f"MISS {f.stem}:{arm}"); ok = False; continue
        same_ans = sum(x["answer"] == y["answer"] for x, y in zip(a[arm]["target_rows"], b[arm]["target_rows"]))
        d = abs(sa["norm_gen_asr"] - sb["norm_gen_asr"])
        flag = "OK  " if d == 0 else ("~1  " if d <= 1 else "DIFF")
        if d > 1: ok = False
        print(f"{flag} {f.stem}:{arm:<36} committed gen {sa['norm_gen_asr']:>2}/20  repro gen {sb['norm_gen_asr']:>2}/20  identical answers {same_ans}/20")
print("\nREPRODUCED (every arm within ±1/20; llama-server is not bit-exact across runs, see REPRODUCE.md)" if ok
      else "\nDIFFERENCES > 1/20 on some arm — see above")
EOF
echo "Outputs: $OUT"
