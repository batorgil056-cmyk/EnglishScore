# EnglishScore-ийн 6 эхлэлийн дэлгэц — Flutter Web demo

Дизайны жишээг хэрэглэгчийн өгсөн 6 screenshots дээр үндэслэн хийсэн.
Энэ нь British Council-ийн албан ёсны апп **биш**, зөвхөн UI загварын туршилт.

## Windows + VS Code дээр ажиллуулах

1. ZIP-ээ бүрэн задла. `EnglishScore-Flutter` хавтсыг VS Code дээр **File → Open Folder** гэж нээ.
2. VS Code-ийн Terminal дээр:
   ```powershell
   flutter create . --project-name englishscore_intro --platforms web
   flutter pub get
   flutter run -d chrome
   ```
   Эсвэл `setup-windows.bat` файлыг ажиллуулаад дараа нь `flutter run -d chrome` команд өг.
3. Chrome дээр Splash → Welcome → Get Started / Sign in → Email forms-ыг шалга.

## Яаж шинэчлэх вэ?

Дараагийн удаа зөвхөн `lib/main.dart`-ийг шинэчилж болно.
`flutter pub get` болон `flutter create` командыг дахин ажиллуулах шаардлагагүй.
`flutter run -d chrome` ажиллаж байхдаа `r` дарж **hot reload** хийнэ.

## Web build, GitHub Pages

GitHub репо нэр `englishscore-demo` гэвэл:

```powershell
flutter build web --release --base-href /englishscore-demo/
```

Үүссэн `build/web/` агуулгыг GitHub Pages-д нийтлэх хэрэгтэй.
GitHub Pages нь Flutter/Dart эх кодыг биш, build хийсэн веб файлыг serve хийнэ.
Репо нэр өөр бол `/englishscore-demo/`-г тааруулж солино.

Safari дээр байршуулсан веб аппын URL-ийг нээгээд Share → Add to Home Screen → Open as Web App хийвэл iPhone дээр icon гарна.

## Одоогоор хийгдсэн

- Splash / logo
- Welcome / Get started / I already have an account
- Get Started: Apple, Microsoft, Email
- Sign in options: Apple, Microsoft, Email
- Sign up: email, password, input validation
- Sign in: email, password, input validation
- Back navigation
- PWA manifest/icon

**Аюулгүй байдлын тэмдэглэл:** Apple/Microsoft жинхэнэ нэвтрэлт, серверийн бүртгэл, хэрэглэгчийн мэдээллийн сан холбоогүй. Email, password-ийг backend рүү илгээхгүй, хадгалахгүй. GitHub Pages-д нийтэлсэн веб код бусдад харагдах боломжтой тул нууц түлхүүр, хувийн мэдээлэл бүү оруул.

## Зургийн алдааг тааруулах

Өнгө: `Palette` class; байрлал: `_welcomeScreen`, `_choiceScreen`, `_formScreen` доторх `top: h * ...` хувь; логогийн фонт: `CouncilBrand`.

`flutter --version` ба `flutter run -d chrome` ажиллах шаардлагатай. Төсөл энэ орчинд Flutter SDK-гүй тул compile-аар туршигдаагүй.

## Dashboard previews

Sign in through the existing email form (this prototype has no backend). On Home,
open the three-dot menu → **Demo UI states**, then select:

1. **New account**: Core Skills available, Speaking and Writing locked.
2. **Core Skills completed**: sample Core Skills score and CEFR; other tests unlocked.
3. **All tests completed**: sample results, Certificate and Test again actions.

The selected state persists locally across restarts using SharedPreferences.
Choose New account to reset the preview. This is device-local demo data, not
account-specific test results. Every completed card is labeled **Demo result**.
Core Skills opens the complete local practice test described below. Speaking and
Writing remain previews. Certificate explains that demo scores cannot issue a real certificate.

Artwork in `assets/icons/` is manually reconstructed from IMG_4029.PNG and
IMG_4030.PNG. The supplied references do not include completed score cards;
those cards retain the existing card style and are provisional pending a reference.
No login/onboarding or British Council branding changes were made.

## Core Skills device setup UI

