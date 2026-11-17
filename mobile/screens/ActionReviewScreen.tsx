import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ActivityIndicator,
  TouchableOpacity,
  ScrollView,
  SafeAreaView
} from 'react-native';
import Mascot from '../components/Mascot';
import { apiService } from '../services/api';
import { colors } from '../theme/tokens';

export default function ActionReviewScreen({ route, navigation }: any) {
  const { objective, interventionId } = route.params || {};
  const [plan, setPlan] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [mascotState, setMascotState] = useState<
    'PLANNING' | 'CONFIRMING' | 'ACTING' | 'SUCCESS' | 'ERROR'
  >('PLANNING');
  const [result, setResult] = useState<any>(null);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  useEffect(() => {
    generatePlan();
  }, []);

  const generatePlan = async () => {
    try {
      setLoading(true);
      setErrorMessage(null);
      setMascotState('PLANNING');
      const data = await apiService.createObjective(
        objective || 'Update openproject worklog'
      );
      setPlan(data);
      setMascotState('CONFIRMING');
    } catch (e: any) {
      console.error('Plan generation failed:', e);
      setErrorMessage(e.message || 'Failed to generate action plan');
      setMascotState('ERROR');
    } finally {
      setLoading(false);
    }
  };

  const handleConfirmAndExecute = async () => {
    if (!plan) return;
    setLoading(true);
    setErrorMessage(null);
    setMascotState('ACTING');
    try {
      await apiService.confirmPlan(plan.id);
      const execResult = await apiService.executePlan(plan.id);
      setResult(execResult);
      setMascotState('SUCCESS');

      if (interventionId) {
        try {
          await apiService.respondIntervention(interventionId, 'ACTED');
        } catch (invErr) {
          console.warn('Intervention status update failed:', invErr);
        }
      }
    } catch (e: any) {
      console.error('Action execution failed:', e);
      setErrorMessage(e.message || 'Action execution failed');
      setMascotState('ERROR');
    } finally {
      setLoading(false);
    }
  };

  const handleCancel = async () => {
    if (plan?.id) {
      try {
        await apiService.cancelPlan(plan.id);
      } catch (_) {}
    }
    navigation.goBack();
  };

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <Mascot state={mascotState as any} size="sm" showLabel={false} />
        <View style={styles.headerTitleBox}>
          <Text style={styles.headerTitle}>AGENT SAFEGUARD</Text>
          <Text style={styles.headerSubtitle}>Deterministic confirmation barrier</Text>
        </View>
        <TouchableOpacity onPress={() => navigation.goBack()} style={styles.closeBtn}>
          <Text style={styles.closeBtnText}>Close</Text>
        </TouchableOpacity>
      </View>

      <ScrollView
        style={styles.content}
        contentContainerStyle={{ paddingBottom: 32 }}
        showsVerticalScrollIndicator={false}
      >
        {errorMessage && (
          <View style={styles.errorBox}>
            <Text style={styles.errorText}>{errorMessage}</Text>
          </View>
        )}

        <View style={styles.objectiveCard}>
          <Text style={styles.objectiveLabel}>PROPOSED AUTONOMOUS OBJECTIVE</Text>
          <Text style={styles.objectiveText}>
            {objective || 'Execute autonomous task update'}
          </Text>
        </View>

        {loading ? (
          <View style={styles.loadingBox}>
            <ActivityIndicator size="large" color={colors.violet} />
            <Text style={styles.loadingText}>
              {mascotState === 'PLANNING'
                ? 'Synthesizing verified tool actions...'
                : 'Executing planned interactions...'}
            </Text>
          </View>
        ) : result ? (
          <View style={styles.resultCard}>
            <Text style={styles.resultBadge}>EXECUTION SUCCESSFUL</Text>
            <Text style={styles.resultStatus}>Status: {result.status}</Text>
            <Text style={styles.resultDetail}>
              All planned tool steps have been deterministically applied.
            </Text>
            <TouchableOpacity
              onPress={() => navigation.goBack()}
              style={styles.btnDone}
            >
              <Text style={styles.btnDoneText}>Done</Text>
            </TouchableOpacity>
          </View>
        ) : plan ? (
          <View style={styles.planContainer}>
            <Text style={styles.stepsTitle}>
              ACTION STEPS REQUIRING APPROVAL ({plan.steps?.length || 0})
            </Text>

            {plan.steps?.map((step: any, idx: number) => {
              const isHigh =
                step.risk_level?.toUpperCase() === 'HIGH' ||
                step.risk_level?.toUpperCase() === 'MEDIUM';
              return (
                <View key={idx} style={styles.stepCard}>
                  <View style={styles.stepHeader}>
                    <Text style={styles.stepIndex}>#{idx + 1}</Text>
                    <Text style={styles.stepTool}>{step.tool_name}</Text>
                    {step.risk_level && (
                      <View
                        style={[
                          styles.riskBadge,
                          {
                            backgroundColor: isHigh
                              ? 'rgba(251, 113, 133, 0.15)'
                              : 'rgba(52, 211, 153, 0.15)'
                          }
                        ]}
                      >
                        <Text
                          style={[
                            styles.riskText,
                            { color: isHigh ? colors.danger : colors.success }
                          ]}
                        >
                          {step.risk_level.toUpperCase()} RISK
                        </Text>
                      </View>
                    )}
                  </View>

                  <Text style={styles.stepDesc}>
                    {step.description || 'Executes external system tool.'}
                  </Text>
                </View>
              );
            })}

            <View style={styles.actionRow}>
              <TouchableOpacity
                onPress={handleConfirmAndExecute}
                style={styles.btnConfirm}
              >
                <Text style={styles.btnConfirmText}>Approve & Execute</Text>
              </TouchableOpacity>

              <TouchableOpacity
                onPress={handleCancel}
                style={styles.btnCancel}
              >
                <Text style={styles.btnCancelText}>Reject</Text>
              </TouchableOpacity>
            </View>
          </View>
        ) : null}
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
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 12,
    backgroundColor: colors.bgSecondary,
    borderBottomWidth: 1,
    borderColor: colors.border
  },
  headerTitleBox: {
    flex: 1,
    marginLeft: 12
  },
  headerTitle: {
    fontSize: 14,
    fontWeight: '800',
    fontFamily: 'monospace',
    color: colors.violetLight,
    letterSpacing: 1
  },
  headerSubtitle: {
    fontSize: 10,
    color: colors.textMuted
  },
  closeBtn: {
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: 6,
    backgroundColor: 'rgba(255, 255, 255, 0.04)',
    borderWidth: 1,
    borderColor: colors.border
  },
  closeBtnText: {
    fontSize: 11,
    color: colors.textSecondary
  },
  content: {
    flex: 1,
    padding: 16
  },
  errorBox: {
    padding: 12,
    borderRadius: 10,
    backgroundColor: 'rgba(251, 113, 133, 0.12)',
    borderWidth: 1,
    borderColor: 'rgba(251, 113, 133, 0.3)',
    marginBottom: 16
  },
  errorText: {
    fontSize: 12,
    color: colors.danger
  },
  objectiveCard: {
    backgroundColor: colors.bgSurface,
    padding: 16,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: colors.border,
    marginBottom: 16
  },
  objectiveLabel: {
    fontSize: 9,
    fontFamily: 'monospace',
    fontWeight: '700',
    color: colors.textMuted,
    letterSpacing: 1,
    marginBottom: 4
  },
  objectiveText: {
    fontSize: 14,
    fontWeight: '600',
    color: colors.textPrimary,
    lineHeight: 20
  },
  loadingBox: {
    padding: 30,
    alignItems: 'center',
    justifyContent: 'center'
  },
  loadingText: {
    fontSize: 12,
    fontFamily: 'monospace',
    color: colors.textMuted,
    marginTop: 12
  },
  resultCard: {
    backgroundColor: colors.bgSurface,
    padding: 20,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: 'rgba(52, 211, 153, 0.4)',
    alignItems: 'center'
  },
  resultBadge: {
    fontSize: 12,
    fontFamily: 'monospace',
    fontWeight: '800',
    color: colors.success,
    letterSpacing: 1.5,
    marginBottom: 6
  },
  resultStatus: {
    fontSize: 13,
    color: colors.textPrimary,
    fontWeight: '600',
    marginBottom: 4
  },
  resultDetail: {
    fontSize: 11,
    color: colors.textMuted,
    textAlign: 'center',
    marginBottom: 16
  },
  btnDone: {
    paddingHorizontal: 24,
    paddingVertical: 10,
    borderRadius: 8,
    backgroundColor: colors.success
  },
  btnDoneText: {
    fontSize: 12,
    fontWeight: '700',
    fontFamily: 'monospace',
    color: '#000'
  },
  planContainer: {
    marginTop: 4
  },
  stepsTitle: {
    fontSize: 11,
    fontFamily: 'monospace',
    fontWeight: '700',
    color: colors.textMuted,
    letterSpacing: 1,
    marginBottom: 10
  },
  stepCard: {
    backgroundColor: colors.bgSurface,
    borderRadius: 10,
    padding: 12,
    borderWidth: 1,
    borderColor: colors.border,
    marginBottom: 10
  },
  stepHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 4
  },
  stepIndex: {
    fontSize: 11,
    fontFamily: 'monospace',
    color: colors.textMuted,
    marginRight: 6
  },
  stepTool: {
    fontSize: 12,
    fontFamily: 'monospace',
    fontWeight: '700',
    color: colors.cyan,
    flex: 1
  },
  riskBadge: {
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4
  },
  riskText: {
    fontSize: 9,
    fontFamily: 'monospace',
    fontWeight: '700'
  },
  stepDesc: {
    fontSize: 11,
    color: colors.textSecondary,
    lineHeight: 16
  },
  actionRow: {
    flexDirection: 'row',
    gap: 10,
    marginTop: 16
  },
  btnConfirm: {
    flex: 1.5,
    paddingVertical: 12,
    borderRadius: 10,
    backgroundColor: colors.violet,
    alignItems: 'center'
  },
  btnConfirmText: {
    fontSize: 12,
    fontWeight: '700',
    fontFamily: 'monospace',
    color: '#FFF'
  },
  btnCancel: {
    flex: 1,
    paddingVertical: 12,
    borderRadius: 10,
    backgroundColor: 'rgba(255, 255, 255, 0.04)',
    borderWidth: 1,
    borderColor: colors.border,
    alignItems: 'center'
  },
  btnCancelText: {
    fontSize: 12,
    fontWeight: '600',
    fontFamily: 'monospace',
    color: colors.textMuted
  }
});
