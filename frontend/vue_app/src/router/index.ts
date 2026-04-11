import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import DashboardView from '@/components/DashboardView.vue'
import LoginView from '@/components/LoginView.vue'
import ReservationsView from '@/components/ReservationsView.vue'
import AvailabilityView from '@/components/AvailabilityView.vue'
import AnalyticsView from '@/components/AnalyticsView.vue'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/',
      name: 'dashboard',
      component: DashboardView,
      meta: { requiresAuth: true },
    },
    {
      path: '/login',
      name: 'login',
      component: LoginView,
      meta: { requiresAuth: false },
    },
    {
      path: '/reservations',
      name: 'reservations',
      component: ReservationsView,
      meta: { requiresAuth: true },
    },
    {
      path: '/availability',
      name: 'availability',
      component: AvailabilityView,
      meta: { requiresAuth: true },
    },
    {
      path: '/analytics',
      name: 'analytics',
      component: AnalyticsView,
      meta: { requiresAuth: true },
    },
  ],
})

router.beforeEach((to) => {
  const auth = useAuthStore()
  if (to.meta.requiresAuth && !auth.isAuthenticated) {
    return { name: 'login' }
  }
  if (to.name === 'login' && auth.isAuthenticated) {
    return { name: 'dashboard' }
  }
})

export default router
