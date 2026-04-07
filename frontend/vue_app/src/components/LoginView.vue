<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const auth = useAuthStore()
const router = useRouter()

const email    = ref('')
const password = ref('')
const error    = ref<string | null>(null)
const loading  = ref(false)

async function submit() {
  error.value = null
  loading.value = true
  try {
    await auth.login(email.value, password.value)
    router.push({ name: 'dashboard' })
  } catch (e: unknown) {
    error.value = e instanceof Error ? e.message : 'Login failed'
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="min-h-screen flex items-center justify-center p-8" style="background: var(--bg);">
    <div class="w-full max-w-sm">
      <div class="mb-10 text-center">
        <div class="text-5xl font-extrabold tracking-tighter mb-2" style="color: var(--accent-hi);">2R</div>
        <div class="text-sm" style="color: var(--muted);">Room Reservation System</div>
      </div>

      <div class="card space-y-4">
        <div>
          <label class="label">Email</label>
          <input v-model="email" type="email" class="input" placeholder="you@example.com" @keydown.enter="submit" />
        </div>
        <div>
          <label class="label">Password</label>
          <input v-model="password" type="password" class="input" placeholder="••••••••" @keydown.enter="submit" />
        </div>

        <div v-if="error" class="text-sm px-3 py-2 rounded" style="background: rgba(244,91,91,0.1); color: var(--danger);">
          {{ error }}
        </div>

        <button
          @click="submit"
          :disabled="loading"
          class="btn-primary w-full justify-center"
          :style="{ opacity: loading ? 0.6 : 1 }"
        >
          {{ loading ? 'Signing in…' : 'Sign in' }}
        </button>
      </div>
    </div>
  </div>
</template>
