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

export default function SignupScreen({ navigation }: any) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);

  async function signUpWithEmail() {
    if (!email || !password || loading) return;
    setLoading(true);
    const { error } = await supabase.auth.signUp({
      email: email.trim().toLowerCase(),
      password: password,
    });

    if (error) {
      Alert.alert('Sign Up Issue', error.message);
    } else {
      Alert.alert('Account Created', 'Your TESS account is ready. You can now sign in!');
      navigation.navigate('Login');
    }
    setLoading(false);
  }

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.card}>
        <Mascot state="HAPPY" size="lg" showLabel={false} />

        <View style={styles.brandRow}>
          <Text style={styles.brandTitle}>TESS</Text>
          <View style={styles.tagBadge}>
            <Text style={styles.tagText}>NEW USER</Text>
          </View>
        </View>

        <Text style={styles.subtitle}>
          Initialize personal AI companion instance
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
          onPress={signUpWithEmail}
          disabled={loading}
        >
          {loading ? (
            <ActivityIndicator color="#FFF" />
          ) : (
            <Text style={styles.btnPrimaryText}>Create Account →</Text>
          )}
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.switchBtn}
          onPress={() => navigation.navigate('Login')}
        >
          <Text style={styles.switchText}>
            Already have an account? <Text style={{ color: colors.violetLight, fontWeight: '700' }}>Sign in</Text>
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
    borderColor: 'rgba(52, 211, 153, 0.35)',
    alignItems: 'center',
    shadowColor: colors.success,
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
    backgroundColor: 'rgba(52, 211, 153, 0.12)',
    borderWidth: 1,
    borderColor: 'rgba(52, 211, 153, 0.3)'
  },
  tagText: {
    fontSize: 9,
    fontFamily: 'monospace',
    fontWeight: '700',
    color: colors.success
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
    backgroundColor: colors.success,
    paddingVertical: 13,
    borderRadius: 10,
    alignItems: 'center',
    marginTop: 4
  },
  btnPrimaryText: {
    color: '#000',
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
