# SPEC.md — RoastMyRoom MVP

> Spécification technique du MVP (v1.0).
> Source de vérité unique. Toute feature absente est hors scope.

---

## 1. Concept

**RoastMyRoom** — Photo d'une pièce → Score /10 par IA → Carte partageable → Boucle virale.

- **Promesse** : "Snap. Score. Share."
- **Target** : iOS 26+, iPhone uniquement (pas iPad)
- **Langues** : EN + FR + DE + ES

---

## 2. Architecture

MVVM strict. Injection via `AppFactory` (composition root, singleton).

```
RoastMyRoom/
  App/
    RoastMyRoomApp.swift            — @main, WindowGroup, lance RootView
    AppFactory.swift                — DI container singleton, crée services + VMs
    RootView.swift                  — Gère first launch (onboarding) → TabView

  Core/
    Models/
      RoomScan.swift                — @Model SwiftData : id, imageData, scores, style, tips, roast, date
      RoomStyle.swift               — Enum styles déco (Japandi, Scandinavian, Industrial, etc.)
      SubScores.swift               — Struct Codable : colorHarmony, proportions, lighting, cleanliness, personality (Float 0-10)
      Tip.swift                     — Struct Codable : text (String), estimatedImpact (Float)
      ScanResult.swift              — Struct Codable : réponse brute API → mapped vers RoomScan
      PersonalityAnalysis.swift     — Struct Codable : traits, celebrity_match, dating_line
      SubScoreComments.swift        — Struct Codable : 5 commentaires sarcastiques (1 par sous-score)
      MoodBoard.swift               — Struct Codable : color_palette (5 hex), suggestions (3 items)
      PointsPack.swift              — Struct Sendable : packs de points consommables
      AnalyticsEvent.swift          — Factory methods statiques pour événements tracking
      AuthSession.swift             — Struct Codable : accessToken, refreshToken, userId, expiresAt
    Services/
      ScoringService.swift          — Protocole + impl : envoie photo, reçoit ScanResult
      APIClient.swift               — URLSession minimal, POST base64 → Supabase Edge Function
      ImageProcessor.swift          — Compression JPEG, resize, validation (est-ce une pièce ?)
      ShareCardRenderer.swift       — UIGraphicsImageRenderer → UIImage carte partageable
      SubscriptionService.swift     — Protocole + impl StoreKit 2 : products, purchase, restore, status, points
      StorageService.swift          — SwiftData wrapper : save/fetch/delete RoomScan
      KeychainService.swift         — Security.framework : persistence anti-abus (points, scans, onboarding)
      AuthService.swift             — Sign in with Apple + Supabase Auth
      AnalyticsService.swift        — Firebase Analytics wrapper
    Extensions/
      Color+Theme.swift             — Couleurs sémantiques adaptatives + AI neon palette
      View+Extensions.swift         — Modifiers : .glassBackground, .neonGlow, .aiGlow, .shimmer
      Image+Compression.swift       — UIImage → JPEG compressé/resizé

  Features/
    Onboarding/
      OnboardingView.swift          — 3 slides PageTabView, demande permission caméra au CTA final
    ATT/
      ATTPrePromptView.swift        — Pré-prompt App Tracking Transparency
    Scan/
      Views/
        ScanView.swift              — Caméra plein écran, shutter, galerie, flash
        CameraPreview.swift         — UIViewRepresentable → AVCaptureVideoPreviewLayer
      ViewModels/
        ScanViewModel.swift         — Gère AVCaptureSession, capture, permissions
    Analysis/
      Views/
        AnalysisView.swift          — Loading animé : neon ring, step indicators, particules
      ViewModels/
        AnalysisViewModel.swift     — Orchestre ImageProcessor → ScoringService → nav résultat
    Result/
      Views/
        ResultView.swift            — Scroll vertical : hero photo, score, badge, roast, sous-scores, tips, personality, mood board
        ScoreCounterView.swift      — Compteur animé 0→score, glow neon, couleur dynamique
        RadarChartView.swift        — Shape pentagone 5 axes, trim animation
        StyleBadgeView.swift        — Capsule Liquid Glass : icône + nom style
        TipCardView.swift           — Card : icône + texte + "+X.X pts"
        RoastBannerView.swift       — Bandeau sarcastique, toujours visible (même free)
        PersonalityCardView.swift   — Traits capsules, celebrity match neon, dating line italic
        SubScoreDetailView.swift    — 5 rows : icône + score + commentaire sarcastique
        MoodBoardView.swift         — Palette 5 couleurs + 3 suggestions numérotées
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
        PaywallView.swift           — Sheet : fond photo blurée, tab points/abo, CTA
        PlanCardView.swift          — Card prix individuelle
        PointsPackCardView.swift    — Card pack de points
      ViewModels/
        PaywallViewModel.swift      — StoreKit 2 products, purchase, restore
  Resources/
    Assets.xcassets
    Localizable.xcstrings           — EN + FR + DE + ES
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
  ├─ First Launch → ATTPrePromptView → OnboardingView (3 slides) → ScanView
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
- Shutter : centre bas dans `tabViewBottomAccessory`, 32pt fill blanc, anneau 38pt stroke
- Galerie : bas gauche, PhotosPicker (SPM), 44pt
- Flash : haut droite, `bolt.fill` / `bolt.slash.fill`, 3 états (auto/on/off)
- Guide CTA (titre + sous-titre) : fade-in 0.3s delay 0.3s, fade-out après 4s
- Capture JPEG `.high` via `AVCapturePhotoOutput`
- Haptic `.medium` au shutter
- PHPickerViewController pour galerie (1 image, pas vidéo)
- Pas de permission caméra → message + "Ouvrir Réglages"

### S2 — Analyse (Loading)

- **Durée min 2.5s** (artificiel même si API plus rapide — suspense)
- Fond : photo capturée, blur progressif 0→20 + scale lente
- Neon ring central : AngularGradient AI palette, progress arc, percentage counter
- Particules bokeh flottantes (Canvas 30fps, palette neon)
- Step indicators : 4 icônes Liquid Glass connectées par des tracks avec glow gradient
- Textes rotatifs (0.8s) : label du step courant avec `.contentTransition(.numericText())`
- Haptics escalading : `.medium` → `.rigid` → `.heavy` à chaque transition step
- Completion : flash + haptic burst (`.success` + `.heavy`)

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
│  ┌─ Sub-Score Comments ───────┐ │  ← 5 rows : score + mini-roast sarcastique
│  └────────────────────────────┘ │
│  ┌─ Tip 1 ────────────────────┐ │  ← 1 visible free
│  │ 🪴 "Floor plant" +0.8      │ │
│  └────────────────────────────┘ │
│  ┌─ Tip 2 (blurred) ─────────┐ │  ← 2-3 blurés
│  └────────────────────────────┘ │
│  ── Personality ──────────────  │
│  ┌─ Traits capsules ─────────┐ │  ← 3 traits en capsules
│  │ Celebrity Match (neon glow)│ │  ← "Nick Miller — ce canapé..."
│  │ Dating Line (italic)       │ │  ← "Ton date penserait que..."
│  └────────────────────────────┘ │
│  ── Mood Board ───────────────  │
│  ┌─ Palette 5 couleurs ──────┐ │  ← 5 cercles hex + labels
│  │ 3 suggestions numérotées  │ │  ← Items concrets avec specs
│  └────────────────────────────┘ │
└─────────────────────────────────┘
Toolbar : [✕ Fermer] [↺ Scan Again] [↗ Share (.glassProminent)]
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
- Long press → context menu → delete + confirmation
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
- Score statique (pas d'animation infinie) + "Débloquez l'analyse complète"
- 4 bullets checkmark : scans illimités, sous-scores + radar, tips personnalisés, historique illimité
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

- **Personnalité** : "the most savage room critic on the internet"
- **Output** : JSON strict
- **Scoring rubric** : grille d'ancrage détaillée pour chaque sous-score (1-3 / 4-5 / 6-7 / 8-9 / 10). Utiliser toute l'échelle 0-10, ne pas compresser dans le 4-6.
- **Formule** : `overall_score = round((color_harmony + proportions + lighting + cleanliness + personality) / 5, 1)` — poids égaux
- **Roasts** : 10+ registres comiques (comparaisons, absurde, object callouts, fake POV, pop culture burns, backhanded compliments, dating roasts, internet slang, capitulation humor, existential humor). Ban list de mots recyclés ("fuir", "crier", "s'enfuir"). Doit référencer un élément visible.
- **Tips** : spécifiques à la photo, prioriser le sous-score le plus faible, max 15 mots, somme impacts ≤ 3.5
- **Styles** : 17 styles avec descriptions visuelles d'identification
- **Edge cases** : non-pièce → `room_type: "other"`, `overall_score: 0.0` ; photo sombre → tip dédié ; pièce stagée → roast adapté
- **Langue** : clés JSON en anglais, textes dans la langue demandée par le client

### Validations serveur (Edge Function)

La Edge Function applique des garde-fous après la réponse IA :

| Validation | Comportement |
|------------|-------------|
| Scores hors range | Clamp 0.0-10.0, arrondi 1 décimale |
| `overall_score` incohérent | Toujours recalculé depuis les sous-scores (le serveur ne fait pas confiance à l'IA) |
| Somme impacts tips > 3.5 | Impacts réduits proportionnellement |
| `personality` malformé | Supprimé silencieusement (traits ≠ 3, champs manquants) |
| `sub_score_comments` malformé | Supprimé silencieusement (5 clés string requises) |
| `mood_board` malformé | Supprimé silencieusement (5 hex valides + 3 suggestions requises) |

### Réponse type

```json
{
  "room_type": "bedroom",
  "overall_score": 5.7,
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
  "roast": "That one decorative pillow is doing community service for the whole couch.",
  "verdict": "Bof bof",
  "personality": {
    "traits": ["Chronic overthinker", "IKEA loyalist", "Hopeless romantic"],
    "celebrity_match": "Nick Miller — ce canapé a vécu des choses",
    "dating_line": "Ton date penserait que t'as un bon crédit immobilier."
  },
  "sub_score_comments": {
    "color_harmony": "Ces couleurs se battent en duel et personne gagne.",
    "proportions": "T'as mis les meubles au hasard ou c'était volontaire ?",
    "lighting": "L'éclairage dit 'salle d'attente chez le dentiste'.",
    "cleanliness": "Pas dégueulasse, mais ta mère serait pas fière.",
    "personality": "Y'a autant de personnalité qu'un hall d'aéroport."
  },
  "mood_board": {
    "color_palette": ["#E8D5B7", "#2C3E50", "#D4A574", "#8B9DC3", "#F5E6CC"],
    "suggestions": [
      "Un tapis berbère beige 160×230",
      "Remplacer l'ampoule par une 2700K",
      "Ajouter 2-3 coussins bleu marine"
    ]
  }
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
    var verdict: String             // 1-3 mots, réaction courte proportionnelle au score
    var createdAt: Date
    var isPremiumResult: Bool
    var personalityData: Data?       // PersonalityAnalysis encodé JSON (optionnel)
    var subScoreCommentsData: Data?  // SubScoreComments encodé JSON (optionnel)
    var moodBoardData: Data?         // MoodBoard encodé JSON (optionnel)
}
```

### Supabase (remote)

- **Auth** : Sign in with Apple (optionnel) via Supabase Auth. Permet sync cross-device des points.
- **Edge Function** : `POST /score` — proxy vers OpenAI GPT-4.1 mini, rate limit par device ID
- **Storage** : Non utilisé MVP (photos locales uniquement)
- **PostgreSQL** : Table `scan_events(device_id, room_type, score, created_at)` pour analytics. Table `user_points` pour sync. Pas de PII.

### Keychain (persistence anti-abus)

Les données sensibles sont en Keychain (survivent à une désinstallation) :

| Clé | Type | Usage |
|-----|------|-------|
| `pointsBalance` | Int | Solde de points consommables |
| `pointsBalanceInitialized` | Bool | 2 pts offerts au 1er lancement |
| `dailyScanCount` | Int | Scans du jour |
| `lastScanDate` | Date | Reset quotidien |
| `hasSeenOnboarding` | Bool | Onboarding vu (miroir AppStorage pour SwiftUI) |
| `auth_access_token` | String | Token Supabase (si connecté) |
| `auth_refresh_token` | String | Refresh token (si connecté) |
| `auth_user_id` | String | User ID (si connecté) |

### AppStorage

| Clé | Type | Usage |
|-----|------|-------|
| `hasSeenOnboarding` | Bool | Miroir Keychain pour SwiftUI |
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
| Commentaires par sous-score | Blurés | ✅ |
| Tips | 1 visible | 3 personnalisés |
| Personality (traits, celebrity, dating) | Blurée | ✅ |
| Mood Board (palette + suggestions) | Bluré | ✅ |
| Historique | 3 derniers | Illimité |
| Share card | Avec watermark | Sans watermark + celebrity match |

### Système de Points (Consumable)

Points = monnaie consommable pour débloquer des fonctions sans abonnement.

**Attribution initiale** : 4 points offerts à la première ouverture de l'app.

**Utilisation** :
- **1 point = 1 scan supplémentaire** au-delà du quota gratuit (2/jour). Priorité : premium → free daily → points.
- **1 point = 1 déblocage du contenu complet** d'un scan existant (sous-scores, radar, 3 tips). Persiste via `isPremiumResult = true` sur `RoomScan` (SwiftData).

**Packs disponibles** (Consumable, App Store Connect) :

| Pack | Product ID | Prix | Points | Badge |
|------|-----------|------|--------|-------|
| Small | `roomscore.points.10` | 0.99€ | 10 | — |
| Medium | `roomscore.points.35` | 2.99€ | 35 | — |
| Large | `roomscore.points.75` | 4.99€ | 75 | Best Value |
| XL | `roomscore.points.200` | 9.99€ | 200 | — |

**Persistence** : Keychain (`pointsBalance`), survit à la désinstallation. Les consumables ne sont pas restaurables (mentionné en fine print paywall).

**Paywall redesigné** :
- Tab picker : "Acheter des points" (défaut) | "Passer illimité" (abonnements)
- Tab points : solde actuel + grille 2×2 de packs
- Tab abonnements : 3 plans existants (inchangé)
- CTA dynamique selon le tab sélectionné

**Confirmation de dépense** :
- Toute dépense de point déclenche une alerte de confirmation : titre "Utiliser 1 point ?", message contextuel avec le solde restant, boutons "Utiliser" / "Annuler".
- S'applique au scan (ScanView), au déblocage (ResultView) et au déblocage depuis l'historique (HistoryView).

**Déblocage dans ResultView** :
- Bouton principal : ouvre paywall (abonnement)
- Bouton secondaire : "Débloquer (1 pt)" si points dispo → alerte confirmation → `unlockWithPoint()`, sinon ouvre paywall tab points

**Déblocage dans HistoryView** :
- Tap sur un scan verrouillé (position ≥ 3, non premium, `isPremiumResult == false`) :
  - Si `hasPoints` → alerte confirmation → `deductPoint()` + `scan.isPremiumResult = true` (SwiftData persiste). La carte est ensuite déverrouillée définitivement (survit aux relances).
  - Si pas de points → ouvre paywall
- Le verrou dans la grille tient compte de `isPremiumResult` : un scan débloqué par point reste accessible même après relance de l'app.

**Animation status bar (ScanView)** :
- Points en hausse (`new > old`) : scale up + flash doré (existant)
- Points en baisse (`new < old`) : shake horizontal + flash orange

**Achat depuis Profile** :
- Section "Points" avec solde actuel + bouton "Acheter des points" → paywall tab points

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
| Branding | "RoastMyRoom" + lien app |
| Watermark free | Branding semi-transparent centre |

Génération via `UIGraphicsImageRenderer`. Pas de SwiftUI snapshot (inconsistant cross-device).

Partage : `UIActivityViewController` — image + texte de partage dynamique

---

## 9. Animations & Haptics

### Animations

| Moment | Type | Durée |
|--------|------|-------|
| Score reveal | Spring counter 0→N | 1.2s, `.easeOut` |
| Radar chart | trim 0→1 | 0.8s, `.easeOut` |
| Badge style | scale 0.5→1 + fade | 0.3s, `.spring` |
| Analysis ring | progress arc spring | 0.6-0.8s par step |
| Analysis steps | spring step indicators + connectors | 0.6s, `.spring(bounce: 0.15)` |
| Analysis percent | `.contentTransition(.numericText())` | 0.6s, `.spring` |
| Analysis bg | blur 0→20 + scale 1→1.08 | 4s, one-shot |
| Paywall | `.sheet` natif | 0.35s |
| Completion flash | white flash + scale pop | 0.4s one-shot |

**Règle perf** : Zéro `.repeatForever` dans les vues principales (ResultView, AnalysisView). Particules Canvas à 30fps max.

### Haptics

| Événement | Type |
|-----------|------|
| Shutter | `UIImpactFeedbackGenerator(.medium)` |
| Score reveal final | `UINotificationFeedbackGenerator(.success)` |
| Loading step 1 | `UIImpactFeedbackGenerator(.medium)` |
| Loading step 2 | `UIImpactFeedbackGenerator(.rigid)` |
| Loading step 3 | `UIImpactFeedbackGenerator(.heavy)` |
| Completion burst | `.success` + `.heavy` |
| Tab switch | `UISelectionFeedbackGenerator()` |
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
    // Semantic
    static let rsAccent = Color("AccentColor")     // #5E5CE6
    static let rsSuccess = Color.green              // system
    static let rsWarning = Color.orange             // system
    static let rsDanger = Color.red                 // system

    // AI Neon Palette (analyse, score glow, step indicators)
    static let aiPurple    = Color(red: 0.737, green: 0.510, blue: 0.953) // #BC82F3
    static let aiPink      = Color(red: 0.961, green: 0.725, blue: 0.918) // #F5B9EA
    static let aiLightBlue = Color(red: 0.553, green: 0.624, blue: 1.0)   // #8D9FFF
    static let aiCoral     = Color(red: 1.0, green: 0.404, blue: 0.471)   // #FF6778

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
| Firebase Analytics | 0€ (free tier) | 0€ (free tier) |
| Apple Developer | 99€/an | 99€/an |
| Total | ~100-200€/mois | ~1000-1200€/mois |

Optimisations : 2 scans/jour free, JPEG compress, cache local, edge function rate limit.

---

## 13. Hors scope MVP

- ❌ iPad / macOS / visionOS
- ❌ AI Redesign ("montre ma pièce en Japandi")
- ❌ Shopping list / liens affiliés
- ~~❌ Color palette extraction~~ → Implémenté via Mood Board IA
- ❌ Leaderboard global / Challenge a Friend
- ❌ Before/After comparator
- ❌ Widget iOS / App Clip
- ~~❌ Compte utilisateur~~ → Implémenté via Sign in with Apple + Supabase Auth
- ~~❌ Sync cross-device~~ → Implémenté via points sync (max merge strategy)
- ❌ Android
- ❌ RevenueCat (StoreKit 2 natif suffit)
