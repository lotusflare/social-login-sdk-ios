# Social Login SDK for iOS

A Swift Package that aggregates social login providers for host apps, plus **email auth networking APIs** (no email UI in the SDK). The current release implements **Google Sign-In**, **Facebook Limited Login**, **Sign in with Apple**, and appauth email register/sign-in/password flows against the v2 gateway.

## Requirements

- iOS 15+
- Xcode 15+
- Swift 5.9+

### Public API renames

| Previous | Current |
|----------|---------|
| `SocialLoginSDK.restoreSession` / `loadPersistedSession` | Removed — host owns session storage |
| `SocialLoginSDK.currentSession` / `isLoggedIn` | Removed — host tracks login state |
| `SocialLoginError.backendExchangeFailed` / `backendLoginFailed` / `nonceFailed` / `logoutFailed` | `backendRequestFailed(statusCode:code:message:)` |
| `SocialLoginError.sessionNotFound` | Removed |
| `BackendConfiguration` required in `configure` | Optional; prefer Info.plist backend keys |
| Google / Facebook client IDs on `SocialLoginConfiguration` | Removed — Info.plist only (`GIDClientID`, `GIDServerClientID`, `FacebookAppID`, `FacebookClientToken`) |
| `FacebookLoginTracking` / `FacebookSignInConfiguration.tracking` | Removed (Limited Login is always used) |
| `SocialLoginSDK.bootstrap` / `configure` / `application(_:didFinishLaunchingWithOptions:)` | Single `setup(configuration:)` (no `UIApplication`); host owns Facebook `ApplicationDelegate` launch hook |
| `BackendConfiguration.PathOverrides` / path init params | Removed — paths fixed in SDK |
| `refreshSession` / `refreshSession(_ session:)` | `refreshToken(_:)` — pass stored refresh token only |
| `signOut()` / `signOut(accessToken:provider:)` | `signOut(accessToken:)` — host clears its own store |
| `changePassword` / `requestPasswordChangeCode` | Require `accessToken` argument |
| `setup` async / session hydrate | Sync `setup(...) -> SocialLoginError?` (no session hydrate) |
| `POST /auth/social/login` | `POST /auth/social/sign_in` |
| `POST /auth/logout` | `POST /auth/sign_out` |
| `44212` nonce invalid | `44221` only (`44212` no longer mapped) |
| `businessLine` / `userStatus` on session | Removed (v2 `user_profile`) |
| `linkedProviders` / `email` / `userID` / `provider` / `displayName` / `avatarURL` on session | `providers` / `primaryEmail` / `userId` only (align with `user_profile`; client-only fields removed) |
| — | New: `setup(configuration:)` / `isProviderConfigured` / `refreshToken` / email networking APIs |

## Project Structure

```
social-login-sdk-ios/
├── Package.swift                # Swift Package (repo root — remote SPM entry)
├── Sources/
│   └── SocialLoginSDK/          # SDK sources
├── Docs/
├── Example/
│   └── SocialLoginDemo/         # Demo app for manual verification
└── SocialLoginSDK.xcworkspace
```

Open `SocialLoginSDK.xcworkspace` in Xcode and run the `SocialLoginDemo` scheme.

## Host App Integration

### Minimal checklist

Code-side requirements for every host: put backend + provider credentials in Info.plist, call `setup` with `environment`, then `signIn` / `signOut`, and forward OAuth URLs when Google or Facebook is enabled. Platform setup depends on which providers you enable:

