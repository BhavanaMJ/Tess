import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ActivityIndicator,
  ScrollView,
  TouchableOpacity,
  SafeAreaView
} from 'react-native';
import { apiService } from '../services/api';
import { colors } from '../theme/tokens';

export default function InterventionScreen({ navigation }: any) {
  const [interventions, setInterventions] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchInterventions();
  }, []);

  const fetchInterventions = async () => {
    try {
      const res = await apiService.getInterventions();
      setInterventions(Array.isArray(res) ? res : []);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  const handleFixIt = (inv: any) => {
    navigation.navigate('ActionReview', {
      objective: `Fix ${inv.title}: ${inv.suggested_action}`,
      interventionId: inv.id
    });
  };

  const handleRespond = async (id: string, action: string) => {
    try {
      await apiService.respondIntervention(id, action);
      fetchInterventions();
    } catch (e) {
      console.error(e);
    }
  };

  const activeInterventions = interventions.filter((i) => i.status === 'SENT');
  const history = interventions.filter((i) => i.status !== 'SENT');

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <View>
          <Text style={styles.headerTitle}>PROACTIVE INTERVENTIONS</Text>
          <Text style={styles.headerSubtitle}>Real-time trajectory corrections</Text>
        </View>
        <TouchableOpacity
          onPress={() => navigation.goBack()}
          style={styles.closeBtn}
        >
          <Text style={styles.closeBtnText}>Close</Text>
        </TouchableOpacity>
      </View>

      <ScrollView
        style={styles.content}
        contentContainerStyle={{ paddingBottom: 32 }}
        showsVerticalScrollIndicator={false}
      >
        {loading ? (
          <View style={styles.loadingContainer}>
            <ActivityIndicator size="large" color={colors.warning} />
            <Text style={styles.loadingText}>Fetching active interventions...</Text>
          </View>
        ) : (
          <>
            {/* ACTIVE INTERVENTIONS */}
            <View style={styles.section}>
              <Text style={styles.sectionTitle}>
                REQUIRES ATTENTION ({activeInterventions.length})
              </Text>

              {activeInterventions.length === 0 ? (
                <View style={styles.emptyCard}>
                  <Text style={styles.emptyTitle}>No Critical Divergences</Text>
                  <Text style={styles.emptySubtext}>
                    TESS has not detected any immediate risks to your milestones.
                  </Text>
                </View>
              ) : (
                activeInterventions.map((inv) => {
                  const isHigh =
                    inv.priority === 'HIGH' || inv.priority === 'CRITICAL';
                  return (
                    <View
                      key={inv.id}
                      style={[
                        styles.activeCard,
                        {
                          borderColor: isHigh
                            ? 'rgba(251, 113, 133, 0.45)'
                            : 'rgba(251, 191, 36, 0.45)'
                        }
                      ]}
                    >
                      <View style={styles.cardHeader}>
                        <Text style={styles.invTitle}>{inv.title}</Text>
                        <View
                          style={[
                            styles.priorityBadge,
                            {
                              backgroundColor: isHigh
                                ? 'rgba(251, 113, 133, 0.15)'
                                : 'rgba(251, 191, 36, 0.15)'
                            }
                          ]}
                        >
                          <Text
                            style={[
                              styles.priorityBadgeText,
                              { color: isHigh ? colors.danger : colors.warning }
                            ]}
                          >
                            {inv.priority}
                          </Text>
                        </View>
                      </View>

                      <Text style={styles.invMessage}>{inv.message}</Text>

                      {inv.suggested_action && (
                        <View style={styles.actionBox}>
                          <Text style={styles.actionBoxLabel}>SUGGESTED FIX</Text>
                          <Text style={styles.actionBoxText}>
                            {inv.suggested_action}
                          </Text>
                        </View>
                      )}

                      <View style={styles.actions}>
                        <TouchableOpacity
                          style={styles.btnAction}
                          onPress={() => handleFixIt(inv)}
                        >
                          <Text style={styles.btnText}>FIX IT</Text>
                        </TouchableOpacity>

                        <TouchableOpacity
                          style={styles.btnActionLater}
                          onPress={() => handleRespond(inv.id, 'LATER')}
                        >
                          <Text style={styles.btnTextSecondary}>LATER</Text>
                        </TouchableOpacity>

                        <TouchableOpacity
                          style={styles.btnActionDismiss}
                          onPress={() => handleRespond(inv.id, 'DISMISS')}
                        >
                          <Text style={styles.btnTextMuted}>DISMISS</Text>
                        </TouchableOpacity>
                      </View>
                    </View>
                  );
                })
              )}
            </View>

            {/* HISTORICAL INTERVENTIONS */}
            <View style={styles.section}>
              <Text style={styles.sectionTitle}>
                RESOLVED & PAST LOGS ({history.length})
              </Text>
              {history.length === 0 ? (
                <Text style={styles.emptyText}>No previous interventions recorded.</Text>
              ) : (
                history.map((inv) => (
                  <View key={inv.id} style={styles.historyCard}>
                    <Text style={styles.historyTitle} numberOfLines={1}>
                      {inv.title}
                    </Text>
                    <Text style={styles.historyStatus}>
                      Status: {inv.status}
                    </Text>
                  </View>
                ))
              )}
            </View>
          </>
        )}
      </ScrollView>
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
    color: colors.warning,
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
  content: {
    flex: 1,
    padding: 16
  },
  loadingContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingTop: 60
  },
  loadingText: {
    fontSize: 12,
    color: colors.textMuted,
    marginTop: 12,
    fontFamily: 'monospace'
  },
  section: {
    marginBottom: 24
  },
  sectionTitle: {
    fontSize: 11,
    fontWeight: '700',
    fontFamily: 'monospace',
    color: colors.textMuted,
    letterSpacing: 1.5,
    marginBottom: 10
  },
  emptyCard: {
    backgroundColor: colors.bgSurface,
    padding: 18,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: 'rgba(52, 211, 153, 0.25)',
    alignItems: 'center'
  },
  emptyTitle: {
    fontSize: 13,
    fontWeight: '700',
    color: colors.textPrimary,
    marginBottom: 4
  },
  emptySubtext: {
    fontSize: 11,
    color: colors.textMuted,
    textAlign: 'center'
  },
  emptyText: {
    fontSize: 11,
    color: colors.textMuted,
    fontStyle: 'italic'
  },
  activeCard: {
    backgroundColor: colors.bgSurface,
    borderRadius: 14,
    padding: 16,
    borderWidth: 1,
    marginBottom: 12
  },
  cardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8
  },
  invTitle: {
    fontSize: 14,
    fontWeight: '700',
    color: colors.textPrimary,
    flex: 1,
    marginRight: 8
  },
  priorityBadge: {
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4
  },
  priorityBadgeText: {
    fontSize: 9,
    fontFamily: 'monospace',
    fontWeight: '700'
  },
  invMessage: {
    fontSize: 12,
    color: colors.textSecondary,
    lineHeight: 18,
    marginBottom: 12
  },
  actionBox: {
    padding: 10,
    borderRadius: 8,
    backgroundColor: 'rgba(0, 0, 0, 0.35)',
    borderWidth: 1,
    borderColor: colors.border,
    marginBottom: 14
  },
  actionBoxLabel: {
    fontSize: 9,
    fontFamily: 'monospace',
    fontWeight: '700',
    color: colors.cyan,
    letterSpacing: 1,
    marginBottom: 2
  },
  actionBoxText: {
    fontSize: 11,
    color: colors.textPrimary,
    lineHeight: 16
  },
  actions: {
    flexDirection: 'row',
    gap: 8
  },
  btnAction: {
    flex: 1.2,
    paddingVertical: 9,
    borderRadius: 8,
    backgroundColor: colors.violet,
    alignItems: 'center'
  },
  btnActionLater: {
    flex: 1,
    paddingVertical: 9,
    borderRadius: 8,
    backgroundColor: 'rgba(255, 255, 255, 0.05)',
    borderWidth: 1,
    borderColor: colors.border,
    alignItems: 'center'
  },
  btnActionDismiss: {
    flex: 1,
    paddingVertical: 9,
    borderRadius: 8,
    backgroundColor: 'rgba(255, 255, 255, 0.03)',
    borderWidth: 1,
    borderColor: colors.border,
    alignItems: 'center'
  },
  btnText: {
    fontSize: 11,
    fontWeight: '700',
    fontFamily: 'monospace',
    color: '#FFF'
  },
  btnTextSecondary: {
    fontSize: 11,
    fontWeight: '600',
    fontFamily: 'monospace',
    color: colors.textSecondary
  },
  btnTextMuted: {
    fontSize: 11,
    fontWeight: '600',
    fontFamily: 'monospace',
    color: colors.textMuted
  },
  historyCard: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    backgroundColor: colors.bgSecondary,
    padding: 12,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: colors.border,
    marginBottom: 8
  },
  historyTitle: {
    fontSize: 12,
    fontWeight: '600',
    color: colors.textPrimary,
    flex: 1,
    marginRight: 10
  },
  historyStatus: {
    fontSize: 10,
    fontFamily: 'monospace',
    color: colors.textMuted
  }
});
