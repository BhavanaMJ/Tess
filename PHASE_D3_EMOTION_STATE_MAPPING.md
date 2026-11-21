# TESS Phase D3 — Emotion State Mapping & Event Architecture

## 1. Official Emotion State Matrix

| Emotion State | Visual Expression | Body & Antenna Behavior | Aura Glow Color | Triggering Application Events | Auto-Revert Behavior | Priority Score |
|---|---|---|---|---|---|---|
| **IDLE** | Relaxed almond eyes, gentle smile | Subtle 4.5s organic floating cycle | `#168F83` (TESS Teal) | Nominal application state, no active jobs | Persistent baseline | 10 |
| **THINKING** | Focused gaze tilted upward-right | Glowing antenna node pulsing (2s) | `#35B9A5` (Vibrant Mint) | Chat request sent, query in progress | Until response / error received | 55 |
| **HAPPY** | Curved joyful eyes `^_^`, cheerful smile | Slight upward buoyant lift | `#35B9A5` (Vibrant Mint) | Chat response received, progress milestone | Auto-reverts to baseline after 3.5s | 40 |
| **ATTENTION** | Alert wide eyes `O_O`, circular alert mouth | Alert status badge pulse | `#FB7185` (Coral Danger) | Overdue tasks detected, high-risk prediction | Persistent until items resolved | 80 |
| **PLANNING** | Thoughtful focused gaze | Antenna node active pulse | `#A99AD9` (Thoughtful Lavender) | Future simulation running, agent composing | Until plan generated | 60 |
| **CONFIRMING** | Questioning curious eyes `?_?` | Alert status badge pulse | `#FBBF24` (Amber Warning) | Agent plan awaiting human confirmation | Persistent until approved / cancelled | 85 |
| **ACTING** | Focused determined gaze | Focused steady posture | `#168F83` (TESS Teal) | Approved agent action actively executing | Until execution completes | 65 |
| **SUCCESS** | Celebratory radiant eyes `^_^!!` | Buoyant celebratory bounce | `#34D399` (Emerald Success) | Agent step succeeded, task synced | Auto-reverts to baseline after 3.5s | 45 |
| **ERROR** | Concerned brow angle `X_X`, downturned mouth | Sympathetic posture | `#FB7185` (Coral Danger) | Network failure, API failure, execution failed | Auto-reverts or persists on failure | 90 |

---

## 2. Event-Driven Application Integration

### 1. Companion Chat Flow (`ChatScreen.tsx`)
- Message sent by user $\rightarrow$ `setMascotState('THINKING')`
- Backend response received $\rightarrow$ `triggerEmotion('HAPPY', 3500)` (smiles cheerfully for 3.5 seconds, then gracefully returns to baseline)
- API failure $\rightarrow$ `triggerEmotion('ERROR', 5000)`

### 2. Future Simulation Flow (`FuturesScreen.tsx`)
- Simulation requested $\rightarrow$ `setMascotState('PLANNING')`
- Simulation complete $\rightarrow$ returns to baseline
- Strategic trajectory converted to agent action $\rightarrow$ `triggerEmotion('SUCCESS', 3500)`

### 3. Agent Execution Safeguards (`AgentActivityScreen.tsx`)
- Objective composition $\rightarrow$ `setMascotState('PLANNING')`
- Plan awaiting confirmation $\rightarrow$ `setMascotState('CONFIRMING')`
- User confirms execution $\rightarrow$ `setMascotState('ACTING')`
- Execution finished with success $\rightarrow$ `triggerEmotion('SUCCESS', 3500)`
- Execution friction/failure $\rightarrow$ `setMascotState('ERROR')`

### 4. Background Telemetry Polling (`Layout.tsx` & `HomeScreen.tsx`)
- Active interventions exist $\rightarrow$ `setMascotState('INTERVENING')`
- Overdue tasks or high-risk predictions $\rightarrow$ `setMascotState('ATTENTION')`
- Clear queues $\rightarrow$ `setMascotState('IDLE')`

---

## 3. Stale Event Overriding Prevention
- The state manager increments an internal transaction sequence ID `transitionSeqRef.current += 1` on every state transition.
- Timers check whether their sequence ID matches the active sequence before reverting. If a newer state was triggered in the interim (e.g. `ERROR` after `HAPPY`), the older timer is automatically discarded.
