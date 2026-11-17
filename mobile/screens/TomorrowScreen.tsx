import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ActivityIndicator,
  ScrollView,
  SafeAreaView,
  TouchableOpacity
} from 'react-native';
import { apiService } from '../services/api';
import { colors } from '../theme/tokens';

export default function TomorrowScreen({ navigation }: any) {
  const [horizon, setHorizon] = useState<'24h' | '3d' | '7d'>('24h');
  const [simResult, setSimResult] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    runSimulation(horizon);
  }, [horizon]);

  const runSimulation = async (hz: '24h' | '3d' | '7d') => {
    setLoading(true);
    try {
      const sim = await apiService.simulateFuture(hz);
      setSimResult(sim);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      {/* HEADER */}
      <View style={styles.header}>
        <View>
          <Text style={styles.headerTitle}>FUTURE ENGINE</Text>
          <Text style={styles.headerSubtitle}>Probabilistic trajectory simulation</Text>
        </View>
        <TouchableOpacity
          onPress={() => navigation.goBack()}
          style={styles.closeBtn}
        >
          <Text style={styles.closeBtnText}>Close</Text>
        </TouchableOpacity>
      </View>

      {/* HORIZON SELECTOR */}
      <View style={styles.horizonSelector}>
        {(['24h', '3d', '7d'] as const).map((hz) => (
          <TouchableOpacity
            key={hz}
            onPress={() => setHorizon(hz)}
            style={[
              styles.horizonBtn,
              horizon === hz && styles.horizonBtnActive
            ]}
          >
            <Text
              style={[
                styles.horizonText,
                horizon === hz && { color: colors.cyan }
              ]}
            >
              {hz === '24h' ? 'Next 24 Hours' : hz === '3d' ? '3 Days' : '7 Days'}
            </Text>
          </TouchableOpacity>
        ))}
      </View>

      {loading ? (
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color={colors.cyan} />
          <Text style={styles.loadingText}>Simulating probabilistic trajectory...</Text>
        </View>
      ) : simResult && simResult.scenario ? (
        <ScrollView
          style={styles.content}
          contentContainerStyle={{ paddingBottom: 32 }}
          showsVerticalScrollIndicator={false}
        >
          {/* PRIMARY TRAJECTORY CARD */}
          <View style={styles.scenarioCard}>
            <View style={styles.cardBadgeRow}>
              <Text style={styles.cardBadgeTitle}>CURRENT TRAJECTORY</Text>
              <View style={styles.confBadge}>
                <Text style={styles.confBadgeText}>
                  CONFIDENCE: {simResult.scenario.confidence || 'HIGH'}
                </Text>
              </View>
            </View>

            <Text style={styles.scenarioSummary}>
              {simResult.scenario.summary}
            </Text>

            {/* TIMELINE EVENTS */}
            <View style={styles.timeline}>
              {simResult.scenario.events?.map((ev: any, index: number) => (
                <View key={ev.id || index} style={styles.eventItem}>
                  <View style={styles.timeTag}>
                    <Text style={styles.timeTagText}>{ev.relative_time}</Text>
                  </View>
                  <Text style={styles.eventTitle}>{ev.title}</Text>
                  <Text style={styles.eventDesc}>{ev.description}</Text>
                  {index < simResult.scenario.events.length - 1 && (
                    <View style={styles.timelineConnector} />
                  )}
                </View>
              ))}
            </View>
          </View>

          {/* COUNTERFACTUAL ALTERNATIVE SCENARIO */}
          {simResult.alternative && (
            <View style={styles.altCard}>
              <View style={styles.cardBadgeRow}>
                <Text style={[styles.cardBadgeTitle, { color: colors.violetLight }]}>
                  RECOMMENDED INTERVENTION PATH
                </Text>
              </View>

              <Text style={styles.altAction}>
                {simResult.alternative.action}
              </Text>

              <View style={styles.altEffectBox}>
                <Text style={styles.altEffectLabel}>PROJECTED OUTCOME SHIFT</Text>
                <Text style={styles.altEffectText}>
                  {simResult.alternative.expected_effect}
                </Text>
              </View>
            </View>
          )}
        </ScrollView>
      ) : (
        <View style={styles.loadingContainer}>
          <Text style={styles.loadingText}>Simulation unavailable. Please sync tasks first.</Text>
        </View>
      )}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.bgPrimary
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingTop: 14,
    paddingBottom: 14,
    backgroundColor: colors.bgSecondary,
    borderBottomWidth: 1,
    borderColor: colors.border
  },
  headerTitle: {
    fontSize: 16,
    fontWeight: '800',
    fontFamily: 'monospace',
    color: colors.cyan,
    letterSpacing: 1.5
  },
  headerSubtitle: {
    fontSize: 11,
    color: colors.textMuted,
    marginTop: 2
  },
  closeBtn: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 8,
    backgroundColor: 'rgba(255, 255, 255, 0.05)',
    borderWidth: 1,
    borderColor: colors.border
  },
  closeBtnText: {
    fontSize: 12,
    fontWeight: '600',
    color: colors.textSecondary
  },
  horizonSelector: {
    flexDirection: 'row',
    padding: 12,
    gap: 8,
    backgroundColor: colors.bgSecondary,
    borderBottomWidth: 1,
    borderColor: colors.border
  },
  horizonBtn: {
    flex: 1,
    paddingVertical: 8,
    borderRadius: 8,
    alignItems: 'center',
    backgroundColor: 'rgba(255, 255, 255, 0.03)',
    borderWidth: 1,
    borderColor: colors.border
  },
  horizonBtnActive: {
    backgroundColor: 'rgba(34, 211, 238, 0.12)',
    borderColor: 'rgba(34, 211, 238, 0.35)'
  },
  horizonText: {
    fontSize: 11,
    fontFamily: 'monospace',
    fontWeight: '700',
    color: colors.textMuted
  },
  loadingContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 30
  },
  loadingText: {
    fontSize: 12,
    color: colors.textMuted,
    marginTop: 12,
    fontFamily: 'monospace'
  },
  content: {
    flex: 1,
    padding: 16
  },
  scenarioCard: {
    backgroundColor: colors.bgSurface,
    borderRadius: 14,
    padding: 16,
    borderWidth: 1,
    borderColor: 'rgba(34, 211, 238, 0.3)',
    marginBottom: 16
  },
  cardBadgeRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8
  },
  cardBadgeTitle: {
    fontSize: 11,
    fontFamily: 'monospace',
    fontWeight: '700',
    color: colors.cyan,
    letterSpacing: 1
  },
  confBadge: {
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4,
    backgroundColor: 'rgba(34, 211, 238, 0.12)'
  },
  confBadgeText: {
    fontSize: 9,
    fontFamily: 'monospace',
    fontWeight: '700',
    color: colors.cyan
  },
  scenarioSummary: {
    fontSize: 13,
    color: colors.textPrimary,
    lineHeight: 19,
    marginBottom: 16
  },
  timeline: {
    paddingLeft: 6
  },
  eventItem: {
    marginBottom: 14,
    position: 'relative'
  },
  timeTag: {
    alignSelf: 'flex-start',
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4,
    backgroundColor: 'rgba(255, 255, 255, 0.05)',
    borderWidth: 1,
    borderColor: colors.border,
    marginBottom: 4
  },
  timeTagText: {
    fontSize: 9,
    fontFamily: 'monospace',
    color: colors.textMuted
  },
  eventTitle: {
    fontSize: 12,
    fontWeight: '700',
    color: colors.textPrimary,
    marginBottom: 2
  },
  eventDesc: {
    fontSize: 11,
    color: colors.textSecondary,
    lineHeight: 16
  },
  timelineConnector: {
    width: 2,
    height: 12,
    backgroundColor: 'rgba(34, 211, 238, 0.3)',
    marginVertical: 4,
    marginLeft: 6
  },
  altCard: {
    backgroundColor: colors.bgSurface,
    borderRadius: 14,
    padding: 16,
    borderWidth: 1,
    borderColor: 'rgba(139, 92, 246, 0.35)'
  },
  altAction: {
    fontSize: 13,
    fontWeight: '600',
    color: colors.textPrimary,
    marginVertical: 8,
    lineHeight: 18
  },
  altEffectBox: {
    padding: 10,
    borderRadius: 8,
    backgroundColor: 'rgba(139, 92, 246, 0.1)',
    borderWidth: 1,
    borderColor: 'rgba(139, 92, 246, 0.25)',
    marginTop: 6
  },
  altEffectLabel: {
    fontSize: 9,
    fontFamily: 'monospace',
    fontWeight: '700',
    color: colors.violetLight,
    letterSpacing: 1,
    marginBottom: 2
  },
  altEffectText: {
    fontSize: 11,
    color: colors.textSecondary,
    lineHeight: 16
  }
});
