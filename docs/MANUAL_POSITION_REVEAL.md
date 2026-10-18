# Reveal Last Viewed Scalar or Byte

Reveal Last Viewed Scalar or Byte completed locally (2026-10-18).
Manual focused navigation exposes Reveal Scalar / Reveal Byte beside Go after a
successful manual position exists. Reveal ignores pending/rejected field text,
restores captured position into the field and clears its error, selects its page;
scalar revision refresh reveals/highlights the original scalar or EOF. Data reuses
captured <=33-byte context and direct page arithmetic. No source lookup, prefix
scan, parsing or new asynchronous work. Search/difference models/history/frontier
and other pane remain separate. Existing captured-value lifecycle resets remain.


Three focused tests and native scalar/byte acceptance passed. Captured positions, EOF, invalid/pending input independence, exact bytes and search/difference state are covered. Accepted checks reused.
