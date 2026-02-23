import React from 'react'
import { motion } from 'framer-motion'
import { ServiceStatus } from '../../types'

interface ServiceCardProps {
  service: ServiceStatus
}

const statusColors = {
  healthy: 'text-green-500',
  degraded: 'text-yellow-500',
  down: 'text-red-500',
}

const bgColors = {
  purple: 'bg-purple-100 dark:bg-purple-900/20',
  orange: 'bg-orange-100 dark:bg-orange-900/20',
  teal: 'bg-teal-100 dark:bg-teal-900/20',
  red: 'bg-red-100 dark:bg-red-900/20',
  gray: 'bg-gray-100 dark:bg-gray-800',
  blue: 'bg-blue-100 dark:bg-blue-900/20',
}

export const ServiceCard: React.FC<ServiceCardProps> = ({ service }) => {
  return (
    <motion.div
      whileHover={{ scale: 1.02 }}
      className="bg-white dark:bg-gray-800 rounded-lg shadow-sm p-4 border border-gray-200 dark:border-gray-700"
    >
      <div className="flex items-center justify-between mb-2">
        <h3 className="font-medium text-gray-900 dark:text-white">{service.name}</h3>
        <span className={`text-xs font-medium ${statusColors[service.status]}`}>
          ● {service.status}
        </span>
      </div>
      <p className="text-xs text-gray-500 dark:text-gray-400 mb-3">{service.description}</p>
      <div className="grid grid-cols-2 gap-2 text-xs">
        {Object.entries(service.metrics).map(([key, value]) => (
          <div key={key}>
            <span className="text-gray-500 dark:text-gray-400">{key}: </span>
            <span className="font-medium text-gray-900 dark:text-white">{value}</span>
          </div>
        ))}
      </div>
    </motion.div>
  )
}