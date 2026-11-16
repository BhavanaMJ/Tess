import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, Button, ActivityIndicator, TouchableOpacity, ScrollView } from 'react-native';
import Mascot from '../components/Mascot';
import { apiService } from '../services/api';

export default function ActionReviewScreen({ route, navigation }: any) {
  const { objective, interventionId } = route.params || {};
  const [plan, setPlan] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [mascotState, setMascotState] = useState<'PLANNING' | 'CONFIRMING' | 'ACTING' | 'SUCCESS' | 'ERROR'>('PLANNING');
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
      const data = await apiService.createObjective(objective || 'Update openproject worklog');
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
      // 1. Confirm plan
      await apiService.confirmPlan(plan.id);
      
      // 2. Execute plan
      const execResult = await apiService.executePlan(plan.id);
      setResult(execResult);
      setMascotState('SUCCESS');
      
      // 3. Resolve the intervention if one triggered this action
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
    <View style={styles.container}>
      <View style={styles.header}>
        <Mascot state={mascotState as any} />
        <Button title="Close" onPress={() => navigation.goBack()} />
      </View>
      
      <ScrollView style={styles.content}>
        {loading && <ActivityIndicator size="large" style={{ margin: 20 }} />}
        
        {errorMessage && !loading && (
          <View style={styles.errorCard}>
            <Text style={styles.errorTitle}>⚠️ Action Failed</Text>
            <Text style={styles.errorText}>{errorMessage}</Text>
            <View style={styles.actions}>
              <TouchableOpacity style={styles.btnRetry} onPress={generatePlan}>
                <Text style={styles.btnText}>RETRY</Text>
              </TouchableOpacity>
              <TouchableOpacity style={styles.btnCancel} onPress={() => navigation.goBack()}>
                <Text style={styles.btnText}>DISMISS</Text>
              </TouchableOpacity>
            </View>
          </View>
        )}

        {!loading && !result && !errorMessage && plan && (
          <View style={styles.card}>
            <Text style={styles.title}>🐾 I can do this for you.</Text>
            <Text style={styles.subtitle}>Proposed Action:</Text>
            
            {plan.steps && plan.steps.map((step: any) => (
              <View key={step.id || step.step_order} style={styles.step}>
                <Text style={styles.stepTool}>Tool: {step.tool_name}</Text>
                <Text style={styles.stepParams}>{JSON.stringify(step.parameters, null, 2)}</Text>
                <Text style={[styles.stepRisk, step.risk_level === 'MEDIUM' ? {color: 'orange'} : {color: 'red'}]}>
                  Risk: {step.risk_level}
                </Text>
              </View>
            ))}
            
            <View style={styles.actions}>
              <TouchableOpacity style={styles.btnConfirm} onPress={handleConfirmAndExecute}>
                <Text style={styles.btnText}>CONFIRM & EXECUTE</Text>
              </TouchableOpacity>
              <TouchableOpacity style={styles.btnCancel} onPress={handleCancel}>
                <Text style={styles.btnText}>CANCEL</Text>
              </TouchableOpacity>
            </View>
          </View>
        )}
        
        {result && (
          <View style={styles.card}>
            <Text style={styles.title}>🐾 Done.</Text>
            <Text style={styles.subtitle}>Action completed successfully.</Text>
            <Text style={styles.stepParams}>{JSON.stringify(result.results || result, null, 2)}</Text>
            <View style={{ marginTop: 15 }}>
              <Button title="Close" onPress={() => navigation.goBack()} />
            </View>
          </View>
        )}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#fff' },
  header: { flexDirection: 'row', justifyContent: 'space-between', padding: 20, paddingTop: 50, backgroundColor: '#f0f0f0', alignItems: 'center' },
  content: { padding: 20 },
  card: { backgroundColor: '#f9f9f9', padding: 20, borderRadius: 10, borderWidth: 1, borderColor: '#eee' },
  errorCard: { backgroundColor: '#FFF5F5', padding: 20, borderRadius: 10, borderWidth: 1, borderColor: '#FEB2B2', marginBottom: 20 },
  errorTitle: { fontSize: 18, fontWeight: 'bold', marginBottom: 8, color: '#C53030' },
  errorText: { fontSize: 14, color: '#742A2A', marginBottom: 15, lineHeight: 20 },
  title: { fontSize: 20, fontWeight: 'bold', marginBottom: 10, color: '#333' },
  subtitle: { fontSize: 16, color: '#666', marginBottom: 15 },
  step: { backgroundColor: '#fff', padding: 10, borderRadius: 5, marginBottom: 15, borderWidth: 1, borderColor: '#ddd' },
  stepTool: { fontWeight: 'bold', marginBottom: 5 },
  stepParams: { fontFamily: 'monospace', fontSize: 12, backgroundColor: '#f0f0f0', padding: 5, borderRadius: 3 },
  stepRisk: { marginTop: 5, fontWeight: 'bold' },
  actions: { flexDirection: 'row', justifyContent: 'space-between', marginTop: 10 },
  btnConfirm: { backgroundColor: '#4CAF50', padding: 15, borderRadius: 5, flex: 1, marginRight: 10, alignItems: 'center' },
  btnRetry: { backgroundColor: '#3182CE', padding: 15, borderRadius: 5, flex: 1, marginRight: 10, alignItems: 'center' },
  btnCancel: { backgroundColor: '#9E9E9E', padding: 15, borderRadius: 5, flex: 1, alignItems: 'center' },
  btnText: { color: '#fff', fontWeight: 'bold' }
});
