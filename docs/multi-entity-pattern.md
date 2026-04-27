# Multi-Entity Article 10: The Joint Deployer Pattern

> The reference implementation for EU AI Act Article 10 compliance when an AI system is operated jointly across multiple legal entities. Single-deployer YAML breaks the moment a subsidiary runs a platform the parent procured. This document shows what the contract looks like when that happens.

**Last updated:** April 2026
**Status:** Aligned with EU AI Act final text (Regulation (EU) 2024/1689)
**Companion file:** [`contracts/energy_balance_v0.5_multi_entity.yaml`](../contracts/energy_balance_v0.5_multi_entity.yaml)

---

## Why this document exists

Article 10 of the EU AI Act requires documented data governance for high-risk AI systems. Most published guidance assumes a single deployer — one company runs one system. Real organisations are not built that way. A parent group sets policy and procures. A Polish subsidiary runs the pipeline. A retail arm uses the same platform for non-regulated purposes. Three entities. One AI system. Where does Article 10 apply?

The answer is in Article 3(8). It defines a deployer as "any natural or legal person... using an AI system under its authority." When two entities share authority over the same system, both are deployers. That is the joint deployer condition. The Article 26 obligations apply to each. The compliance burden compounds. Documentation that names a single owner ceases to function the moment a regulator asks which entity is responsible for what.

Single-deployer YAML cannot represent this. Multi-entity YAML must. This document is the working pattern.

---

## 1. The dilution problem

The dilution happens in one phrase. Article 3(8) defines a deployer as "using an AI system under its authority." The word "authority" carries weight in three dimensions, and they rarely sit in the same legal entity:

- **Procurement authority** — who signed the contract with the AI system provider.
- **Policy authority** — who sets the rules about how the system may be used.
- **Operational authority** — who runs the pipelines, deploys the model, and responds to incidents.

In a single-company deployment, all three sit with the same legal entity. Article 26 obligations attach to that entity. Documentation is straightforward.

In a group structure, they fragment. The parent typically holds procurement and policy. A subsidiary typically holds operations. A retail or non-regulated business unit may consume the same platform output without holding any deployer authority at all. The boundary between "in scope of Article 10" and "out of scope" runs through the middle of the same database.

When this fragmentation is undocumented, three failure modes become inevitable. Within twelve months, escalation paths decay. Within twenty-four months, regulators ask "who is responsible for the bias monitoring on this system?" and receive three different answers from three different entities. By month thirty, the joint accountability has eroded to the point where each entity can plausibly point to the others. This is the operational failure that Article 26 obligations are designed to prevent — and they only prevent it when the contract structure forces explicit allocation up front.

Single-deployer YAML cannot force that allocation. There is no field for "this responsibility is shared between two named entities." There is no field for "this part of the platform is in scope, that part is out." The structure makes joint deployer arrangements representable only by adding free-text notes that nobody validates. The pattern in this document closes that gap.

---

## 2. Why single-deployer YAML breaks at scale

Standard data contracts written at small organisations contain fields like `data_owner: "data-engineering-team"` or `responsible_party: "head-of-compliance"`. These fields are functional when one team holds full authority. They produce a single named owner. A regulator asks "who?", the contract answers, the auditor moves on.

The same fields stop working when authority fragments. Three problems compound:

**Problem one — single-name ambiguity.** When a contract names "data-engineering-team" as the owner of bias examination, but that team sits in the Polish subsidiary while policy is set by the parent, the field is half-true. Operationally accurate, structurally misleading. A regulator following the contract back to a person ends up at someone with operational authority but no policy authority. The accountability the contract claims to document does not exist as named.

**Problem two — invisible boundaries.** Single-deployer contracts have no concept of partial scope. Every row of every table is either covered or not covered. Real platforms run mixed workloads — a recommendation system used both for high-risk customer-facing decisions and for low-risk internal analytics. The boundary between regulated and non-regulated usage exists in operational reality, but the contract has nowhere to record it. The result: either everything is documented to high-risk standard (expensive and inappropriate for non-regulated parts) or nothing is (non-compliant for the regulated parts).

**Problem three — no escalation matrix.** When a quality test fails, who acknowledges? When the acknowledgement does not arrive within SLA, who escalates? When the escalation reaches a deadlock, which entity carries the regulator-facing responsibility to notify supervisors? Single-deployer YAML treats escalation as a single chain. Joint arrangements need a matrix where tier-1 sits with the operating entity, tier-2 with the procuring entity, and the regulator-notification authority is named explicitly.

