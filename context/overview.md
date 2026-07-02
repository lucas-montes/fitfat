# FitFat — Project Overview

A Flutter fitness tracking app for logging exercises and calorie intake.

## Current state

All previous source code was deleted in commit `2893826`. The project is being rebuilt from scratch with a barebone, minimal implementation using:

- **Flutter** — UI framework
- **Drift** — SQLite ORM for persistence
- **Riverpod** — State management
- **GoRouter** — Declarative routing
- **Bottom navigation** — 4 tabs (Dashboard, Exercise, Diet, Settings)

## Design principles

- Minimal, single-user, local-first
- CRUD forms as the primary interaction pattern
- No authentication, no sync, no cloud
