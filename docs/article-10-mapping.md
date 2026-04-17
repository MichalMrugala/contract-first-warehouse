# EU AI Act Article 10: YAML Data Contract Mapping

> The reference document mapping each sub-clause of EU AI Act Article 10 to specific YAML fields in the Contract First data warehouse.

**Last updated:** April 2026
**Status:** Aligned with Article 10 final text (Regulation (EU) 2024/1689)
**Caveat:** Will be updated when Digital Omnibus trilogue concludes (April 28, 2026)

---

## Why this document exists

EU AI Act Article 10 enforcement begins **August 2, 2026**. The text of the article is 8 sub-clauses long. Most compliance documentation translates these sub-clauses into PDF policy documents. Auditors do not audit PDFs — they audit pipelines.

This document shows how each sub-clause maps to a specific, testable YAML field. The contract is validated on every pipeline run. The validation results are the audit evidence.

---

## The mapping at a glance

| Sub-clause | What Article 10 requires | YAML field in our contract |
|---|---|---|
| 2(a) | Data governance and management practices | `metadata.ai_act_article_10_mapping.sub_clause_2a` |
| 2(b) | Data collection procedures and origin | `source.systems[].collection_*` + `legal_basis` |
| 2(c) | Data preparation operations (annotation, labelling, cleaning) | `transformations[]` |
| 2(d) | Examination for biases likely to affect health, safety, fundamental rights | `bias_examination.*` |
| 2(e) | Identification of relevant data gaps or shortcomings | `data_gaps.*` |
| 2(f) | Examination of relevance, representativeness, errors | `relevance_assessment.*` |
| 3 | Training/validation/testing data sets shall be sufficiently representative | `representativeness_statement.*` |
| 5 | Special categories of personal data — only if necessary for bias monitoring | `special_categories_handling.*` |

---

## Sub-clause 2(a) — Data governance practices

**Article 10(2)(a):** *"Training, validation and testing data sets shall be subject to data governance and management practices appropriate for the intended purpose of the high-risk AI system. Those practices shall concern in particular: (a) the relevant design choices..."*

**What this means in practice:** The regulator wants documented evidence that someone made conscious design choices about the data — not just inherited a pipeline from a former colleague.

**YAML implementation:**

```yaml
metadata:
  name: customer_churn_training_data
  owner: data-engineering-team
  reviewer: head-of-compliance
  next_review_date: 2026-07-01
  ai_act_article_10_mapping:
    sub_clause_2a: data_governance_practices
  design_choices:
    - choice: stratified_sampling_by_geography
      reason: EU-27 customer distribution is skewed; uniform sample would underrepresent CEE
      decided_by: data_engineering_team
      decided_date: 2026-01-15
```

**Test that validates this sub-clause:**

```sql
-- Verify the contract has a non-empty design_choices block
SELECT
  CASE
    WHEN ARRAY_LENGTH(JSON_EXTRACT(contract_yaml, '$.design_choices')) > 0
    THEN 'PASS'
    ELSE 'FAIL: Article 10(2)(a) requires documented design choices'
  END AS sub_clause_2a_check
FROM contract_registry;
```

---

## Sub-clause 2(b) — Data collection procedures and origin

**Article 10(2)(b):** *"...data collection processes and the origin of data, and in the case of personal data, the original purpose of the data collection."*

**What this means in practice:** You must be able to show, per source system, when collection started and ended, what the legal basis was, and (for personal data) what the consent or legitimate-interest reasoning was at collection time.

**YAML implementation:**

```yaml
source:
  systems:
    - name: crm_production
      collection_start: 2023-01-01
      collection_end: 2026-04-01
      legal_basis: legitimate_interest
      legal_basis_documentation: docs/legal_basis_crm_production.md
      consent_version: v3.2
      original_purpose: customer_relationship_management
      geographic_scope: EU_27
    - name: support_tickets
      collection_start: 2024-06-01
      collection_end: 2026-04-01
      legal_basis: contract
      original_purpose: service_delivery_obligation
```

---

## Sub-clause 2(c) — Data preparation operations

**Article 10(2)(c):** *"...the relevant data preparation processing operations, such as annotation, labelling, cleaning, updating, enrichment and aggregation."*

**What this means in practice:** Every transformation between source and model must be documented with what it does and why.

**YAML implementation:**

```yaml
transformations:
  - operation: deduplication
    method: customer_id_hash_match
    rows_removed: 1247
    rationale: source CRM exports include staging artifacts
  - operation: imputation
    field: customer_income
    method: regression_imputation_v2
    coverage_before: 0.42
    coverage_after: 0.89
    rationale: insufficient coverage for stratified analysis
  - operation: aggregation
    field: lifetime_value
    method: sum_over_purchase_history
    granularity: per_customer_per_quarter
```

---

## Sub-clause 2(d) — Bias examination

**Article 10(2)(d):** *"...examination in view of possible biases that are likely to affect the health and safety of persons, have a negative impact on fundamental rights or lead to discrimination prohibited under Union law."*

**This is the sub-clause most teams underestimate.**

The phrase "likely to affect" is a legal term. It means the burden is on the deployer to document why a bias was unlikely — not on the regulator to prove it was likely.

**YAML implementation:**

