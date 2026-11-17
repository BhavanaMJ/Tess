import React, { useEffect, useRef } from 'react';
import { View, Text, StyleSheet, Animated, Easing } from 'react-native';

export type MascotState =
  | 'IDLE'
  | 'HAPPY'
  | 'CURIOUS'
  | 'LISTENING'
  | 'THINKING'
  | 'SPEAKING'
  | 'VIEWING'
  | 'BROWSING'
  | 'READING'
  | 'RESPONDING'
  | 'WARNING'
  | 'SIMULATING'
  | 'FUTURE_RISK'
  | 'FUTURE_POSITIVE'
  | 'FUTURE_NEUTRAL'
  | 'INTERVENING'
  | 'ATTENTION'
  | 'CELEBRATING'
  | 'PLANNING'
  | 'CONFIRMING'
  | 'ACTING'
  | 'SUCCESS'
  | 'ERROR'
  | 'RESTING'
  | 'SLEEPING';

interface MascotProps {
  state: MascotState;
  themeColor?: string;
  size?: 'sm' | 'md' | 'lg';
  showLabel?: boolean;
}

export default function Mascot({
  state,
  themeColor,
  size = 'md',
  showLabel = true
}: MascotProps) {
  let face = '•_•';
  let color = themeColor || '#8B5CF6';

  if (state === 'HAPPY') {
    face = '^_^';
    color = '#34D399';
  } else if (state === 'CURIOUS') {
    face = 'o_O?';
    color = '#22D3EE';
  } else if (state === 'LISTENING') {
    face = 'O_o';
    color = '#38BDF8';
  } else if (state === 'SPEAKING') {
    face = '^o^';
    color = '#34D399';
  } else if (state === 'VIEWING') {
    face = '◉_◉';
    color = '#22D3EE';
  } else if (state === 'BROWSING' || state === 'READING') {
    face = '•‿•';
    color = '#FBBF24';
  } else if (state === 'RESTING' || state === 'SLEEPING') {
    face = 'u_u';
    color = '#64748B';
  } else if (state === 'THINKING') {
    face = 'O_O';
    color = '#A78BFA';
  } else if (state === 'RESPONDING') {
    face = '^_^';
    color = '#34D399';
  } else if (state === 'WARNING' || state === 'FUTURE_RISK') {
    face = '>_<';
    color = '#FB7185';
  } else if (state === 'SIMULATING') {
    face = 'O_~';
    color = '#22D3EE';
  } else if (state === 'FUTURE_POSITIVE') {
    face = '✧_✧';
    color = '#34D399';
  } else if (state === 'FUTURE_NEUTRAL') {
    face = 'O_O';
    color = '#60A5FA';
  } else if (state === 'ATTENTION' || state === 'INTERVENING') {
    face = 'O_O!';
    color = '#FB7185';
  } else if (state === 'CELEBRATING' || state === 'SUCCESS') {
    face = '^_^!!';
    color = '#34D399';
  } else if (state === 'PLANNING' || state === 'ACTING') {
    face = '-_-';
    color = '#8B5CF6';
  } else if (state === 'CONFIRMING') {
    face = '?_?';
    color = '#FBBF24';
  } else if (state === 'ERROR') {
    face = 'X_X';
    color = '#FB7185';
  }

  // Smooth breathing animation
  const breathAnim = useRef(new Animated.Value(1)).current;
  const pulseAnim = useRef(new Animated.Value(0.4)).current;

  useEffect(() => {
    const breathing = Animated.loop(
      Animated.sequence([
        Animated.timing(breathAnim, {
          toValue: 1.06,
          duration: 2000,
          easing: Easing.inOut(Easing.ease),
          useNativeDriver: true
        }),
        Animated.timing(breathAnim, {
          toValue: 0.96,
          duration: 2000,
          easing: Easing.inOut(Easing.ease),
          useNativeDriver: true
        })
      ])
    );

    const pulsing = Animated.loop(
      Animated.sequence([
        Animated.timing(pulseAnim, {
          toValue: 0.85,
          duration: 1500,
          easing: Easing.inOut(Easing.ease),
          useNativeDriver: true
        }),
        Animated.timing(pulseAnim, {
          toValue: 0.35,
          duration: 1500,
          easing: Easing.inOut(Easing.ease),
          useNativeDriver: true
        })
      ])
    );

    breathing.start();
    pulsing.start();

    return () => {
      breathing.stop();
      pulsing.stop();
    };
  }, [breathAnim, pulseAnim]);

  const dimensions = {
    sm: { box: 44, core: 34, font: 12 },
    md: { box: 76, core: 56, font: 16 },
    lg: { box: 104, core: 76, font: 22 }
  }[size];

  return (
    <View style={styles.container}>
      <Animated.View
        style={[
          styles.outerAura,
          {
            width: dimensions.box,
            height: dimensions.box,
            borderRadius: dimensions.box / 2,
            borderColor: color,
            opacity: pulseAnim,
            transform: [{ scale: breathAnim }]
          }
        ]}
      />

      <Animated.View
        style={[
          styles.mascotCore,
          {
            width: dimensions.core,
            height: dimensions.core,
            borderRadius: dimensions.core / 2,
            borderColor: color,
            backgroundColor: `${color}18`,
            shadowColor: color,
            transform: [{ scale: breathAnim }]
          }
        ]}
      >
        <Text style={[styles.face, { color, fontSize: dimensions.font }]}>
          {face}
        </Text>
      </Animated.View>

      {showLabel && (
        <View style={styles.labelContainer}>
          <View style={[styles.statusDot, { backgroundColor: color }]} />
          <Text style={[styles.stateText, { color }]}>{state}</Text>
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    alignItems: 'center',
    justifyContent: 'center',
    position: 'relative'
  },
  outerAura: {
    position: 'absolute',
    borderWidth: 1.5,
    borderStyle: 'dashed'
  },
  mascotCore: {
    borderWidth: 2,
    alignItems: 'center',
    justifyContent: 'center',
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 0.6,
    shadowRadius: 12,
    elevation: 8
  },
  face: {
    fontWeight: '700',
    fontFamily: 'monospace',
    letterSpacing: 1
  },
  labelContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    marginTop: 8
  },
  statusDot: {
    width: 6,
    height: 6,
    borderRadius: 3
  },
  stateText: {
    fontSize: 10,
    fontFamily: 'monospace',
    fontWeight: '700',
    textTransform: 'uppercase',
    letterSpacing: 1
  }
});
