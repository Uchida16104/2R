<script setup lang="ts">
import { computed } from 'vue'
import { useReservationStore, type Reservation } from '@/stores/reservation'
import dayjs from 'dayjs'

const store = useReservationStore()

const props = defineProps<{
  filter?: 'all' | 'pending' | 'confirmed'
}>()

const filtered = computed<Reservation[]>(() => {
  if (!props.filter || props.filter === 'all') return store.items
  if (props.filter === 'pending') return store.items.filter((r) => !r.synced)
  return store.items.filter((r) => r.status === 'confirmed')
})

function fmt(dt: string) {
  return dayjs(dt).format('MMM D, YYYY HH:mm')
}

async function cancel(r: Reservation) {
  await store.remove(r.id!, r.client_id)
}
</script>

<template>
  <div>
    <div v-if="store.loading" class="text-sm" style="color: var(--muted);">Loading…</div>

    <div v-else-if="!filtered.length" class="text-sm py-8 text-center" style="color: var(--muted);">
      No reservations found.
    </div>

    <ul v-else class="space-y-2">
      <li
        v-for="r in filtered"
        :key="r.client_id"
        class="card animate-in flex items-start justify-between gap-4"
        style="padding: 1rem 1.25rem;"
      >
        <div class="flex-1 min-w-0">
          <div class="flex items-center gap-2 mb-1">
            <span class="font-bold text-sm truncate" style="color: var(--text);">{{ r.title }}</span>
            <span class="badge" :class="r.synced ? 'badge-success' : 'badge-warning'">
              {{ r.synced ? 'synced' : 'pending' }}
            </span>
            <span class="badge badge-accent font-mono">{{ r.room_id }}</span>
          </div>
          <div class="text-xs font-mono" style="color: var(--muted);">
            {{ fmt(r.start_time) }} → {{ fmt(r.end_time) }}
          </div>
        </div>
        <button
          v-if="r.status !== 'cancelled'"
          @click="cancel(r)"
          class="btn-danger text-xs flex-shrink-0"
          style="padding: 0.25rem 0.75rem;"
        >
          Cancel
        </button>
        <span v-else class="badge badge-danger flex-shrink-0">cancelled</span>
      </li>
    </ul>
  </div>
</template>
