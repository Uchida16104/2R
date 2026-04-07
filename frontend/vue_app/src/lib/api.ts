import { useAuthStore } from '@/stores/auth'

const BASE = '/api'

async function request<T>(path: string, init: RequestInit = {}): Promise<T> {
  const auth = useAuthStore()
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(init.headers as Record<string, string> ?? {}),
  }

  if (auth.token) {
    headers['Authorization'] = `Bearer ${auth.token}`
  }

  const response = await fetch(`${BASE}${path}`, { ...init, headers })

  if (response.status === 401) {
    auth.logout()
    throw new Error('Unauthenticated')
  }

  if (!response.ok) {
    const body = await response.json().catch(() => ({ message: 'Request failed' }))
    throw new Error(body.message ?? body.error ?? 'Request failed')
  }

  if (response.status === 204) return undefined as T
  return response.json()
}

export const api = {
  get:    <T>(path: string)                          => request<T>(path, { method: 'GET' }),
  post:   <T>(path: string, body: unknown)           => request<T>(path, { method: 'POST',  body: JSON.stringify(body) }),
  put:    <T>(path: string, body: unknown)           => request<T>(path, { method: 'PUT',   body: JSON.stringify(body) }),
  delete: <T>(path: string)                          => request<T>(path, { method: 'DELETE' }),
}
