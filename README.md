# TnT — TopUp & Tournament System

> **Build Specification Version 1.0 Implementation**  
> Complete implementation adhering to all requirements in [TopUp_Tournament_System_Requirements.pdf](file:///Users/macbookpro/projects/TopUp%20and%20Tournament/TopUp_Tournament_System_Requirements.pdf).

---

## 🚀 Key Highlights & Architecture

- **Backend**: Zero-dependency Node.js (`v26+`) native HTTP server with built-in SQLite (`node:sqlite`).
- **Database Schema**: Full implementation of all **16 entities** specified in Section 8.
- **Double-Entry Wallet**: Append-only transaction ledger with atomic balance updates, idempotency key enforcement, and mathematical reconciliation checks (`available + locked == sum(credits) - sum(debits)`).
- **Automated Top-Up Engine**: Game catalog (Free Fire MAX, PUBG Mobile, Mobile Legends, Valorant), player UID format validation regex, webhook HMAC-SHA256 signature verification, and delivery dispatch.
- **Tournament Lifecycle**: Complete state machine (`Draft` → `Published` → `Registration Open` → `Check-in` → `Live` → `Results Pending Review` → `Completed`, with cancellation auto-refund path).
- **Time-Gated Lobby Credentials**: Room ID & Password are strictly masked from unregistered users and time-gated before the configured release time.
- **Dual-Approval Prize Workflow**: High-value payouts require 2-step signoff (Tournament Manager 1st approval → Finance Reviewer dual-approval) before automated wallet disbursement.
- **Admin & Risk Dashboard**: Live KPIs, orders manager, manual delivery retries, refunds, user ban toggles, dispute queue, immutable audit logs, and an interactive **Webhook Test Harness**.
- **Frontend**: Dark cyberpunk/esports design with neon cyan/violet accents, glassmorphic header, live wallet pill, role switcher, and responsive layouts.

---

## 📁 Repository Structure

```
├── server/
│   ├── db.js              # SQLite database schema (16 tables) & seed data
│   ├── ledger.js          # Double-entry append-only wallet engine
│   ├── security.js        # HMAC-SHA256 signatures, RBAC permissions, audit logger
│   ├── router.js          # REST API endpoints matching Section 9 specification
│   └── index.js           # Native HTTP server & static SPA file server
├── public/
│   ├── index.html         # Single Page Application HTML5 structure
│   ├── css/
│   │   ├── variables.css  # Esports dark mode theme tokens & custom properties
│   │   ├── layout.css     # Navigation header, wallet pill, role switcher, footer
│   │   ├── components.css # Buttons, glass cards, badges, modal dialogs, tables
│   │   └── views.css      # View layouts for Home, Top-Up, Wallet, Tournaments, Admin
│   └── js/
│       ├── api.js         # REST API client with auth token injection
│       ├── state.js       # Global reactive state & Toast notification manager
│       └── app.js         # Interactive application controller & view renderer
├── tests/
│   └── api.test.js        # Section 12 test plan (12 automated test suites)
├── package.json
└── README.md
```

---

## 🛠️ How to Run

### 1. Start the Server
```bash
npm start
```
The server will start at **http://localhost:8080** (or `PORT` environment variable).

### 2. Run the Section 12 Test Plan
```bash
npm test
```
Executes all 12 test suites verifying:
1. ✅ Valid payment webhook HMAC signature & instant delivery credit
2. ✅ Invalid signature rejection (HTTP 401)
3. ✅ Amount mismatch protection (HTTP 400)
4. ✅ Duplicate webhook replay idempotency
5. ✅ Double-entry ledger balance reconciliation
6. ✅ Insufficient wallet balance spending rejection
7. ✅ Idempotent transaction key duplicate deduction prevention
8. ✅ Duplicate tournament registration rejection (HTTP 409)
9. ✅ Registration cancellation and entry fee refund to wallet ledger
10. ✅ Room secret masking from unregistered/unreleased participants
11. ✅ Room secret decryption for eligible registered participants
12. ✅ Deterministic match scoring & 2-step dual-approval prize payout

---

## 🛡️ Admin Login & Role Credentials

You can log in to the administrative portal using the dedicated **Admin Login** button in the top bar, via the API endpoint `/api/auth/login`, or by using the top-bar role selector.

### Super Admin Credentials:
- **Username**: `admin` &nbsp;(or `admin@platform.io` / `usr_admin`)
- **Password**: `admin123`
- **Role**: `super_admin` (`Aegis_Root`)
- **Permissions**: Full unrestricted administrative access, payment verification, tournament management, dispute resolution, financial auditing, and risk control.

### Other Pre-Seeded Personnel & Player Accounts:

| Persona | Role Key | Email / Login | Permissions |
|---|---|---|---|
| **Aegis_Root** | `super_admin` | `admin@platform.io` / `admin` | Full system control, payment verification, audit |
| **Phoenix_Ace** | `player` | `phoenix@gamer.io` | Top-up orders, tournament registration, wallet |
| **Kage_Director** | `tournament_manager` | `tournaments@platform.io` | Tournament CRUD, match scoring, prize approvals |
| **Nexus_Ops** | `topup_operator` | `ops@platform.io` | Orders lifecycle, delivery retries, package edits |
| **Audit_Vault** | `finance_reviewer` | `finance@platform.io` | Dual-approval prize payouts, wallet adjustments |
| **Sentinel_Care** | `support` | `support@platform.io` | Dispute review, user lookups, read-only audit log |

---

## 📱 Mobile-Friendly Features

The platform is designed to look and feel like a native mobile gaming app on smartphones and tablets:
- **Infographic Mobile App Bottom Bar**: Fixed bottom navigation with 5 key tabs (*Home, Games, Top Up, Tournaments, Wallet, Profile*) for one-thumb navigation.
- **Adaptive Touch Layouts**: 2-column top-up stepper, wallet balance hero, and package denomination lists automatically adapt into touch-friendly cards on small viewports.
- **Responsive Modals & QR Codes**: Checkout dialogs and QR scan containers scale fluidly to `95vw` with native momentum touch scrolling.
- **Horizontal Ledger Scrolling**: Data tables scroll smoothly on small screens with pinned headers.

---

## 🤖 AI Subscriptions & License Vault Management

A complete production module for selling, dispatching, and managing official AI model subscriptions and developer tools (OpenAI ChatGPT Plus, Anthropic Claude 3.5 Pro, Midjourney, Cursor Pro, Perplexity Pro, and GitHub Copilot).

### User Features:
- **Instant Checkout**: Select 1-Month, 3-Month, or 1-Year plans with dual pricing in NPR (`Rs.`) and USD (`$`).
- **Multiple Local Payment Options**: Wallet Balance (1-click instant debit), eSewa Mobile Wallet / QR, and Khalti Digital Wallet.
- **Instant Vault Key Allocation**: Pulls genuine activation keys / tokens from the vault immediately on payment confirmation.
- **Subscriber Dashboard**: View active licenses, 1-click clipboard copy (`📋`), expiration countdowns, and renewal toggles.

### Admin Panel Controls (`🤖 AI Subscriptions` Tab):
- **Live MRR & Analytics**: Monthly Recurring Revenue tracking, active subscriber counts, pending activations, and vault inventory gauges.
- **Subscriptions Queue**: Real-time status filtering (*Active, Pending, Suspended, Expired*), 1-click `[⚡ Activate & Assign Key]`, 30-day `[🔄 Renew]`, `[⚠️ Suspend]`, and `[❌ Cancel]` actions.
- **License Key Vault**: Dedicated inventory management for serial codes and vouchers. Filter by AI tool, view assignment status (*Available* vs *Assigned*), and replenish inventory via single or bulk key pastes or 1-click test key generation.