These three problems are the reason data governance documentation accumulates appendices, side-letters, and Confluence pages over time. Each addition is a workaround for what the contract structure cannot represent. The pattern below removes the need for the workarounds by making the structure carry the load.

---

## 3. The CJEU analogy: where the doctrine comes from

The AI Act does not yet have case law of its own. The doctrine of joint deployership in Article 3(8) is new in regulatory text but not new in EU law. GDPR Article 26 — joint controllers — covers structurally identical territory. The CJEU has built three cases worth of doctrine on what "joint" means. The principle survives translation from controller to deployer.

Three cases established the line:

**C-210/16 (Wirtschaftsakademie Schleswig-Holstein, 2018).** A German trade academy hosted a fan page on Facebook. The academy did not control Facebook's data processing infrastructure and had no direct technical access to user data. Despite that, the CJEU held that the academy was a joint controller alongside Facebook. The controlling test was decisive influence — by choosing to operate the page and configure its parameters, the academy exercised influence over the means and purposes of processing. The case established that joint status exists without direct technical access. Translation to AI Act Article 3(8): an entity can be a deployer by virtue of policy and procurement authority, even when day-to-day operation sits elsewhere.

**C-25/17 (Jehovah's Witnesses / Tietosuojavaltuutettu, 2018).** A religious community organised door-to-door evangelical visits during which members took notes about persons visited. The community itself never handled the notes. The CJEU held the community was a joint controller because it organised, coordinated, and encouraged the activity that produced the data — joint determination of purposes and means even when one party never touches the data. Translation: a parent entity that sets data governance policy and AI system purposes is a joint deployer even if it never executes a SQL query against the system's training data.

**C-40/17 (Fashion ID, 2019).** A clothing retailer embedded a Facebook "Like" plugin on its website. The plugin caused user data to flow to Facebook on every page load. Fashion ID never received the data, never processed it, and could not have prevented the transfer except by removing the plugin. The CJEU held Fashion ID was a joint controller for the collection and transmission stages (though not for what Facebook did afterwards). The case extended the doctrine to embedded-component scenarios — one party enables another's processing on a shared technical foundation. Translation: an entity that procures or policies an AI system used by another entity inherits joint deployer status for the in-scope stages.

The principle survives translation: authority plus decision rights equals joint deployer status. The contract pattern below encodes this principle into machine-validatable YAML.

---

## 4. The composable pattern

The pattern is built from four blocks. Each block is a YAML structure that single-deployer contracts do not contain. Together they describe the full joint deployer arrangement at a level a regulator can validate and a SQL test can enforce.

**Block one — `entities[]`.** One row per legal entity participating in the arrangement. Each row carries `entity_id` (a stable identifier), `legal_name` (the registered company name), `jurisdiction` (the country of registration, which determines which national regulator applies), `role` (one of `procuring_deployer`, `operating_deployer`, or `non_regulated_consumer`), and `authority_basis` (a one-line citation back to Article 3(8) explaining why this entity is in this role). The list is not a hierarchy. It is a flat enumeration of every entity with a stake in the system.

**Block two — `joint_responsibilities`.** One row per Article 26 obligation that requires joint handling. Each row names a `lead` entity and a `reviewer` entity. The lead carries primary execution responsibility. The reviewer holds the second pair of eyes. For incident escalation, the structure expands to `tier_1_responder`, `tier_2_escalation`, and `regulator_notification_authority` — three named roles, three named entities, no ambiguity. The pattern is deliberately matrix-shaped: rows are obligations, columns are entities. A regulator asking "who handles bias examination?" reads one row and gets one answer, with the reviewer named for accountability.

**Block three — `hybrid_usage_boundary`.** Two named scopes — `regulated_scope` and `non_regulated_scope` — each listing the entities they cover and the technical isolation method (`RLS`, `schema`, `database`, or `network`). The boundary is a contract field, not a meeting. A regulator asking "which subsidiary is in scope of Article 10?" reads `regulated_scope.entities` and gets a list. The isolation field tells the auditor how the boundary is enforced technically. The `monitored: true/false` flag makes explicit which side of the boundary carries ongoing audit obligations.

**Block four — `obligation_matrix`.** One row per Article 26 sub-paragraph (10 in total in the current text). Each row names the lead entity and any shared entities, plus a path to evidence. This is the structure that converts Article 26 from text into a queryable data structure. A SQL test can verify that every sub-paragraph has a named lead. A reviewer can verify that the named lead actually holds the authority claimed.

The four blocks together produce a contract that no longer requires appendices or side-letters. Every joint deployer fact lives in YAML. Every fact has a corresponding SQL test or an explicit out-of-scope marker. The structure forces the conversation up front rather than letting it emerge from regulator inquiry under time pressure.

---

## 5. SQL implementation

The contract describes the arrangement. SQL enforces it. Two tables and one trigger carry the load.

**Table one — `role_assignments`.** Maps role names to current person, with effective dates. The contract names roles, not people. People leave organisations. Roles persist. The table looks like this:

```sql
CREATE TABLE role_assignments (
  role_id              TEXT NOT NULL,
  entity_id            TEXT NOT NULL,
  person_email         TEXT NOT NULL,
  effective_from       DATE NOT NULL,
  effective_to         DATE,
  PRIMARY KEY (role_id, entity_id, effective_from)
);

-- Example rows
INSERT INTO role_assignments VALUES
  ('bias_examination_lead', 'GROUP_PARENT_DE', 'a.kowalski@parent.de', '2026-01-01', NULL),
  ('bias_examination_reviewer', 'SUBSIDIARY_PL', 'm.nowak@subsidiary.pl', '2026-01-01', NULL),
  ('incident_tier_1', 'SUBSIDIARY_PL', 'oncall@subsidiary.pl', '2026-01-01', NULL),
  ('incident_tier_2', 'GROUP_PARENT_DE', 'risk@parent.de', '2026-01-01', NULL);
```

When a person leaves, the row gets an `effective_to` date and a successor row is inserted with a fresh `effective_from`. The contract continues to reference the role. The role continues to map to a current person. Accountability does not evaporate when individuals depart.

**Table two — `article_10_audit_ledger` (extended for entity scoping).** The single-deployer audit ledger pattern works as published in v0.4. Multi-entity adds one column: `responsible_entity_id`. Every audit event names the entity that is responsible for it. Cross-entity queries become possible. A regulator inspecting events for `SUBSIDIARY_PL` reads one filtered query, not three.

```sql
ALTER TABLE article_10_audit_ledger
  ADD COLUMN responsible_entity_id TEXT NOT NULL DEFAULT 'UNKNOWN';

CREATE INDEX idx_audit_entity ON article_10_audit_ledger (responsible_entity_id, event_ts);
```

**Trigger — boundary enforcement.** When a row is written to a regulated-scope table, a `BEFORE INSERT` trigger checks that the writing role is associated with an entity in `regulated_scope.entities`. Cross-boundary writes are rejected at the database layer. The hybrid boundary enforces itself.

```sql
CREATE OR REPLACE FUNCTION enforce_regulated_scope() RETURNS TRIGGER AS $$
DECLARE
  writing_entity TEXT;
BEGIN
  SELECT entity_id INTO writing_entity
  FROM role_assignments
  WHERE person_email = current_setting('app.current_user_email')
    AND effective_to IS NULL
  LIMIT 1;

  IF writing_entity NOT IN ('SUBSIDIARY_PL') THEN
    RAISE EXCEPTION 'Entity % cannot write to regulated scope', writing_entity;
  END IF;

  NEW.responsible_entity_id := writing_entity;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_regulated_scope
  BEFORE INSERT ON article_10_audit_ledger
  FOR EACH ROW EXECUTE FUNCTION enforce_regulated_scope();
```

The `pg_net` or `pgsql-http` extension supplies HTTP integration when the trigger needs to escalate to PagerDuty or Jira — the audit ledger augments the existing operations layer rather than replacing it. Engineers acknowledge incidents where they already acknowledge incidents. The ledger picks up that the acknowledgement happened. That is the entire integration surface.

---

## 6. Three twelve-month failure modes

Joint arrangements decay in patterns single-deployer arrangements do not. Three modes recur across published case studies and published audit findings:

**Mode (a) — The ledger becomes write-only.** Pipelines append events. Nobody reads them. After six months the ledger contains every quality-test outcome since launch and zero acknowledgement of trends. The first time anyone queries it is when a regulator asks. By then the ledger has thirty months of data and no review evidence. *Prevention.* A quarterly review query is embedded in the contract with a hard `next_review_date` field. A missed review fires its own ledger entry: `"review_skipped"`. The contract breaches itself, audibly. The next quarterly review cannot pass while a `review_skipped` event remains unresolved.

**Mode (b) — Schema drift uncovered.** A new AI use case ships without contract update. Engineering velocity beats governance cadence. The new system accumulates training data, generates predictions, and serves users for weeks before anyone notices the contract registry has not been updated. *Prevention.* A `BEFORE INSERT` trigger checks the `article_10_registered_systems` table. An unregistered `system_id` raises an exception. The pipeline cannot write until registration is explicit. Engineering velocity is preserved — registration is a YAML edit and a pull request — but the contract gate is non-bypassable.

**Mode (c) — Cross-entity escalation decays.** This is the multi-entity-specific failure mode. The joint committee stops meeting (every quarter slips, then every six months, then never). Tier-2 acknowledgements stop. The original signers leave. By the time a regulator asks who currently holds tier-2 authority for the joint arrangement, the answer is not in the contract. The answer is not anywhere. *Prevention.* Accountability is held by `responsible_role`, never by personal email. The `role_assignments` table maps role to current person with `effective_from` and `effective_to` columns. People change. The contract does not. Quarterly verification runs a query checking that every role named in the contract has at least one active row in `role_assignments`. A role with zero active rows fires a `role_unfilled` ledger event — and the breach surfaces before the next regulator inquiry.

The three modes are not theoretical. Each appears in the public audit findings of organisations operating shared platforms across subsidiaries. The prevention patterns turn each from an inevitability into a contract-level breach event that surfaces within the SLA window rather than at year-end.

---

## 7. When to use single vs joint deployer YAML

The pattern in this document is more complex than single-deployer YAML. Complexity has a cost. Use joint deployer YAML when the following conditions apply, and only when:

**Use joint deployer YAML when:**
- Two or more legal entities share authority over the same AI system
- The arrangement spans jurisdictions (e.g., parent in Germany, subsidiary in Poland)
- The platform serves both regulated and non-regulated workloads
- Procurement authority and operational authority sit in different entities
- The system meets the Article 6 high-risk threshold and Article 10 applies

**Do not use joint deployer YAML when:**
- A single legal entity holds all three authority dimensions (procurement, policy, operational)
- The system is out of scope for Article 10 (general-purpose AI in low-risk applications)
- The complexity would be premature for the actual organisational structure
- A simpler single-deployer pattern can carry the load without ambiguity

The decision is not aesthetic. Adopt the pattern when the organisational structure forces it. Adopt the simpler pattern when the structure does not. Misapplication in either direction creates documentation overhead without compliance benefit.

---

## 8. Limitations

This document is a reference implementation, not legal advice. The following limitations apply:

- **Not legal advice.** The CJEU analogy is doctrinal reasoning, not a substitute for qualified counsel review of a specific organisational structure. Regulators may take positions that differ from the analogy. Engagement-specific legal review is required before deployment.
- **EU-only.** The pattern addresses EU AI Act Article 10 and uses GDPR Article 26 as analogy basis. Non-EU jurisdictions (UK, US-state-level, Switzerland) have their own frameworks. The pattern is portable in structure but not in legal grounding.
- **Deployer-side only.** The pattern is built from the deployer perspective. Providers of high-risk AI systems carry separate Article 16 obligations. The provider-deployer interface is documented separately in production engagements.
- **Reflects April 2026 regulatory state.** Annex III enforcement was extended from 2 August 2026 to 2 December 2027 via the Digital Omnibus process. CEN/CENELEC harmonised standards remain in drafting. The pattern will be updated when standards are published and when implementation acts from the EU AI Office clarify Article 26 sub-paragraphs.
- **Illustrative entity values.** All entity names (`GROUP_PARENT_DE`, `SUBSIDIARY_PL`, `RETAIL_ARM`) are placeholders. Real implementations use legal entity identifiers (LEI codes preferred where available) and registered legal names.

---

## Author

Michał Mrugała. Architecture First.

If you need help implementing the joint deployer pattern for a specific organisational structure, see [architecture-first.beehiiv.com](https://architecture-first.beehiiv.com) or [LinkedIn](https://www.linkedin.com/in/michal-mrugala02/).

---

## Citations

- Regulation (EU) 2024/1689 (EU AI Act) — Article 3(8), Article 10, Article 26
- Regulation (EU) 2016/679 (GDPR) — Article 26
- CJEU C-210/16, *Wirtschaftsakademie Schleswig-Holstein*, 5 June 2018
- CJEU C-25/17, *Jehovah's Witnesses / Tietosuojavaltuutettu*, 10 July 2018
- CJEU C-40/17, *Fashion ID*, 29 July 2019
- Open Data Contract Standard (ODCS) v3.1.0, Bitol / Linux Foundation
