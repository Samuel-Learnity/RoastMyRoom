# CLAUDE.md — Instructions pour le développement assisté par IA

> Ce fichier configure le comportement de Claude Code pour ce projet.
> Toujours lire SPEC.md pour les détails fonctionnels.

---

## Build

- **Scheme** : "RoastMyRoom"
- **Simulateur par défaut** : iPhone 16 (iOS 26)
- Toujours utiliser `--quiet` avec xcodebuild
- Utiliser les outils MCP xcode-tools plutôt que xcodebuild brut

### Commandes MCP préférées

- Build : `mcp__xcode-tools__BuildProject`
- Tests : `mcp__xcode-tools__RunAllTests` / `mcp__xcode-tools__RunSomeTests`
- Preview : `mcp__xcode-tools__RenderPreview`
- Diagnostics rapides : `mcp__xcode-tools__XcodeRefreshCodeIssuesInFile`
- Issues : `mcp__xcode-tools__XcodeListNavigatorIssues`

---

## Projet

**RoastMyRoom** — App iOS (Swift, SwiftUI) de notation de pièces par IA.
Photo → Score /10 → Carte partageable → Boucle virale.

- **Target** : iOS 26+, iPhone uniquement
- **Xcode** : 26+
- **Swift** : 6.1, concurrency stricte activée
- **Architecture** : MVVM strict
- **Persistence** : SwiftData
- **IAP** : StoreKit 2 natif
- **Backend** : Supabase Edge Functions (Deno/TypeScript)
- **Packages** : Zéro dépendance externe (zéro SPM package MVP)

---

## Architecture

MVVM avec injection via `AppFactory` (singleton, composition root).

```
RoomScore/
  App/
    RoomScoreApp.swift              — @main, WindowGroup, lance RootView
    AppFactory.swift                — DI container singleton, crée services + VMs
    RootView.swift                  — First launch → Onboarding, sinon TabView

  Core/
    Models/
      RoomScan.swift                — @Model SwiftData : scores, style, tips, roast
      RoomStyle.swift               — Enum styles déco
      SubScores.swift               — Struct Codable : 5 floats
      Tip.swift                     — Struct Codable : text + impact
      ScanResult.swift              — Struct Codable : réponse brute API
    Services/
      ScoringService.swift          — Envoie photo, reçoit ScanResult
      APIClient.swift               — URLSession POST base64 → Edge Function
      ImageProcessor.swift          — Compress JPEG, resize, validation
      ShareCardRenderer.swift       — UIGraphicsImageRenderer → UIImage
      SubscriptionService.swift     — StoreKit 2 wrapper
      StorageService.swift          — SwiftData CRUD
    Extensions/
      Color+Theme.swift             — Couleurs sémantiques (adaptive)
      View+Extensions.swift         — .glassBackground, .scoreColor, .shimmer
      Image+Compression.swift       — UIImage resize + compress

  Features/
    Onboarding/Views|ViewModels
    Scan/Views|ViewModels|Services/CameraService.swift
    Analysis/Views|ViewModels
    Result/Views|ViewModels
    History/Views|ViewModels
    Profile/Views|ViewModels
    Paywall/Views|ViewModels

  Resources/
    Assets.xcassets
    Localizable.xcstrings           — EN + FR + DE + ES
```

---

## Pipeline principal

```
Geste (Shutter tap / Gallery pick)
  → ScanViewModel.capturePhoto()
    → UIImage capturée
      → Navigation push → AnalysisView
        → ImageProcessor.prepare(image:)
            → Resize 1024×768 max, JPEG 0.8, validation
        → APIClient.post("/score", base64)
            → Supabase Edge Function (Deno)
              → OpenAI GPT-4o Vision
              → JSON structuré
            → ScanResult (Codable)
        → StorageService.save(RoomScan)
        → Navigation replace → ResultView
          → Score animation (spring 1.2s)
          → Radar chart (trim 0.8s)
          → Share → UIActivityViewController
```

---

## Flux de données

```
View (SwiftUI, déclarative)
  ↕ @StateObject / @ObservedObject
ViewModel (@MainActor, ObservableObject, @Published)
  → Service (protocole, injecté via init)
    → API / SwiftData / StoreKit / AVFoundation
```

- **Views** : Déclaratives, zéro logique métier. Lisent `@Published`.
- **ViewModels** : `@MainActor final class`, `ObservableObject`. Appellent services.
- **Services** : Protocoles + implémentations concrètes. Injectés par `AppFactory`.
- **Models** : `Codable` structs transport. `@Model` SwiftData persistance.

---

## Code Style

### Swift