```yaml
bias_examination:
  performed_by: data_engineering_team
  performed_date: 2026-03-15
  protected_attributes_analyzed:
    - age
    - gender_inferred
    - geographic_origin
  demographic_distribution:
    method: stratified_sample_comparison
    reference_population: EU_27_customer_base
    known_skew:
      - attribute: age
        skew_direction: under_35_overrepresented
        magnitude_pct: 18
        mitigation: weighted_sampling_v2
        residual_skew_after_mitigation_pct: 4
  likely_to_affect_assessment:
    health_safety: no_likely_effect
    fundamental_rights: no_likely_effect
    discrimination_risk: low
    reasoning: model_outputs_are_marketing_propensity_scores_only
    reasoning_documentation: docs/bias_assessment_reasoning.md
  bias_we_cannot_measure:
    - attribute: ethnicity
      reason: not_collected_in_source_systems
      proxy_used: geographic_origin
      proxy_limitations: high_false_positive_rate_for_diverse_regions
      escalation_trigger: complaint_or_audit_finding
```

---

## Sub-clause 2(e) — Data gaps identification

**Article 10(2)(e):** *"...identification of relevant data gaps or shortcomings that prevent compliance with this Regulation, and how those gaps and shortcomings can be addressed."*

**This is the requirement most teams have never seen documented anywhere.**

You must document what is missing — not what you have, but what you do not have.

**YAML implementation:**

```yaml
data_gaps:
  known_missing:
    - field: customer_income
      coverage_pct: 42
      impact_assessment: medium
      mitigation: imputation_v2_documented
      addressable_by: 2026-Q3_via_survey_augmentation
    - field: customer_disability_status
      coverage_pct: 0
      impact_assessment: high_for_accessibility_features
      mitigation: not_currently_addressable
      escalation: legal_review_required_before_production_use
  shortcomings:
    - issue: source_system_a_lacks_timestamp_precision_below_one_day
      impact: cannot_distinguish_intra_day_purchase_patterns
      mitigation: deferred_to_2027_data_modernization_roadmap
```

---

## Sub-clause 2(f) — Relevance, representativeness, errors

**Article 10(2)(f):** *"...examination in view of the appropriate statistical properties, including, where applicable, as regards the persons or groups of persons in relation to whom the high-risk AI system is intended to be used."*

**YAML implementation:**

```yaml
relevance_assessment:
  intended_use_population: EU_27_B2C_customers_aged_18_to_75
  source_data_population: EU_27_existing_customers_aged_22_to_68
  representativeness_gap:
    age_18_to_22: not_in_training_data
    age_69_to_75: not_in_training_data
    mitigation: model_outputs_flagged_when_inference_input_is_outside_training_age_range
  statistical_properties:
    target_distribution_skew: 0.34
    feature_correlation_max: 0.71
    multicollinearity_check: VIF_all_features_below_5
```

---

## Sub-clause 3 — Representativeness

**Article 10(3):** *"Training, validation and testing data sets shall be relevant, sufficiently representative, and to the best extent possible, free of errors and complete in view of the intended purpose."*

**The phrase "to the best extent possible" is the regulator's escape hatch.** It only protects you if you documented what was not possible.

**YAML implementation:**

```yaml
representativeness_statement:
  intended_purpose: customer_churn_prediction_for_marketing_segmentation
  representativeness_method: stratified_population_match
  not_possible_to_achieve:
    - aspect: full_demographic_coverage
      reason: protected_attributes_not_collected_in_source_systems
      best_extent_documented: docs/representativeness_constraints.md
  error_rate_acceptance:
    label_noise_pct: 2.1
    threshold_for_retraining_pct: 5.0
```

---

## Sub-clause 5 — Special categories of personal data

**Article 10(5):** *"To the extent that it is strictly necessary for the purposes of ensuring bias detection and correction in relation to the high-risk AI systems, the providers of such systems may exceptionally process special categories of personal data..."*

**YAML implementation:**

```yaml
special_categories_handling:
  uses_special_categories: false
  reasoning: bias_monitoring_uses_proxies_only_no_special_category_data_processed
  if_uses_special_categories:
    legal_basis: article_10_5_AI_Act_strict_necessity
    documented_safeguards: docs/special_category_safeguards.md
    pseudonymization_method: not_applicable
    state_of_the_art_security: not_applicable
```

---

## Limitations of this implementation

This reference implementation does not cover:

- **Bias measurement for protected categories not present in source data** (e.g., ethnicity in most EU CRMs). The contract documents this gap explicitly.
- **Cross-jurisdictional regulatory variation** (UK, Switzerland, US-state-level requirements). Article 10 is EU-only.
- **Updates published after April 2026.** This mapping reflects the AI Act final text and the ODCS v3.1.0 specification.
- **Provider-side obligations.** This contract is built from the deployer perspective. Providers have additional obligations under Article 10.

---

## When this document will be updated

| Trigger | Expected update |
|---|---|
| Digital Omnibus trilogue conclusion (April 28, 2026) | Within 24 hours |
| Implementation acts published by EU AI Office | Within 1 week |
| Clarifying guidance from EU Commission | Within 1 week |
| Annex III updates | Within 1 month |

---

## How to use this document

1. **Read the sub-clause** in the actual EU AI Act text (Regulation EU 2024/1689). Do not rely on this summary for legal advice.
2. **Compare your existing data documentation** to the YAML fields shown.
3. **For each missing field**, decide whether your AI system is in scope.
4. **If in scope**, build the field into your data contract before August 2, 2026.

This document is not legal advice. Consult a qualified lawyer for AI Act compliance opinions.

---

## Author

Michał Mrugała — law student at WSB Merito Wrocław, data engineering intern at ArcelorMittal.

If you need help implementing Article 10 data governance for your team, see the [About section](https://www.linkedin.com/in/michal-mrugala02/) of my LinkedIn profile.
