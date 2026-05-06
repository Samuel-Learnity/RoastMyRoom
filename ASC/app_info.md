# App Store Connect — App Information

## General

| Field | Value |
|-------|-------|
| **Bundle ID** | `com.disco.RoastMyRoom` |
| **SKU** | `RoastMyRoom` |
| **Primary Language** | English (U.S.) |
| **Category** | Lifestyle |
| **Secondary Category** | Entertainment |
| **Content Rights** | Does not contain third-party content |

## Pricing

| Field | Value |
|-------|-------|
| **Price** | Free |
| **Availability** | All territories |

## Age Rating

| Question | Answer |
|----------|--------|
| Cartoon or Fantasy Violence | None |
| Realistic Violence | None |
| Prolonged Graphic or Sadistic Violence | None |
| Profanity or Crude Humor | Infrequent/Mild |
| Mature/Suggestive Themes | None |
| Horror/Fear Themes | None |
| Medical/Treatment Information | None |
| Alcohol, Tobacco, or Drug Use | None |
| Simulated Gambling | None |
| Sexual Content or Nudity | None |
| Unrestricted Web Access | No |
| Gambling and Contests | No |

**Expected Rating:** 4+ (or 9+ due to infrequent mild humor)

## URLs

| Field | URL |
|-------|-----|
| **Privacy Policy** | https://web-neon-six-28.vercel.app/privacy |
| **Terms of Service** | https://web-neon-six-28.vercel.app/terms |
| **Support URL** | https://web-neon-six-28.vercel.app/support |
| **Marketing URL** | *(optional)* |

> **WARNING:** These are placeholder Vercel URLs. Update to final domain before submitting for review.

## In-App Purchases (7 products)

### Auto-Renewable Subscriptions (Group: "RoomScore Premium")

| Product ID | Name | Price | Trial |
|-----------|------|-------|-------|
| `roomscore.weekly` | Weekly | €4.99/week | 3-day free trial |
| `roomscore.annual` | Annual | €29.99/year | 7-day free trial |
| `roomscore.lifetime` | Lifetime | €49.99 one-time | — |

### Consumables

| Product ID | Name | Price |
|-----------|------|-------|
| `roomscore.points.10` | 10 Points | €0.99 |
| `roomscore.points.35` | 35 Points | €2.99 |
| `roomscore.points.75` | 75 Points | €4.99 |
| `roomscore.points.200` | 200 Points | €9.99 |

## App Privacy (Data Collection)

| Data Type | Usage | Linked to User |
|-----------|-------|----------------|
| Analytics | App Functionality | No |
| Product Interaction | Analytics | No |
| User ID (if signed in) | App Functionality | Yes |

## Sign in with Apple

- Optional (not required to use the app)
- Used for cross-device points sync
- Uses Supabase Auth backend

## Copyright

`© 2026 Thiiink. All rights reserved.`

## Fastlane

| Command | Description |
|---------|-------------|
| `bundle exec fastlane metadata` | Upload localized metadata (name, description, keywords, etc.) |
| `bundle exec fastlane screenshots` | Upload localized screenshots from `ASC/output/` |
| `bundle exec fastlane generate_screenshots` | Generate screenshots via Python script |
| `bundle exec fastlane build` | Build archive for App Store |
| `bundle exec fastlane testflight_upload` | Build + upload to TestFlight |
| `bundle exec fastlane upload_store_assets` | Upload metadata + screenshots together |
| `bundle exec fastlane release` | Full release: build + metadata + screenshots + submit |
| `bundle exec fastlane bump` | Increment build number |

### Prerequisites

- Ruby (Homebrew): `export PATH="/opt/homebrew/opt/ruby/bin:/opt/homebrew/lib/ruby/gems/4.0.0/bin:$PATH"`
- Install deps: `bundle install`
- Auth: Credentials stored in macOS Keychain after first login

### Metadata Structure (Fastlane deliver)

```
ASC/metadata/
├── copyright.txt                    # Non-localized
├── review_information/
│   ├── notes.txt
│   ├── contact_first_name.txt
│   ├── contact_last_name.txt
│   ├── contact_phone.txt
│   ├── contact_email.txt
│   ├── demo_account_name.txt
│   └── demo_account_password.txt
└── {en-US,fr-FR,de-DE,es-ES}/      # Localized per language
    ├── name.txt
    ├── subtitle.txt
    ├── description.txt
    ├── keywords.txt
    ├── promotional_text.txt
    ├── whats_new.txt
    ├── support_url.txt
    ├── marketing_url.txt
    ├── privacy_policy_url.txt
    └── privacy_policy_text.txt
```