| Step | Google only | Apple only | Facebook only | All three |
|------|:-----------:|:----------:|:-------------:|:---------:|
| Add SPM package (Git URL or local repo root) | ✓ | ✓ | ✓ | ✓ |
| Info.plist: backend Base URL + Client ID | ✓ | ✓ | ✓ | ✓ |
| `setup` (`environment`) | ✓ | ✓ | ✓ | ✓ |
| Sign-in UI (`signIn` / `signOut`) | ✓ | ✓ | ✓ | ✓ |
| Info.plist: `GIDClientID` + `GIDServerClientID` | ✓ | — | — | ✓ |
| URL Scheme: `com.googleusercontent.apps.<prefix>` | ✓ | — | — | ✓ |
| Google Cloud: iOS + Web OAuth clients | ✓ | — | — | ✓ |
| Xcode Capability: Sign in with Apple | — | ✓ | — | ✓ |
| Apple Developer: enable Sign in with Apple | — | ✓ | — | ✓ |
| Info.plist: `FacebookAppID` + `FacebookClientToken` | — | — | ✓ | ✓ |
| URL Scheme: `fb{APP_ID}` | — | — | ✓ | ✓ |
| `LSApplicationQueriesSchemes` (fbapi / fbauth / …) | — | — | ✓ | ✓ |
| Meta: Facebook Login + iOS Bundle ID | — | — | ✓ | ✓ |
| `handleOpenURL` / `.onOpenURL` | ✓ | — | ✓ | ✓ |

Details for each provider follow below.

### 1. Add the Swift package

**Remote (recommended for host apps):**

1. Xcode → **File → Add Package Dependencies…**
2. Enter `https://github.com/lotusflare/social-login-sdk-ios`
3. Choose version rule **Exact** / **Up to Next Major** for tag `1.0.0` (or newer)
4. Add the `SocialLoginSDK` product to your app target

**Local (development):**

**File → Add Package Dependencies → Add Local…** and select this repository root (the folder that contains `Package.swift`).

### 2. Configure Info.plist (Google)

Add your Google OAuth iOS client ID, **Web client ID** (`GIDServerClientID`), and reversed client ID URL scheme:

```xml
<key>GIDClientID</key>
<string>YOUR_IOS_CLIENT_ID.apps.googleusercontent.com</string>
<key>GIDServerClientID</key>
<string>YOUR_WEB_CLIENT_ID.apps.googleusercontent.com</string>
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.YOUR_CLIENT_ID_PREFIX</string>
    </array>
  </dict>
</array>
```

### 3. Configure Sign in with Apple (Apple)

#### Apple Developer Portal

