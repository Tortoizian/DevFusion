# SplitSmart

SplitSmart is a feature-rich, Flutter-based expense sharing application built for seamless bill splitting, expense tracking, and group settlements. It includes advanced features like OCR bill scanning, PDF/CSV exports, real-time analytics, and UPI integration for settlements.

## Features
- **Group Management**: Create and join groups using invite codes or QR codes.
- **Expense Tracking**: Add expenses, split them equally, exactly, by percentage, or by shares.
- **Analytics**: Visualize group spending with beautiful, interactive charts.
- **Receipt Parsing (OCR)**: Automatically extract amounts from receipts using Google ML Kit.
- **Exports**: Export group expenses to PDF and CSV formats.
- **Trip Mode**: Track budgets specifically for trips.
- **UPI Settlements (Sandbox)**: Settle debts effortlessly via a mock UPI flow.

## Setup Instructions

1. **Prerequisites**
   - Flutter SDK installed (version 3.24 or higher)
   - Dart SDK
   - Access to a Supabase project (for production usage, though mock data is available)

2. **Installation**
   ```bash
   git clone https://github.com/yourusername/splitsmart.git
   cd splitsmart
   flutter pub get
   ```

3. **Environment Configuration**
   Create a `.env` file in the root directory:
   ```env
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   ```
   *(Note: The app is currently configured to use `MockDatabaseRepository` via Riverpod overrides in `main.dart` for rapid testing.)*

4. **Run the App**
   ```bash
   flutter run
   ```

## Test Credentials (Mock Mode)
When running the app in Mock mode (default), the following dummy users are available:
- `user1` (Abhinav)
- `user2` (Alice)
- `user3` (Bob)

You can generate invite codes and use the generated dummy groups directly.

## Edge Functions
The project contains Supabase Edge Functions for handling recurring expenses and FCM push notifications.
- `supabase/functions/notify-settlement`
- `supabase/functions/process-recurring`

Deploy them using:
```bash
supabase functions deploy process-recurring
supabase functions deploy notify-settlement
```

## Contributing
1. Fork the project.
2. Create your feature branch (`git checkout -b feature/AmazingFeature`).
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`).
4. Push to the branch (`git push origin feature/AmazingFeature`).
5. Open a Pull Request.

## License
Distributed under the MIT License. See `LICENSE` for more information.
