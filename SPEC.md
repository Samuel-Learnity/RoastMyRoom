# SPEC.md — RoomScore MVP

> Spécification technique du MVP (v1.0).
> Source de vérité unique. Toute feature absente est hors scope.

---

## 1. Concept

**RoomScore** — Photo d'une pièce → Score /10 par IA → Carte partageable → Boucle virale.

- **Promesse** : "Snap. Score. Share."
- **Target** : iOS 17+, iPhone uniquement (pas iPad)
- **Langues** : FR + EN

---

## 2. Architecture

MVVM strict. Injection via `AppFactory` (composition root, singleton).

```
RoomScore/
  App/
    RoomScoreApp.swift              — @main, WindowGroup, lance RootView
    AppFactory.swift                — DI container singleton, crée services + VMs
    RootView.swift                  — Gère first launch (onboarding) → TabView

  Core/
    Models/
      RoomScan.swift                — @Model SwiftData : id, imageData, scores, style, tips, roast, date
      RoomStyle.swift               — Enum styles déco (Japandi, Scandinavian, Industrial, etc.)
      SubScores.swift               — Struct Codable : colorHarmony, proportions, lighting, cleanliness, personality (Float 0-10)
      Tip.swift                     — Struct Codable : text (String), estimatedImpact (Float)
      ScanResult.swift              — Struct Codable : réponse brute API → mapped vers RoomScan
    Services/
      ScoringService.swift          — Protocole + impl : envoie photo, reçoit ScanResult
      APIClient.swift               — URLSession minimal, POST base64 → Supabase Edge Function
      ImageProcessor.swift          — Compression JPEG, resize, validation (est-ce une pièce ?)
      ShareCardRenderer.swift       — UIGraphicsImageRenderer → UIImage carte partageable
      SubscriptionService.swift     — StoreKit 2 : products, purchase, restore, status
      StorageService.swift          — SwiftData wrapper : save/fetch/delete RoomScan
    Extensions/
      Color+Theme.swift             — Couleurs sémantiques adaptatives (light/dark)
      View+Extensions.swift         — Modifiers : .glassBackground, .scoreColor, .shimmer
      Image+Compression.swift       — UIImage → JPEG compressé/resizé

  Features/
    Onboarding/
      OnboardingView.swift          — 3 slides PageTabView, demande permission caméra au CTA final
    Scan/
      Views/
        ScanView.swift              — Caméra plein écran, shutter, galerie, flash
        CameraPreview.swift         — UIViewRepresentable → AVCaptureVideoPreviewLayer
      ViewModels/
        ScanViewModel.swift         — Gère AVCaptureSession, capture, permissions
    Analysis/
      Views/
        AnalysisView.swift          — Loading animé : scan laser + textes rotatifs + progress bar
      ViewModels/
        AnalysisViewModel.swift     — Orchestre ImageProcessor → ScoringService → nav résultat
    Result/
      Views/
        ResultView.swift            — Scroll vertical : hero photo, score, badge, roast, sous-scores, tips, action bar
        ScoreCounterView.swift      — Compteur animé 0→score, couleur dynamique
        RadarChartView.swift        — Shape pentagone 5 axes, trim animation
        StyleBadgeView.swift        — Capsule colorée : icône + nom style
        TipCardView.swift           — Card : icône + texte + "+X.X pts"
        RoastBannerView.swift       — Bandeau sarcastique, toujours visible (même free)
      ViewModels/
        ResultViewModel.swift       — Display data, share logic, paywall trigger
    History/
      Views/
        HistoryView.swift           — LazyVGrid 2 colonnes
        HistoryCardView.swift       — Miniature photo + score overlay
      ViewModels/
        HistoryViewModel.swift      — SwiftData fetch, tri date, delete, limite free
    Profile/
      Views/
        ProfileView.swift           — List groupé : stats, abo, settings, légal
      ViewModels/
        ProfileViewModel.swift      — Stats agrégées, subscription status
    Paywall/
      Views/
        PaywallView.swift           — Sheet : fond photo blurée, 3 plans, CTA, social proof
        PlanCardView.swift          — Card prix individuelle
      ViewModels/
        PaywallViewModel.swift      — StoreKit 2 products, purchase, restore
  Resources/
    Assets.xcassets
    Localizable.xcstrings           — FR + EN
```

---

## 3. Navigation

### Tab Bar — 3 onglets

