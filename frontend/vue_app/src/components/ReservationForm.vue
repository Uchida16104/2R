<script setup lang="ts">
import { ref } from 'vue'
import { useReservationStore } from '@/stores/reservation'

const store = useReservationStore()

const form = ref({
  room_id:    '',
  title:      '',
  start_time: '',
  end_time:   '',
})

const submitting = ref(false)
const formError = ref<string | null>(null)
const success = ref(false)

async function submit() {
  formError.value = null
  success.value = false

  if (!form.value.room_id || !form.value.title || !form.value.start_time || !form.value.end_time) {
    formError.value = 'All fields are required.'
    return
  }

  if (new Date(form.value.end_time) <= new Date(form.value.start_time)) {
    formError.value = 'End time must be after start time.'
    return
  }

  submitting.value = true
  try {
    await store.create(form.value)
    success.value = true
    form.value = { room_id: '', title: '', start_time: '', end_time: '' }
    setTimeout(() => { success.value = false }, 3000)
  } catch (e: unknown) {
    formError.value = e instanceof Error ? e.message : 'Booking failed.'
  } finally {
    submitting.value = false
  }
}
</script>

<template>
  <div class="card animate-in">
    <h2 class="text-lg font-bold mb-6" style="color: var(--text);">New Reservation</h2>

    <div class="space-y-4">
      <div>
        <label class="label">Room ID</label>
        <input v-model="form.room_id" class="input" placeholder="e.g. CONF-A1" />
      </div>

      <div>
        <label class="label">Title</label>
        <input v-model="form.title" class="input" placeholder="Meeting title" />
      </div>

      <div class="grid grid-cols-2 gap-4">
        <div>
          <label class="label">Start</label>
          <input v-model="form.start_time" type="datetime-local" class="input" />
        </div>
        <div>
          <label class="label">End</label>
          <input v-model="form.end_time" type="datetime-local" class="input" />
        </div>
      </div>

      <div v-if="formError" class="text-sm px-3 py-2 rounded" style="background: rgba(244,91,91,0.1); color: var(--danger);">
        {{ formError }}
      </div>

      <div v-if="success" class="text-sm px-3 py-2 rounded animate-in" style="background: rgba(34,211,160,0.1); color: var(--success);">
        Reservation created{{ store.isOnline ? '.' : ' (queued for sync when online).' }}
      </div>

      <button
        @click="submit"
        :disabled="submitting"
        class="btn-primary w-full justify-center"
        :style="{ opacity: submitting ? 0.6 : 1 }"
      >
        {{ submitting ? 'Booking…' : 'Book Room' }}
      </button>
    </div>
  </div>
</template>
