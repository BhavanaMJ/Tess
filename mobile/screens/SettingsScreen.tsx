import React, { useState } from 'react';
import { View, Text, Button, StyleSheet, TextInput, Alert, ActivityIndicator } from 'react-native';
import { supabase } from '../lib/supabase';
import { useAuth } from '../contexts/AuthContext';
import { apiService } from '../services/api';

export default function SettingsScreen() {
  const { user } = useAuth();
  const [opUrl, setOpUrl] = useState('');
  const [opToken, setOpToken] = useState('');
  const [loading, setLoading] = useState(false);

  const testConnection = async () => {
    if (!opUrl || !opToken) {
      Alert.alert('Error', 'Please enter URL and Token');
      return;
    }
    setLoading(true);
    try {
      const res = await apiService.testOpenProject(opUrl, opToken);
      if (res.connected) {
        Alert.alert('Success', `Connected! Found ${res.project_count} projects.`);
        setOpToken(''); // Clear from UI after save
      } else {
        Alert.alert('Failed', res.error || 'Connection failed');
      }
    } catch (e: any) {
      Alert.alert('Error', e.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Settings</Text>
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Profile</Text>
        <Text>Email: {user?.email}</Text>
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Productivity Integrations</Text>
        <Text style={styles.subsectionTitle}>OpenProject</Text>
        <TextInput
          style={styles.input}
          placeholder="Base URL (e.g., https://openproject.com)"
          value={opUrl}
          onChangeText={setOpUrl}
          autoCapitalize="none"
        />
        <TextInput
          style={styles.input}
          placeholder="API Token"
          value={opToken}
          onChangeText={setOpToken}
          secureTextEntry
        />
        {loading ? <ActivityIndicator /> : <Button title="Test & Save Connection" onPress={testConnection} />}
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>AI Provider</Text>
        <Text style={styles.note}>(Configured on backend via environment variables)</Text>
      </View>

      <View style={styles.section}>
        <Button title="Logout" onPress={() => supabase.auth.signOut()} color="red" />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: 20, backgroundColor: '#f5f5f5' },
  title: { fontSize: 24, fontWeight: 'bold', marginBottom: 20 },
  section: { backgroundColor: '#fff', padding: 15, borderRadius: 8, marginBottom: 20 },
  sectionTitle: { fontSize: 18, fontWeight: 'bold', marginBottom: 10 },
  subsectionTitle: { fontSize: 16, fontWeight: '600', marginBottom: 5, color: '#444' },
  note: { color: '#888', fontStyle: 'italic' },
  input: { borderWidth: 1, borderColor: '#ddd', borderRadius: 4, padding: 8, marginBottom: 10 },
});
