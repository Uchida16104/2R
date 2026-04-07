<script setup lang="ts">
import { useReservationStore } from '@/stores/reservation'

const store = useReservationStore()
</script>

<template>
  <div class="flex items-center gap-2">
    <span
      class="w-2 h-2 rounded-full"
      :style="{ background: store.isOnline ? 'var(--success)' : 'var(--danger)' }"
    />
    <span class="text-xs font-mono" style="color: var(--muted);">
      {{ store.isOnline ? 'online' : 'offline — changes queued' }}
    </span>
  </div>
</template>
