# TESS - Phase 6 Agent & Action Layer

TESS is a personal AI companion that will eventually evolve into a personal AI operating system. 
Phase 6 introduces the "Agent & Action Layer", enabling TESS to create explicit plans to mutate external systems (like OpenProject) and execute them via a Tool Router only after explicitly requesting user confirmation for Medium/High risk actions.

## Architecture
- **Mobile**: React Native + Expo (TypeScript)
- **Backend**: Python + FastAPI
- **Database**: Supabase PostgreSQL
- **AI**: Configurable provider (Ollama / OpenRouter)

## Prerequisites
- Node.js (for Expo)
- Python 3.10+
- Supabase account (or local setup)
- Ollama (for local AI)

## Installation

### Environment Setup
1. Copy `.env.example` to `.env` in the root directory.
2. Fill in the values for Supabase, and your preferred AI provider.

### Backend
```bash
cd backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

### Mobile
```bash
cd mobile
npm install
npx expo start
```

## AI Configuration
You can configure TESS to use either a local Ollama instance or OpenRouter for cloud LLMs.

### Using Ollama
1. Install Ollama and start it.
2. Pull a model, e.g., `ollama pull llama3`.
3. Set `AI_PROVIDER=ollama` and `OLLAMA_MODEL=llama3` in `.env`.

### Using OpenRouter
1. Set `AI_PROVIDER=openrouter`.
2. Provide your `OPENROUTER_API_KEY` and the desired `OPENROUTER_MODEL` in `.env`.

## Troubleshooting
- If the backend cannot reach the AI provider, check your `OLLAMA_BASE_URL` or `OPENROUTER_API_KEY`.
- For React Native issues, try clearing the Expo cache: `npx expo start -c`.
