<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { api } from '@/lib/api'
import dayjs from 'dayjs'

interface UsageStat {
  room_id:   string
  count:     number
  avg_hours: number
}

interface ForecastPoint {
  date:     string
  predicted: number
}

const from = ref(dayjs().subtract(30, 'day').format('YYYY-MM-DD'))
const to   = ref(dayjs().format('YYYY-MM-DD'))
const usage = ref<UsageStat[]>([])
const forecast = ref<ForecastPoint[]>([])
const loadingUsage    = ref(false)
const loadingForecast = ref(false)
const usageError      = ref<string | null>(null)
const forecastError   = ref<string | null>(null)

async function loadUsage() {
  loadingUsage.value = true
  usageError.value = null
  try {
    usage.value = await api.get<UsageStat[]>(`/analytics/usage?from=${from.value}&to=${to.value}`)
  } catch (e: unknown) {
    usageError.value = 'Analytics service unavailable'
    usage.value = []
  } finally {
    loadingUsage.value = false
  }
}

async function loadForecast() {
  loadingForecast.value = true
  forecastError.value = null
  try {
    forecast.value = await api.get<ForecastPoint[]>('/analytics/forecast?room_id=ALL&days=14')
  } catch (e: unknown) {
    forecastError.value = 'Forecast service unavailable'
    forecast.value = []
  } finally {
    loadingForecast.value = false
  }
}

onMounted(() => {
  loadUsage()
  loadForecast()
})

const maxCount = () => Math.max(...usage.value.map((u) => u.count), 1)
</script>

<template>
  <div class="max-w-4xl mx-auto space-y-8">
    <div class="flex items-center justify-between">
      <h1 class="text-2xl font-extrabold" style="color: var(--text);">Analytics</h1>
      <div class="flex items-center gap-2">
        <input v-model="from" type="date" class="input" style="width: auto;" />
        <span style="color: var(--muted);">→</span>
        <input v-model="to"   type="date" class="input" style="width: auto;" />
        <button @click="loadUsage" class="btn-primary">Apply</button>
      </div>
    </div>

    <div class="card">
      <h2 class="text-sm font-bold uppercase tracking-widest mb-6" style="color: var(--muted);">Room Usage</h2>
      <div v-if="loadingUsage" class="text-sm" style="color: var(--muted);">Loading…</div>
      <div v-else-if="usageError" class="text-sm" style="color: var(--warning);">{{ usageError }}</div>
      <div v-else-if="!usage.length" class="text-sm" style="color: var(--muted);">No data for selected period.</div>
      <div v-else class="space-y-3">
        <div v-for="u in usage" :key="u.room_id" class="flex items-center gap-3">
          <span class="font-mono text-xs w-20 flex-shrink-0" style="color: var(--muted);">{{ u.room_id }}</span>
          <div class="flex-1 h-2 rounded-full overflow-hidden" style="background: var(--border);">
            <div
              class="h-2 rounded-full transition-all duration-500"
              style="background: var(--accent);"
              :style="{ width: `${(u.count / maxCount()) * 100}%` }"
            />
          </div>
          <span class="font-mono text-xs w-10 text-right" style="color: var(--accent-hi);">{{ u.count }}</span>
          <span class="font-mono text-xs w-16 text-right" style="color: var(--muted);">{{ u.avg_hours.toFixed(1) }}h avg</span>
        </div>
      </div>
    </div>

    <div class="card">
      <h2 class="text-sm font-bold uppercase tracking-widest mb-6" style="color: var(--muted);">14-Day Forecast</h2>
      <div v-if="loadingForecast" class="text-sm" style="color: var(--muted);">Loading…</div>
      <div v-else-if="forecastError" class="text-sm" style="color: var(--warning);">{{ forecastError }}</div>
      <div v-else-if="!forecast.length" class="text-sm" style="color: var(--muted);">No forecast available.</div>
      <div v-else class="flex items-end gap-1 h-24">
        <div
          v-for="pt in forecast"
          :key="pt.date"
          class="flex-1 rounded-t transition-all duration-300"
          :style="{
            height: `${(pt.predicted / Math.max(...forecast.map(f => f.predicted), 1)) * 100}%`,
            background: 'var(--accent)',
            opacity: 0.7,
            minHeight: '4px',
          }"
          :title="`${pt.date}: ${pt.predicted}`"
        />
      </div>
      <div class="flex justify-between mt-2">
        <span class="text-xs font-mono" style="color: var(--muted);">{{ forecast[0]?.date }}</span>
        <span class="text-xs font-mono" style="color: var(--muted);">{{ forecast[forecast.length - 1]?.date }}</span>
      </div>
    </div>
  </div>
</template>
