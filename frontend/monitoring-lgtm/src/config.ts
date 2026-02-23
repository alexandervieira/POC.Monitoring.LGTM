import { AppConfig } from './types'

// Carregar configuração do Firebase (gerado pelo Terraform)
const loadFirebaseConfig = async () => {
  try {
    const response = await fetch('/firebase-config.json')
    return await response.json()
  } catch (error) {
    console.warn('Firebase config not found, using environment variables')
    return {
      apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
      authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
      projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
      storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET,
      messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
      appId: import.meta.env.VITE_FIREBASE_APP_ID,
      measurementId: import.meta.env.VITE_FIREBASE_MEASUREMENT_ID,
    }
  }
}

export const createConfig = async (): Promise<AppConfig> => {
  const firebaseConfig = await loadFirebaseConfig()
  
  return {
    environment: (import.meta.env.VITE_ENVIRONMENT as AppConfig['environment']) || 'development',
    apiUrl: import.meta.env.VITE_API_URL || 'http://localhost:8080',
    grafana: {
      url: import.meta.env.VITE_GRAFANA_URL || 'http://localhost:3000',
      dashboards: {
        metrics: '/d/19924/asp-net-core-metrics',
        endpoints: '/d/19925/asp-net-core-endpoint',
        logs: '/explore',
        traces: '/explore',
      },
      defaultTimeRange: 'now-6h',
    },
    firebase: firebaseConfig,
    features: {
      metrics: true,
      logs: true,
      traces: true,
      alerts: true,
      darkMode: true,
    },
    refreshIntervals: {
      metrics: 30000,
      logs: 10000,
      traces: 15000,
    },
  }
}

// Configuração inicial (será substituída após carregar)
export let config: AppConfig = {
  environment: 'development',
  apiUrl: '',
  grafana: { url: '', dashboards: {}, defaultTimeRange: '' },
  features: { metrics: true, logs: true, traces: true, alerts: true, darkMode: true },
  refreshIntervals: { metrics: 0, logs: 0, traces: 0 },
}

// Inicializar configuração
createConfig().then(c => { config = c })