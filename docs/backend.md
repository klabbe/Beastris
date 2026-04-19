# Backend — Firebase Auth & Global Topplista

BeastBlocks använder **Firebase** för autentisering och global topplista. Ingen egen server behövs — Google sköter all infrastruktur.

## Arkitektur

```
Flutter-appen
  ├── firebase_auth      →  Firebase Authentication (e-post/lösenord)
  └── cloud_firestore    →  Firestore-databas
        ├── leaderboard/ →  Globala resultat (öppen läsning/skrivning)
        └── users/{uid}  →  Användarprofiler (ägaren skriver, alla läser)
```

## Firebase-projekt

- **Projekt-ID**: `beastris-game-90b1b`
- **Region**: `europe-west1`
- **Konsol**: https://console.firebase.google.com/project/beastris-game-90b1b

## Datamodell

### `leaderboard` — ett dokument per inlämnat resultat

```
leaderboard/<auto-id>
  name:      "DragonSlayer"          ← alias (från profilen)
  score:     1172
  lines:     14
  level:     2
  date:      "2026-04-09T21:00:00Z"  ← ISO 8601
  timestamp: 1744232400000           ← ms sedan epoch (för filtrering)
  uid:       "abc123..."             ← Firebase Auth UID
  country:   "SE"                    ← ISO 3166-1 alpha-2
```

**Deduplicering**: Leaderboarden visar max ett resultat per spelare (bästa poängen). Poster utan uid (anonyma) visas alltid.

### `users/{uid}` — användarprofil

```
users/<uid>
  uid:     "abc123..."
  alias:   "DragonSlayer"   ← visas på leaderboarden, måste vara unikt
  name:    "Klas Flodqvist" ← ej offentligt
  country: "SE"
```

## Autentisering

Inloggning är **frivillig**. Utan konto kan man spela och se topplistan, men inte skicka in resultat.

### Flöde

1. Spelaren registrerar konto med e-post, lösenord och unik alias
2. `AuthService.register()` kontrollerar aliasens unikhet mot `users`-collectionen innan kontot skapas
3. Vid game over:
   - **Inloggad**: Resultatet skickas automatiskt om det slår topp-10 denna vecka eller personligt bästa
   - **Ej inloggad**: Spelaren erbjuds att logga in; väljer man nej sparas resultatet bara lokalt

### `lib/services/auth_service.dart`

| Metod | Beskrivning |
|-------|-------------|
| `register(email, password, profile)` | Skapar konto, kontrollerar alias-unikhet, sparar profil |
| `signIn(email, password)` | Loggar in och hämtar profil |
| `signOut()` | Loggar ut |
| `sendPasswordReset(email)` | Skickar återställningsmail |
| `updateProfile(profile)` | Uppdaterar alias/namn/land, kontrollerar unikhet |

## Leaderboard-logik

### `lib/services/leaderboard_service.dart`

| Metod | Beskrivning |
|-------|-------------|
| `submitScore(result, alias, uid:, country:)` | Skriver ett dokument i `leaderboard` |
| `fetchAllTimeData({uid})` | Returnerar topp 10 (deduplicerat) + användarens rank |
| `fetchWeeklyData({uid})` | Samma men filtrerar de senaste 7 dagarna |
| `fetchUserBestScoreThisWeek(uid)` | Används för att avgöra om auto-submit ska ske |

### Auto-submit-logik (vid game over)

```dart
// Skicka in om:
//   (a) poängen slår nuvarande topp-10 denna vecka, ELLER
//   (b) det är ett nytt personligt bästa denna vecka
final isTopTen = _topWeekly.length < 10 || result.score > _topWeekly.last.score;
final isPersonalBest = prevBest == null || result.score > prevBest;
if (isTopTen || isPersonalBest) submitScore(...);
```

### Två flikar på topplistan

- **All Time** — bästa poängen någonsin, deduplicerat per uid
- **This Week** — senaste 7 dagarna, deduplicerat per uid
- Inloggad spelares post markeras i guld med "(you)"
- Om spelaren är utanför topp 10 visas deras rank nedanför en avdelare

## Modeller

### `lib/models/user_profile.dart`
Fält: `uid`, `alias`, `name`, `country`. Metoder: `toMap()`, `fromMap()`, `copyWith()`.

### `lib/models/countries.dart`
Lista med 70+ länder (`kCountries`) plus `countryCodeToFlag(code)` som konverterar ISO-kod till flagg-emoji via Unicode Regional Indicator-tecken.

## Säkerhetsregler (`firestore.rules`)

```
leaderboard/{doc}
  allow read:  if true;   // Alla kan se topplistan
  allow write: if true;   // Skrivning kräver inloggning i applogiken

users/{userId}
  allow read:  if true;   // Alias-unikhetskontroll kräver läsning
  allow write: if request.auth.uid == userId;  // Bara ägaren skriver
```

Distribueras med:
```bash
firebase deploy --only firestore:rules
```

## Konfiguration

Firebase konfigurerades med FlutterFire CLI:

```bash
flutterfire configure --project=beastris-game-90b1b --platforms=android,web
```

Detta skapade `lib/firebase_options.dart` och `android/app/google-services.json`.

## Gratiskvoter (Spark-plan)

| Resurs | Gräns per dag |
|--------|---------------|
| Läsningar | 50 000 |
| Skrivningar | 20 000 |
| Borttagningar | 20 000 |
| Lagring | 1 GB totalt |

Räcker för tusentals aktiva spelare utan kostnad.

## Lokal historik vs global topplista

| | Lokal historik | Global topplista |
|---|---|---|
| Lagring | `shared_preferences` (enhet) | Firestore (moln) |
| Synkning | Nej | Ja, alla enheter |
| Kräver inloggning | Nej | Ja |
| Kräver nätverk | Nej | Ja |
| Data vid avinstall | Försvinner | Finns kvar |
| Kod | `lib/models/game_history.dart` | `lib/services/leaderboard_service.dart` |
