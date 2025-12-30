# Codex Runbook — Brain Duel (Flutter Trivia App)

## Purpose

This document defines **how Codex must operate** when working in the Brain Duel repository.

Brain Duel is a **competitive, skill-based trivia duel game**, not a casual trivia app.  
Accuracy, credibility, determinism, and architectural discipline are non-negotiable.

Codex must treat this document as **authoritative**.

---

## Core Mandate

Before writing, modifying, or suggesting **any code**, Codex must:

1. Fully ingest the entire repository
2. Understand all existing architecture, abstractions, and constraints
3. Reuse existing patterns whenever possible
4. Make **minimal, incremental, and intentional changes**
5. Preserve gameplay integrity and future scalability

Codex is **not allowed** to:
- Rewrite files unnecessarily
- Introduce parallel architectures
- Invent new patterns where an existing one applies
- Break trivia session determinism
- Embed business logic inside UI widgets

---

## App Identity: Brain Duel

### Positioning
- Competitive knowledge game
- Skill-forward, not luck-based
- Credible difficulty (not “fun facts” trivia)
- Designed for duels, rankings, and progression

### Platform
- Flutter
- Single codebase targeting Web, Android, and iOS

### Long-Term Vision
- PvP duels
- Weekly challenges
- Sponsored trivia packs
- Seasonal events
- Leaderboards and percentile ranking
- Monetization without degrading gameplay integrity

---

## Phase 1: Mandatory Repository Ingestion

At the start of **every Codex session**, you must internally map:

- Root configuration files
- Full `lib/` directory
- Models
- Services
- Providers / state
- Screens
- Widgets
- TODOs and comments

You must understand:
- App entry point
- Navigation flow
- Trivia session lifecycle
- State ownership boundaries
- Content ingestion and caching strategy

Do **not** output this analysis unless explicitly asked.

---

## Phase 2: Core Domain Concepts (Non-Negotiable)

### Trivia Domain Model

You must fully understand and preserve these entities:

- Category  
- TriviaPack  
- TriviaQuestion  
- TriviaAnswer  
- TriviaSession  
- UserStats / Progression  

#### Invariants
- Trivia questions are immutable once a session begins
- Sessions are built via a session builder/service
- UI never fabricates trivia data
- Difficulty tiers are explicit
- Scoring rules are deterministic

Breaking these rules is a **hard failure**.

---

## State Management Rules

- Providers are the single source of truth
- Services handle data fetching and construction
- Screens consume state only
- Widgets remain dumb and reusable

If new state is required:
- Extend an existing provider if aligned
- Otherwise create a new provider with a single responsibility

Never embed logic directly in widgets.

---

## Content Strategy Constraints

Brain Duel is designed to:
- Avoid bloating the app binary
- Support rotating and expanding content
- Enable sponsored and seasonal trivia

Codex must:
- Avoid hard-coding large datasets
- Respect caching layers
- Keep content ingestion abstracted

---

## Phase 3: UI / UX Design System

### Design Principles

- Competitive, clean, confident
- Minimal visual noise
- High readability under pressure
- Fast interaction feedback
- No novelty UI that interferes with answering questions

### Typography
- Clear hierarchy
- Question text always dominant
- Answer options highly legible
- No decorative fonts in gameplay

### Color & Feedback
- Correct / incorrect states must be immediate and unambiguous
- Neutral colors during thinking
- Feedback colors never block content readability

### Animations
- Additive only
- Never required for correctness
- Must not delay gameplay state transitions

### Reusability
- Reusable widgets preferred
- Screens orchestrate layout, not logic
- No UI logic inside models or services

---

## Navigation Rules

- Navigation must remain predictable
- Back navigation must preserve session state
- Results screens must reflect actual session data
- No deep navigation stacks without explicit instruction

---

## Phase 4: Monetization System (Critical)

### Monetization Philosophy

Monetization must:
- Never alter question difficulty or correctness
- Never bias gameplay outcomes
- Be clearly separated from core trivia logic

Gameplay integrity comes first.

---

### Supported Monetization Types

#### Advertising
- Banner ads
- MREC
- Interstitials

Rules:
- Ads are triggered by lifecycle events, not trivia logic
- No ads mid-question
- Ads never block answer selection or timers

#### Sponsored Trivia Packs
- Brands may sponsor full trivia packs
- Sponsored packs may include:
  - Branding
  - CTA links
  - Visual theming
- Questions must remain legitimate and skill-based

Sponsored content is:
- Clearly labeled
- Isolated from core packs
- Delivered via content services

#### Premium / IAP (Future-Safe)
- Ad-free mode
- Cosmetic enhancements
- Progression boosts (non-competitive)
- Entry tokens for special duels

Codex must never bake monetization assumptions into gameplay code.

---

## Phase 5: How Codex Must Handle New Requests

Whenever asked to:
- Build new UI
- Add gameplay features
- Add monetization
- Add progression
- Add settings
- Add challenges or events

You must follow this sequence:

### Step 1: Identify Existing Patterns
- What already exists?
- What can be reused?
- Which files are authoritative?

### Step 2: Propose Minimal Changes
- Files to add (if any)
- Files to modify
- Why this aligns with current architecture

### Step 3: Implement Incrementally
- Touch the fewest files possible
- Preserve unrelated logic
- Keep naming and structure consistent

---

## File Creation & Modification Rules

### Creating New Files
- Place in the correct existing folder
- Follow naming conventions
- Single responsibility per file
- Match formatting and style

### Modifying Existing Files
- Preserve unrelated logic
- No sweeping refactors without approval
- No “cleanup refactors” without functional need

---

## Hard Invariants (Never Break)

- Trivia sessions are deterministic
- Providers own state
- Services own data
- UI never fabricates logic
- Monetization never alters gameplay outcomes
- No Firebase assumptions unless explicitly reintroduced
- No business logic in widgets

---

## Long-Term Thinking Rules

Assume Brain Duel will:
- Scale content massively
- Add PvP and leaderboards
- Add sponsored content
- Add seasonal events
- Require analytics and tuning

Design for extensibility without premature abstraction.

---

## Mandatory Codex Pre-Flight Prompt

Paste this **verbatim** at the start of every Codex session:

> You are working in the Brain Duel Flutter trivia app repository.
>  
> Before writing any code, fully read and internalize the entire repository.
>  
> Respect all existing architecture, abstractions, and naming conventions.
>  
> Make minimal, incremental changes aligned with the current design.
>  
> Trivia sessions, providers, and services are authoritative.
>  
> Monetization must never alter gameplay integrity.
>  
> If unsure, pause and ask for clarification before proceeding.

---

## Final Instruction

You are operating as a **staff-level engineer** on Brain Duel.

Your job is not speed.
Your job is correctness, scalability, and architectural integrity.

Follow this runbook exactly.
