## 📌 Project Overview
This repository contains a full end-to-end SQL case study focusing on global tech industry layoffs. The project is split into two major phases: **Data Cleaning** (building an optimized, anomaly-free staging environment) and **Exploratory Data Analysis (EDA)** (extracting actionable business metrics and macro-trends).

---

## 📁 Repository Structure
* `layoffs.csv`: Raw, unformatted source data loaded straight from Excel.
* `layoffs_clean.csv`: The polished database output extracted post-cleaning.
* `layoffs_analysis.sql`: Unified, step-by-Step production script containing the database schema and all queries.

---

## 🛠️ Phase 1: Data Cleaning Steps
1. **Staging Environment Setup:** Cloned structural frameworks to preserve raw tables against accidental data corruption.
2. **Duplicate Remediation:** Utilized advanced Common Table Expressions (CTEs) combined with `ROW_NUMBER() OVER(PARTITION BY...)` window functions to isolate and purge redundant records.
3. **Field Standardization:** Corrected messy string entries using `TRIM()`, unified structural categories (e.g., merging variations of 'Crypto'), and stripped trailing punctuation blocks.
4. **Temporal Transformation:** Converted raw text fields into standardized dates using `STR_TO_DATE()` and systematically altered column layouts to true database `DATE` attributes.
5. **Null & Missing Value Strategy:** Deployed database self-joins (`JOIN`) to automatically populate missing industrial descriptors based on repeating company attributes, and trimmed redundant, uninformative blank rows.

---

## 📊 Phase 2: Key EDA Insights & Metrics

### 1. Macro-Level Impact & Timeline
* **Data Time Horizon:** March 2020 (Pandemic onset) to March 2023.
* **Peak Single Layoff Event:** 11,000 employees laid off in a single announcement.

### 2. Industry & Geographic Epicenters
* **Hardest Hit Industries:** **Consumer** and **Retail** sectors registered the highest cumulative job losses globally.
* **Geographic Concentration:** The **United States** emerged as the global epicenter, accounting for the highest total volume of layoffs.

### 3. Top-Tier Corporate Realities
* **Highest Absolute Losses:** Tech giants **Amazon, Meta, and Google** top the list for total layoffs across the entire 3-year span.
* **Highly Funded Collapses:** Companies like **Katerra** and **FTX** raised hundreds of millions in venture capital but ultimately laid off 100% of their staff upon operational collapse.

### 4. Advanced Year-by-Year Cohort Rankings (Top 3 per Year)
* **2020:** Booking.com, Uber, Yelp
* **2021:** Bytedance, Katerra, Zillow
* **2022:** Meta, Amazon, Cisco
* **2023 (Q1 Spikes):** Google, Amazon, Microsoft

---

## 💡 Advanced SQL Concepts Showcased
* **Window Functions:** Deployed `DENSE_RANK()` and `SUM() OVER(ORDER BY...)` for rolling monthly aggregates and annual positioning.
* **Multi-Layered CTEs:** Interlinked multiple Common Table Expressions together to cleanly segment, rank, and filter complex hierarchical data pools.
* **Self-Joins (`JOIN`):** Implemented programmatic cross-row references to fix data gaps automatically.