| # | SF Symbol | Label | Vue | Par défaut |
|---|-----------|-------|-----|------------|
| 1 | `camera.viewfinder` | Scan | ScanView | ✅ |
| 2 | `clock.arrow.circlepath` | History | HistoryView | |
| 3 | `person.crop.circle` | Profile | ProfileView | |

Matériau Liquid Glass (translucide + blur). Accent : indigo `#5E5CE6`. Pas de 4e onglet.

### Flow principal

```
App Launch
  ├─ First Launch → OnboardingView (3 slides) → ScanView
  └─ Return User → ScanView (tab 1)

ScanView
  └─ Shutter / Gallery pick
      └─ AnalysisView (2.5s loading)
          └─ ResultView
              ├─ "Share" → UIActivityViewController (image + texte)
              ├─ "Scan Again" → ScanView
              ├─ Scroll sous-scores blurés → PaywallView (.sheet)
              └─ Auto-save → HistoryView

HistoryView
  ├─ Tap card → ResultView (relecture)
  └─ Swipe left → Delete (confirmation)

ProfileView
  ├─ "Upgrade" → PaywallView
  ├─ "Invite a Friend" → ShareSheet (lien app)
  └─ "Restore Purchases" → StoreKit restore
```

---

## 4. Écrans

### S0 — Onboarding

- `TabView` + `PageTabViewStyle`, 3 slides, indicateur dots
- Skip en haut droite (gris, discret)
- Slide 1 : "Photographiez n'importe quelle pièce" + illustration
- Slide 2 : "Obtenez un score design instantané" + animation compteur
- Slide 3 : "Partagez et challengez vos amis" + CTA "Scanner ma pièce →"
- Permission caméra au tap CTA slide 3
- `@AppStorage("hasSeenOnboarding")` — une seule fois

### S1 — Scan (Caméra)

- Plein écran, zéro navigation bar
- `AVCaptureVideoPreviewLayer` via UIViewRepresentable
- Shutter : centre bas, 72pt blanc, anneau 80pt, `shadow(radius: 8)`
- Galerie : bas gauche, 44pt, miniature dernière photo (PHAsset)
- Flash : haut droite, `bolt.fill` / `bolt.slash.fill`, 3 états (auto/on/off)
- Guide "Cadrez votre pièce" : fade-out après 2s
- Capture JPEG `.high` via `AVCapturePhotoOutput`
- Haptic `.medium` au shutter
- PHPickerViewController pour galerie (1 image, pas vidéo)
- Pas de permission caméra → message + "Ouvrir Réglages"

### S2 — Analyse (Loading)

- **Durée min 2.5s** (artificiel même si API plus rapide — suspense)
- Fond : photo capturée, blur progressif 0→20
- Scan laser : ligne horizontale gradient blanc, descend en boucle
- Textes rotatifs (0.8s) : "Analyse des couleurs..." → "Détection du style..." → "Évaluation du layout..." → "Calcul du score..."
- ProgressView linéaire indigo
- Haptic `.light` à chaque transition texte

### S3 — Résultat (Score Card)

Scroll vertical, sections empilées :

```
┌─────────────────────────────────┐
│  Photo hero (4:3, radius 24)    │  ← Overlay gradient noir vers le bas
│         ┌───────┐               │
│         │  7.3  │               │  ← 96pt, animé 0→7.3, couleur dynamique
│         │  /10  │               │
│         └───────┘               │
│      ┌─────────────┐            │
│      │  🎋 Japandi │            │  ← Badge capsule colorée
│      └─────────────┘            │
│  ┌─────────────────────────┐    │
│  │ 🔥 "Your cable manage-  │    │  ← Roast (TOUJOURS visible, même free)
│  │  ment called. It quit." │    │
│  └─────────────────────────┘    │
│                                 │
│  ══ BLUR WALL (si free) ══════  │  ← blur + lock + "Débloquer" → PaywallView
│                                 │
│  ┌─ Radar Chart (pentagone) ──┐ │  ← 5 sous-scores, anim trim 0.8s
│  └────────────────────────────┘ │
│  ┌─ Tip 1 ────────────────────┐ │  ← 1 visible free
│  │ 🪴 "Floor plant" +0.8      │ │
│  └────────────────────────────┘ │
│  ┌─ Tip 2 (blurred) ─────────┐ │  ← 2-3 blurés
│  └────────────────────────────┘ │
├─────────────────────────────────┤
│ [ 📤 Share ]  [ 🔄 Scan Again] │  ← Sticky bottom
└─────────────────────────────────┘
```

