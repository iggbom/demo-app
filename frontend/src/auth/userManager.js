import { UserManager, WebStorageStateStore } from 'oidc-client-ts'

const settings = {
  authority:     import.meta.env.VITE_AUTHORITY,
  client_id:     import.meta.env.VITE_CLIENT_ID,
  client_secret: import.meta.env.VITE_CLIENT_SECRET,
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
}

export const userManager = new UserManager(settings)
