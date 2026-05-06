# CLAUDE.md — RoastMyRoom

## WHY

App iOS native Swift 6 / SwiftUI / iOS 26+ qui note les pièces de la maison via IA (photo → score /10 → carte partageable → boucle virale). Distribuée en production via App Store. Backend Supabase Edge Functions (Deno/TS) + Firebase Analytics.

## WHAT

- **Code Swift** : `RoastMyRoom/` — `App/` (entry point, RootView), `Core/{Extensions,Models,Services}/`, `Features/{Scan,Analysis,Result,Profile,History,ATT,Paywall,Onboarding}/`
- **Tests** : `RoastMyRoomTests/`
- **Dépendances** : SPM géré via Xcode (résolu dans `RoastMyRoom.xcodeproj/…/swiftpm/Package.resolved`, ~14 packages dont `firebase-ios-sdk`)
- **Assets** : `RoastMyRoom/Assets.xcassets/`
- **App Store Connect** : `ASC/` — métadonnées localisées + fastlane
- **Companion web** : `web/`
- **Backend** : `supabase/`
- **Hooks & permissions** : `.claude/settings.json`

## HOW — Workflow

### MCP XcodeBuildMCP (préféré à `xcodebuild` brut)

```
Scheme  : RoastMyRoom
Sim     : iPhone 17 Pro (iOS 26.2)   ← défaut session_set_defaults
Device  : Samuel's iPhone 16 Pro
         id         : 00008140-001202460184801C
         CoreDevice : 00992BA0-472B-5500-810E-D896A8F380B8
```

Toujours appeler `session_show_defaults` avant le premier build d'une session, puis `build_run_sim` / `test_sim` / `screenshot` via MCP.

### Fastlane (ASC)

```bash
export PATH="/opt/homebrew/opt/ruby/bin:/opt/homebrew/lib/ruby/gems/4.0.0/bin:$PATH"

bundle exec fastlane metadata          # upload métadonnées localisées
bundle exec fastlane screenshots       # upload screenshots localisés
bundle exec fastlane upload_store_assets  # metadata + screenshots
bundle exec fastlane archive_upload    # archive Release + upload ASC
bundle exec fastlane release           # build + metadata + screenshots + soumission
```

> **Workaround critique** : fastlane utilise l'API Spaceship directement (pas `deliver`) pour contourner les bugs de `deliver` sur les uploads ASC. Ne pas revenir à `deliver` sans tester.

### Build bottom-up

`Model → Service → ViewModel → View → Tests → #Preview → build sans warning`

## RÈGLES NON-NÉGOCIABLES

1. **Jamais** de force-unwrap (`!`) hors `fatalError` debug — utiliser `guard let` ou `??`
2. **Jamais** de `Any` / `AnyObject` quand un type concret est connu
3. **Jamais** d'accès UI hors `@MainActor` (Swift 6 strict concurrency)
4. **Jamais** commit sans build passant (`build_sim` MCP retourne success)
5. **Toujours** un test pour les ViewModels avec logique métier
6. **Toujours** `@Observable` (Observation framework) pour les ViewModels SwiftUI — pas `ObservableObject`
7. **Toujours** MCP XcodeBuildMCP plutôt que `xcodebuild` brut
8. **Toujours** localiser via `String(localized:)` dans les 4 langues : EN, FR, DE, ES

## Conventions iOS

- **Architecture** : MVVM strict — `@MainActor @Observable final class`. `AppFactory` = composition root (DI init-based, pas de singleton sauf `AppFactory`)
- **Async** : `async/await` uniquement — pas de Combine, pas de `DispatchQueue` sauf interop UIKit
- **Persistence** : SwiftData (`@Model`) — pas CoreData
- **SwiftUI** : `body` < 30 lignes, extraire sous-vues. `.toolbar {}` avec Liquid Glass automatique (ne pas ajouter `.buttonStyle(.glass)` manuellement). `NavigationStack`, pas `NavigationView`
- **TabView** : ViewModels des onglets créés comme `@State` dans `MainTabView` (`App/RootView.swift`) et injectés — jamais recréés dans les vues enfants
- **Couleurs** : `Color+Theme.swift` uniquement — jamais de hex hardcodé
- **Previews** : `#Preview` par état clé (loading / success / error / empty)
- **Tests** : framework `Swift Testing` (`import Testing`, `#expect`, `@Test`)

## Identifiants App Store

| Champ | Valeur |
|-------|--------|
| Bundle ID | `com.disco.RoastMyRoom` |
| SKU | `RoastMyRoom` |
| Langues | EN, FR, DE, ES |
| IAP | 3 subscriptions (weekly / annual / lifetime) + 4 consumables (points) |
| `whats_new` | Non uploadable pour v1.0 (première version) |

## Gotchas

- **Simulator state** : `xcrun simctl erase` si comportement bizarre après changement d'iOS
- **Swift 6 + main-actor** : strict concurrency active — warnings à traiter progressivement, pas d'un coup
- **Firebase** : `GoogleService-Info.plist` requis dans le target (sans lui, Firebase désactivé + log console)
- **Keychain anti-abus** : `KeychainService` survit aux désinstallations (`kSecAttrAccessibleAfterFirstUnlock`) — clés : `pointsBalance`, `dailyScanCount`, `lastScanDate`, `hasSeenOnboarding`
- **Auth** : Sign in with Apple → Supabase (`/auth/v1/token?grant_type=id_token`). Auth optionnelle : achats fonctionnent sans elle
- **Analytics** : tout nouvel événement visible utilisateur → `AnalyticsEvent` dans le ViewModel + `TRACKING_PLAN.md`
- **Fastlane** : mettre à jour les gems à chaque release (`bundle update`)