**Couleur dynamique du score** :

| Plage | Couleur | Hex |
|-------|---------|-----|
| 0.0 – 3.9 | Rouge | `#FF453A` |
| 4.0 – 5.9 | Orange | `#FF9F0A` |
| 6.0 – 7.9 | Vert | `#30D158` |
| 8.0 – 10.0 | Indigo | `#5E5CE6` |

**Animation score** : compteur 0.0→score final, 1.2s, `.spring(dampingFraction: 0.7)`, haptic `.success` au stop.

**Radar Chart** : Shape custom, 5 axes, `.trim(from: 0, to: 1)` sur 0.8s, `.easeOut`.

**Blur paywall** : `VisualEffectBlur` + icône cadenas + "Débloquer l'analyse complète" → `.sheet` PaywallView.

### S4 — History

- `LazyVGrid(columns: [.flexible(), .flexible()], spacing: 12)`
- Card : photo 4:3 radius 16, gradient bas + score bas-droite (28pt bold blanc shadow)
- Sections : "Cette semaine" / "Plus ancien"
- Tap → push ResultView (relecture)
- Swipe left → delete + confirmation
- Empty state : illustration + "Votre première pièce vous attend" + CTA caméra
- Limite free : 3 derniers scans visibles, reste grisé + lock → paywall

### S5 — Profile

- `List` groupé, sections :
  - **Mes stats** : total scans, score moyen, style dominant
  - **Abonnement** : badge Free/Premium, bouton gérer/upgrade
  - **Paramètres** : notifications toggle, apparence (system/light/dark)
  - **Partager** : "Inviter un ami" → ShareSheet lien app
  - **Légal** : CGU, Confidentialité, Support (SafariView)
- Footer : version + "Made with ❤️ and AI"

### Paywall (Sheet)

- `.sheet`, `.presentationDetents([.large])`, toujours dismissable (X + swipe + lien texte bas)
- Fond : photo de la pièce, blur 20, overlay sombre 60%
- Score qui pulse (scale loop) + "Débloquez l'analyse complète"
- 3 bullets animés checkmark : sous-scores, tips personnalisés, historique illimité
- Social proof : "247K+ pièces scannées"
- 3 plans :

| Plan | Product ID | Prix | Trial | Note |
|------|-----------|------|-------|------|
| Hebdo | `roomscore.weekly` | 4.99€/sem | 3 jours | **Pré-sélectionné** |
| Annuel | `roomscore.annual` | 29.99€/an | 7 jours | Badge "BEST VALUE" |
| Lifetime | `roomscore.lifetime` | 49.99€ | — | Non-consumable |

- CTA pleine largeur, gradient indigo→violet, "Essayer gratuitement", radius 16
- Fine print : "Annulable à tout moment" + CGU + Confidentialité + Restaurer
- "Continuer en version gratuite" : gris, 13pt, tout en bas

---

## 5. Service IA

### Pipeline

```
UIImage (capture)
  → ImageProcessor.prepare()
      → Resize max 1024×768 (aspect ratio conservé)
      → JPEG quality 0.8 (~200-400KB)
      → Validation : pas selfie, pas noir, pas flou extrême
  → APIClient.post("/score", imageBase64)
      → Supabase Edge Function (Deno/TS)
        → OpenAI GPT-4.1 mini (vision)
        → System prompt v2 (voir roomscore-prompt-v2.md)
      → JSON response
  → ScoringService.decode() → ScanResult → RoomScan (SwiftData)
```

### Prompt système (v2)

Le prompt complet est dans `roomscore-prompt-v2.md`. Points clés :

- **Personnalité** : "ruthlessly honest interior design critic with comedic timing"
- **Output** : JSON strict, même schéma que v1 (pas de changement structurel)
- **Scoring rubric** : grille d'ancrage détaillée pour chaque sous-score (2/5/8/10)
- **Distribution** : médiane ~5.0-5.5, 7+ rare (1/4 des pièces), 10 quasi inatteignable
- **Formule** : `overall_score = round((color_harmony × 2 + proportions + lighting + cleanliness + personality × 2) / 8, 1)`
- **Roasts** : 5 registres comiques (pop culture, observation ciblée, comparaison exagérée, compliment détourné, anthropomorphisme), doit référencer un élément visible
- **Tips** : spécifiques à la photo, prioriser le sous-score le plus faible, max 15 mots, somme impacts ≤ 3.5
- **Styles** : 17 styles avec descriptions visuelles d'identification
- **Edge cases** : non-pièce → `room_type: "other"`, `overall_score: 0.0` ; photo sombre → tip dédié ; pièce stagée → roast adapté
- **Langue** : clés JSON en anglais, textes dans la langue demandée par le client