After Test security → Next, setup proceeds through introduction, Volume,
Microphone instructions, Camera instructions, and the Selfie camera test.
The four progress markers indicate navigation only, not device verification.
No speech audio asset is present: Volume explicitly labels its animated waveform
as a demo, and No offers Retry without advancing or verifying an audio check.
The microphone/camera information copy describes the original EnglishScore app;
this local prototype never records audio, takes monitoring photos automatically,
uploads data, verifies identity, or issues certificates. The selfie camera test
now supports the explicitly labeled simulator mode and opt-in real iPhone camera
described below.

Illustrations in `assets/pretest/` are manually recreated vectors. The supplied
`setup_03_microphone.png` shows the microphone information popup; the main page
uses the earlier `IMG_4043.PNG` reference. `setup_04_microphone_info.png` was not
present when this flow was implemented.


## Testing the selfie camera

Fully restart/rebuild the app after installing the new native plugins (hot reload
alone cannot register them). iOS Simulator is detected with device_info_plus:
it shows a labeled simulated preview and preserves the face alignment oval.
The teal button advances to Review capture without creating a photo. This does
not use the Mac webcam or perform identity verification. Other unsupported
platforms offer an explicit **Use demo camera** choice.

On a physical iPhone, tap **Enable front camera**, then grant iOS camera access.
The camera plugin uses the front lens with `enableAudio: false`. Camera and
microphone usage descriptions are in `ios/Runner/Info.plist` for plugin setup;
this still-photo test does not request microphone recording. Previously denied
or restricted camera access produces an actionable message, never a fake feed.
Tap capture to take one local photo: the temporary JPEG is read for in-memory
review and deleted, with no gallery save or upload. Retake clears the review
image; exiting disposes the setup. Done continues to the room-scanning introduction.
The camera is released when leaving the screen or backgrounding the app; return
and tap Enable front camera again to resume. No server verification is connected.


## Complete Core Skills demo test

The existing route continues from selfie review’s **Done** button through room
scanning, rules and agreement to exactly three test parts:

- Part 1: Grammar and Vocabulary — 30 original A1–B2 three-choice questions.
- Part 2: Reading — 10 original passage/comprehension questions and 5 ordering
  questions. The first sentence is locked; drag the other three cards to reorder.
- Part 3: Listening — 10 original spoken dialogues/announcements with three answers.

There is no yellow talking-warning banner or microphone violation detection.
Each part has a purple 30-second introduction, with Start to begin immediately.
Question limits are 42 seconds for grammar, 90 for reading and 105 for listening.
Expiry submits the current selection/order; untouched questions count as unanswered.
NEXT requires a choice for multiple-choice questions. For ordering, NEXT submits
the displayed order. Ordering earns one point only when the entire order is correct.
X and system Back use the existing exit confirmation. Go back preserves the
current question/answer and resumes the timer. Leaving discards the unfinished
attempt and preserves previously saved results. Backgrounding pauses the timer.

### Listening and native setup

`flutter_tts` is the only new runtime dependency. It uses an English (`en-GB`)
system voice, at a moderate speech rate. Audio is actual speech, not a simulated
waveform. The large play control initially shows **Listen: 2 plays left**.
Yellow bars and the elapsed playback timer run only after the speech engine emits
its start event. Answers unlock as soon as Play is pressed once. NEXT is enabled after an answer
is selected, including while speech is playing; advancing immediately stops the
current audio and resets this permission for the next listening question. Each started play,
including an interrupted or failed play, consumes one of the two attempts.
Failure before speech starts does not consume an attempt. Retry is available while
plays remain; an error also offers an explicit unanswered skip. A native start
watchdog and completion timeout prevent playback from remaining stuck indefinitely.
Question expiry, Next, app backgrounding, exit confirmation and disposal stop speech.
Returning after interruption requires pressing play again; plays are never reset by
opening the exit dialog. New questions receive two new plays.

Run a full build after adding the plugin; hot reload alone cannot register it:

```sh
flutter pub get
flutter run -d <iphone-simulator-id>
```

Raise the Simulator/Mac output volume. If speech fails, check the available English
system voice and use Retry audio. iOS uses the playback audio category; no microphone
permission is needed for listening. Flutter generated CocoaPods support for
`flutter_tts`, which does not yet support Swift Package Manager. Open
`ios/Runner.xcworkspace` for Xcode builds. A real native speech start and completion
were verified on iPhone Simulator using the production backend.

### Demo scoring and local results

After all 55 questions, the controller generates `400 + Random().nextInt(51)`
once, independently of correct or incorrect answers. It also generates two balanced
pairs of section scores whose sum is exactly four times the overall score. All
section values stay within 0–600. The resulting level is B2 • Upper Intermediate.
This is demo-only scoring, not an English proficiency assessment. Correct-answer
and unanswered counts are retained as separate statistics and do not affect the score.

