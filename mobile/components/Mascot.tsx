import React from 'react';
import { View, Text, StyleSheet, Animated } from 'react-native';

export type MascotState = 'IDLE' | 'HAPPY' | 'CURIOUS' | 'LISTENING' | 'THINKING' | 'SPEAKING' | 'VIEWING' | 'BROWSING' | 'READING' | 'RESPONDING' | 'WARNING' | 'SIMULATING' | 'FUTURE_RISK' | 'FUTURE_POSITIVE' | 'FUTURE_NEUTRAL' | 'INTERVENING' | 'ATTENTION' | 'CELEBRATING' | 'PLANNING' | 'CONFIRMING' | 'ACTING' | 'SUCCESS' | 'ERROR' | 'RESTING';

interface MascotProps {
  state: MascotState;
  themeColor?: string;
}

export default function Mascot({ state, themeColor }: MascotProps) {
  // A simple representation of TESS for Phase 1 & 2
  let face = "•_•"; // IDLE
  let color = themeColor || "#8B5CF6";

  if (state === 'HAPPY') {
    face = "^_^";
    color = "#34C759";
  } else if (state === 'CURIOUS') {
    face = "o_O?";
    color = "#00BCD4";
  } else if (state === 'LISTENING') {
    face = "O_o";
    color = "#007AFF";
  } else if (state === 'SPEAKING') {
    face = "^o^";
    color = "#34C759";
  } else if (state === 'VIEWING') {
    face = "◉_◉";
    color = "#00BCD4";
  } else if (state === 'BROWSING' || state === 'READING') {
    face = "•‿•";
    color = "#FF9500";
  } else if (state === 'RESTING') {
    face = "u_u";
    color = "#8E8E93";
  } else if (state === 'THINKING') {
    face = "O_O";
    color = "#007AFF";
  } else if (state === 'RESPONDING') {
    face = "^_^";
    color = "#34C759";
  } else if (state === 'WARNING' || state === 'FUTURE_RISK') {
    face = ">_<";
    color = "#FF3B30";
  } else if (state === 'SIMULATING') {
    face = "O_~";
    color = "#9C27B0"; // Purple for simulating the future
  } else if (state === 'FUTURE_POSITIVE') {
    face = "✧_✧";
    color = "#00C853";
  } else if (state === 'FUTURE_NEUTRAL') {
    face = "O_O";
    color = "#FF9500";
  } else if (state === 'ATTENTION' || state === 'INTERVENING') {
    face = "O_O!";
    color = "#FF3B30";
  } else if (state === 'CELEBRATING' || state === 'SUCCESS') {
    face = "^_^!!";
    color = "#4CAF50";
  } else if (state === 'PLANNING' || state === 'ACTING') {
    face = "-_-";
    color = "#007AFF";
  } else if (state === 'CONFIRMING') {
    face = "?_?";
    color = "#FF9500";
  } else if (state === 'ERROR') {
    face = "X_X";
    color = "#FF3B30";
  }

  return (
    <View style={styles.container}>
      <View style={[styles.mascotCircle, { borderColor: color }]}>
        <Text style={[styles.face, { color }]}>{face}</Text>
      </View>
      <Text style={styles.stateText}>{state}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    alignItems: 'center',
    justifyContent: 'center',
    marginVertical: 20,
  },
  mascotCircle: {
    width: 100,
    height: 100,
    borderRadius: 50,
    borderWidth: 4,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#fff',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 2,
  },
  face: {
    fontSize: 32,
    fontWeight: 'bold',
  },
  stateText: {
    marginTop: 10,
    fontSize: 12,
    color: '#888',
  }
});
