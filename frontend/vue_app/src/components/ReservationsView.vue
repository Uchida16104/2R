<script setup lang="ts">
import { ref } from 'vue'
import ReservationList from '@/components/ReservationList.vue'
import ReservationForm from '@/components/ReservationForm.vue'

const tab = ref<'all' | 'pending' | 'confirmed'>('all')
const showForm = ref(false)
</script>

<template>
  <div class="max-w-4xl mx-auto space-y-6">
    <div class="flex items-center justify-between">
      <h1 class="text-2xl font-extrabold" style="color: var(--text);">Reservations</h1>
      <button @click="showForm = !showForm" class="btn-primary">
        {{ showForm ? 'Hide Form' : '+ New' }}
      </button>
    </div>

    <div v-if="showForm" class="animate-in">
      <ReservationForm />
    </div>

    <div class="flex gap-2 border-b" style="border-color: var(--border);">
      <button
        v-for="t in (['all', 'confirmed', 'pending'] as const)"
        :key="t"
        @click="tab = t"
        class="px-4 py-2 text-sm font-semibold capitalize transition-colors duration-150"
        :style="{
          color: tab === t ? 'var(--accent-hi)' : 'var(--muted)',
          borderBottom: tab === t ? '2px solid var(--accent-hi)' : '2px solid transparent',
          marginBottom: '-1px',
        }"
      >
        {{ t }}
      </button>
    </div>

    <ReservationList :filter="tab" />
  </div>
</template>
