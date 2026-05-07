import { useEffect, useState } from 'react'
import { getUserManager } from './auth/userManager'
import { ItemList } from './components/ItemList'

export default function App() {
  const [user, setUser] = useState(null)

  // On mount: check for existing session or handle the callback redirect
  useEffect(() => {
    const path = window.location.pathname

    if (path === '/callback') {
      getUserManager().signinRedirectCallback()
        .then(u => {
          setUser(u)
          window.history.replaceState({}, '', '/')
        })
        .catch(err => console.error('Callback error:', err))
    } else {
      getUserManager().getUser().then(u => {
        if (u && !u.expired) setUser(u)
      })
    }
  }, [])

  const login  = () => getUserManager().signinRedirect()
  const logout = () => getUserManager().signoutRedirect()

  return (
    <main style={{ fontFamily: 'sans-serif', maxWidth: 800, margin: '2rem auto', padding: '0 1rem' }}>
      <h1>Demo App</h1>

      {user ? (
        <>
          <p>Signed in as <strong>{user.profile.sub}</strong></p>
          <button onClick={logout}>Sign out</button>
          <hr />
          <h2>Items</h2>
          <ItemList accessToken={user.access_token} />
        </>
      ) : (
        <button onClick={login}>Sign in</button>
      )}
    </main>
  )
}
