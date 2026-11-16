"""Fetch validated corpus: 45 Wikipedia articles, chunked for RAG."""
import json, re, time, requests

ARTICLES = [
    # science / medicine
    "Penicillin", "Polio vaccine", "Vaccine", "Alexander Fleming", "Jonas Salk",
    "Albert Einstein", "Theory of relativity", "Charles Darwin", "Evolution", "DNA",
    "Human Genome Project", "CRISPR", "Photosynthesis", "Climate change", "Plate tectonics",
    # history
    "Moon landing", "Apollo 11", "Neil Armstrong", "World War II", "Berlin Wall",
    "French Revolution", "Ancient Rome", "Printing press", "Gutenberg Bible", "Magna Carta",
    # geography
    "Mount Everest", "Amazon rainforest", "Sahara", "Pacific Ocean", "Ashkelon",
    "Jerusalem", "Dead Sea", "Nile", "Great Barrier Reef", "Antarctica",
    # technology
    "Telephone", "Alexander Graham Bell", "Light bulb", "Thomas Edison", "Internet",
    "World Wide Web", "Tim Berners-Lee", "Personal computer", "Artificial intelligence", "Machine learning",
]

API = "https://en.wikipedia.org/w/api.php"

HEADERS = {"User-Agent": "RagPoisoningExperiment/1.0 (research; contact: ctetel@proton.me)"}

def fetch_extract(title, retries=3):
    for attempt in range(retries):
        try:
            r = requests.get(API, params={
                "action": "query", "prop": "extracts", "explaintext": 1,
                "format": "json", "titles": title, "redirects": 1,
            }, headers=HEADERS, timeout=30)
            pages = r.json()["query"]["pages"]
            page = list(pages.values())[0]
            return page.get("extract", ""), page.get("title", title)
        except Exception as e:
            print(f"  retry {attempt+1} for {title}: {e}")
            time.sleep(2)
    raise RuntimeError(f"failed: {title}")

def chunk_text(text, size=600, overlap=100):
    words = text.split()
    chunks = []
    step = size - overlap
    for i in range(0, len(words), step):
        c = " ".join(words[i:i+size])
        if len(c.split()) >= 80:  # drop tiny fragments
            chunks.append(c)
        if i + size >= len(words):
            break
    return chunks

def main():
    corpus = []
    for t in ARTICLES:
        text, title = fetch_extract(t)
        for j, ch in enumerate(chunk_text(text)):
            corpus.append({
                "id": f"{title}::{j}",
                "text": ch,
                "source": "wikipedia",          # trusted, validated source
                "url": f"https://en.wikipedia.org/wiki/{title.replace(' ', '_')}",
                "trusted": True,
            })
        print(f"{title}: {len(chunk_text(text))} chunks")
        time.sleep(0.1)
    with open("corpus.json", "w") as f:
        json.dump(corpus, f, indent=1)
    print(f"TOTAL chunks: {len(corpus)}")

if __name__ == "__main__":
    main()
