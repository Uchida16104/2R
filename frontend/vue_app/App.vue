<script setup lang="ts">
import { onMounted } from 'vue'
import { RouterView, RouterLink, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useReservationStore } from '@/stores/reservation'
import OfflineStatus from '@/components/OfflineStatus.vue'

const auth = useAuthStore()
const store = useReservationStore()
const router = useRouter()

async function logout() {
  await auth.logout()
  router.push({ name: 'login' })
}

onMounted(() => {
  if (auth.isAuthenticated) {
    store.fetchAll()
  }
})
</script>

<template>
  <div v-if="!auth.isAuthenticated">
    <RouterView />
  </div>

  <div v-else class="flex min-h-screen" style="background: var(--bg);">
    <aside class="w-56 flex-shrink-0 flex flex-col border-r" style="border-color: var(--border); background: var(--surface);">
      <div class="px-6 py-5 border-b" style="border-color: var(--border);">
        <span class="text-xl font-extrabold tracking-tight" style="color: var(--accent-hi);">2R</span>
        <span class="text-xs ml-2" style="color: var(--muted);">Room Reservation</span>
      </div>

      <nav class="flex-1 p-4 space-y-1">
        <RouterLink
          v-for="link in [
            { to: '/',              label: 'Dashboard',    icon: '⬡' },
            { to: '/reservations',  label: 'Reservations', icon: '◈' },
            { to: '/availability',  label: 'Availability', icon: '◉' },
            { to: '/analytics',     label: 'Analytics',    icon: '◎' },
          ]"
          :key="link.to"
          :to="link.to"
          class="flex items-center gap-3 px-3 py-2 rounded text-sm font-medium transition-all duration-150"
          :class="{ 'router-link-exact-active': $route.path === link.to }"
          style="color: var(--muted);"
          active-class="!text-white"
        >
          <span class="font-mono text-base">{{ link.icon }}</span>
          {{ link.label }}
        </RouterLink>
      </nav>

      <div class="p-4 border-t" style="border-color: var(--border);">
        <div class="text-xs mb-3 font-mono truncate" style="color: var(--muted);">
          {{ auth.user?.email }}
        </div>
        <button @click="logout" class="btn-ghost w-full justify-center text-xs">
          Sign out
        </button>
      </div>
    </aside>

    <main class="flex-1 flex flex-col min-h-screen overflow-hidden">
      <header class="h-12 border-b flex items-center justify-between px-6" style="border-color: var(--border);">
        <OfflineStatus />
        <div v-if="store.pending.length > 0" class="badge badge-warning">
          {{ store.pending.length }} pending sync
        </div>
      </header>

      <div class="flex-1 overflow-auto p-8">
        <RouterView />
      </div>
    </main>
  </div>
</template>

<style scoped>
.router-link-active {
  color: var(--text) !important;
  background: rgba(91, 94, 244, 0.1);
}
</style>