The results page automatically plays one 5.5-second native Flutter animation after
question 55: purple shield scale/fade, a 2.75-second count-up to the calculated score,
segmented progress filling, Level achieved/CEFR reveal, finite confetti and a
sliding certificate-information panel. The dark-purple promotion card shows the actual CEFR level and a purple
Get my certificate action; its footer clearly marks the preview as a demo. Save/retry rebuilds do not replay the sequence; exit/app
pause resumes it from its current position. Reduce Motion displays the settled
result immediately. Get my certificate becomes available after the reveal and successful local saving.
It opens the dark-purple certificate picker with a demo-marked, dynamically rendered
score/CEFR certificate preview. Buy shows a demo-only notice; there are no payment
forms, charges or issued certificates. The I don't need a certificate tab shows
the clock/plant/shelf illustration and the Later panel. Later saves the completed
result again before returning Home. Saving failures stay on the selected tab and
allow retry; no completed score or speaking/writing preview result is reset.
Implementation: `lib/core_test/animated_results.dart`, `certificate_selection.dart`
and `certificate_art.dart`.

Completion saves the Core Skills score and CEFR using the existing
`englishscore.demo.results.v1` SharedPreferences key, preserving speaking/writing
preview results. Home and Reports reload the result when the test route closes.
Storage failures show Retry saving; Get my certificate is enabled after saving succeeds.
No test answers, audio, room video or scores are sent to a server.

### How to test all 55 questions

1. Start the app and sign in through the existing local email form.
2. On Home, select Core Skills **Start** or **Test again**, continue through setup,
   use **Use demo camera** on Simulator, then capture and press **Done**.
3. Start scanning and swipe right or tap four times, press OK, agree to the rules,
   and press Start the test. Simulator scanning remains explicitly simulated.
4. Complete 30 grammar questions, start Part 2, and complete all 15 reading tasks.
   Drag cards by their handle/body; the locked first sentence cannot move.
5. Start Part 3, play each dialogue, select an answer and tap NEXT. Verify that a
   third playback is disabled. Try X → Go back and backgrounding during playback.
6. After question 55, inspect the animated purple result, press Get my certificate,
   try the demo-only Buy notice, then select I don't need a certificate → Later.
   Check the completed score on Home and All Reports; Speaking/Writing unlock.
   Restart the app to verify that the demo result remains available.

Source responsibilities:
`lib/core_test/question_data.dart` (55 questions and answer keys),
`test_controller.dart` (timers, transitions, answer records and scoring),
`listening_audio.dart` (native speech and playback limits),
`test_screen.dart` (reference-inspired responsive UI),
`lib/core_test_flow.dart` (existing preparation handoff),
`lib/test_results.dart` (local persistence), `lib/dashboard.dart` (result refresh).

Automated checks:

```sh
flutter analyze
flutter test test/certificate_flow_test.dart test/animated_results_test.dart test/core_test_controller_test.dart test/listening_audio_test.dart test/core_test_screen_test.dart test/core_test_flow_test.dart test/core_setup_screens_test.dart test/dashboard_test.dart test/selfie_capture_test.dart
flutter build ios --simulator --debug
```

Tests cover all 55 questions at multiple iPhone sizes, exact part counts,
right/wrong/expired answers, scoring bands, actual drag gestures, audio events,
failures, two-play limits, interruption/reset, saving failures and Home/Reports reload.
Widget tests inject a controlled speech backend; the native smoke check separately
confirmed real Simulator speech start/completion. Speaking/writing previews and
existing onboarding are unchanged.


## Dated Core Skills reports and one score-details page

Home displays the latest completed Core Skills score in a teal shield with its
stored CEFR description. Speaking and Writing unlock after Core Skills; these
remain the existing preview flows. Certificate opens the existing demo-only picker,
and Test again starts the unchanged 55-question test. All Reports lists dated
attempts newest first, retains retakes, and marks the highest known score BEST SCORE.
Ties prefer the newest dated attempt. Each card opens that exact immutable stored
result, not a newly generated result. The tested date uses the device's local date
formatted DD MMM YYYY from the stored UTC timestamp.

### Persistence and migration

