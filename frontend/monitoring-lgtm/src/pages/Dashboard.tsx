import React, { useState, useEffect } from 'react';
import { ChartBarIcon, ServerIcon, DocumentTextIcon, BeakerIcon, ArrowPathIcon } from '@heroicons/react/24/outline';

type DashboardType = 'metrics' | 'endpoints' | 'logs' | 'traces';

const Dashboard: React.FC = () => {
  const [timeRange, setTimeRange] = useState<string>('now-7d');
  const [dashboard, setDashboard] = useState<DashboardType>('metrics');
  const [grafanaUrl] = useState<string>('/grafana');
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    setIsLoading(true);
    const timer = setTimeout(() => setIsLoading(false), 500);
    return () => clearTimeout(timer);
  }, [dashboard, timeRange]);

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

  return (
    <div className="flex flex-col h-screen bg-gray-900">
      {/* Navbar */}
      <nav className="bg-gray-800 border-b border-gray-700 px-4 py-3 flex-shrink-0">
        <div className="flex items-center justify-between gap-4 flex-wrap">
          {/* Logo/Title */}
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 bg-gradient-to-br from-blue-500 to-purple-600 rounded-lg flex items-center justify-center">
              <ChartBarIcon className="w-5 h-5 text-white" />
            </div>
            <div>
              <h1 className="text-white font-semibold text-sm sm:text-base">LGTM Stack</h1>
              <p className="text-gray-400 text-xs hidden sm:block">Observabilidade + LGPD</p>
            </div>
          </div>

          {/* Dashboard Tabs */}
          <div className="flex gap-1 sm:gap-2">
            {[
              { value: 'metrics', label: 'Métricas', icon: ChartBarIcon },
              { value: 'endpoints', label: 'Endpoints', icon: ServerIcon },
              { value: 'logs', label: 'Logs', icon: DocumentTextIcon },
              { value: 'traces', label: 'Traces', icon: BeakerIcon },
            ].map((option) => (
              <button
                key={option.value}
                onClick={() => setDashboard(option.value as DashboardType)}
                className={`
                  px-3 py-2 rounded-lg text-xs sm:text-sm font-medium transition-all flex items-center gap-1.5
                  ${dashboard === option.value
                    ? 'bg-blue-600 text-white'
                    : 'text-gray-300 hover:bg-gray-700 hover:text-white'
                  }
                `}
              >
                <option.icon className="w-4 h-4" />
                <span className="hidden sm:inline">{option.label}</span>
              </button>
            ))}
          </div>

          {/* Time Range */}
          <select
            value={timeRange}
            onChange={(e) => setTimeRange(e.target.value)}
            className="px-3 py-2 bg-gray-700 text-gray-200 text-xs sm:text-sm rounded-lg border border-gray-600 focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="now-1h">1h</option>
            <option value="now-6h">6h</option>
            <option value="now-24h">24h</option>
            <option value="now-7d">7d</option>
            <option value="now-30d">30d</option>
            <option value="now-90d">90d</option>
          </select>
        </div>
      </nav>

      {/* Iframe Container */}
      <div className="flex-1 relative bg-black">
        {isLoading && (
          <div className="absolute inset-0 flex items-center justify-center bg-gray-900 z-10">
            <ArrowPathIcon className="w-8 h-8 text-blue-500 animate-spin" />
          </div>
        )}
        <iframe
          key={`${dashboard}-${timeRange}`}
          src={grafanaUrls[dashboard]}
          title="Grafana Dashboard"
          className="w-full h-full border-0"
          allow="fullscreen"
          sandbox="allow-scripts allow-same-origin allow-forms allow-popups"
        />
      </div>
    </div>
  );
};

export default Dashboard;
