export {}

declare global {
  interface Window {
    htmx: typeof import('htmx.org')
  }
}

export interface PaginatedResponse<T> {
  data:          T[]
  current_page:  number
  last_page:     number
  per_page:      number
  total:         number
}

export interface ApiError {
  message?: string
  error?:   string
  errors?:  Record<string, string[]>
}
