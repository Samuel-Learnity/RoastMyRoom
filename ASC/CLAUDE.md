# CLAUDE.md — ASC (App Store Connect metadata)

> Sous-projet `RoastMyRoom/ASC/` : métadonnées et screenshots App Store Connect, générés et uploadés via fastlane (config dans `../fastlane/`).

## WHY (sous-projet)

Ce dossier centralise les métadonnées localisées et les screenshots de RoastMyRoom. Fastlane lit ces fichiers et les pousse sur ASC via l'API Spaceship (pas `deliver` — voir le workaround critique dans le CLAUDE.md racine).

Distinct du projet Swift pour que les changements de copy ou de screenshots ne polluent pas le diff Xcode.

## WHAT (sous-projet)

- `metadata/<locale>/` : copy localisée (description, keywords, subtitle, etc.) pour EN, FR, DE, ES
- `metadata/review_information/` : infos de review Apple (compte de test, notes)
- `screenshots/` : captures source brutes (raw, par device)
- `output/<locale>/` : screenshots finaux localisés générés par `generate_screenshots.py` — **source des uploads ASC**
- `generate_screenshots.py` : script Python qui produit `output/` à partir de `screenshots/`
- `app_info.md` : référence humaine des champs ASC (titre, sous-titre, catégorie)
- `review_notes.txt` : notes pour le reviewer Apple (lu par fastlane `:release`)
- `guide_fastlane_claude_code.html` : guide d'utilisation interne

> `../fastlane/Fastfile` et `../fastlane/Appfile` sont dans le dossier `fastlane/` à la racine — pas ici.

## RÈGLES NON-NÉGOCIABLES (sous-projet)

1. **Jamais** modifier `metadata/<locale>/<champ>.txt` dans une seule locale sans répercuter dans les 3 autres (EN/FR/DE/ES) — incohérence = rejet ASC
2. **Toujours** versionner les screenshots source dans `screenshots/`, pas dans `output/`
3. **Toujours** régénérer `output/` via `fastlane generate_screenshots` après modification des sources — ne pas éditer `output/` à la main
4. **`output/` n'est pas gitignorée** — committer les screenshots finaux fait partie du workflow (fichiers localisés attendus)

## Commandes fastlane courantes

Toujours lancer depuis la racine `RoastMyRoom/` avec le PATH Ruby homebrew :

```bash
export PATH="/opt/homebrew/opt/ruby/bin:/opt/homebrew/lib/ruby/gems/4.0.0/bin:$PATH"

bundle exec fastlane generate_screenshots  # Génère output/ depuis screenshots/ via Python
bundle exec fastlane metadata              # Upload métadonnées localisées vers ASC
bundle exec fastlane screenshots           # Upload output/ vers ASC
bundle exec fastlane upload_store_assets   # metadata + screenshots (sans build)
bundle exec fastlane archive_upload        # Archive Release + upload ASC
bundle exec fastlane release               # Tout : build + metadata + screenshots + soumission
bundle exec fastlane bump                  # Incrémente le build number
bundle exec fastlane testflight_upload     # Build + upload TestFlight
```

## Gotchas

- **Métadonnées dérivées** : ASC côté Apple peut dériver si on y édite directement sans mettre à jour `metadata/`. Toujours traiter ce dossier comme source de vérité.
- **Screenshots résolution** : Apple change parfois les dimensions exigées. Vérifier dans `generate_screenshots.py` les profils à jour.
- **Privacy declarations** : champ `App Privacy` dans ASC ≠ `Privacy Manifest` dans le bundle Swift. Les deux doivent être cohérents.
- **`whats_new`** : non uploadable pour v1.0 (première version sur l'App Store).
