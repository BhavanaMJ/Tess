# TESS Wardrobe Intelligence — Mobile Phase 4 Known Limitations

**Product:** TESS Personal AI Operating System  
**Module:** Laundry Manager & Lifecycle Tracking (Mobile Phase 4)  
**Date:** November 22, 2026  

---

## 1. Single Active Batch per Garment
- **Limitation**: A garment can only belong to one active laundry batch at a time (`active_batch_id`). If an item is already assigned to an ongoing wash cycle, it cannot be added to a second concurrent batch without first removing it from the former.
- **Rationale**: Physical garments cannot exist in two separate physical washing machines simultaneously.
- **Future Enhancement**: Visual warning banner when attempting to add an item that belongs to another active batch with a one-tap "Transfer to this batch" option.

---

## 2. Fabric Care Compatibility Warnings
- **Limitation**: The batch creation workflow currently groups garments by user selection without asserting fabric temperature or color incompatibility warnings (e.g., warning if dry-clean-only silk is added to a 60°C hot cotton wash batch).
- **Rationale**: Strict Phase 4 boundary focusing on lifecycle state management, batch progression, and wear/wash tracking.
- **Future Enhancement**: Planned for Phase 7 (Wardrobe Insights & Care Tag Decoder), which will cross-reference fabric composition and care tags to flag color bleeding and temperature risks before wash confirmation.

---

## 3. IoT & Smart Appliance Connectivity
- **Limitation**: Laundry batch progression currently relies on user interaction (advancing the stepper from the app UI). There is no direct integration with smart washing machine APIs (e.g., Samsung SmartThings, LG ThinQ).
- **Rationale**: Out of scope for native mobile MVP.
- **Future Enhancement**: Webhook and local MQTT integration in TESS Proactive Engine to automatically trigger batch transitions upon physical cycle completion signals from connected appliances.

---

## 4. Multi-Device Offline Batch Sync Race Conditions
- **Limitation**: If a user modifies individual garment statuses on two devices while offline, reconciliation when reconnecting adheres to Last-Write-Wins (LWW) based on server arrival time.
- **Mitigation**: Every transition records an immutable log in `wardrobe_laundry_history` with source attribution and timestamp so state alterations can always be audited and inspected.
