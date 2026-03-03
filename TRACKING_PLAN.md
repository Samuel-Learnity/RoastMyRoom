# Tracking Plan — RoastMyRoom

> Source de vérité pour tous les événements analytics Firebase.
> Convention : `snake_case` pour les noms d'événements et paramètres.

---

## Onboarding

| Événement | Paramètres | Description |
|-----------|-----------|-------------|
| `onboarding_completed` | — | L'utilisateur a terminé l'onboarding |
| `camera_permission_result` | `granted: Bool` | Résultat de la demande de permission caméra |

---

## Scan

| Événement | Paramètres | Description |
|-----------|-----------|-------------|
| `scan_photo_captured` | `source: String` ("camera" \| "gallery") | Photo prise ou sélectionnée |
| `scan_flash_changed` | `mode: String` ("auto" \| "on" \| "off") | Flash changé |
| `scan_lens_switched` | `lens: String` ("0.5x" \| "1x" \| "2x") | Objectif changé |
| `scan_limit_reached` | `remaining_points: Int` | L'utilisateur atteint sa limite gratuite |
| `scan_limit_paywall_shown` | — | La paywall scan limit s'affiche |

---

## Analysis

| Événement | Paramètres | Description |
|-----------|-----------|-------------|
| `analysis_started` | — | Analyse lancée |
| `analysis_success` | `score: Double`, `style: String`, `duration_ms: Int` | Analyse terminée avec succès |
| `analysis_error` | `error: String` | Analyse échouée |

---

## Result

| Événement | Paramètres | Description |
|-----------|-----------|-------------|
| `result_view_opened` | `score: Double`, `style: String`, `is_premium: Bool` | Écran résultat affiché |
| `result_share_clicked` | `score: Double` | Bouton partage cliqué |
| `result_share_completed` | `score: Double` | Partage effectué (sheet fermée après action) |
| `result_unlock_clicked` | `score: Double` | Bouton débloquer cliqué (points) |
| `result_unlock_success` | `score: Double`, `points_remaining: Int` | Déblocage réussi |

---

## Paywall

| Événement | Paramètres | Description |
|-----------|-----------|-------------|
| `paywall_opened` | `source: String` ("scan_limit" \| "result_unlock" \| "profile" \| "history") | Paywall affichée |
| `paywall_tab_switched` | `tab: String` ("points" \| "subscription") | Onglet changé |
| `paywall_cta_clicked` | `tab: String`, `product_id: String` | Bouton CTA cliqué |
| `paywall_closed` | `tab: String` | Paywall fermée sans achat |
| `paywall_restore_clicked` | — | Bouton restaurer cliqué |

---

## Purchase

| Événement | Paramètres | Description |
|-----------|-----------|-------------|
| `purchase_started` | `product_id: String`, `product_type: String` ("subscription" \| "points") | Achat lancé |
| `purchase_success` | `product_id: String`, `product_type: String`, `price: String` | Achat réussi |
| `purchase_error` | `product_id: String`, `error: String` | Erreur d'achat |
| `purchase_cancelled` | `product_id: String` | Achat annulé par l'utilisateur |
| `purchase_restored` | — | Achats restaurés |

---

## Points

| Événement | Paramètres | Description |
|-----------|-----------|-------------|
| `points_unlock_used` | `points_remaining: Int`, `score: Double` | Point utilisé pour débloquer un résultat |

---

## History

| Événement | Paramètres | Description |
|-----------|-----------|-------------|
| `history_card_tapped` | `score: Double`, `style: String` | Carte historique tapée |
| `history_delete_confirmed` | `score: Double` | Scan supprimé |

---

## Profile

| Événement | Paramètres | Description |
|-----------|-----------|-------------|
| `profile_upgrade_clicked` | — | Bouton upgrade cliqué |
| `profile_share_app_clicked` | — | Bouton partager l'app cliqué |

---

## Auth

| Événement | Paramètres | Description |
|-----------|-----------|-------------|
| `auth_sign_in_started` | — | L'utilisateur lance Sign in with Apple |
| `auth_sign_in_success` | — | Connexion réussie |
| `auth_sign_in_error` | `error: String` | Erreur lors de la connexion |
| `auth_sign_out` | — | L'utilisateur se déconnecte |
| `auth_prompt_shown` | `source: String` ("post_purchase") | Prompt de connexion affiché |
| `auth_prompt_dismissed` | — | Prompt de connexion ignoré |

---

## Points Sync

| Événement | Paramètres | Description |
|-----------|-----------|-------------|
| `points_sync_started` | — | Sync des points lancée |
| `points_sync_success` | `local_balance: Int`, `remote_balance: Int`, `merged_balance: Int` | Sync réussie |
| `points_sync_conflict` | `local_balance: Int`, `remote_balance: Int` | Conflit local/remote détecté |

---

## ATT (App Tracking Transparency)

| Événement | Paramètres | Description |
|-----------|-----------|-------------|
| `att_pre_prompt_shown` | — | Écran pré-prompt ATT affiché |
| `att_pre_prompt_continue` | — | L'utilisateur clique "Continuer" (avant dialogue système) |
| `att_permission_result` | `status: String` ("authorized" \| "denied" \| "restricted" \| "not_determined") | Résultat final ATT (après dialogue ou skip) |

---

## Navigation

| Événement | Paramètres | Description |
|-----------|-----------|-------------|
| `tab_switched` | `tab: String` ("scan" \| "history" \| "profile") | Onglet changé |
| `screen_view` | `screen_name: String` | Vue affichée (auto-tracked via `.onAppear`) |

---

## User Properties

| Propriété | Type | Description |
|-----------|------|-------------|
| `is_premium` | `String` ("true" \| "false") | Abonnement actif |
| `points_balance` | `String` | Solde de points actuel |
| `total_scans` | `String` | Nombre total de scans |
| `att_status` | `String` ("authorized" \| "denied" \| "restricted" \| "not_determined") | Statut ATT de l'utilisateur |
