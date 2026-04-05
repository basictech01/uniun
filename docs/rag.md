 What is RAG?
                                                                                
  RAG = Retrieval Augmented Generation                      
                                                                                
  Without RAG, Shiv only knows what the LLM was trained on. It has no idea what 
  YOU wrote in your notes.
                                                                                
  With RAG, Shiv can answer questions like:                                     
  - "What did I write about machine learning?"
  - "Summarize my notes on project X"                                           
  - "Find everything I saved about Nostr"                   
                                                                                
  ---                                                                           
  The Core Idea
                                                                                
  Normal LLM:                                               
    User asks → LLM answers from training data only                             
                                                                                
  RAG:                                                                          
    User asks → Find relevant notes → Give notes + question to LLM → Better     
  answer                                                                        
  
  The LLM's context window becomes a temporary "working memory" that you fill   
  with the user's own notes before asking the question.     
                                                                                
  ---                                                       
  How It Works — Step by Step
                             
  Step 1: When a note is SAVED → generate embedding
                                                                                
  User saves a note
          ↓                                                                     
  Note content → Embedding Model → [0.12, -0.45, 0.89, ...] (384 numbers)       
          ↓                                                                     
  Store: NoteModel.embedding = [0.12, -0.45, 0.89, ...] in Isar                 
                                                                                
  An embedding is just a list of numbers that captures the semantic meaning of  
  the text. Notes about similar topics produce similar number patterns.         
                                                                                
  ---                                                       
  Step 2: When user asks Shiv a question → find relevant notes

  User types: "what did I write about relays?"
          ↓                                                                     
  Same Embedding Model → [0.08, -0.41, 0.92, ...] (question as numbers)
          ↓                                                                     
  Compare against ALL saved note embeddings in Isar         
          ↓                                                                     
  Cosine Similarity:                                                            
    Note A (about relays) → similarity: 0.91  ✅ very relevant
    Note B (about Python)  → similarity: 0.23  ❌ not relevant                  
    Note C (about Nostr)   → similarity: 0.78  ✅ relevant                      
          ↓                                                                     
  Pick top 3-5 most similar notes                                               
                                                                                
  Cosine similarity = a formula that measures how "close" two vectors are.      
  Result is 0 (unrelated) to 1 (identical meaning).                             
                                                                                
  ---                                                       
  Step 3: Build the LLM prompt with context
                                           
  final prompt = """
  You are Shiv, a personal AI assistant.                                        
  Use the following notes from the user to answer their question.
                                                                                
  --- USER NOTES ---                                        
  Note 1: ${relevantNotes[0].content}                                           
  Note 2: ${relevantNotes[1].content}                                           
  Note 3: ${relevantNotes[2].content}
  --- END NOTES ---                                                             
                                                            
  User question: what did I write about relays?                                 
                                                            
  Answer based on the notes above:                                              
  """;                                                      

  ---
  Step 4: LLM streams back the answer
                                     
  The LLM reads the injected notes + the question and generates a grounded
  answer. It's not guessing from training data — it's reading the user's own    
  notes.
                                                                                
  ---                                                       
  The Two Models Needed
                                                                                
  ┌────────────────┬─────────────────┬──────────────────────────────────────────┐
  │     Model      │       Job       │                Size                      │
  ├────────────────┼─────────────────┼──────────────────────────────────────────┤
  │ Embedding      │ Converts text   │ ~80MB (all-MiniLM-L6-v2) — bundled       │
  │ model          │ to vector       │ always available, no download needed      │
  ├────────────────┼─────────────────┼──────────────────────────────────────────┤
  │ LLM (user-     │ Generates the   │ 586MB–4.3GB depending on model chosen     │
  │ selected, via  │ answer          │ flutter_gemma ^0.13.1                     │
  │ flutter_gemma) │                 │ GPU-accelerated on Android + iOS          │
  │                │                 │ Downloaded once on first Shiv open        │
  └────────────────┴─────────────────┴──────────────────────────────────────────┘

  These run separately. The embedding model runs fast, synchronously. The LLM
  (flutter_gemma) runs slower, streams tokens via getResponseStream().

  For available LLM options see docs/SHIV_AI.md — Model Selection section.
                                                                                
  ---                                                       
  The Challenge: Vector Search in Isar
                                                                                
  Isar has no native vector search. So how do you find similar notes?
                                                                                
  For small corpus (<5,000 saved notes):                                        
  Load all embeddings from Isar into memory                                     
  For each → compute cosine similarity with query vector                        
  Sort by score → pick top K                                                    
  This is fast enough in Dart for small collections.
                                                                                
  For large corpus (future):                                                    
  - Migrate to sqlite-vec (SQLite vector extension) or usearch                  
  - Or maintain a separate HNSW index on device                                 
                                                            
  For UNIUN's use case (personal notes app), most users will have <1,000 saved  
  notes. In-memory Dart computation is totally fine.                            
   
  ---                                                                           
  Full Flow Diagram                                         

  SAVE TIME:
  Note saved → Embedding model → vector → stored in Isar (NoteModel.embedding)
                                                                                
  QUERY TIME:
  User question                                                                 
        ↓                                                                       
  Embedding model → query vector
        ↓                                                                       
  Load all saved note embeddings from Isar                  
        ↓
  Cosine similarity → rank notes
        ↓                                                                       
  Top 3-5 notes retrieved
        ↓                                                                       
  Build prompt: [system prompt + notes + question]          
        ↓                                                                       
  LLM → streams answer token by token
        ↓                                                                       
  ShivStreamingText widget shows it live                                        
   
  ---                                                                           
  Why Only Saved Notes?                                     
                                                                                
  Because:
  1. Regular notes get cleaned up after 7 days (CleanupManager)                 
  2. The user explicitly chose to save these — they're the "important" ones
  3. Generating embeddings for every note ever seen would be wasteful      
  4. Saved notes = the user's personal knowledge base                           
                                                                                
  ---                                                                           
  What Shiv Can Do With This                                                    
                                                                                
  - "Summarize everything I saved this week"                
  - "What are my notes about <topic>?"                                          
  - "Do I have anything related to <question>?"
  - "Find contradictions in my notes about <topic>"                             
  - Future: RAG over referenced notes graph (follow e tags to pull thread
  context)                                                                      
                                                            
  ---                                                                           
  Build Sequence for Shiv                                   

  1. Embedding model integration  (runs offline, no relay needed)
  2. Save note → generate + store embedding                                     
  3. Query pipeline: embed → cosine sim → top-K                                 
  4. Prompt builder (inject notes into LLM context)                             
  5. ShivAIBloc: handle streaming response                                      
  6. Chat UI: ShivStreamingText (token-by-token render)                         
  7. Model selection page (AIModelSelectionPage — see docs/SHIV_AI.md)                 
                                                                                
  This is why Shiv is built last — it needs:
  - Vishnu (so notes exist)
  - Brahma (so user can create notes)
  - Saved notes (so embeddings exist)

  ---
  Next Level: GraphRAG

  Standard vector RAG only finds notes that are semantically similar to the query.
  GraphRAG also traverses the knowledge graph — following note references (e tags),
  topic links (t tags), and reply chains to find connected context that vector
  similarity would miss.

  UNIUN's knowledge graph (already built via Nostr tags) can be used directly as
  a GraphRAG graph — no extra entity extraction needed.

  See docs/graphrag.md for full details.                       
                                                            