- **Naming** : PascalCase types, camelCase propriétés/méthodes
- **State** : `@State private var` pour SwiftUI, `let` pour constantes
- **Accès** : `private` par défaut. `internal` si partagé. Jamais `open`.
- **Optionals** : `guard let` early return. Jamais de `!` (sauf `fatalError` debug)
- **Formatting** : 4 espaces. Pas de trailing whitespace.
- **Imports** : Triés alpha. Un par ligne. Pas d'inutile.
- **Types** : Typage fort. Pas de `Any`. Pas de `as!`.
- **Strings** : **JAMAIS de texte brut dans le code**. Tout texte visible par l'utilisateur doit passer par `String(localized:)` avec une clé dans `Localizable.xcstrings`. Chaque nouvelle clé doit être traduite dans les 4 langues : EN, FR, DE, ES.
- **Commentaires** : `///` doc publique, `//` inline. Pas d'évidence.
- **Async** : `async/await` uniquement. Pas de Combine. Pas de callbacks.

### SwiftUI

- **body** < 30 lignes. Extraire sous-vues sinon.
- **Previews** : `#Preview` pour chaque View avec données mock
- **Modifiers** : layout → style → effets → animation → accessibilité
- **Couleurs** : `Color+Theme.swift` uniquement. Jamais de hex hardcodé.
- **Navigation** : `NavigationStack` (pas NavigationView)
- **Sheets** : `.sheet(item:)` quand on passe des données
- **Listes** : `LazyVStack`/`LazyVGrid` pour contenu, `List` pour Settings
- **ScrollView** : Toujours masquer les indicateurs de scroll (`ScrollView(showsIndicators: false)` ou `.scrollIndicators(.hidden)`)
- **Toolbar** : Les boutons dans `.toolbar {}` ont automatiquement un background Liquid Glass. Ne jamais ajouter `.buttonStyle(.glass)` ni de background custom. Utiliser `.buttonStyle(.glassProminent)` uniquement pour les actions principales (ex: Partager).

### Concurrency

- `@MainActor` sur tous les ViewModels
- `.task {}` modifier pour lancer async depuis les Views
- Services → `async throws`, VM catch → `@Published var error: String?`
- Pas de `DispatchQueue` sauf interop UIKit inévitable

---

## Patterns

```swift
// ✅ Service — Protocole + impl
protocol ScoringServiceProtocol {
    func scoreRoom(image: UIImage) async throws -> ScanResult
}

final class ScoringService: ScoringServiceProtocol {
    private let apiClient: APIClientProtocol
    private let imageProcessor: ImageProcessorProtocol

    init(apiClient: APIClientProtocol, imageProcessor: ImageProcessorProtocol) {
        self.apiClient = apiClient
        self.imageProcessor = imageProcessor
    }

    func scoreRoom(image: UIImage) async throws -> ScanResult {
        let compressed = try imageProcessor.prepare(image)
        let data = try await apiClient.post("/score", body: compressed)
        return try JSONDecoder().decode(ScanResult.self, from: data)
    }
}

// ✅ ViewModel — @MainActor, ObservableObject
@MainActor
final class AnalysisViewModel: ObservableObject {
    enum State: Equatable {
        case idle, analyzing, success(RoomScan), error(String)
    }

    @Published private(set) var state: State = .idle
    private let scoringService: ScoringServiceProtocol
    private let storageService: StorageServiceProtocol

    init(scoringService: ScoringServiceProtocol, storageService: StorageServiceProtocol) {
        self.scoringService = scoringService
        self.storageService = storageService
    }

    func analyze(image: UIImage) async {
        state = .analyzing
        do {
            let result = try await scoringService.scoreRoom(image: image)
            let scan = RoomScan(from: result, imageData: image.jpegData(compressionQuality: 0.8)!)
            try storageService.save(scan)
            state = .success(scan)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}

// ✅ View — Déclarative, sous-vues extraites
struct ResultView: View {
    @ObservedObject var viewModel: ResultViewModel

    var body: some View {
        ScrollView {
            heroSection
            scoreSection
            styleBadge
            roastBanner
            subScoresSection
            tipsSection
        }
        .safeAreaInset(edge: .bottom) { actionBar }
    }

    private var heroSection: some View { ... }
    private var scoreSection: some View { ... }
}

// ✅ Mock pour tests
final class MockScoringService: ScoringServiceProtocol {
    var mockResult: ScanResult = .mock

    func scoreRoom(image: UIImage) async throws -> ScanResult {
        mockResult
    }
}

// ✅ ViewState enum réutilisable
enum ViewState<T: Equatable>: Equatable {
    case idle, loading, success(T), error(String)
}
```

### Anti-patterns

```swift
// ❌ Force unwrap
let image = UIImage(named: "photo")!

// ❌ Logique métier dans la View
Button("Score") { let data = try await URLSession.shared.data(from: url) }

// ❌ Combine
var cancellables = Set<AnyCancellable>()

// ❌ Singleton service
static let shared = APIClient()  // Injecter via init

// ❌ @EnvironmentObject pour les VMs
// Utiliser @StateObject + injection explicite

// ❌ NavigationView
NavigationView { }  // NavigationStack

// ❌ Couleur hardcodée
.foregroundColor(Color(hex: "#5E5CE6"))  // Color.rsAccent

// ❌ String non localisée
Text("Score")  // Text(String(localized: "score_label"))
```