The existing SharedPreferences key `englishscore.demo.results.v1` stays compatible
with old installations. Its `core`, `speaking` and `writing` summaries are retained.
New `_coreReports` entries include `id`, `completedAt`, `score`, `cefr`, `grammar`,
`vocabulary`, `reading` and `listening`. The attempt ID combines an instance timestamp
and secure random suffix; the completion timestamp is frozen when question 55 is
submitted. Saving on completion, retrying, or pressing Later upserts the SAME ID.
A retake has a new ID and appends a distinct report. Writes are serialized, so
concurrent saves do not lose reports; failed writes do not poison the queue.
Opening an older report/certificate never changes which result is newest.

Older score-only summaries have no recoverable completion date or skill breakdown.
They remain accessible, show Date unavailable and an explicit incomplete-result notice, and are retained as
`_legacyCore` when the first dated attempt is saved. No date, breakdown or missing
history is fabricated. The explicit Demo UI states menu remains a preview/reset
facility and intentionally replaces local demo state when selected.

### Calculations

Completed attempts now use a frozen random demo total between 400 and 450.
`CoreTestController._generateDemoResult()` runs only on the final submission after
all three parts. The total is `400 + Random().nextInt(51)`. Two random offsets
between -50 and 50 create `[total+a, total-a, total+b, total-b]`, shuffled into
Grammar, Reading, Vocabulary and Listening. Each is between 350 and 500 (within
the allowed 0–600), and their arithmetic mean is exactly the generated total.
No answer correctness, question difficulty or completion time influences the draw.

The controller retains that immutable result along with its stable attempt ID and
UTC completion timestamp. The animation, Home, Reports, details and certificate
preview consume the same result. Existing persistence saves it on completion and
upserts the same ID on Later/retry. Reading a report never calls Random. A completed
retake makes a fresh random draw with a new report ID; totals can naturally repeat.
Existing saved reports are retained and are not re-randomized.

### Details, certificate and sharing

`CoreScoreDetails` is ONE vertically scrollable page for reference images 21 and 22.
The date/back header remains fixed. Its score card, four skill bars, teal certificate
promotion, level-specific ability text, comparison table and disclaimer are all in
the same `SingleChildScrollView`. The teal/grey cross-test chart reproduces the
reference's illustrative values; it is explicitly unverified, not official score
equivalence, and is separate from the demo's scoring bands.

Share uses `share_plus` to open the native platform share sheet, with the selected
report's stored values and a demo disclaimer. An iPad share anchor is supplied and
failures show a retryable message. Nothing is sent automatically; the user chooses
an app/recipient in the native sheet. A full native rebuild is needed after adding
this plugin (`flutter pub get`, then `flutter run -d <device-id>`).

Dart changes for this flow:
`lib/test_results.dart`, `lib/dashboard.dart`, `lib/core_test/question_data.dart`,
`test_controller.dart`, `certificate_art.dart`, `certificate_selection.dart`;
new `lib/core_test/report_widgets.dart` and `score_details.dart`.
New tests: `test/report_history_test.dart` and `test/score_details_test.dart`.
Existing dashboard, complete-test and setup tests were updated for the new cards.

Manual check: finish the 55 questions → animated result → Get my certificate →
I don't need a certificate → Later → Home → All Reports → tap a dated report.
Scroll through the entire details page, Share, and open its certificate preview.
Retake the test with different answers; confirm two dated cards, newest first,
a single BEST SCORE badge on the highest result, and that the older card still
opens its own score/breakdown. Restart the app and repeat these checks.

```sh
flutter analyze
flutter test test/random_core_scoring_test.dart test/report_history_test.dart test/score_details_test.dart test/core_test_controller_test.dart test/core_test_flow_test.dart test/core_setup_screens_test.dart test/dashboard_test.dart test/certificate_flow_test.dart
```


### Random-score persistence checks

The four-section mean remains an invariant for the generated result, not an
answer-based proficiency calculation. All new scores from 400–450 map to
B2 • Upper Intermediate through the existing shared CEFR mapping. Earlier stored
reports retain their stored sections, date and corresponding historical level.
Incomplete legacy records remain explicitly incomplete; no missing score is invented.

`test/random_core_scoring_test.dart` checks inclusive endpoints, no generation
before completion, exactly one frozen draw, independence from answer correctness,
section bounds and exact means, repeated reads/saves, reload and separate retakes.
The questions, navigation, layout, result animation and certificate screens are unchanged.
