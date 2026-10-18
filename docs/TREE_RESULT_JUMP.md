# Go to Result in Tree Search

Go to Result and Return select a one-based ordinal within results already found. No search or automatic focused-view opening occurs. Successful selection scrolls to the stable hit, including when reselecting the same result. Previous/Next and row selection synchronize the field; continuation preserves the selected hit.

Numeric input is bounded to a short UTF-8 prefix and validated as ASCII digits, Int and current range. Invalid or overflowing input preserves the last valid selection. Query, scope, Clear and restart reset pending jump state. Running work and unrelated busy operations disable jumping. Existing current-comparison and stale-result protections remain.

Two focused development methods and native jump, invalid input, Return, navigation, Copy and Open acceptance passed. Accepted unchanged checks reused; no suite or accessibility work rerun. Schema-1 reports and exact UTF-8 match data remain unchanged.
