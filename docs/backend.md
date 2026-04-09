# Backend — Global Topplista

Beastris använder **Firebase Firestore** som backend för den globala topplistan. Ingen egen server behövs — Google sköter all infrastruktur.

## Arkitektur

```
Flutter-appen  →  Firestore SDK  →  Google Cloud  →  Firestore-databas
```

Appen kommunicerar direkt med Firestore via `cloud_firestore`-paketet. Data skickas och hämtas via HTTPS mot Googles servrar.

## Firebase-projekt

- **Projektnamn**: beastris-game
- **Projekt-ID**: beastris-game-90b1b
- **Konsol**: https://console.firebase.google.com/project/beastris-game-90b1b

## Datamodell

Firestore är en dokumentdatabas. Alla resultat lagras i en collection kallad `leaderboard`:

```
leaderboard/                     ← collection
  <auto-id>/                     ← ett dokument per spelsession
    name:  "Klas"                ← spelarnamn (anges vid game over)
    score: 1172                  ← poäng
    lines: 14                    ← rensade rader
    level: 2                     ← uppnådd nivå
    date:  "2026-04-09T21:00:00" ← tidsstämpel (ISO 8601)
```

## Kod

### `lib/firebase_options.dart`
Automatgenererad av `flutterfire configure`. Innehåller API-nycklar och app-ID:n för web och Android.

### `lib/services/leaderboard_service.dart`
Hanterar all kommunikation med Firestore:

- `submitScore(result, name)` — skriver ett nytt dokument
- `fetchTopScores()` — hämtar topp 10 sorterat på poäng (fallback: returnerar tom lista vid fel)

### `lib/main.dart`
Firebase initieras vid uppstart:
```dart
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

### `lib/screens/game_screen.dart`
- Vid game over visas en dialog där spelaren anger sitt namn
- "Skicka & Spela igen" — sparar till Firestore och startar nytt spel
- "Menu" — sparar till Firestore och går till startsidan
- Startsidan anropar `_loadGlobalLeaderboard()` vid start och efter varje inlämning

## Säkerhetsregler

Nuvarande regler (test mode) tillåter alla att läsa och skriva:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /leaderboard/{doc} {
      allow read: if true;
      allow write: if true;
    }
  }
}
```

Reglerna redigeras i Firebase Console under:
**Firestore Database → Rules**

> ⚠️ Inför en publik release bör reglerna skärpas, t.ex. begränsa skrivfrekvens och validera datafält.

## Konfiguration

Firebase konfigurerades med FlutterFire CLI:

```bash
flutterfire configure --project=beastris-game-90b1b --platforms=android,web
```

Detta skapade `lib/firebase_options.dart` och registrerade appar för web och Android i Firebase-projektet.

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
| Kräver nätverk | Nej | Ja |
| Data vid avinstall | Försvinner | Finns kvar |
| Kod | `lib/models/game_history.dart` | `lib/services/leaderboard_service.dart` |
