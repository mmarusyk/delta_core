## [Unreleased]
## [1.0.0] - 2026-02-21

- First stable release of DeltaCore (1.0.0).
	- Added Rails DSL (`DeltaCore::DSL`) for declaring `snapshot_column` and `map` mappings.
	- Implemented `StateBuilder` to serialize model associations into plain Hash state.
	- Implemented `Comparator` with three built-in strategies: `:quantity`, `:replace`, and `:merge`.
	- Added `Snapshot` persistence via `Adapters::ActiveRecord` and JSON column storage.
	- Added `Context` flows: `delta_result` (calculate delta), `confirm_snapshot!` (update snapshot), and `with_delta_transaction`.
	- Support for custom strategies and mapping extensions via registration APIs.

## [0.1.0] - 2026-02-20

- Initial release
