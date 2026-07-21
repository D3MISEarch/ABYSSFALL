# Stage 3 Ability Execution Review Targets

Review the exact pull-request head and verify:

1. RuntimeSession owns one AbilityExecutor.
2. AbilityExecutor receives the session-scoped RuntimeEventBus and introduces no autoload.
3. Locked abilities are rejected without spending resource.
4. Resource-type mismatches are rejected without spending resource.
5. Insufficient resource is rejected without changing the pool.
6. Successful execution spends the configured cost exactly once.
7. Successful execution starts cooldown and emits one ability_cast event.
8. Cooldown attempts are rejected and do not spend additional resource.
9. Rejected attempts emit one ability_rejected event with an explicit reason.
10. Cooldown state is isolated by build ID and ability ID.
11. Godot 4.4.1 runtime tests pass.
