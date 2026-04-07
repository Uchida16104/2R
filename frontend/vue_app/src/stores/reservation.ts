import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { v4 as uuidv4 } from 'uuid'
import { useAuthStore } from './auth'
import { getDB } from '@/lib/pouchdb'

export interface Reservation {
  id?: number
  client_id: string
  room_id: string
  title: string
  start_time: string
  end_time: string
  status: 'confirmed' | 'pending' | 'cancelled'
  synced: boolean
}

export const useReservationStore = defineStore('reservation', () => {
  const auth = useAuthStore()
  const items = ref<Reservation[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)
  const isOnline = ref(navigator.onLine)

  window.addEventListener('online', () => {
    isOnline.value = true
    syncOfflineQueue()
  })
  window.addEventListener('offline', () => {
    isOnline.value = false
  })

  const pending = computed(() => items.value.filter((r) => !r.synced))

  async function fetchAll(): Promise<void> {
    loading.value = true
    error.value = null

    if (!isOnline.value) {
      await loadFromLocal()
      loading.value = false
      return
    }

    try {
      const response = await fetch('/api/reservations', {
        headers: auth.getAuthHeaders(),
      })
      if (!response.ok) throw new Error('Failed to fetch reservations')
      const data = await response.json()
      items.value = (data.data ?? data).map((r: Reservation) => ({ ...r, synced: true }))
      await persistToLocal(items.value)
    } catch {
      await loadFromLocal()
    } finally {
      loading.value = false
    }
  }

  async function create(payload: Omit<Reservation, 'id' | 'client_id' | 'status' | 'synced'>): Promise<void> {
    const clientId = uuidv4()
    const local: Reservation = {
      ...payload,
      client_id: clientId,
      status: 'pending',
      synced: false,
    }

    items.value.unshift(local)
    await saveToLocal(local)

    if (!isOnline.value) return

    try {
      const response = await fetch('/api/reservations', {
        method: 'POST',
        headers: auth.getAuthHeaders(),
        body: JSON.stringify({ ...payload, client_id: clientId }),
      })

      if (!response.ok) {
        const err = await response.json()
        throw new Error(err.error ?? 'Failed to create reservation')
      }

      const saved: Reservation = await response.json()
      const idx = items.value.findIndex((r) => r.client_id === clientId)
      if (idx !== -1) {
        items.value[idx] = { ...saved, synced: true }
        await saveToLocal(items.value[idx])
      }
    } catch (e: unknown) {
      error.value = e instanceof Error ? e.message : 'Unknown error'
    }
  }

  async function remove(id: number, clientId: string): Promise<void> {
    items.value = items.value.filter((r) => r.id !== id && r.client_id !== clientId)
    await deleteFromLocal(clientId)

    if (!isOnline.value || !id) return

    await fetch(`/api/reservations/${id}`, {
      method: 'DELETE',
      headers: auth.getAuthHeaders(),
    })
  }

  async function syncOfflineQueue(): Promise<void> {
    const unsynced = items.value.filter((r) => !r.synced)
    if (!unsynced.length) return

    try {
      const response = await fetch('/api/reservations/sync', {
        method: 'POST',
        headers: auth.getAuthHeaders(),
        body: JSON.stringify({
          records: unsynced.map((r) => ({
            client_id: r.client_id,
            room_id: r.room_id,
            title: r.title,
            start_time: r.start_time,
            end_time: r.end_time,
            client_ts: Date.now(),
          })),
        }),
      })

      if (!response.ok) return
      const { results } = await response.json()

      for (const result of results) {
        const idx = items.value.findIndex((r) => r.client_id === result.client_id)
        if (idx === -1) continue

        if (result.status === 'created' || result.status === 'already_exists') {
          items.value[idx] = {
            ...items.value[idx],
            id: result.id,
            status: 'confirmed',
            synced: true,
          }
          await saveToLocal(items.value[idx])
        } else if (result.status === 'conflict') {
          items.value[idx].status = 'cancelled'
          await saveToLocal(items.value[idx])
        }
      }
    } catch {
      // Sync will be retried on next online event
    }
  }

  async function loadFromLocal(): Promise<void> {
    const db = await getDB()
    const result = await db.allDocs({ include_docs: true })
    items.value = result.rows
      .map((r) => r.doc as unknown as Reservation)
      .filter(Boolean)
  }

  async function persistToLocal(records: Reservation[]): Promise<void> {
    const db = await getDB()
    for (const r of records) {
      await saveToLocal(r)
    }
  }

  async function saveToLocal(r: Reservation): Promise<void> {
    const db = await getDB()
    const docId = `reservation_${r.client_id}`
    try {
      const existing = await db.get(docId)
      await db.put({ ...existing, ...r, _id: docId })
    } catch {
      await db.put({ ...r, _id: docId })
    }
  }

  async function deleteFromLocal(clientId: string): Promise<void> {
    const db = await getDB()
    const docId = `reservation_${clientId}`
    try {
      const doc = await db.get(docId)
      await db.remove(doc)
    } catch {
      // Document not found — nothing to delete
    }
  }

  return { items, loading, error, isOnline, pending, fetchAll, create, remove, syncOfflineQueue }
})
