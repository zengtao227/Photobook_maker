# Antigravity Global Workflow Protocol

## 1. FIRST PRINCIPLES & GITHUB RESEARCH (MANDATORY)
**Before writing ANY code for a new feature or project:**

1.  **STOP and THINK**: Do not reinvent the wheel.
2.  **RESEARCH**: Search GitHub immediately for existing open-source solutions, libraries, or similar projects.
    *   Query examples: "SwiftUI photo editor github", "SwiftUI draggable view modifier", "SwiftUI canvas layer architecture".
3.  **ANALYZE**: Read the source code of the best candidates (3-5 repositories).
    *   Understand their data models.
    *   Understand their state management.
    *   Understand their interaction logic (Gestures vs. UIGestureRecognizer).
4.  **ADAPT**: Copy or adapt the proven patterns. Only write custom code if no existing solution fits.

## 2. CODE QUALITY & ARCHITECTURE
- **Simplicity First**: If a solution requires complex "hacks" (e.g., fighting with ZStack z-indexes or geometry readers excessively), it is likely wrong. Look for a simpler native approach.
- **State Management**: Use Source of Truth honestly. Avoid duplicating state in View and Model.

## 3. ERROR HANDLING
- If a feature "flickers" or "doesn't work sometimes", DO NOT patch it with boolean flags.
- Revert to First Principles and analyze the root cause (e.g., view identity, render loop, auto-save triggers).

---
*This document is the supreme law for this workspace and must be consulted before every major task.*
