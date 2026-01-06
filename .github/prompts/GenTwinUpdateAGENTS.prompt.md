---
agent: agent
---

# Update `AGENTS.md`

Update the `AGENTS.md` in the **base directory** after fake dataset created, following the example below:

```md
(... existing contents...)
- **Testing:** The validity of the pipeline is tested by running the production logic against a lightweight "Fake Dataset" (`./fake-data`) that mirrors the structure of the real dataset (`./data`).

(... existing contents...)
## File Structure Conventions
- `./data`: Production data (Git-ignored, managed by DVC).
- `./fake-data`: Synthetic data for testing (matches `./data` schema exactly).
```