1. Open [Apple Developer](https://developer.apple.com/account) → **Certificates, Identifiers & Profiles**.
2. Select your App ID (must match host app Bundle ID).
3. Enable **Sign in with Apple** capability.
4. Regenerate/download the Development Provisioning Profile that includes this capability.

#### Xcode host app

1. Target → **Signing & Capabilities** → add **Sign in with Apple**.
2. Ensure an entitlements file contains:

```xml
<key>com.apple.developer.applesignin</key>
<array>
  <string>Default</string>
</array>
```

3. Test on a real device or a simulator signed in with an Apple ID.

Native iOS Sign in with Apple does **not** require Services ID, redirect URL, or client secret. Those are needed later when your backend validates Apple tokens server-side.

### 4. Configure Facebook Login (Facebook)

#### Meta for Developers

1. Open [Meta for Developers](https://developers.facebook.com/) and create or select your app.
2. Add the **Facebook Login** product.
3. Under **Settings → Basic**, copy **App ID** and **Client Token** (Advanced).
4. Add an **iOS** platform with your host app Bundle ID (must match exactly).
5. Add test users or developers while the app is in development mode.

#### Info.plist

Add Facebook keys, URL scheme, and query schemes alongside any Google entries:

```xml
<key>FacebookAppID</key>
<string>YOUR_APP_ID</string>
<key>FacebookClientToken</key>
<string>YOUR_CLIENT_TOKEN</string>
<key>CFBundleURLTypes</key>
<array>
  <!-- existing Google URL scheme -->
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>fbYOUR_APP_ID</string>
    </array>
  </dict>
</array>
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>fbapi</string>
  <string>fbauth</string>
  <string>fbauth2</string>
  <string>fb-messenger-share-api</string>
</array>
```

#### App lifecycle

When Facebook Login is enabled, call Meta’s launch hook **before** `SocialLoginSDK.setup` in the **main app**:

```swift
import SocialLoginSDK

func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
) -> Bool {
    _ = ApplicationDelegate.shared.application(
        application,
        didFinishLaunchingWithOptions: launchOptions
    )
    _ = SocialLoginSDK.setup(
        configuration: SocialLoginConfiguration(environment: .production)
    )
    return true
}
```

Widget / other extensions: call only `SocialLoginSDK.setup(configuration:)` (no Facebook lifecycle). Session persistence remains the host’s responsibility. See **§5**.

Facebook Login also uses `handleOpenURL` for SSO callbacks (same as Google).

### 5. Configure backend in Info.plist and call `setup`

Add environment-specific gateway URLs and client ID:

```xml
<key>SocialLoginStagingBaseURL</key>
<string>https://rmax-dev.nomadsplits.com/appauth/</string>
<key>SocialLoginProductionBaseURL</key>
<string>https://rmax.nomadsplits.com/appauth/</string>
<key>SocialLoginClientID</key>
<string>YOUR_CLIENT_ID</string>
<!-- Optional per-environment overrides: SocialLoginStagingClientID / SocialLoginProductionClientID -->
```

Google / Facebook client credentials are read **only** from Info.plist (`GIDClientID`, `GIDServerClientID`, `FacebookAppID`, `FacebookClientToken`). They cannot be passed via `SocialLoginConfiguration`.

UIKit launch (recommended):

```swift
func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
) -> Bool {
    // Facebook-enabled main app only — call before setup:
    _ = ApplicationDelegate.shared.application(
        application,
        didFinishLaunchingWithOptions: launchOptions
    )

    if let error = SocialLoginSDK.setup(
        configuration: SocialLoginConfiguration(environment: .production)
    ) {
        // Missing plist backend keys, etc.
        print(error.localizedDescription)
    } else {
        // SDK ready — restore your own stored session if any
    }
    return true
}
```

`setup(configuration:)` is the single entry point for the main app and extensions (e.g. Widget). It does not take `UIApplication`. When Facebook is enabled, the **host** must call `ApplicationDelegate.shared.application(_:didFinishLaunchingWithOptions:)` in the main app **before** `setup` (`ApplicationDelegate` is available through `import SocialLoginSDK`). Extensions should not call that Facebook hook.

Use `isProviderConfigured(_:)` to hide unavailable provider buttons.

Sign-in always follows (paths are built into the SDK; hosts do not configure them):

1. `GET /auth/social/nonce` with `X-Client-Id`, `X-Device-Id`, and a per-request `X-Request-Id`
2. Provider sign-in (Google: raw nonce; Apple: SHA256(raw); Facebook Limited Login: raw nonce into FB SDK)
3. `POST /auth/social/sign_in` with `{ login_type, id_token, nonce, user_name? }`
4. Host persists the returned `SocialLoginSession` (`access_token` / `refresh_token` / `user_profile`, environment, expiry)

Use `SocialLoginSDK.refreshToken(storedRefreshToken)` for `POST /auth/refresh_token`, then merge `SocialLoginTokenRefresh` into your stored session (e.g. `session.applying(tokens)`).

### Email auth (networking only)

The SDK exposes email register / sign-in / password APIs **without UI**. Host apps must build their own screens and call:

| Method | Backend |
|--------|---------|
| `requestEmailSignUpCode` | `POST /auth/email/sign_up/get_code` → `EmailCodeSendResult` (`resendAfterSec`, …) |
| `completeEmailSignUp` | `POST /auth/email/sign_up` → `SocialLoginSession` (auto-login tokens; same shape as `signInWithEmail`) |
| `checkEmailCode` | `POST /auth/code/check` (OTP pre-check; does **not** consume the code; `sign_up` / `password_reset` / `password_change`) |
| `signInWithEmail` | `POST /auth/email/sign_in` |
| `isEmailRegistered` | `POST /auth/email/is_registered` → `EmailRegistrationStatus` (`registered`, `existsLoginTypes`) |
| `requestPasswordResetCode` / `resetPassword` | forgot-password (`get_code` → `EmailCodeSendResult`) |
| `requestPasswordChangeCode(accessToken:)` / `changePassword(accessToken:…)` | logged-in change (`get_code` → `EmailCodeSendResult`) |

Optional UI flow: call `checkEmailCode` after the user enters the OTP, then call the consuming API (`completeEmailSignUp` / `resetPassword` / `changePassword`) with the **same** code. Password reset/change success invalidates tokens server-side; the host should clear its local session. The Demo **Email** tab is for smoke-testing these APIs only.

### 6. Handle OAuth redirect URLs (Google & Facebook)

SwiftUI:

```swift
.onOpenURL { url in
    _ = SocialLoginSDK.handleOpenURL(url)
}
```

UIKit `AppDelegate`:

```swift
func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    SocialLoginSDK.handleOpenURL(url)
}
```

Apple Sign In does not use `handleOpenURL` for the native iOS flow.

### 7. Start sign-in

```swift
SocialLoginSDK.signIn(provider: .google, from: viewController) { result in
    switch result {
    case .success(let session):
        print(session.accessToken ?? "")
    case .failure(let error):
        print(error.localizedDescription)
    }
}

SocialLoginSDK.signIn(provider: .apple, from: viewController) { result in
    // handle result
}

SocialLoginSDK.signIn(provider: .facebook, from: viewController) { result in
    // handle result
}
```

### 8. Host-owned session storage

The SDK does **not** persist business tokens. After `signIn` / `signInWithEmail` / `completeEmailSignUp`, save the returned `SocialLoginSession` yourself (Keychain recommended in production). On cold start, load your store after `setup`, then optionally call `refreshToken` when access expiry is past.

```swift
SocialLoginSDK.signIn(provider: .google, from: viewController) { result in
    if case .success(let session) = result {
        MySessionStore.save(session) // host implementation
    }
}

SocialLoginSDK.refreshToken(storedRefreshToken) { result in
    if case .success(let tokens) = result, let session = MySessionStore.load() {
        MySessionStore.save(session.applying(tokens))
    }
}

SocialLoginSDK.signOut(accessToken: storedSession.accessToken)
MySessionStore.clear()
```

`signOut(accessToken:)` calls `POST /auth/sign_out` when a token is provided, then clears provider SDK sessions. It does not touch host storage.

## Environments

Prefer Info.plist for gateway **Base URL** and **`X-Client-Id`**. Pass only `environment` at `setup` time. The SDK does not hardcode Dev/Prod endpoints or client IDs.

Optional `requestTimeoutSeconds` on `BackendConfiguration` overrides each appauth HTTP request timeout (seconds). When omitted (including Info.plist-only backend setup), the system / `URLSession` default applies (typically 60s for `URLSession.shared`).

| Setting | Staging (Dev) | Production |
|---------|---------------|------------|
| `environment` | `.staging` | `.production` |
| Info.plist Base URL | `SocialLoginStagingBaseURL` | `SocialLoginProductionBaseURL` |
| Info.plist Client ID | `SocialLoginClientID` (or `SocialLoginStagingClientID`) | `SocialLoginClientID` (or `SocialLoginProductionClientID`) |
| Google / Facebook client IDs | Info.plist only (`GIDClientID`, `GIDServerClientID`, `FacebookAppID`, `FacebookClientToken`) | same keys |

For full environment isolation (different URL schemes per client), use separate Xcode build configurations and Info.plist files.

## Google Native App vs Web Sign-In

The SDK delegates authorization to **Google Sign-In iOS SDK**. It automatically uses the Google app when available, otherwise falls back to `ASWebAuthenticationSession` web sign-in.

## Facebook Login Notes

- Always uses **Limited Login** (`LoginTracking.limited`). App Tracking Transparency (ATT) is not required.
- Returns a Facebook **AuthenticationToken** (OIDC JWT), which is sent to the backend as `id_token`.
- The social `raw_nonce` is passed into `LoginConfiguration` and also included in the login body.
- Default permissions: `public_profile` and `email`.
- Email requires the `email` permission and may need app review for production users.
- Graph API is not available with Limited Login credentials.
- If the Facebook app is not installed, the SDK falls back to Safari/web authorization.
- `signOut(accessToken:)` clears the Facebook session via `LoginManager.logOut()`.

## Apple Sign In Notes

- Requests **fullName** and **email** by default.
- Email and full name are only guaranteed on the **first** authorization for a given Apple ID.
- Apple does not provide an avatar URL.
- `signOut(accessToken:)` does not revoke Apple credentials on Apple's side.

## appauth Social Login v3.0 Integration

### Flow

1. `GET /auth/social/nonce` with headers `X-Client-Id`, `X-Device-Id`, `X-Request-Id` → `raw_nonce`
2. Provider sign-in:
   - **Google**: inject `raw_nonce` into Google Sign-In; use `googleServerClientID` as `serverClientID`
   - **Apple**: pass `SHA256(raw_nonce)` hex to `ASAuthorizationAppleIDRequest.nonce`; POST body still uses plaintext `nonce`
   - **Facebook**: Limited Login — inject `raw_nonce` into `LoginConfiguration`; POST body also sends plaintext `nonce`
3. `POST /auth/social/sign_in` with `{ login_type, id_token, nonce, user_name? }`
4. Host receives `SocialLoginSession` and persists tokens / profile as needed

### Provider-specific body mapping

| Provider | `id_token` field | `nonce` | `user_name` |
|----------|------------------|---------|-------------|
| Google | Google OIDC JWT | raw_nonce | from Google profile when available |
| Apple | Apple identity token JWT | raw_nonce (plaintext) | first authorization only (`Given Family`) |
| Facebook | Facebook Limited Login **AuthenticationToken** (OIDC JWT) | raw_nonce (also passed into FB SDK) | from Profile / token claims when available |

### Required configuration

Backend (Info.plist, selected by `environment`):

- `SocialLoginStagingBaseURL` / `SocialLoginProductionBaseURL`: gateway URL with `/appauth/` suffix
- `SocialLoginClientID`: value for the `X-Client-Id` header (optional per-env: `SocialLoginStagingClientID` / `SocialLoginProductionClientID`)
- Or pass explicit `BackendConfiguration` to override plist
- `X-Device-Id`: generated automatically and persisted in Keychain
- `X-Request-Id`: UUID v4, generated fresh for every HTTP request (including retries)

API paths (`/auth/social/nonce`, `/auth/social/sign_in`, `/auth/sign_out`, `/auth/refresh_token`, email/password routes) are fixed inside the SDK. Hosts only configure gateway `baseURL` and `clientID`.

Provider credentials are read **only** from the host Info.plist:

- `GIDClientID`: iOS client ID
- `GIDServerClientID`: Web client ID (aligns ID token `aud` with backend validation)
- `FacebookAppID` / `FacebookClientToken`: Meta app credentials
- Reversed Google client ID and `fb{APP_ID}` URL schemes remain required in Info.plist for OAuth callbacks

### Backend error codes

The SDK maps these common appauth business codes to typed errors:

| Code | SDK error |
|------|-----------|
| 40001 | `accessTokenInvalid` — call `refreshToken` |
| 40002 | `invalidRequest` — parameter validation failed |
| 44201 | `clientInvalid` |
| 44202 | `loginMethodNotAllowed` |
| 44203 | `userNotFound` |
| 44204 | `invalidPassword` (may include `existsLoginTypes` from error `body`) |
| 44205 | `emailAlreadyRegistered` (may include `existsLoginTypes` from error `body`) |
| 44206 | `registrationNotAllowed` |
| 44207 | `oauthTokenInvalid` |
| 44208 | `oauthEmailConflict` |
| 44209 | `refreshTokenInvalid` |
| 44211 | `rateLimited` — optional `resendAfterSec` / `lockRemainingSec` / `retryAfterSec` from error `body` |
| 44214 | `emailCodeInvalid` |
| 44219 | `passwordPolicyViolation` |
| 44221 | `oauthNonceInvalid` — restart from fetching a new nonce |
| 44222 | `oauthAudienceMismatch` |
| 44223 | `emailCodeExpired` |
| 44224 | `emailCodeAlreadyUsed` |
| 44226 | `registrationAutoLoginFailed` — account created but auto-login failed; navigate like `emailAlreadyRegistered` (prompt `signInWithEmail`) |

Unknown / non-`URLError` transport failures map to `backendRequestFailed(statusCode:code:message:)`. For `URLError`, `.timedOut` maps to `timeOut`; all other codes map to `networkError`. Known business codes map to the typed cases above.

### Session ownership

| Layer | Responsibility |
|-------|----------------|
| Host | Persist / restore / clear `access_token`, `refresh_token`, profile, expiry; decide when to refresh |
| SDK | Provider OAuth + appauth HTTP; returns `SocialLoginSession`; accepts tokens as API arguments |
| SDK Device ID Keychain | Only `X-Device-Id` (not business session) |

Provider tokens are never stored by the SDK.

## Backend Token Exchange

Backend exchange is required. The login body looks like:

**Google**

```json
{
  "login_type": "google",
  "id_token": "<google oidc jwt>",
  "nonce": "<raw_nonce>"
}
```

**Apple**

```json
{
  "login_type": "apple",
  "id_token": "<apple identity token>",
  "nonce": "<raw_nonce>",
  "user_name": "Given Family"
}
```

**Facebook** (Limited Login)

```json
{
  "login_type": "facebook",
  "id_token": "<facebook authentication token jwt>",
  "nonce": "<raw_nonce>"
}
```

**Expected response**

```json
{
  "access_token": "...",
  "refresh_token": "...",
  "access_token_expin": 3600,
  "refresh_token_expin": 2592000,
  "is_new_user": false,
  "user_profile": {
    "user_id": "...",
    "primary_email": "...",
    "first_name": "...",
    "last_name": "...",
    "created_at": 0,
    "last_login_at": 0,
    "updated_at": 0,
    "providers": [
      {
        "provider": "google",
        "provider_user_id": "...",
        "provider_email": "...",
        "provider_first_name": "...",
        "provider_last_name": "...",
        "created_at": 0,
        "updated_at": 0
      }
    ]
  }
}
```

## Demo App

The Demo app includes:

- Staging / Production environment switcher
- Google, Facebook, and Apple sign-in buttons
- Refresh session / sign-out
- Scrollable session result panel (v2 profile fields)
- **Email** tab: networking-only smoke tests for register / sign-in / forgot / change password (not a product UI)

Replace `YOUR_FACEBOOK_APP_ID` and `YOUR_FACEBOOK_CLIENT_TOKEN` in `Info.plist` with real Meta credentials to test Facebook login.

## Provider Status

| Provider | Status |
|----------|--------|
| Google | Implemented |
| Apple | Implemented |
| Facebook | Implemented (Limited Login / AuthenticationToken JWT) |

## Google Cloud Console Checklist

1. Create an iOS OAuth client for your app Bundle ID.
2. Copy the client ID into `GIDClientID` (and `GIDServerClientID` for backend exchange) in Info.plist.
3. Add the reversed client ID as a URL scheme in Info.plist.
4. Repeat for staging and production clients if needed.

## Apple Developer Checklist

1. Enable **Sign in with Apple** on the App ID matching your Bundle ID.
2. Add **Sign in with Apple** capability in Xcode.
3. Commit entitlements with `com.apple.developer.applesignin = Default`.
4. Refresh provisioning profiles after enabling the capability.
5. Test on device or simulator with a signed-in Apple ID.

## Meta for Developers Checklist

1. Create a Meta app and enable **Facebook Login**.
2. Copy **App ID** and **Client Token** into Info.plist (`FacebookAppID`, `FacebookClientToken`).
3. Register your iOS Bundle ID under the iOS platform settings.
4. Add `fb{APP_ID}` as a URL scheme in Info.plist.
5. Add `fbapi`, `fbauth`, `fbauth2`, and `fb-messenger-share-api` to `LSApplicationQueriesSchemes`.
6. Main app: call Facebook `ApplicationDelegate.application(_:didFinishLaunchingWithOptions:)` (if using Facebook), then `SocialLoginSDK.setup(configuration:)`. Extensions: `setup(configuration:)` only.
7. Add test users while the app is in development mode.
