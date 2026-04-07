# Series tracking MVP — patch notes

## Scope implemented
- explicit series tracking separate from favorites
- local persistence in SQLite (`tracked_series`)
- track/untrack button on TV detail page
- `NEW` badge on favorite series entries when a tracked series has a newer released episode
- status refresh when opening the favorite series playlist and when opening a TV detail page

## Not implemented in this patch
- phone notifications
- background scheduler
- dedicated tracked-series settings screen
- automated tests

## Technical notes
- DB version bumped to 20
- new storage repository: `SeriesTrackingLocalRepository`
- latest released episode is resolved from `TvRepository.getSeasons`
- entering a TV detail page refreshes tracking status then marks the pending `NEW` state as seen

## Validation limits
- static patch only
- `flutter analyze` / `flutter test` not executed in this environment
