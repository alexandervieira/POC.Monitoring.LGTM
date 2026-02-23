import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  ArrowPathIcon,
  ChartBarIcon,
  ServerIcon,
  DocumentTextIcon,
  BeakerIcon,
  ExclamationTriangleIcon,
  CheckCircleIcon,
  XCircleIcon,
} from '@heroicons/react/24/outline';

type DashboardType = 'metrics' | 'endpoints' | 'logs' | 'traces';
type ConnectionStatus = 'checking' | 'connected' | 'error';

const Dashboard: React.FC = () => {
  const [timeRange, setTimeRange] = useState<string>('now-7d');
  const [dashboard, setDashboard] = useState<DashboardType>('metrics');
  const [connectionStatus, setConnectionStatus] = useState<ConnectionStatus>('checking');
  const [errorDetails, setErrorDetails] = useState<string>('');
  const [grafanaUrl, setGrafanaUrl] = useState<string>('');

  useEffect(() => {
    const testGrafanaConnection = async () => {
      console.log('=== Testando conexão com Grafana ===');
      
      // Lista de possíveis URLs para testar
      const urlsToTest = [
        { name: 'Proxy /grafana/api/health', url: '/grafana/api/health' },
        { name: 'Proxy /api/health', url: '/api/health' },
        { name: 'Direto localhost:3000/api/health', url: 'http://localhost:3000/api/health' },
        { name: 'Proxy /grafana/health', url: '/grafana/health' },
        { name: 'Proxy /grafana/api/health (sem rewrite)', url: '/grafana/api/health', noRewrite: true },
      ];

      for (const test of urlsToTest) {
        try {
          console.log(`Testando: ${test.name} (${test.url})`);
          
          const response = await fetch(test.url, {
            method: 'GET',
            headers: {
              'Accept': 'application/json',
            },
          });
          
          console.log(`Status: ${response.status} ${response.statusText}`);
          
          const contentType = response.headers.get('content-type');
          console.log(`Content-Type: ${contentType}`);
          
          if (response.ok && contentType?.includes('application/json')) {
            const data = await response.json();
            console.log('✅ Conexão bem-sucedida:', data);
            setConnectionStatus('connected');
            setGrafanaUrl(test.url.replace('/api/health', ''));
            return;
          } else {
            const text = await response.text();
            console.log(`Resposta (primeiros 100 caracteres): ${text.substring(0, 100)}`);
          }
        } catch (error) {
          console.log(`❌ Erro em ${test.name}:`, error);
        }
      }
      
      setConnectionStatus('error');
      setErrorDetails('Não foi possível conectar ao Grafana. Verifique se o container está rodando e o proxy configurado.');
    };

    testGrafanaConnection();
  }, []);

  const grafanaUrls: Record<DashboardType, string> = {
    metrics: `${grafanaUrl}/d/KdDACDp4z/asp-net-core?orgId=1&kiosk=tv&from=${timeRange}`,
    endpoints: `${grafanaUrl}/d/NagEsjE4z/asp-net-core-endpoint?orgId=1&kiosk=tv&from=${timeRange}`,
    logs: `${grafanaUrl}/explore?orgId=1&left=${encodeURIComponent(JSON.stringify({
      datasource: "Loki",
      queries: [{ refId: "A", expr: '{service_name="apicontagem"}' }],
      range: { from: timeRange, to: "now" }
    }))}&kiosk=tv`,
    traces: `${grafanaUrl}/explore?orgId=1&left=${encodeURIComponent(JSON.stringify({
      datasource: "Tempo",
      queries: [{ refId: "A", queryType: "search" }],
      range: { from: timeRange, to: "now" }
    }))}&kiosk=tv`
  };

  if (connectionStatus === 'checking') {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <ArrowPathIcon className="h-12 w-12 animate-spin text-primary-600 mx-auto mb-4" />
          <p className="text-gray-600">Testando conexão com Grafana...</p>
          <p className="text-sm text-gray-400 mt-2">Verificando múltiplos endpoints</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Header */}
        <div className="mb-8">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-3xl font-bold text-gray-900">
                Observabilidade - LGTM Stack
              </h1>
              <p className="mt-2 text-sm text-gray-600">
                Dados anonimizados conforme LGPD - Retenção máxima de 90 dias
              </p>
            </div>
            
            {/* Status Indicator */}
            <div className={`flex items-center space-x-2 px-3 py-1 rounded-full ${
              connectionStatus === 'connected' ? 'bg-green-100' : 'bg-red-100'
            }`}>
              {connectionStatus === 'connected' ? (
                <>
                  <CheckCircleIcon className="h-5 w-5 text-green-600" />
                  <span className="text-sm font-medium text-green-800">Conectado</span>
                </>
              ) : (
                <>
                  <XCircleIcon className="h-5 w-5 text-red-600" />
                  <span className="text-sm font-medium text-red-800">Erro</span>
                </>
              )}
            </div>
          </div>
        </div>

        {/* Error Alert */}
        <AnimatePresence>
          {connectionStatus === 'error' && (
            <motion.div
              initial={{ opacity: 0, y: -20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -20 }}
              className="mb-6"
            >
              <div className="bg-red-50 border-l-4 border-red-400 p-4 rounded-lg">
                <div className="flex">
                  <ExclamationTriangleIcon className="h-5 w-5 text-red-400 mr-3" />
                  <div>
                    <p className="text-sm text-red-700">{errorDetails}</p>
                    <p className="text-xs text-red-500 mt-2">
                      Execute os seguintes comandos para diagnóstico:
                    </p>
                    <pre className="text-xs bg-red-100 p-2 rounded mt-2">
                      docker-compose ps
                      docker-compose logs grafana
                      curl http://localhost:3000/api/health
                    </pre>
                  </div>
                </div>
              </div>
            </motion.div>
          )}
        </AnimatePresence>

        {/* Controls */}
        <div className="bg-white rounded-lg shadow-sm p-6 mb-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Período
              </label>
              <select
                value={timeRange}
                onChange={(e) => setTimeRange(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent"
              >
                <option value="now-1h">Última hora</option>
                <option value="now-6h">Últimas 6 horas</option>
                <option value="now-24h">Últimas 24 horas</option>
                <option value="now-7d">Últimos 7 dias</option>
                <option value="now-30d">Últimos 30 dias</option>
                <option value="now-90d">Últimos 90 dias</option>
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Dashboard
              </label>
              <div className="grid grid-cols-2 gap-2">
                {[
                  { value: 'metrics', label: 'Métricas', icon: ChartBarIcon },
                  { value: 'endpoints', label: 'Endpoints', icon: ServerIcon },
                  { value: 'logs', label: 'Logs', icon: DocumentTextIcon },
                  { value: 'traces', label: 'Traces', icon: BeakerIcon },
                ].map((option) => (
                  <button
                    key={option.value}
                    onClick={() => setDashboard(option.value as DashboardType)}
                    disabled={connectionStatus !== 'connected'}
                    className={`
                      p-3 rounded-lg border text-sm font-medium transition-all flex items-center justify-center space-x-2
                      ${connectionStatus !== 'connected' && 'opacity-50 cursor-not-allowed'}
                      ${dashboard === option.value
                        ? 'border-primary-500 bg-primary-50 text-primary-700'
                        : 'border-gray-200 hover:border-gray-300 text-gray-600 hover:bg-gray-50'
                      }
                    `}
                  >
                    <option.icon className="h-5 w-5" />
                    <span>{option.label}</span>
                  </button>
                ))}
              </div>
            </div>
          </div>
        </div>

        {/* Grafana Iframe */}
        {connectionStatus === 'connected' ? (
          <AnimatePresence mode="wait">
            <motion.div
              key={dashboard}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -20 }}
              className="w-full h-[600px] overflow-hidden rounded-xl shadow-lg border border-gray-200 bg-white"
            >
              <iframe
                src={grafanaUrls[dashboard]}
                title="Grafana Dashboard"
                className="w-full h-full border-none"
                allow="fullscreen"
                sandbox="allow-scripts allow-same-origin allow-forms allow-popups"
              />
            </motion.div>
          </AnimatePresence>
        ) : (
          <div className="w-full h-[600px] bg-gray-100 rounded-xl shadow-lg border border-gray-200 flex items-center justify-center">
            <div className="text-center max-w-md px-6">
              <ExclamationTriangleIcon className="h-16 w-16 text-gray-400 mx-auto mb-4" />
              <h3 className="text-lg font-medium text-gray-700 mb-2">Grafana não disponível</h3>
              <p className="text-gray-500 mb-4">
                Não foi possível conectar ao Grafana. Verifique se:
              </p>
              <ul className="text-left text-sm text-gray-600 space-y-2 mb-4">
                <li>1. O container Docker está rodando: <code className="bg-gray-200 px-1 rounded">docker-compose ps</code></li>
                <li>2. O Grafana está acessível: <code className="bg-gray-200 px-1 rounded">curl http://localhost:3000</code></li>
                <li>3. O proxy está configurado corretamente no vite.config.ts</li>
              </ul>
              <button
                onClick={() => window.location.reload()}
                className="px-4 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700 transition-colors"
              >
                Tentar novamente
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default Dashboard;