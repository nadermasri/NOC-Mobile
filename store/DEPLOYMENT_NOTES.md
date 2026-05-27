# Pocket NOC — Store Deployment Guide

Step-by-step deployment to Google Play (do first) and Apple App Store (do after).

---

## ✅ STEP 0 — One-time prerequisites

### Host the Privacy Policy (FREE, do this first)

Both stores require a public URL for your privacy policy. Use GitHub Pages:

```bash
# In your pocket-noc repo:
mkdir -p docs
cp store/PRIVACY_POLICY.md docs/index.md
# Add a simple privacy.html that renders the markdown
git add docs/
git commit -m "Add privacy policy page"
git push
```

Then on GitHub: **Settings → Pages → Source → Deploy from branch → `main` → `/docs`**.

Your privacy policy will be live at: `https://nadermasri.github.io/noc-mobile/`

---

## 🤖 GOOGLE PLAY STORE

### Step 1 — Create Play Console account ($25 one-time)
1. Go to https://play.google.com/console
2. Sign up with your Google account
3. Pay $25 — instant activation

### Step 2 — Create the app
1. Click **Create app**
2. Default language: English (United States)
3. App name: `Pocket NOC`
4. App or game: **App**
5. Free or paid: **Free**
6. Accept declarations

### Step 3 — Set up your store listing
Navigate to **Main store listing** in the left sidebar. Paste in:
- Short description — from `STORE_LISTINGS.md`
- Full description — from `STORE_LISTINGS.md`
- App icon — `assets/branding/icon_1024.png`
- Feature graphic — `store/feature_graphic_1024x500.png`
- Screenshots — at least 2 (max 8) phone screenshots

