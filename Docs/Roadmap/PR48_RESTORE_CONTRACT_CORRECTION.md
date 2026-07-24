# PR #48 Restoration-Contract Correction

- **Applies to:** Issue #46A persistent class progression runtime
- **Authority:** ADR-020 and `ISSUE46_IMPLEMENTATION_BRIEF.md`
- **Reason:** frozen-artifact pre-verification audit

## Correction

The durable `class_tree_state` snapshot must bind allocations to both the progression-state container and the exact immutable class-tree definition that authored them.

The implemented snapshot therefore contains:

```gdscript
{
    "schema_version": 1,
    "definition_schema_id": "framework_proof_v1",
    "definition_schema_version": 1,
    "award_ledger": {},
    "allocations": {},
}
```

`schema_version` governs the mutable progression-state container. `definition_schema_id` and `definition_schema_version` govern the immutable tree contract. A non-empty snapshot with a mismatched definition identity or version must fail transactionally unless a separately reviewed migration exists.

## Restore validation

Restoration must reject without changing live state when any of the following is true:

- the state schema is missing or unsupported;
- the tree-definition identity or version does not match;
- a level source is malformed, noncanonical, above the character's reached level, or carries the wrong authored amount;
- an award amount or allocation rank is non-integral or non-positive;
- an allocation is unknown, over-ranked, prerequisite-invalid, mutually exclusive, or unaffordable.

Non-level authored sources remain positive, canonical, exactly-once IDs. A later quest/trial award registry may narrow those source IDs without changing the current level-award contract.

## Bind reconciliation

Existing characters may predate `class_tree_state`. Binding such a character reconciles missing `level:<n>` sources inside the temporary progression candidate. After the complete candidate is committed, the session emits one `runtime_state_changed(build_id, &"class_progression")` event when reconciliation added points. This makes the durable mutation visible to persistence observers without exposing a partially bound session or generating duplicate level notifications.

A fully reconciled rebind emits no false progression-state mutation.

## Verification additions

`test_class_progression_restore_contract.gd` covers:

- definition identity/version persistence and mismatch rejection;
- affordability and integral-rank restoration;
- reached-level and authored-amount validation for level sources;
- canonical level-source formatting;
- rejection of fractional awards;
- one durable state-change event for legacy level backfill;
- no false event on a fully reconciled rebind.
