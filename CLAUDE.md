# Relay

## Project Overview

Relay is a personal assistant Rails app that connects the tools and services I use daily. It acts as a relay layer — ingesting data from external sources, applying LLM-powered reasoning, and taking actions across integrated services. Over time it will replace some third-party tools with home-built alternatives.

## Architecture Philosophy

- **Agent-first**: use ruby_llm agents for any classification, parsing, or decision-making. Prefer agents over hand-coded conditionals or regex.
- **LLMs reason, Rails orchestrates**: LLM agents handle interpretation and judgment; Rails models handle persistence; background jobs handle async execution.
- **Rails defaults**: stick to what Rails provides out of the box. Avoid gems that duplicate framework features.
- **Start simple, grow into complexity**: extract new agents and abstractions only when there is a clear need.

## Tech Stack

- **Rails 8.1.3** with SQLite (multi-database: primary, queue, cache, cable)
- **Solid Queue** for background jobs, **Solid Cache**, **Solid Cable**
- **ruby_llm** for LLM integrations and agents
- **Kamal** for deployment to Hetzner

## Development Conventions

### TDD — red, green, refactor

Write a failing test first. Make it pass. Then refactor. Never write production code without a failing test driving it.

### Full-stack slices

Each PR is a small, independently usable vertical slice: model + migration + controller + job + test, all together. Slices stack on top of each other until a feature is complete. No half-finished layers.

### PRs early and often

Open a PR as soon as tests are passing. Don't wait for a feature to be "complete". Small, frequent PRs are preferred over large batches.

### Controller conventions

- Controllers receive, enqueue, and respond — nothing more.
- LLM calls always go through a background job so webhooks return quickly.
- Auth logic lives in `before_action` callbacks, not inline.

### Agent conventions

- One agent class per responsibility.
- Agents live in `app/agents/`.
- Agents are invoked from jobs, never directly from controllers.

## Current Feature: Banking Notifications → YNAB

Mobile notifications from banking apps are forwarded from Android via Tasker as webhook POST requests. An LLM agent parses the notification text and extracts transaction details, which are then posted to YNAB.

**Flow:**

```
Tasker (Android) → POST /webhooks/notifications
  → NotificationsController (authenticate, enqueue)
  → ProcessNotificationJob
  → BankingNotificationAgent (ruby_llm) — extracts amount, merchant, account, type
  → YnabClient — creates transaction via YNAB API
```

**Authentication:** Bearer token in the `Authorization` header. The controller validates it against `Rails.application.credentials.webhook_token` in a `before_action`.

## External Integrations

| Service | Auth | Purpose |
|---------|------|---------|
| YNAB    | Personal access token (`Rails.application.credentials.ynab_token`) | Create transactions from parsed notifications |
| Tasker  | Bearer token (`Rails.application.credentials.webhook_token`) | Forward Android notifications as webhooks |

## Roadmap

- [x] Project setup
- [x] Banking notification → YNAB entry (initial feature)
- [ ] Support additional notification types and services
- [ ] Chat interface with intent recognition — route user input to the right feature (e.g. upload a receipt photo → add YNAB entry + mark shopping list items as bought)
- [ ] Home Assistant integration
- [ ] Home-built replacements for third-party apps (TBD)

## Key Files

_This section will grow as the codebase develops._
