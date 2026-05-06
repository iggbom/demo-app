import { useEffect, useState } from 'react'

export function ItemList({ accessToken }) {
  const [items, setItems]   = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError]   = useState(null)

  useEffect(() => {
    if (!accessToken) return

    fetch('/api/items', {
      headers: { Authorization: `Bearer ${accessToken}` }
    })
      .then(res => {
        if (!res.ok) throw new Error(`${res.status} ${res.statusText}`)
        return res.json()
      })
      .then(data => { setItems(data); setLoading(false) })
      .catch(err => { setError(err.message); setLoading(false) })
  }, [accessToken])

  if (loading) return <p>Loading items…</p>
  if (error)   return <p style={{ color: 'red' }}>Error: {error}</p>

  return (
    <table>
      <thead>
        <tr>
          <th>ID</th>
          <th>Name</th>
          <th>Description</th>
        </tr>
      </thead>
      <tbody>
        {items.map(item => (
          <tr key={item.id}>
            <td>{item.id}</td>
            <td>{item.name}</td>
            <td>{item.description}</td>
          </tr>
        ))}
      </tbody>
    </table>
  )
}
