import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  Alert,
  SafeAreaView,
  ActivityIndicator
} from 'react-native';
import { supabase } from '../lib/supabase';
import Mascot from '../components/Mascot';
import { colors } from '../theme/tokens';

export default function LoginScreen({ navigation }: any) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);

  async function signInWithEmail() {
    if (!email || !password || loading) return;
    setLoading(true);
    const { error } = await supabase.auth.signInWithPassword({
      email: email.trim().toLowerCase(),
      password: password,
    });

    if (error) Alert.alert('Authentication Failed', error.message);
    setLoading(false);
  }

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.card}>
        <Mascot state="IDLE" size="lg" showLabel={false} />

        <View style={styles.brandRow}>
          <Text style={styles.brandTitle}>TESS</Text>
          <View style={styles.tagBadge}>
            <Text style={styles.tagText}>OS</Text>
          </View>
        </View>

        <Text style={styles.subtitle}>
          Sign in to your cross-device AI companion
        </Text>

        <TextInput
          style={styles.input}
          placeholder="Email address"
          placeholderTextColor={colors.textMuted}
          value={email}
          autoCapitalize="none"
          autoCorrect={false}
          keyboardType="email-address"
          onChangeText={setEmail}
        />

        <TextInput
          style={styles.input}
          placeholder="Password"
          placeholderTextColor={colors.textMuted}
          value={password}
          secureTextEntry
          onChangeText={setPassword}
        />

        <TouchableOpacity
          style={styles.btnPrimary}
          onPress={signInWithEmail}
          disabled={loading}
        >
          {loading ? (
            <ActivityIndicator color="#FFF" />
          ) : (
            <Text style={styles.btnPrimaryText}>Sign In →</Text>
          )}
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.switchBtn}
          onPress={() => navigation.navigate('Signup')}
        >
          <Text style={styles.switchText}>
            Don't have an account? <Text style={{ color: colors.violetLight, fontWeight: '700' }}>Sign up</Text>
          </Text>
        </TouchableOpacity>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.bgPrimary,
    justifyContent: 'center',
    padding: 20
  },
  card: {
    backgroundColor: colors.bgSurface,
    padding: 24,
    borderRadius: 18,
    borderWidth: 1,
    borderColor: 'rgba(139, 92, 246, 0.35)',
    alignItems: 'center',
    shadowColor: colors.violet,
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 16,
    elevation: 8
  },
  brandRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginTop: 14,
    marginBottom: 4
  },
  brandTitle: {
    fontSize: 22,
    fontWeight: '800',
    fontFamily: 'monospace',
    color: colors.textPrimary,
    letterSpacing: 2
  },
  tagBadge: {
    paddingHorizontal: 6,
    paddingVertical: 1,
    borderRadius: 8,
    backgroundColor: 'rgba(34, 211, 238, 0.12)',
    borderWidth: 1,
    borderColor: 'rgba(34, 211, 238, 0.3)'
  },
  tagText: {
    fontSize: 9,
    fontFamily: 'monospace',
    fontWeight: '700',
    color: colors.cyan
  },
  subtitle: {
    fontSize: 11,
    color: colors.textMuted,
    marginBottom: 20,
    textAlign: 'center'
  },
  input: {
    width: '100%',
    backgroundColor: 'rgba(5, 6, 10, 0.7)',
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 10,
    paddingHorizontal: 16,
    paddingVertical: 12,
    color: colors.textPrimary,
    fontSize: 13,
    marginBottom: 12
  },
  btnPrimary: {
    width: '100%',
    backgroundColor: colors.violet,
    paddingVertical: 13,
    borderRadius: 10,
    alignItems: 'center',
    marginTop: 4
  },
  btnPrimaryText: {
    color: '#FFF',
    fontSize: 13,
    fontWeight: '700',
    fontFamily: 'monospace'
  },
  switchBtn: {
    marginTop: 18
  },
  switchText: {
    fontSize: 11,
    color: colors.textMuted
  }
});
