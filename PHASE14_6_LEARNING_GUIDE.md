# TESS Phase 14.6 Learning Guide: Future Engine & Multiple Futures Simulator

## 1. Executive Summary & Paradigm Shift

In Phase 14.6, the TESS Flutter client evolves from a conventional chat and dashboard app into a **Personal Future Simulator**.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        TESS FLUTTER CLIENT                             │
├────────────────────────────────────────────────────────────────────────┤
│                 FuturesScreen (Personal Future Simulator)              │
│ ┌────────────────────────────────────────────────────────────────────┐ │
│ │  Mascot Cognitive Reactive Bar (THINKING / ATTENTION / HAPPY / IDLE) │
│ └────────────────────────────────────────────────────────────────────┘ │
│ ┌──────────────┬──────────────┬──────────────┬───────────┬───────────┐ │
│ │  TRAJECTORY  │   FORECAST   │  MULTIPLE    │  WHAT IF? │  ACCURACY │ │
│ │  (Active     │   (30d/90d/  │  SELVES      │ (Counter- │  (Brier & │ │
│ │   Risks &    │    365d      │ (Current vs  │  factuals │  Calib-   │ │
│ │   Evidence)  │   Backlog)   │  Improved)   │  Levers)  │  ration)  │ │
│ └──────────────┴──────────────┴──────────────┴───────────┴───────────┘ │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ HTTP / JSON
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                        CORE NETWORK LAYER                              │
│  - FutureService                                                       │
│  - ApiClient (GET, POST, PUT, DELETE with Bearer JWT)                  │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                  FASTAPI FUTURE ENGINE SERVICE                         │
│  - GET  /api/v1/future/predictions                                     │
│  - POST /api/v1/future/simulate                                        │
│  - POST /api/v1/future/forecast                                        │
│  - POST /api/v1/future/scenarios                                       │
│  - GET  /api/v1/future/accuracy                                        │
│  - GET  /api/v1/future/behavior                                        │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Deep Dive: Probability vs Confidence & Epistemic Honesty

### 2.1 The Critical Distinction: Probability vs Confidence
In AI systems, users frequently conflate **probability** with **confidence**:
- **Probability** ($P \in [0, 1]$): The estimated mathematical likelihood of an event occurring (e.g. `85% Probability`).
- **Confidence** (`LOW`, `MEDIUM`, `HIGH`): The model's degree of certainty in its estimate, determined by evidence quantity, historical baseline depth, and data variance.

A model can output **80% Probability** with **LOW Confidence** if based on only 2 recent data points. Presenting this without confidence is misleading.

In TESS Flutter architecture:
1. `FuturePredictionModel.probabilityPercentage` parses and normalizes raw values ($0.85 \to 85\%$).
2. `TrajectoryCard` explicitly displays both badges:
   ```dart
   Text('${prediction.probabilityPercentage.toInt()}% Probability', style: ...);
   Text('CONF: ${prediction.confidence}', style: ...);
   ```
3. Neither heuristic is ever conflated into guaranteed certainty.

### 2.2 Epistemic Honesty in Calibration & Sample Size
In `AccuracyMetricsView`, we calculate whether the historical evaluation sample size is sufficient to claim calibrated accuracy:
```dart
bool get hasSufficientSampleSize => totalEvaluated >= 5;
```
If $N < 5$, the UI displays an **Amber Epistemic Honesty Banner**:
> *"Calibration Sample Size Note: Current evaluation sample size (N < 5) is insufficient to guarantee statistically calibrated accuracy percentages. Active forecasts represent directional heuristics."*

---

## 3. Flutter Concepts & Design Patterns Mastered

### 3.1 Tabbed Asynchronous State Segmentation
Rather than loading all heavy simulation calculations in a single blocking call, `FuturesScreen` separates computations:
1. **Initial Load**: Fetches lightweight active `FuturePredictionModel` items (`GET /api/v1/future/predictions`).
2. **On-Demand Subviews**:
   - `ForecastView`: Fetches long-term backlog and burnout projections only when the `FORECAST` tab is tapped.
   - `MultipleFuturesView`: Queries comparative trajectories (`CURRENT`, `IMPROVED`, `ALTERNATIVE`).
   - `CounterfactualSimulator`: Runs interactive `24h` / `48h` / `72h` counterfactual simulation.
   - `AccuracyMetricsView`: Loads empirical Brier scores.

### 3.2 Counterfactual Reasoning (The "What-If" Lever)
A counterfactual answers: *"What would the trajectory look like if one variable changed?"*
- `SimulationResponseModel` contains:
  - `scenario`: Timeline of events with relative timestamps (`+4h`, `+12h`, `+24h`).
  - `alternative`: Counterfactual lever specifying `action`, `assumption`, and `expected_effect`.
- In strict adherence to our safety rules, **simulations never modify databases or create tasks automatically**. They remain pure predictive projections.

---

## 4. Comparing Flutter with React Native in Complex Multi-View Screens

| Dimension | React Native (Expo) | Flutter 3.50 (Dart 3) |
|---|---|---|
| **Subview Switching** | Typically uses `@react-navigation/material-top-tabs` or custom state toggles triggering unmount/remount cycles. | Clean `_buildActiveTabContent()` method driven by `_selectedTab` state; Flutter's element tree retains scroll position and minimizes layout rebuilds. |
| **Complex Nested JSON** | Interfaces in TypeScript disappear at runtime; unexpected `null` in deeply nested arrays (e.g. `events[0].relative_time`) causes `TypeError: Cannot read property of undefined`. | Dart's sound null safety (`(json['events'] as List<dynamic>?)?.map(...) ?? []`) guarantees zero runtime crashes from null fields. |
| **Numeric Serialization** | JS dynamically types numbers as float64, making `num` vs `int` parsing ambiguous without manual parsing. | Dart provides explicit `(json['projected_backlog'] as num?)?.toInt() ?? 0` and `.clamp(0.0, 100.0)`. |
| **Reactive Visual Telemetry** | Requires React Context or Zustand subscribers dispatching to external animation drivers. | Integrated `MascotWidget` using `SingleTickerProviderStateMixin` and `CurvedAnimation` smoothly responds to `_resolvedMascotState`. |