---

## Tests

### Framework : Swift Testing (`import Testing`)

```swift
import Testing
@testable import RoomScore

@Test func scoringServiceDecodesValidJSON() async throws {
    let service = ScoringService(apiClient: MockAPIClient(responseFixture: "valid_score"))
    let result = try await service.scoreRoom(image: UIImage())
    #expect(result.overallScore >= 0 && result.overallScore <= 10)
    #expect(result.tips.count == 3)
}

@Test func imageProcessorRejectsSelfie() async throws {
    let processor = ImageProcessor()
    #expect(throws: ImageProcessorError.notARoom) {
        try processor.prepare(selfieImage)
    }
}
```

### Quoi tester

| Couche | Quoi | Mock |
|--------|------|------|
| Services | `ScoringService` : parsing JSON, erreurs | MockAPIClient |
| Services | `ImageProcessor` : compression, validation | Images fixtures |
| Services | `SubscriptionService` : logique premium/free | StoreKit Config File |
| ViewModels | `AnalysisViewModel` : flow analyze | MockScoringService |
| ViewModels | `HistoryViewModel` : fetch, delete, limite | MockStorageService |
| Models | `RoomScan`, `SubScores` : Codable, calculs | JSON fixtures |

### Pas tester (MVP)

- Views SwiftUI (Previews = test visuel)
- AVFoundation (device)
- StoreKit transactions réelles
- API OpenAI

---

## Règles

### Interdictions

- Ne **JAMAIS** supprimer DerivedData sans permission
- Ne **JAMAIS** modifier le `.pbxproj` manuellement
- Toujours **builder + tester avant de rendre la main**
- Utiliser les **conventions Apple** pour le nommage

### Développement

1. **SPEC.md est la source de vérité** — pas dans la spec = pas construit
2. **Simplicity First** — code le plus simple qui marche. Pas de sur-ingénierie
3. **Root Cause** — cause racine, pas de fix temporaire
4. **Minimal Impact** — toucher uniquement ce qui est nécessaire
5. **Vérifier avant de valider** — build, test, preuve que ça marche
6. **Plan mode** pour toute tâche non triviale (3+ fichiers ou décision archi)

### Workflow

```
1. Lire la section SPEC.md correspondante
2. Identifier fichiers à créer/modifier
3. Proposer plan (si non trivial)
4. Implémenter bottom-up : Model → Service → ViewModel → View
5. Tests (Service + ViewModel)
6. #Preview
7. Build sans warning + tests passent
```

### Checklist

- [ ] Compile sans warning
- [ ] Tests passent
- [ ] Previews fonctionnelles
- [ ] Strings localisées
- [ ] Couleurs via Color+Theme
- [ ] ViewModels `@MainActor`
- [ ] Services injectés (pas de singleton sauf AppFactory)
- [ ] Accessibilité basique (labels, Dynamic Type)

---

## Ordre d'implémentation

```
Phase 1 — Fondations
  1. Setup Xcode, structure dossiers, AppFactory
  2. Core/Models (RoomScan, SubScores, Tip, RoomStyle, ScanResult)
  3. Core/Extensions (Color+Theme, View+Extensions, Image+Compression)
  4. Scan — CameraService + ScanView + ScanViewModel
  5. RootView + TabView 3 onglets
  6. Onboarding — OnboardingView (3 slides, AppStorage)

Phase 2 — IA & Résultat
  7. APIClient + ImageProcessor
  8. ScoringService (appel API, parsing JSON)
  9. Supabase Edge Function /score
  10. AnalysisView + AnalysisViewModel (loading animé)
  11. ResultView complet (score, badge, roast, sous-scores, tips)
  12. Animations (score counter, radar chart)
  13. ShareCardRenderer + UIActivityViewController

Phase 3 — Monétisation & Persistence
  14. StorageService (SwiftData)
  15. HistoryView + HistoryViewModel
  16. SubscriptionService (StoreKit 2)
  17. PaywallView + PaywallViewModel
  18. Intégration paywall dans ResultView (blur, triggers)
  19. ProfileView + stats + settings

Phase 4 — Polish
  20. Haptics
  21. Notifications (permission + scheduled)
  22. Localisation FR + EN
  23. Tests unitaires
  24. QA + App Store prep
```

---

## Git

### Branches

```
main              — Production
develop           — Intégration
feature/scan      — Feature
fix/camera-crash  — Bug fix
```

### Commits

```
feat(scan): add camera preview with AVFoundation
feat(result): implement score animation with spring
fix(paywall): fix sheet dismiss not updating state
refactor(services): extract image compression to ImageProcessor
test(scoring): add JSON parsing tests
```

Types : `feat`, `fix`, `refactor`, `test`, `chore`, `docs`
