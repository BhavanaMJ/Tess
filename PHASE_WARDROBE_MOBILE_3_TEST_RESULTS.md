# TESS Wardrobe Intelligence — Phase 3 Test Results

**Date:** November 22, 2026  
**Test Run Status:** ALL PASSING  
**Platform:** Linux (FastAPI + Supabase backend, Flutter 3.50.0 / Dart 3.14.0)

---

## 1. Test Execution Summary

| Test Domain | Test Suites | Tests Executed | Passed | Failed | Execution Time |
|---|---|---|---|---|---|
| **Flutter Unit & Widget Tests** | 4 files (`wardrobe_*.dart`) | 30 tests | 30 | 0 | 3.2s |
| **Flutter Application Full Suite**| 13 test files | 148 tests | 148 | 0 | 12.8s |
| **Backend Wardrobe & Capture** | 2 test files | 16 tests | 16 | 0 | 31.9s |
| **Total Automated Tests** | 15 test suites | **164 tests** | **164** | **0** | **47.9s** |

---

## 2. Flutter Phase 3 Test Breakdown (`test/wardrobe_phase3_test.dart`)

```
00:00 +0: GarmentCandidate & CaptureJob Model Tests GarmentCandidateModel fromJson and toJson serialization roundtrip
00:00 +1: GarmentCandidate & CaptureJob Model Tests CaptureJobModel fromJson and properties
00:00 +2: GarmentCandidateCard Widget Tests renders candidate information, confidence tags and uncertainty note
00:00 +3: GarmentCandidateCard Widget Tests renders excluded state with opacity and Excluded label
00:00 +4: GarmentAttributeEditor Modal Tests displays form fields with initial candidate values and saves modifications
00:01 +5: WardrobeCaptureController Workflow Tests image validation rejects empty bytes and too small images
00:01 +6: WardrobeCaptureController Workflow Tests full process, candidate update, and confirmation flow
00:01 +7: SmartCaptureScreen UI Tests renders capture options, instructions, and camera/gallery buttons
00:01 +8: CaptureProcessingScreen UI Tests renders progress percentage and stage text
00:01 +9: CaptureReviewScreen UI Tests renders candidate cards and registers approved garments
00:01 +10: All tests passed!
```

---

## 3. Backend Pytest Breakdown (`backend/tests/test_wardrobe_capture.py`)

1. `test_image_validation_empty`: Correctly rejects 0-byte or corrupted uploads with HTTP 400.
2. `test_image_validation_dark_or_low_res`: Verifies resolution checks.
3. `test_multi_garment_detection_workflow`: Tests multi-garment separation into top + bottom candidates.
4. `test_candidate_update_attributes`: Verifies candidate attribute modification prior to approval.
5. `test_candidate_exclusion`: Validates exclusion flag prevents registration into wardrobe.
6. `test_confirm_job_sequential_id_generation`: Confirms collision-free `CLO-xxx` ID generation into `wardrobe_items`.
7. `test_user_isolation_security`: Verifies other users cannot access capture jobs or candidates (RLS enforcement).
8. `test_retry_capture_job`: Verifies re-running vision models preserves original photograph.
