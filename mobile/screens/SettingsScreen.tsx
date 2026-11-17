import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TextInput,
  Alert,
  ActivityIndicator,
  TouchableOpacity,
  ScrollView,
  SafeAreaView
} from 'react-native';
import { supabase } from '../lib/supabase';
import { useAuth } from '../contexts/AuthContext';
import { apiService } from '../services/api';
import { colors } from '../theme/tokens';

export default function SettingsScreen() {
  const { user } = useAuth();
  const [opUrl, setOpUrl] = useState('');
  const [opToken, setOpToken] = useState('');
  const [loading, setLoading] = useState(false);

  const testConnection = async () => {
    if (!opUrl || !opToken) {
      Alert.alert('Configuration Missing', 'Please provide both OpenProject Base URL and API Token');
      return;
    }
    setLoading(true);
    try {
      const res = await apiService.testOpenProject(opUrl, opToken);
      if (res.connected) {
        Alert.alert('Connection Successful', `Connected! Synchronized with ${res.project_count} projects.`);
        setOpToken('');
      } else {
        Alert.alert('Connection Failed', res.error || 'Failed to authenticate with OpenProject');
      }
    } catch (e: any) {
      Alert.alert('Network Error', e.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView
        contentContainerStyle={{ padding: 20, paddingBottom: 40 }}
        showsVerticalScrollIndicator={false}
      >
        <Text style={styles.screenTitle}>SYSTEM CONFIGURATION</Text>

        {/* USER IDENTITY CARD */}
        <View style={styles.card}>
          <Text style={styles.sectionHeader}>USER IDENTITY</Text>
          <View style={styles.identityRow}>
            <View style={styles.avatarCircle}>
              <Text style={styles.avatarText}>
                {user?.email ? user.email[0].toUpperCase() : 'U'}
              </Text>
            </View>
            <View>
              <Text style={styles.userEmail}>{user?.email}</Text>
              <View style={styles.statusRow}>
                <View style={styles.onlineDot} />
                <Text style={styles.statusText}>AUTHENTICATED & SYNCED</Text>
              </View>
            </View>
          </View>
        </View>

        {/* OPENPROJECT INTEGRATION */}
        <View style={styles.card}>
          <Text style={styles.sectionHeader}>PRODUCTIVITY INTEGRATIONS</Text>
          <Text style={styles.subHeader}>OpenProject Workspace</Text>

          <TextInput
            style={styles.input}
            placeholder="Base URL (e.g. https://openproject.example.com)"
            placeholderTextColor={colors.textMuted}
            value={opUrl}
            onChangeText={setOpUrl}
            autoCapitalize="none"
            autoCorrect={false}
          />

          <TextInput
            style={styles.input}
            placeholder="API Access Token"
            placeholderTextColor={colors.textMuted}
            value={opToken}
            onChangeText={setOpToken}
            secureTextEntry
          />

          <TouchableOpacity
            style={styles.btnSync}
            onPress={testConnection}
            disabled={loading}
          >
            {loading ? (
              <ActivityIndicator color="#000" size="small" />
            ) : (
              <Text style={styles.btnSyncText}>Test & Connect</Text>
            )}
          </TouchableOpacity>
        </View>

        {/* AI TELEMETRY */}
        <View style={styles.card}>
          <Text style={styles.sectionHeader}>INTELLIGENCE ENGINE</Text>
          <Text style={styles.infoText}>
            Local Ollama (llama3.1:8b) / OpenRouter cloud fallback configured on backend.
          </Text>
        </View>

        {/* DISCONNECT */}
        <TouchableOpacity
          style={styles.btnSignOut}
          onPress={() => supabase.auth.signOut()}
        >
          <Text style={styles.btnSignOutText}>Sign Out of Companion</Text>
        </TouchableOpacity>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.bgPrimary
  },
  screenTitle: {
    fontSize: 16,
    fontWeight: '800',
    fontFamily: 'monospace',
    color: colors.violetLight,
    letterSpacing: 1.5,
    marginBottom: 20
  },
  card: {
    backgroundColor: colors.bgSurface,
    borderRadius: 14,
    padding: 18,
    borderWidth: 1,
    borderColor: colors.border,
    marginBottom: 16
  },
  sectionHeader: {
    fontSize: 10,
    fontFamily: 'monospace',
    fontWeight: '700',
    color: colors.textMuted,
    letterSpacing: 1.5,
    marginBottom: 12
  },
  subHeader: {
    fontSize: 13,
    fontWeight: '700',
    color: colors.textPrimary,
    marginBottom: 10
  },
  identityRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12
  },
  avatarCircle: {
    width: 42,
    height: 42,
    borderRadius: 21,
    backgroundColor: 'rgba(139, 92, 246, 0.2)',
    borderWidth: 1,
    borderColor: colors.violet,
    alignItems: 'center',
    justifyContent: 'center'
  },
  avatarText: {
    fontSize: 18,
    fontWeight: '800',
    color: colors.violetLight
  },
  userEmail: {
    fontSize: 13,
    fontWeight: '600',
    color: colors.textPrimary
  },
  statusRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    marginTop: 4
  },
  onlineDot: {
    width: 6,
    height: 6,
    borderRadius: 3,
    backgroundColor: colors.success
  },
  statusText: {
    fontSize: 9,
    fontFamily: 'monospace',
    color: colors.success,
    fontWeight: '700'
  },
  input: {
    backgroundColor: 'rgba(5, 6, 10, 0.7)',
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 10,
    paddingHorizontal: 14,
    paddingVertical: 10,
    color: colors.textPrimary,
    fontSize: 12,
    marginBottom: 10
  },
  btnSync: {
    backgroundColor: colors.cyan,
    paddingVertical: 12,
    borderRadius: 10,
    alignItems: 'center',
    marginTop: 4
  },
  btnSyncText: {
    fontSize: 12,
    fontWeight: '700',
    fontFamily: 'monospace',
    color: '#000'
  },
  infoText: {
    fontSize: 12,
    color: colors.textSecondary,
    lineHeight: 18
  },
  btnSignOut: {
    paddingVertical: 14,
    borderRadius: 10,
    backgroundColor: 'rgba(251, 113, 133, 0.1)',
    borderWidth: 1,
    borderColor: 'rgba(251, 113, 133, 0.3)',
    alignItems: 'center',
    marginTop: 10
  },
  btnSignOutText: {
    fontSize: 12,
    fontWeight: '700',
    fontFamily: 'monospace',
    color: colors.danger
  }
});
