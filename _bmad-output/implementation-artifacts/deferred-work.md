## Deferred from: code review of 1-1-reach-a-usable-startup-state-without-crash-loops.md (2026-04-03)

- Supabase sanity check can still emit a complete URL in startup telemetry when the URL is short enough to bypass truncation. Deferred as pre-existing observability debt outside the current patch surface.
- Structured JSON secrets still bypass `MessageSanitizer` because the current masking logic only handles header-like and `key[:=]value` forms. Deferred as a pre-existing sanitizer limitation outside the scope of this review patch.
