# DocChat

DocChat is a free, open-source Mac app that lets you have a conversation with any document. You drop in a PDF, a photo of a page, or a text file, and then you just ask questions about it in plain English. The app reads the document, finds the most relevant parts, and gives you a clear answer — along with the exact page number where it found the information.

Everything happens on your Mac. Your documents are never uploaded to any server, and you do not need to create an account.

---

## What can you do with it?

- Ask questions about long PDFs without reading the whole thing
- Upload a photo of a handwritten or printed page and ask questions about it
- Get a quick summary of any document
- Find specific facts, dates, names, or clauses inside a contract or report
- Switch between multiple documents in the sidebar and chat with each one

---

## What AI does it use?

You can choose which AI powers the answers. You can change this anytime from the settings panel inside the app.

| AI Option | What you need | Is it private? |
|---|---|---|
| **Apple Intelligence** | A Mac with Apple Intelligence turned on | Yes — runs fully on your Mac |
| **OpenAI (ChatGPT)** | An OpenAI API key | No — your question is sent to OpenAI |
| **Anthropic (Claude)** | An Anthropic API key | No — your question is sent to Anthropic |
| **Ollama** | The free Ollama app installed on your Mac | Yes — runs fully on your Mac |

If you are not sure which to pick, start with **Apple Intelligence** — it requires no account and no API key, and it works completely offline.

---

## Requirements

- A Mac running **macOS 26 (Tahoe)** or a newer version
- If you want to use Apple Intelligence, you need to have it enabled in **System Settings → Apple Intelligence & Siri**
- If you want to build the app yourself from the code, you need **Xcode 26** or newer

---

## How to install

Right now the easiest way is to build it yourself. Here is how to do it step by step:

**Step 1** — Download the code

```bash
git clone https://github.com/itsmeyuvraj/DocChat.git
cd DocChat
```

**Step 2** — Open it in Xcode

```bash
open Package.swift
```

**Step 3** — Set your name on the app

In Xcode, click on the **DocChat** target in the left sidebar, go to **Signing & Capabilities**, and select your Apple ID under Team. This is required to run the app on your own Mac.

**Step 4** — Run it

Press **⌘R** (Command + R) to build and launch the app.

---

## How to use it

1. Open the app — you will see an empty screen with a big drop zone in the middle
2. Drag and drop any PDF or image onto the window, or click **Choose File** to pick one
3. Wait a few seconds while the app reads and processes your document
4. Once it is done, the chat window opens automatically
5. Type your question and press Enter — the app will stream an answer back to you in real time
6. Below each answer, you will see which pages the information came from

---

## How does it actually work?

When you import a document, DocChat breaks it into small pieces of text and creates a kind of index from those pieces. When you ask a question, it searches that index to find the pieces most likely to contain the answer. It then sends only those relevant pieces — along with your question — to the AI. The AI reads those pieces and writes an answer for you.

This approach means the AI only sees the parts of your document that are actually relevant to your question. It also means the app works well even with very long documents, because it never tries to send the entire document to the AI at once.

---

## Project structure (for developers)

```
Sources/DocChat/
├── DocChatApp.swift
├── ContentView.swift
├── Models/
│   ├── Document.swift              # Data types for documents and messages
│   └── ProviderSettings.swift      # Saves your AI provider choice and API keys
├── Services/
│   ├── DocumentParser.swift        # Reads PDFs and runs OCR on images
│   ├── TextChunker.swift           # Splits text into small overlapping pieces
│   ├── EmbeddingService.swift      # Converts text into numbers for comparison
│   ├── VectorStore.swift           # Finds the most relevant pieces for a question
│   ├── DocumentStore.swift         # Manages the import process and saves data
│   ├── LLMService.swift            # Picks the right AI provider and sends the request
│   ├── AIProviding.swift           # Shared interface that all AI providers follow
│   ├── AppleIntelligenceProvider.swift
│   ├── OpenAIProvider.swift
│   ├── AnthropicProvider.swift
│   └── OllamaProvider.swift
└── Views/
    ├── DocumentLibraryView.swift   # The sidebar showing your documents
    ├── ChatView.swift              # The main chat interface
    ├── DropZoneView.swift          # The screen shown when no document is selected
    └── SettingsView.swift          # The AI provider settings panel
```

---

## What is planned next?

- Ability to ask questions across multiple documents at the same time
- Saving your chat history so you can come back to it later
- Searching for keywords across all your imported documents
- Exporting a conversation as a text or Markdown file
- Improved accuracy by using a better way to match questions to document sections

---

## License

This project is open source under the MIT License. You are free to use it, modify it, share it, or build on top of it for any purpose.
