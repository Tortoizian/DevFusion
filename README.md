# SplitSmart

**DevFusion 3.O** · Problem Statement **#26ENSS5**

*No more WhatsApp math.*

---

## What is this?

SplitSmart is a group expense app built for Indian college students. You know the drill: four friends go to Goa, someone books the hotel, someone pays for Swiggy at 2am, someone fills petrol, and by day three nobody remembers who owes what. The group chat fills up with screenshots and "bhai tu bhi de de" messages. Someone makes an Excel sheet. Nobody opens it.

This app is our answer to that mess.

Create a group, share a 6-character code or QR, log expenses as they happen, and everyone sees the same numbers in real time. When it's time to settle, SplitSmart runs a debt simplification algorithm so you don't end up with seven random UPI transfers when three would do. Tap Settle Up, your UPI app opens with the amount and memo already filled in, and the payee confirms when the money lands.

We built it for DevFusion 3.O as a Flutter + Supabase project with the DSA challenge (debt minimisation), UPI settlement, and live sync baked in from the start.

---

## Download the app

**Release APK (Google Drive):** [Add your APK link here]

Install on Android, sign in with the test Google account below, and you're good to go. The backend runs on Supabase cloud, not localhost, so it works on any device with internet.

---

## For judges (quick test flow)

1. Install the APK and open SplitSmart.
2. Tap **Continue with Google** and sign in with the test account.
3. Set up your profile (display name + UPI VPA). Any valid-looking VPA works for demo, e.g. `yourname@ybl`.
4. Create a group (try Trip Mode for the Goa-style demo) or join one with a code.
5. Add an expense on one phone. Open the same group on a second device and watch it appear within a couple of seconds.
6. Go to **Balances**, hit **Simplify**, and watch the debt graph collapse to the minimum transfers.
7. Tap **Settle Up** on a transfer. GPay/PhonePe opens in **sandbox test mode** (no real money). Mark as paid, then confirm from the payee side.

---

## Features

**Groups & onboarding**
- Google OAuth sign-in
- Profile setup with display name and UPI VPA
- Create groups with category and optional Trip Mode (dates + budget)
- Join via 6-character invite code or QR scan
- Cross-group dashboard showing total owed/owing across all your groups

**Expenses**
- Add expenses with four split types: equal, exact amounts, percentage, shares
- Keyword-based category detection (type "Swiggy" and it picks Food)
- Remembers your last split type per group
- Receipt photo attachment (Supabase Storage)
- Bill scanner: point camera at a receipt, OCR pre-fills amount and description
- Real-time sync across all group members via Supabase Realtime

**Balances & settlement**
- Per-member net balances
- Greedy heap debt simplification (O(V log V), runs on device)
- Animated debt graph showing raw debts vs simplified transfers
- Debt leaderboard (who owes the most)
- One-tap UPI deep link settlement (Android, sandbox mode)
- Two-step settlement: debtor marks paid, creditor confirms
- Push notification to payee when a settlement is pending (FCM + Supabase Edge Function)
- Confetti when the group hits zero balance

**History & analytics**
- Expense history with filters (date, category, payer, member)
- Category spending donut chart
- Trip summary card when Trip Mode is on
- Export to PDF or CSV and share via WhatsApp/email

**Stretch**
- Recurring expenses (monthly rent, Netflix, etc.) via Edge Function

---

## Tech stack

| Layer | Tools |
|-------|-------|
| App | Flutter / Dart, Riverpod, GoRouter |
| Backend | Supabase (PostgreSQL, Auth, Realtime, Storage, Edge Functions) |
| Push | Firebase Cloud Messaging |
| Charts | fl_chart |
| OCR | Google ML Kit (on-device, no API key) |
| Export | pdf, csv, share_plus |

---

## Run locally

**Requirements:** Flutter 3.6+, a Supabase project with migrations applied, Google OAuth configured for Android.

```bash
git clone https://github.com/Tortoizian/DevFusion.git
cd DevFusion
cp .env.example .env
```

Fill in `.env`:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

Apply SQL migrations in order from `supabase/migrations/` in the Supabase SQL editor.

```bash
flutter pub get
flutter run
```

For release APK:

```bash
flutter build apk --release
```

**Edge Functions** (optional, for push + recurring expenses):

```bash
supabase functions deploy notify-settlement
supabase functions deploy process-recurring
```

Set `FCM_SERVICE_ACCOUNT` in Supabase Edge Function secrets for push notifications.

---

## Test account

Sign in with Google using:

| | |
|---|---|
| **Email** | [Add test Google account email here] |

OAuth only. No password needed if you're already logged into that account on the device.

---

## UPI (sandbox)

All settlement flows are **test mode**. No real money moves.

| | |
|---|---|
| **Test VPA** | `test@upi` |
| **Platform** | Android only |

The app shows an orange sandbox banner on settlement screens (labeled TEST MODE). Tapping Settle Up opens GPay/PhonePe with pre-filled amount, VPA, and a memo like `SplitSmart: Goa 2025 (6 expenses)`.

iOS users see a message that UPI settlement is Android-only.

---

## Team

| Name | Role |
|------|------|
| Arnav Prasad | Solo developer (Flutter, Supabase, DSA, UI) |

---

## Known limitations

- UPI deep links work on **Android only**. iOS shows a fallback message.
- Bill OCR works best on printed receipts with clear text. Handwritten bills are hit or miss.
- Push notifications need Firebase configured (`google-services.json`) on the Android build.
- Floating-point rounding: balances under ₹0.01 are treated as zero.
- Settlement is never auto-confirmed. You must tap Mark as Paid after returning from the UPI app, and the payee must confirm.
- Recurring expenses need the Edge Function deployed (or triggered manually from the Supabase dashboard for demo).

---

## Project structure (high level)

```
lib/
  core/algorithms/     # Debt simplification engine
  core/repository/     # Supabase + mock repos
  core/state/          # Riverpod group state
  features/auth/       # Login, profile setup
  features/dashboard/  # Home + global balance
  features/groups/     # Groups, expenses, balances, analytics
supabase/
  migrations/          # PostgreSQL schema + RLS
  functions/           # FCM push, recurring expenses
```

Tests: `flutter test` (debt simplification + group state notifier).

---

Built for **DevFusion 3.O**, Problem Statement **#26ENSS5 (SplitSmart)**.
