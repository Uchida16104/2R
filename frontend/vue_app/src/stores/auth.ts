import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

interface User {
  id: number
  name: string
  email: string
}

export const useAuthStore = defineStore('auth', () => {
  const token = ref<string | null>(localStorage.getItem('2r_token'))
  const user = ref<User | null>(JSON.parse(localStorage.getItem('2r_user') ?? 'null'))

  const isAuthenticated = computed(() => !!token.value)

  async function login(email: string, password: string): Promise<void> {
    const response = await fetch('/api/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password }),
    })

    if (!response.ok) {
      const data = await response.json()
      throw new Error(data.message ?? 'Login failed')
    }

    const data = await response.json()
    token.value = data.token
    user.value = data.user
    localStorage.setItem('2r_token', data.token)
    localStorage.setItem('2r_user', JSON.stringify(data.user))
  }

  async function logout(): Promise<void> {
    try {
      await fetch('/api/auth/logout', {
        method: 'POST',
        headers: { Authorization: `Bearer ${token.value}` },
      })
    } finally {
      token.value = null
      user.value = null
      localStorage.removeItem('2r_token')
      localStorage.removeItem('2r_user')
    }
  }

  function getAuthHeaders(): Record<string, string> {
    return {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token.value}`,
    }
  }

  return { token, user, isAuthenticated, login, logout, getAuthHeaders }
})
