<script setup lang="ts">
import { computed } from 'vue'
import { useReservationStore } from '@/stores/reservation'
import { useAuthStore } from '@/stores/auth'
import ReservationForm from '@/components/ReservationForm.vue'
import ReservationList from '@/components/ReservationList.vue'
import dayjs from 'dayjs'

const store = useReservationStore()
const auth  = useAuthStore()

const todayCount = computed(() =>
  store.items.filter((r) =>
    dayjs(r.start_time).isSame(dayjs(), 'day') && r.status === 'confirmed'
  ).length
)

const stats = computed(() => [
  { label: 'Total',     value: store.items.length,                                 color: 'var(--accent-hi)' },
  { label: 'Today',     value: todayCount.value,                                   color: 'var(--success)'   },
  { label: 'Pending',   value: store.items.filter((r) => !r.synced).length,        color: 'var(--warning)'   },
  { label: 'Cancelled', value: store.items.filter((r) => r.status === 'cancelled').length, color: 'var(--muted)'  },
])
</script>

<template>
  <div class="max-w-5xl mx-auto space-y-8">
    <div>
      <h1 class="text-3xl font-extrabold tracking-tight mb-1" style="color: var(--text);">
        Welcome, {{ auth.user?.name ?? 'User' }}
      </h1>
      <p class="text-sm" style="color: var(--muted);">{{ dayjs().format('dddd, MMMM D YYYY') }}</p>
    </div>

    <div class="grid grid-cols-4 gap-4">
      <div v-for="s in stats" :key="s.label" class="card text-center">
        <div class="text-3xl font-extrabold font-mono mb-1" :style="{ color: s.color }">{{ s.value }}</div>
        <div class="text-xs uppercase tracking-widest" style="color: var(--muted);">{{ s.label }}</div>
      </div>
    </div>

    <div class="grid grid-cols-5 gap-6">
      <div class="col-span-2">
        <ReservationForm />
      </div>
      <div class="col-span-3">
        <h2 class="text-sm font-bold uppercase tracking-widest mb-4" style="color: var(--muted);">Recent</h2>
        <ReservationList filter="all" />
      </div>
    </div>
  </div>
</template>
