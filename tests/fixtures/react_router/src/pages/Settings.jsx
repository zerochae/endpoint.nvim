import React, { useState, useEffect } from 'react';

const Settings = () => {
  const [settings, setSettings] = useState({
    profile: {
      name: 'John Doe',
      email: 'john.doe@example.com',
      bio: 'Software developer passionate about React and TypeScript',
      avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=johndoe'
    },
    preferences: {
      theme: 'light',
      language: 'en',
      notifications: {
        email: true,
        push: true,
        sms: false
      },
      privacy: {
        showEmail: false,
        showActivity: true,
        allowMessages: true
      }
    },
    account: {
      twoFactorEnabled: false,
      sessionTimeout: 30,
      dataRetention: 365
    }
  });

  const [activeTab, setActiveTab] = useState('profile');
  const [hasChanges, setHasChanges] = useState(false);
  const [saving, setSaving] = useState(false);

  const handleInputChange = (section, field, value) => {
    setSettings(prev => ({
      ...prev,
      [section]: {
        ...prev[section],
        [field]: value
      }
    }));
    setHasChanges(true);
  };

  const handleNestedChange = (section, nested, field, value) => {
    setSettings(prev => ({
      ...prev,
      [section]: {
        ...prev[section],
        [nested]: {
          ...prev[section][nested],
          [field]: value
        }
      }
    }));
    setHasChanges(true);
  };

  const handleSave = async () => {
    setSaving(true);
    
    // Simulate API call
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    setHasChanges(false);
    setSaving(false);
    
    // Show success message (you could use a toast library here)
    alert('Settings saved successfully!');
  };

  const tabs = [
    { id: 'profile', label: 'Profile', icon: '👤' },
    { id: 'preferences', label: 'Preferences', icon: '⚙️' },
    { id: 'account', label: 'Account', icon: '🔒' }
  ];

  return (
    <div className="settings">
      <header className="settings-header">
        <h1>Settings</h1>
        {hasChanges && (
          <button 
            className="save-button"
            onClick={handleSave}
            disabled={saving}
          >
            {saving ? 'Saving...' : 'Save Changes'}
          </button>
        )}
      </header>

      <div className="settings-layout">
        <nav className="settings-tabs">
          {tabs.map(tab => (
            <button
              key={tab.id}
              className={`tab ${activeTab === tab.id ? 'active' : ''}`}
              onClick={() => setActiveTab(tab.id)}
            >
              <span className="tab-icon">{tab.icon}</span>
              <span className="tab-label">{tab.label}</span>
            </button>
          ))}
        </nav>

        <main className="settings-content">
          {activeTab === 'profile' && (
            <div className="settings-section">
              <h2>Profile Information</h2>
              
              <div className="form-group">
                <label htmlFor="name">Full Name</label>
                <input
                  id="name"
                  type="text"
                  value={settings.profile.name}
                  onChange={(e) => handleInputChange('profile', 'name', e.target.value)}
                />
              </div>

              <div className="form-group">
                <label htmlFor="email">Email Address</label>
                <input
                  id="email"
                  type="email"
                  value={settings.profile.email}
                  onChange={(e) => handleInputChange('profile', 'email', e.target.value)}
                />
              </div>

              <div className="form-group">
                <label htmlFor="bio">Bio</label>
                <textarea
                  id="bio"
                  rows="4"
                  value={settings.profile.bio}
                  onChange={(e) => handleInputChange('profile', 'bio', e.target.value)}
                />
              </div>

              <div className="form-group">
                <label>Profile Picture</label>
                <div className="avatar-section">
                  <img src={settings.profile.avatar} alt="Profile" className="avatar-preview" />
                  <button className="avatar-change-btn">Change Avatar</button>
                </div>
              </div>
            </div>
          )}

          {activeTab === 'preferences' && (
            <div className="settings-section">
              <h2>Preferences</h2>
              
              <div className="form-group">
                <label htmlFor="theme">Theme</label>
                <select
                  id="theme"
                  value={settings.preferences.theme}
                  onChange={(e) => handleInputChange('preferences', 'theme', e.target.value)}
                >
                  <option value="light">Light</option>
                  <option value="dark">Dark</option>
                  <option value="auto">Auto</option>
                </select>
              </div>

              <div className="form-group">
                <label htmlFor="language">Language</label>
                <select
                  id="language"
                  value={settings.preferences.language}
                  onChange={(e) => handleInputChange('preferences', 'language', e.target.value)}
                >
                  <option value="en">English</option>
                  <option value="es">Español</option>
                  <option value="fr">Français</option>
                  <option value="de">Deutsch</option>
                </select>
              </div>

              <div className="form-section">
                <h3>Notifications</h3>
                <div className="checkbox-group">
                  <label className="checkbox-label">
                    <input
                      type="checkbox"
                      checked={settings.preferences.notifications.email}
                      onChange={(e) => handleNestedChange('preferences', 'notifications', 'email', e.target.checked)}
                    />
                    Email notifications
                  </label>
                  <label className="checkbox-label">
                    <input
                      type="checkbox"
                      checked={settings.preferences.notifications.push}
                      onChange={(e) => handleNestedChange('preferences', 'notifications', 'push', e.target.checked)}
                    />
                    Push notifications
                  </label>
                  <label className="checkbox-label">
                    <input
                      type="checkbox"
                      checked={settings.preferences.notifications.sms}
                      onChange={(e) => handleNestedChange('preferences', 'notifications', 'sms', e.target.checked)}
                    />
                    SMS notifications
                  </label>
                </div>
              </div>

              <div className="form-section">
                <h3>Privacy</h3>
                <div className="checkbox-group">
                  <label className="checkbox-label">
                    <input
                      type="checkbox"
                      checked={settings.preferences.privacy.showEmail}
                      onChange={(e) => handleNestedChange('preferences', 'privacy', 'showEmail', e.target.checked)}
                    />
                    Show email publicly
                  </label>
                  <label className="checkbox-label">
                    <input
                      type="checkbox"
                      checked={settings.preferences.privacy.showActivity}
                      onChange={(e) => handleNestedChange('preferences', 'privacy', 'showActivity', e.target.checked)}
                    />
                    Show activity status
                  </label>
                  <label className="checkbox-label">
                    <input
                      type="checkbox"
                      checked={settings.preferences.privacy.allowMessages}
                      onChange={(e) => handleNestedChange('preferences', 'privacy', 'allowMessages', e.target.checked)}
                    />
                    Allow direct messages
                  </label>
                </div>
              </div>
            </div>
          )}

          {activeTab === 'account' && (
            <div className="settings-section">
              <h2>Account Security</h2>
              
              <div className="form-group">
                <label className="checkbox-label">
                  <input
                    type="checkbox"
                    checked={settings.account.twoFactorEnabled}
                    onChange={(e) => handleInputChange('account', 'twoFactorEnabled', e.target.checked)}
                  />
                  Enable Two-Factor Authentication
                </label>
                <p className="form-help">Add an extra layer of security to your account</p>
              </div>

              <div className="form-group">
                <label htmlFor="sessionTimeout">Session Timeout (minutes)</label>
                <select
                  id="sessionTimeout"
                  value={settings.account.sessionTimeout}
                  onChange={(e) => handleInputChange('account', 'sessionTimeout', parseInt(e.target.value))}
                >
                  <option value={15}>15 minutes</option>
                  <option value={30}>30 minutes</option>
                  <option value={60}>1 hour</option>
                  <option value={240}>4 hours</option>
                  <option value={480}>8 hours</option>
                </select>
              </div>

              <div className="form-group">
                <label htmlFor="dataRetention">Data Retention (days)</label>
                <select
                  id="dataRetention"
                  value={settings.account.dataRetention}
                  onChange={(e) => handleInputChange('account', 'dataRetention', parseInt(e.target.value))}
                >
                  <option value={30}>30 days</option>
                  <option value={90}>90 days</option>
                  <option value={365}>1 year</option>
                  <option value={730}>2 years</option>
                  <option value={-1}>Forever</option>
                </select>
              </div>

              <div className="danger-zone">
                <h3>Danger Zone</h3>
                <div className="danger-actions">
                  <button className="danger-button">Reset All Settings</button>
                  <button className="danger-button">Delete Account</button>
                </div>
              </div>
            </div>
          )}
        </main>
      </div>
    </div>
  );
};

export default Settings;