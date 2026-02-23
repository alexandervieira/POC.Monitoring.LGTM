// Tipos globais da aplicação

export interface MetricData {
  value: number
  unit: string
  timestamp: Date
  labels?: Record<string, string>
}

export interface ServiceStatus {
  name: string
  description: string
  status: 'healthy' | 'degraded' | 'down'
  metrics: Record<string, string | number>
  color: 'purple' | 'orange' | 'teal' | 'red' | 'gray' | 'blue'
}

export interface DashboardConfig {
  timeRange: string
  dashboard: 'metrics' | 'endpoints' | 'logs' | 'traces'
  refreshInterval: number
}

export interface GrafanaConfig {
  url: string
  dashboards: Record<string, string>
  defaultTimeRange: string
}

export interface FirebaseConfig {
  apiKey: string
  authDomain: string
  projectId: string
  storageBucket: string
  messagingSenderId: string
  appId: string
  measurementId?: string
}

export interface AppConfig {
  environment: 'development' | 'staging' | 'production'
  apiUrl: string
  grafana: GrafanaConfig
  firebase?: FirebaseConfig
  features: {
    metrics: boolean
    logs: boolean
    traces: boolean
    alerts: boolean
    darkMode: boolean
  }
  refreshIntervals: {
    metrics: number
    logs: number
    traces: number
  }
}