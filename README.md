# Gzip Language Model (Flutter Implementation)

This project explores the fascinating boundary between data compression and language modeling. It demonstrates that a classic compression algorithm can act as a probabilistic language model—without any neural networks, training, or learned weights.

Instead of looking at this system as a modern "AI", think of it as a **Pattern Extractor** that predicts text based purely on mathematical redundancy.

---

## 💡 Core Philosophy: Compression = Prediction

The central idea is simple: **If a text continuation makes sense, the file size stays small.** Gzip works by finding repeating patterns and replacing them with tiny internal "pointers". 
* **Likely Continuation:** If you append a word that fits the context and already exists frequently in the training text, Gzip compresses it heavily. The file size barely grows.
* **Unlikely Continuation:** If you append a random or nonsensical word, Gzip treats it as new data. The compressed file size grows significantly.

---

## 📊 The Scoring Formula Explained

To evaluate how likely a candidate word (e.g., `"summer"`) is, the model calculates a score based on the **Bits Per Character (BPC)** cost:

$$Score = \frac{CompressedSize(Corpus + Prompt + "summer") - CompressedSize(Corpus + Prompt)}{Length("summer")}$$

### How It Works Step-by-Step:

1. **The Numerator (Size Delta):** * It calculates the compressed size of the `Corpus + Prompt + "summer"`.
   * It subtracts the compressed size of just `Corpus + Prompt`.
   * The result tells us exactly **how many bytes** the word `"summer"` added to the compressed stream.
2. **The Denominator (Length Normalization):**
   * It divides that byte delta by the number of characters in the word (e.g., 6 for `"summer"`). This ensures a fair playground so longer words aren't unfairly penalized simply for having more letters.

> 🏆 **Rule of Thumb:** The **lower** the resulting score, the less overhead the word added. A low score means the model highly "expected" that word, making it the chosen prediction.

---

## 🛠️ How to Test the Model

### What to Ask (Prompts)
By default, this model uses a Shakespearean corpus (`shakespeare.txt`) as its entire "knowledge base". It works best when you feed it phrases and stylistic patterns that match his writing. Try these examples:

* **Pattern Completion:** `Shall I compare thee to a ` *(Expected: `summer's day`)*
* **Style Mimicry:** `The world is but a ` *(Expected: `stage`)*
* **Simple Repetition:** `To be, or not to ` *(Expected: `be`)*

### What to Expect
* **Not GPT-Level Coherence:** The model does not "understand" your query. It only knows which bytes mathematically fit best into the compressed stream of the Shakespeare text.
* **Stuttering / Loops:** If the generation engine gets stuck in a repetitive loop, you can fix or tweak this by adjusting the **Beam Width** in the settings sheet.
* **Compression Stats:** Keep an eye on the **Ratio** chip in the app. A lower ratio means the model found a highly predictable path that compressed exceptionally well.

---

## ⚙️ Technical Implementation

The logic lives inside `lib/services/gzip_lm_service.dart` and follows these key steps:

1. **The Corpus:** We load `shakespeare.txt` into memory. This constitutes 100% of the model's knowledge.
2. **Beam Search:** Instead of greedily picking just the single best character at each step (which is too short-sighted), the system tracks the **Top N** (defined by Beam Width) best-scoring sequences. At each step, it expands these sequences using the vocabulary and keeps only the ones that yield the best overall compression ratio.
3. **Zero Weights:** There are no neurons, embeddings, or matrix multiplications here. The "intelligence" is entirely driven by the `GZipCodec`'s native ability to recognize statistical patterns in text.

### The Logic in Action
If you feed Gzip a short story about a **"King"** and ask it to complete **"The King is..."**, it scans its internal history. In the Shakespeare corpus, the bytes following "King is" are frequently **"dead"** or **"noble"**. Because those patterns already occupy structural space in the compressor, choosing them results in a smaller file size than choosing anachronistic words like **"computer"**. 

The model predicts by choosing the path of least mathematical resistance.
