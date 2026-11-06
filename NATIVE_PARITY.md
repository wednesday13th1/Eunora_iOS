| Source | Reviewed default branch revision |
|---|---|
| Web | `a2bbd053bb94c078479467b0e77400fd4d24f732` |
| Express backend | `17d643a9f474f301648e511e133e5a74908009bf` |
| iOS baseline | `e379e7c90e9135e13bfc11152e8403c76c8c03a5` |

| Feature | Web reference | Native implementation | Remaining implementation | Priority | Verification |
|---|---|---|---|---|---|
| Welcome | Ocean hero and immediate voyage entry | Scrollable ocean welcome and one tap to enter. Guest welcome preference persists locally. | Exact hero illustration and placement. Fraunces and Nunito are bundled. | High | Guest UI journey |
| Map | Illustrated SVG world and selectable routes | Native drawing from source geometry, ten original destination images, scrollable destination list and animated route | Web ocean life, precise landmark presentation, verify source destinations that share coordinates | Medium | Map navigation in guest UI journey |
| Quests | Four categories, date-based rotation, XP, ranks and badges | Same daily quest IDs, local completion and XP, adaptive cards. Several prompts use gentler wording. | Badges and exact artwork | High | Quest navigation and persistence across relaunch on iPhone 18 Pro, plus the 400-date rotation comparison |
| Letters | Six built-in bottles and moderated community messages | Scrollable bottle selector, staged native cork and paper animation, scrollable reader | Exact bottle artwork and approved community feed | High | Open and close UI journey |
| Sailor | Customizable avatar, companions and cabin rewards | Existing native wardrobe and cabin, persisted hat and lamp preferences | Web avatar, companions, décor and unlocks | High | Sailor navigation in guest UI journey |
| Settings | Account controls in Web navigation | Native account, privacy and accessibility sections | Account deletion requires a backend route | High | Settings navigation in guest UI journey |
| Authentication | Supabase email/password with optional confirmation | Configurable Express API integration, Keychain session, refresh and local logout | Verify deployment configuration and exercise a real account lifecycle | High | Local HTTP fixtures |
| Progress | Profile XP and a replaceable daily completion snapshot | Local SwiftData progress with no automatic upload | Backend needs isolated reads and conflict-safe updates before opt-in sync | High | Quest rotation parity and local progress across relaunch. Upgrade persistence needs additional verification. |
| Persistence | Web account-backed quests and profile | Existing SwiftData models and local preferences. Account credentials are separate. | Multi-account sync, upgrade regression tests | High | Guest relaunch UI journey |
| Animations | Waves, floating bottles and scroll opening | Native route and bottle phases with Reduce Motion branches | Visual timing and accessibility settings coverage | Medium | Default bottle opening UI journey |
| Accessibility | Web keyboard controls and visual styling | Scrollable layouts, scaled headings, adaptive quest cards, accessible tab labels and safe area inset | VoiceOver, increased contrast, appearance, landscape and full Dynamic Type QA | High | UI tests use accessibility labels. Manual assistive technology checks pending. |

The backend accepts bearer tokens for `GET /me` and `PUT /me/progress`, and returns errors as `{ error, code? }`. It also exposes a public approved-letter list and authenticated letter submission. No live API origin is published in the reviewed repository. The iOS app currently uses only the verified auth routes.

The checked-in Supabase migration permits unrestricted profile reads under its row policy. The profile includes XP and daily completion data. The Express progress route reads XP and then replaces the daily snapshot in a separate update. Concurrent or out-of-order clients can overwrite a newer completion list. Guest quest, journal and check-in data remain local until the backend supports private progress and safe updates with user consent.


The five requested legacy device models (iPhone SE 3rd generation, iPhone 13 mini, iPhone 15, iPhone 16 Pro and iPhone 16 Pro Max) were absent from the installed simulator inventory. The app target requires iOS 27.0. Simulator tests use isolated bundle identifiers to avoid touching existing user data.

| Simulator | Observed result |
|---|---|
| iPhone 17, iOS 27.0 | Guest navigation and letter open/close passed. A separate largest Dynamic Type retest passed after expanding tab hit areas. |
| iPhone 18 Pro, iOS 27.0 | Six tests passed, covering guest navigation and relaunch, letters, quest progress persistence and three HTTP fixtures. Screenshot review then led to a letter-reader clearance adjustment. |
| iPhone 17e, iOS 27.0 | Isolated app launched and displayed the welcome screen. The multi-device XCTest run stalled. |
| iPhone 18 Pro Max, iOS 27.0 | Simulator booted. A complete UI test result was unavailable. |
