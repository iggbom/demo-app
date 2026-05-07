import { UserManager, WebStorageStateStore } from 'oidc-client-ts'

// Lazily initialised so window.env is read after config.js has executed.
let _userManager = null

export function getUserManager() {
  if (_userManager) return _userManager

  // Prefer runtime config injected by nginx (window.env), fall back to Vite build-time vars.
  const env = window.env ?? {}

  _userManager = new UserManager({
    authority:     env.AUTHORITY     ?? import.meta.env.VITE_AUTHORITY,
    client_id:     env.CLIENT_ID     ?? import.meta.env.VITE_CLIENT_ID,
    client_secret: env.CLIENT_SECRET ?? import.meta.env.VITE_CLIENT_SECRET,
    redirect_uri:  `${window.location.origin}/callback`,
    // Route the token exchange through nginx (same origin) to avoid CORS issues
    // with the Authorization: Basic header used for confidential client auth
    metadataSeed: {
      token_endpoint: `${window.location.origin}/token`,
    },
    post_logout_redirect_uri: window.location.origin,
    response_type:     'code',
    scope:             'openid profile read:items',
    // PKCE is used by default in oidc-client-ts
    userStore:         new WebStorageStateStore({ store: window.sessionStorage }),
  })

  return _userManager
}
