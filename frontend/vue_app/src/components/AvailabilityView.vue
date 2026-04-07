<script setup lang="ts">
import { ref, watch } from 'vue'
import { api } from '@/lib/api'
import dayjs from 'dayjs'

const selectedDate = ref(dayjs().format('YYYY-MM-DD'))
const slots = ref<{ room_id: string; slots: { start: string; end: string; available: boolean }[] }[]>([])
const loading = ref(false)
const error = ref<string | null>(null)

async function load() {
  loading.value = true
  error.value = null
  try {
    const data = await api.get<typeof slots.value>(`/availability?date=${selectedDate.value}`)
    slots.value = data ?? []
  } catch (e: unknown) {
    error.value = e instanceof Error ? e.message : 'Failed to load availability'
  } finally {
    loading.value = false
  }
}

watch(selectedDate, load, { immediate: true })
</script>

<template>
  <div class="max-w-4xl mx-auto space-y-6">
    <div class="flex items-center justify-between">
      <h1 class="text-2xl font-extrabold" style="color: var(--text);">Availability</h1>
      <input
        v-model="selectedDate"
        type="date"
        class="input"
        style="width: auto;"
      />
    </div>

    <div v-if="loading" class="text-sm" style="color: var(--muted);">Loading…</div>
    <div v-else-if="error" class="text-sm px-3 py-2 rounded" style="background: rgba(244,91,91,0.1); color: var(--danger);">
      {{ error }}
    </div>
    <div v-else-if="!slots.length" class="text-sm py-12 text-center" style="color: var(--muted);">
      No availability data for {{ selectedDate }}.
    </div>

    <div v-else class="space-y-4">
      <div v-for="room in slots" :key="room.room_id" class="card">
        <div class="flex items-center gap-3 mb-4">
          <span class="badge badge-accent font-mono">{{ room.room_id }}</span>
          <span class="text-xs" style="color: var(--muted);">{{ room.slots.length }} bookings</span>
        </div>

        <div v-if="room.slots.length" class="space-y-2">
          <div
            v-for="(slot, i) in room.slots"
            :key="i"
            class="flex items-center gap-3 text-xs font-mono p-2 rounded"
            style="background: rgba(244,91,91,0.06); color: var(--danger);"
          >
            <span class="w-2 h-2 rounded-full flex-shrink-0" style="background: var(--danger);"></span>
            {{ dayjs(slot.start).format('HH:mm') }} – {{ dayjs(slot.end).format('HH:mm') }}
          </div>
        </div>
        <div v-else class="text-xs" style="color: var(--success);">Available all day</div>
      </div>
    </div>
  </div>
</template>