### Step 4 — Required forms
Complete all the orange-icon sections in left sidebar:
- **App access** — "All functionality available without restrictions" (or provide test credentials)
- **Ads** — No
- **Content rating** — answer the questionnaire (will rate as Everyone)
- **Target audience** — 18+ (it's a developer tool)
- **News app** — No
- **COVID-19 contact tracing** — No
- **Data safety** — paste from `STORE_LISTINGS.md`
- **Government apps** — No
- **Financial features** — No
- **Health** — No

### Step 5 — Upload your first build (Internal Testing)
1. Build a signed AAB:
   ```bash
   ./scripts/build_android.sh https://pocket-noc-api-production.up.railway.app
   ```
   This creates `build/app/outputs/bundle/release/app-release.aab`

2. In Play Console: **Testing → Internal testing → Create new release**
3. Upload the AAB
4. Add release notes (from STORE_LISTINGS.md "What's new")
5. **Save → Review release → Start rollout to Internal testing**

### Step 6 — Test internally
- Add testers (your own email + a few friends)
- Get the opt-in URL, click it, install via Play Store
- Verify everything works

### Step 7 — Submit for production review
Once internal testing looks good:
1. **Production → Create new release**
2. Promote the build from internal testing
3. Submit for review
4. **Review time: 2-7 days** for first submission (subsequent: 2-4 hours)

---

## 🍎 APPLE APP STORE

### Step 1 — Join Apple Developer Program ($99/year)
1. Go to https://developer.apple.com/programs/enroll/
2. Sign in with Apple ID
3. Choose **Individual** (not Organization, unless you have a company)
4. Pay $99 — activation takes 24-48 hours

### Step 2 — Create app in App Store Connect
1. Go to https://appstoreconnect.apple.com
2. **My Apps → +**
3. Platform: iOS
4. Name: `Pocket NOC`
5. Bundle ID: `com.pocketnoc.pocketNoc` (must be unique — change if taken)
6. SKU: `pocket-noc-001` (internal identifier, anything unique)
7. User Access: Full Access

### Step 3 — Configure Xcode signing
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Runner** project → **Runner** target → **Signing & Capabilities**
3. Check **Automatically manage signing**
4. Team: select your Apple Developer team
5. Wait for Xcode to provision certificates

### Step 4 — Build & upload IPA
```bash
flutter build ipa --release --dart-define=API_BASE_URL=https://pocket-noc-api-production.up.railway.app
```
Then open the result in Xcode:
```bash
open build/ios/archive/Runner.xcarchive
```
Xcode Organizer opens → **Distribute App → App Store Connect → Upload**.

### Step 5 — Configure App Store Connect listing
Back in App Store Connect:
- **App Information**: paste from `STORE_LISTINGS.md`
- **Pricing and Availability**: Free, all countries
- **App Privacy**: complete the questionnaire (see `STORE_LISTINGS.md` privacy nutrition label)
- **App Review Information**: your contact email + a demo account login

### Step 6 — TestFlight first
1. Once your build finishes processing (~10-30 min)
2. **TestFlight tab** → invite yourself + testers
3. Install TestFlight on your iPhone → install Pocket NOC
4. Test for a few days

### Step 7 — Submit for review
1. **App Store tab** → fill in all metadata
2. Upload screenshots (use the capture script — required sizes: 6.7" iPhone, 6.5" iPhone, 5.5" iPhone, 12.9" iPad)
3. **Add for Review → Submit for Review**
4. **Review time: 24-48 hours typically**

---

## 📸 Taking screenshots

You need at least **2 screenshots per device size** for each store. iOS is stricter — you need multiple device sizes.

### Required sizes:

**Google Play (1 size is enough):**
- 16:9 or 9:16 ratio
- Min dimension: 320px
- Max dimension: 3840px
- Recommended: 1080×1920 (portrait phone)

**Apple App Store (must have these sizes):**
- **iPhone 6.7"** (1290×2796) — required for iPhone 16 Pro Max
- **iPhone 6.5"** (1242×2688 or 1284×2778) — alternative
- **iPad 12.9"** (2048×2732) — required if you want iPad
- Older sizes optional

### Suggested screenshots to capture (5-6 total per device):

1. **Dashboard** — main hub showing tools grid
2. **Ping result** — live diagnostic with chart
3. **Monitor list** — uptime overview with status chips
4. **AI Explanation** — showing the severity banner + recommendations
5. **Settings → Pro upgrade screen** — shows what users get
6. **Report / PDF preview** — shows the export feature

### Workflow:
```bash
# 1. Boot the simulator at the right size
xcrun simctl boot "iPhone 17 Pro Max"   # for 6.7"

# 2. Run the app
flutter run --dart-define=API_BASE_URL=https://pocket-noc-api-production.up.railway.app -d "<UDID>"

# 3. Navigate to each screen, then capture:
./scripts/capture_screenshots.sh dashboard
./scripts/capture_screenshots.sh ping_result
./scripts/capture_screenshots.sh monitors
./scripts/capture_screenshots.sh ai_explain
./scripts/capture_screenshots.sh pro_upgrade
./scripts/capture_screenshots.sh report
```

Screenshots land in `store/screenshots/<device>/`.

---

## ⚠️ Common rejection reasons (avoid these)

### Apple:
- **Missing demo credentials**: provide a test account in "App Review Information"
- **Misleading metadata**: don't claim features you don't have
- **Crashes on launch**: test thoroughly on TestFlight first
- **Missing Privacy Policy URL**: required, no exceptions
- **Spam keywords**: don't stuff irrelevant terms (e.g. competitor names)

### Google:
- **Missing data safety form**: required for all new apps
- **Permissions mismatch**: only request permissions you actually use
- **Privacy policy URL must be the EXACT same URL** in the manifest and in the listing
- **Target API level too low**: must target Android 14 (API 34) as of late 2024

---

## 📅 Realistic timeline

| Step | Time |
|---|---|
| Privacy policy hosted on GitHub Pages | 30 min |
| Google Play Console account | 1 hour (incl. $25 payment) |
| First Play Store listing complete | 3-4 hours |
| Google internal testing approval | instant |
| Google production review | 2-7 days first time |
| Apple Developer Program activation | 24-48 hours after paying $99 |
| App Store Connect listing | 4-5 hours |
| Apple TestFlight processing | 10-30 min per build |
| Apple App Store review | 1-3 days typically |

**Total: ~1 week from "I want to ship" to "live on both stores"** assuming no rejections.
