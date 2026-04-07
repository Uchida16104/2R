/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{vue,ts,tsx}'],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Syne', 'sans-serif'],
        mono: ['DM Mono', 'monospace'],
      },
      colors: {
        bg:        '#0a0a0f',
        surface:   '#111118',
        border:    '#1e1e2e',
        accent:    '#5b5ef4',
        'accent-hi': '#7b7ef8',
        success:   '#22d3a0',
        warning:   '#f4a135',
        danger:    '#f45b5b',
        muted:     '#6b6b80',
      },
    },
  },
  plugins: [],
}