### Validations serveur (Edge Function)

La Edge Function applique des garde-fous après la réponse IA :

| Validation | Comportement |
|------------|-------------|
| Scores hors range | Clamp 0.0-10.0, arrondi 1 décimale |
| `overall_score` incohérent | Si écart > 0.5 vs formule, recalculé automatiquement |
| Somme impacts tips > 3.5 | Impacts réduits proportionnellement |

### Réponse type

```json
{
  "room_type": "bedroom",
  "overall_score": 4.9,
  "style": "Student Chaos",
  "sub_scores": {
    "color_harmony": 5.5,
    "proportions": 5.0,
    "lighting": 6.0,
    "cleanliness": 6.5,
    "personality": 5.5
  },
  "tips": [
    { "text": "Replace the harsh overhead light with a warm floor lamp", "impact": 0.8 },
    { "text": "Pick a two-color palette and ditch the clashing pillows", "impact": 0.6 },
    { "text": "Hide cables with an adhesive raceway behind the desk", "impact": 0.4 }
  ],
  "roast": "That one decorative pillow is doing community service for the whole couch."
}
```

### Gestion d'erreurs

| Cas | Comportement |
|-----|-------------|
| Pas de réseau | Alert + retry |
| Timeout >10s | Retry auto ×1, puis alert |
| JSON invalide | Retry ×1, puis "Analyse partielle" avec score seul |
| Pas une pièce | IA retourne `room_type: "other"`, `overall_score: 0.0`, roast explicatif. L'app affiche le résultat normalement (score 0.0 + roast) |
| Photo sombre/floue | IA fait de son mieux + tip dédié ("Better lighting in the photo would help") |
| Pièce stagée/pro | IA note honnêtement + roast adapté |
| Rate limit | Queue + "Beaucoup de demandes, patientez..." |
| 5xx serveur | Alert générique + "Réessayer" |

---

## 6. Données

### SwiftData (local)

```swift
@Model
class RoomScan {
    var id: UUID
    var imageData: Data              // JPEG compressé
    var roomType: String
    var overallScore: Float
    var style: String
    var subScores: SubScoresData     // Codable struct → JSON
    var tips: [TipData]              // Codable array → JSON
    var roast: String
    var createdAt: Date
    var isPremiumResult: Bool
}
```

### Supabase (remote)

- **Auth** : Anonyme. Device ID uniquement. Pas de compte utilisateur MVP.
- **Edge Function** : `POST /score` — proxy vers OpenAI, rate limit par device ID
- **Storage** : Non utilisé MVP (photos locales uniquement)
- **PostgreSQL** : Table `scan_events(device_id, room_type, score, created_at)` pour analytics. Pas de PII.

### AppStorage

| Clé | Type | Usage |
|-----|------|-------|
| `hasSeenOnboarding` | Bool | Onboarding vu |
| `dailyScanCount` | Int | Scans du jour |
| `lastScanDate` | Date | Reset quotidien |
| `preferredAppearance` | String | system / light / dark |

---

## 7. Paywall Logic

### Triggers

1. Scroll sous-scores blurés (inline, pas blocking)
2. 3e scan du jour → sheet obligatoire avant scan
3. Tap scan grisé dans History (au-delà des 3 derniers)
4. Bouton "Upgrade" dans Profile

### Règles

