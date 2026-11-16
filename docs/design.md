# Design notes

Formation focuses on the small layer between companion ownership and visual rendering. It deliberately leaves inventory, equipment, replication and rewards to the game.

## References and decisions

- [PetFollow v0.1](https://devforum.roblox.com/t/introducing-petfollow-v01/494494) establishes that pet following is an existing Roblox pattern. Formation's contribution is an inspectable small implementation, a model preview workflow, footprint-aware layouts and an explicit cleanup contract. It does not claim to invent companion following.
- The [Hatchwren sampler](https://www.cybermaxtools.com/roblox/kits/hatchwren/) was considered as a behavioral example. Its license/readme were reviewed; its implementation and assets were not used. The source and included companions here were built independently.
- [RbxUtil](https://github.com/Sleitnick/RbxUtil) demonstrates narrow utilities and explicit ownership. Formation uses a single update connection per controller and destroys only its own clones. It does not require RbxUtil or copy its implementation.
- Roblox's [PVInstance:PivotTo](https://create.roblox.com/docs/reference/engine/classes/PVInstance#PivotTo) is used to move whole models. No BulkMoveTo complexity is introduced without measurements showing a need.
- Roblox's [raycasting documentation](https://create.roblox.com/docs/workspace/raycasting) informs the reused RaycastParams filter. Own companions and the Instance owner are excluded; games can add their effects through `Exclude`.
- The plugin follows [Studio widget guidance](https://create.roblox.com/docs/studio/plugins/create-widgets): native theme colors, compact controls and a dockable inspector. It avoids networking, custom web rendering and large UI dependencies.

## Layout and motion

Rows are centered independently and use measured diameters. Curved layouts derive adjacent angular gaps from chord lengths and search for a radius that fits the requested span. A final all-pairs check uniformly expands the layout when needed to preserve the requested gap between every footprint, including large models separated by a much smaller one. Orbit distributes remaining angular space around the full circle; Arc limits the occupied span to 145 degrees behind the owner. The tests cover mixed sizes, zero spacing and the 200-companion limit.

The layout runs when companions or relevant settings change. Frame updates reuse those slots. Position and rotation use exponential smoothing so responsiveness is independent of the render rate. Teleports bypass smoothing. Ground samples are cached between configurable intervals, and distance tiers reduce update frequency. The controller records its own latest update cost rather than promising a universal frame budget.

## Ownership

Templates remain untouched. A controller owns one folder, its clones and its update connection. Stop disconnects the loop without deleting companions; Destroy is idempotent and releases everything. Destroying an Instance owner also destroys the controller. A function owner can temporarily return nil; the caller retains responsibility for ending that controller.

The plugin preview is temporary and non-archivable. Configuration export is an explicit ChangeHistoryService recording so it can be undone. It returns separate `Settings` and `PetOptions` tables so the flying choice can be passed to `Add` alongside the layout settings passed to `new`. The shipped game module does not include the plugin or demo models.

## Deliberate limits

This is a cosmetic follower, not a navigation system or rig animation controller. Probe-based height following can cut through obstructions. Footprints do not account for geometry changed after Add. Companion travel paths may cross while transitioning between layouts. A game with many groups should benchmark its own model complexity and lower distant update frequency where appropriate.
