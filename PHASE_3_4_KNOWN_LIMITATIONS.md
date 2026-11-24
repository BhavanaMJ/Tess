# TESS — PHASE 3.4 KNOWN LIMITATIONS
## Smart Capture: ChatGPT-Assisted Garment Import Workflow

### 1. Manual Copy & Paste Step
- **Description**: The transfer of generated studio images and Schema 1.1 JSON metadata from ChatGPT to TESS is manual. The user must save the catalogue image to their phone gallery/desktop and copy the JSON text block into the TESS JSON editor.
- **Rationale**: Direct automated API integration with ChatGPT Plus/Team custom projects is constrained by OpenAI's lack of authenticated project webhook/export APIs for client apps. Explicit manual transfer ensures total privacy, zero API key credential leaks, and complete user ownership over what enters TESS.

### 2. Studio Image Quality & Boundary Dependent on ChatGPT Generation
- **Description**: The quality of background removal, isolated garment texture, and proportions reflects the capability of the DALL-E / GPT-4o vision model in the user's custom project.
- **Mitigation**: TESS validates that a catalogue image is uploaded, displays side-by-side verification in Stage 4, and preserves the original unedited phone photograph as a reference asset.

### 3. File Size Constraints
- **Description**: Image uploads (both catalogue and original) are restricted to a maximum of 15MB per file to maintain reasonable Supabase storage quotas and mobile bandwidth usage.
- **Handling**: If an uploaded image exceeds 15MB, TESS displays an immediate client-side error warning before initiating network upload.

### 4. Custom Categories and Search Normalization
- **Description**: While Schema 1.1 supports arbitrary `custom_category` values (e.g. "Spacesuit", "Fencing Jacket"), top-level wardrobe filtering in TESS is optimized for the standard 10 core categories (`Tops`, `Bottoms`, `Ethnic wear`, `Dresses`, `Outerwear`, `Activewear`, `Innerwear`, `Sleepwear`, `Footwear`, `Accessories`).
- **Handling**: Garments with a custom category are grouped under `Other` in high-level category filters while retaining their exact `custom_category` in the details view, search queries, and `metadata_payload`.