- **Jamais bloquer** : score global + badge style + roast (c'est le contenu viral)
- **Toujours dismissable** : X + swipe down + lien texte
- **Pas de fullscreen takeover** au 1er lancement
- Plan hebdo **pré-sélectionné** (bordure indigo, scale 1.05)

### Limites free vs premium

| Feature | Free | Premium |
|---------|------|---------|
| Scans/jour | 2 | Illimité |
| Score global + badge + roast | ✅ | ✅ |
| 5 sous-scores + radar chart | Blurés | ✅ |
| Tips | 1 visible | 3 personnalisés |
| Historique | 3 derniers | Illimité |
| Share card | Avec watermark | Sans watermark |

---

## 8. Share Card

| Propriété | Valeur |
|-----------|--------|
| Story | 1080 × 1920 px |
| Feed | 1080 × 1080 px |
| Export | JPEG quality 0.92 |
| Fond | Photo pièce, aspect fill, blur 4 |
| Overlay | Gradient noir 60% bas |
| Score | 96pt bold blanc, centre-haut |
| Badge | Capsule blanc semi-transparent |
| Roast | 16pt blanc italic, centré bas |
| Branding | "RoomScore" + "roomscore.app" |
| Watermark free | "roomscore.app" semi-transparent centre |

Génération via `UIGraphicsImageRenderer`. Pas de SwiftUI snapshot (inconsistant cross-device).

Partage : `UIActivityViewController` — image + "Mon salon a eu {score}/10 sur RoomScore 🏠✨ roomscore.app"

---

## 9. Animations & Haptics

### Animations

| Moment | Type | Durée |
|--------|------|-------|
| Score reveal | Spring counter 0→N | 1.2s, `.spring(dampingFraction: 0.7)` |
| Radar chart | trim 0→1 | 0.8s, `.easeOut` |
| Badge style | scale 0.5→1 + fade | 0.3s |
| Scan laser | offset.y loop | 2.5s, `.repeatForever` |
| Loading text | `.transition(.opacity)` | 0.4s |
| Paywall | `.sheet` natif | 0.35s |
| Blur wall | blur 0→20 + lock fade | 0.5s |

### Haptics

| Événement | Type |
|-----------|------|
| Shutter | `UIImpactFeedbackGenerator(.medium)` |
| Score reveal final | `UINotificationFeedbackGenerator(.success)` |
| Loading step | `UIImpactFeedbackGenerator(.light)` |
| Tab switch | `UISelectionFeedbackGenerator()` |
| CTA paywall | `UIImpactFeedbackGenerator(.heavy)` |
| Share done | `UINotificationFeedbackGenerator(.success)` |

---

## 10. Notifications

| Notif | Timing | Texte |
|-------|--------|-------|
| Réengagement J+1 | +24h | "Votre {room_type} avait {score}/10. Rangez un peu et gagnez des points ! 🧹" |
| Réengagement J+7 | +7j sans scan | "Votre cuisine attend son score... 👀🏠" |
| Scans dispo | +24h après limit | "Vos 2 scans gratuits sont de retour ! 📸" |

Permission demandée après le 1er scan réussi. Jamais au lancement.

---

## 11. Design Tokens

### Couleurs (adaptatives, system colors)

```swift
extension Color {
    static let rsAccent = Color("AccentColor")     // #5E5CE6
    static let rsSuccess = Color.green              // system
    static let rsWarning = Color.orange             // system
    static let rsDanger = Color.red                 // system
    static let rsGlass = Color.white.opacity(0.7)   // Liquid Glass surface

    static func scoreColor(for score: Float) -> Color {
        switch score {
        case 0..<4:  return .rsDanger
        case 4..<6:  return .rsWarning
        case 6..<8:  return .rsSuccess
        default:     return .rsAccent
        }
    }
}
```

### Typo

- Score principal : `.system(size: 96, weight: .bold, design: .rounded)`
- Titres : `.title` (28pt semibold)
- Body : `.body` (16pt regular)
- Caption : `.caption` (13pt)
- Badge : `.system(size: 15, weight: .semibold, design: .rounded)`
- Dynamic Type supporté partout

### Spacing

- Padding standard : 16pt
- Grille history spacing : 12pt
- Corner radius cards : 16pt
- Corner radius hero photo : 24pt
- Corner radius CTA : 16pt
- Badge : `.capsule`

---

## 12. Infra & Coûts

| Service | 0-10K users | 10K-100K |
|---------|-------------|----------|
| Supabase | 0€ (free tier) | 25€/mois |
| OpenAI GPT-4.1 mini | ~100€/mois | ~1000€/mois |
| Apple Developer | 99€/an | 99€/an |
| Total | ~100-200€/mois | ~1000-1200€/mois |

Optimisations : 2 scans/jour free, JPEG compress, cache local, edge function rate limit.

---

## 13. Hors scope MVP

- ❌ iPad / macOS / visionOS
- ❌ AI Redesign ("montre ma pièce en Japandi")
- ❌ Shopping list / liens affiliés
- ❌ Color palette extraction
- ❌ Leaderboard global / Challenge a Friend
- ❌ Before/After comparator
- ❌ Widget iOS / App Clip
- ❌ Compte utilisateur (login/signup)
- ❌ Sync cross-device
- ❌ Android
- ❌ RevenueCat (StoreKit 2 natif suffit)
