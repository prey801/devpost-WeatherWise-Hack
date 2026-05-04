import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { io } from 'socket.io-client';
import { MapContainer, TileLayer, Marker, Popup, Circle } from 'react-leaflet';
import { AlertCircle, WifiOff, Activity, ShieldAlert, CheckCircle2 } from 'lucide-react';

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000';

function App() {
  const [alerts, setAlerts] = useState([]);
  const [reports, setReports] = useState([]);
  const [isOffline, setIsOffline] = useState(!navigator.onLine);
  const [selectedAlert, setSelectedAlert] = useState(null);

  // Load cached data initially
  useEffect(() => {
    const cachedAlerts = localStorage.getItem('safeskies_alerts');
    if (cachedAlerts) {
      setAlerts(JSON.parse(cachedAlerts));
    }

    const handleOnline = () => setIsOffline(false);
    const handleOffline = () => setIsOffline(true);

    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);

    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, []);

  useEffect(() => {
    if (isOffline) return;

    // Fetch initial data
    const fetchData = async () => {
      try {
        const [alertsRes, reportsRes] = await Promise.all([
          axios.get(`${API_URL}/v1/alerts/active`),
          axios.get(`${API_URL}/v1/reports/`)
        ]);
        setAlerts(alertsRes.data);
        setReports(reportsRes.data);
        localStorage.setItem('safeskies_alerts', JSON.stringify(alertsRes.data));
      } catch (err) {
        console.error("Failed to fetch data", err);
      }
    };
    
    fetchData();

    // Setup WebSocket for real-time updates
    const socket = io(API_URL);
    
    socket.on('new_alert', (alert) => {
      setAlerts(prev => {
        const newAlerts = [alert, ...prev];
        localStorage.setItem('safeskies_alerts', JSON.stringify(newAlerts));
        return newAlerts;
      });
    });

    return () => socket.disconnect();
  }, [isOffline]);

  const handleAction = async (alertId, action) => {
    try {
      await axios.patch(`${API_URL}/v1/responder/${alertId}`, { status: action });
      setAlerts(prev => prev.map(a => a.id === alertId ? { ...a, status: action } : a).filter(a => a.status === 'active' || action === 'responding'));
    } catch (err) {
      console.error("Action failed", err);
    }
  };

  // Mock zones for map
  const mockZones = [
    { id: "KE-NBI-001", name: "Nairobi Central", lat: -1.2921, lon: 36.8219 },
    { id: "KE-MSA-001", name: "Mombasa Island", lat: -4.0435, lon: 39.6682 },
  ];

  return (
    <div className="dashboard-container">
      <header>
        <div className="header-title">
          <h1>SafeSkies Responder Dashboard</h1>
        </div>
        {isOffline && (
          <div className="offline-banner">
            <WifiOff size={16} style={{ marginRight: '8px', verticalAlign: 'middle' }} />
            You are offline - showing cached data
          </div>
        )}
      </header>

      <div className="stats-bar">
        <div className="stat-card">
          <h3>Active Alerts</h3>
          <div className="value" style={{ color: 'var(--critical-color)' }}>
            {alerts.filter(a => a.status === 'active').length}
          </div>
        </div>
        <div className="stat-card">
          <h3>Highest Severity</h3>
          <div className="value" style={{ color: 'var(--high-color)' }}>
            {alerts.some(a => a.severity === 'CRITICAL') ? 'CRITICAL' : 
             alerts.some(a => a.severity === 'HIGH') ? 'HIGH' : 'LOW'}
          </div>
        </div>
        <div className="stat-card">
          <h3>Crowd Reports</h3>
          <div className="value" style={{ color: 'var(--accent-color)' }}>
            {reports.length}
          </div>
        </div>
      </div>

      <div className="main-content">
        <div className="map-container">
          <MapContainer center={[-1.2921, 36.8219]} zoom={6} scrollWheelZoom={true}>
            <TileLayer
              attribution='&copy; <a href="https://carto.com/">Carto</a>'
              url="https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png"
            />
            {mockZones.map(zone => {
              const zoneAlert = alerts.find(a => a.zone_ids === zone.id);
              const color = zoneAlert ? 
                (zoneAlert.severity === 'CRITICAL' ? '#ef4444' : '#f97316') 
                : '#3b82f6';
                
              return (
                <Circle 
                  key={zone.id}
                  center={[zone.lat, zone.lon]} 
                  radius={5000}
                  pathOptions={{ color, fillColor: color, fillOpacity: 0.4 }}
                >
                  <Popup>
                    <strong>{zone.name}</strong><br/>
                    Status: {zoneAlert ? zoneAlert.severity : 'Normal'}
                  </Popup>
                </Circle>
              );
            })}
          </MapContainer>
        </div>

        <div className="panels-container">
          <div className="panel">
            <h2><ShieldAlert size={20} style={{marginRight: '8px', verticalAlign: 'bottom'}}/> Active Alerts</h2>
            {alerts.length === 0 ? (
              <p style={{ color: 'var(--text-secondary)' }}>No active alerts. All clear.</p>
            ) : alerts.map(alert => (
              <div 
                key={alert.id} 
                className={`alert-item severity-${alert.severity}`}
                onClick={() => setSelectedAlert(alert)}
              >
                <div className="alert-header">
                  <span>{alert.id.substring(0, 13)}...</span>
                  <span className="alert-severity">{alert.severity}</span>
                </div>
                <div style={{ fontSize: '0.875rem' }}>{alert.message_en || alert.message}</div>
                
                {selectedAlert?.id === alert.id && (
                  <div className="alert-actions">
                    <button className="respond" onClick={(e) => { e.stopPropagation(); handleAction(alert.id, 'responding'); }}>
                      Respond
                    </button>
                    <button className="resolve" onClick={(e) => { e.stopPropagation(); handleAction(alert.id, 'resolved'); }}>
                      Resolve
                    </button>
                  </div>
                )}
              </div>
            ))}
          </div>

          <div className="panel">
            <h2><Activity size={20} style={{marginRight: '8px', verticalAlign: 'bottom'}}/> Crowd Reports Feed</h2>
            {reports.length === 0 ? (
              <p style={{ color: 'var(--text-secondary)' }}>No recent reports.</p>
            ) : reports.map(report => (
              <div key={report.id} className="alert-item" style={{ borderLeftColor: 'var(--accent-color)' }}>
                <div className="alert-header">
                  <span>{report.type.replace('_', ' ').toUpperCase()}</span>
                  <span className="alert-severity">{report.severity}</span>
                </div>
                <div style={{ fontSize: '0.875rem', color: 'var(--text-secondary)' }}>
                  Location: {report.lat.toFixed(4)}, {report.lon.toFixed(4)}<br/>
                  Status: {report.status}
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

export default App;
