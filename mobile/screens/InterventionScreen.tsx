import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, Button, ActivityIndicator, ScrollView, TouchableOpacity } from 'react-native';
import { apiService } from '../services/api';

export default function InterventionScreen({ navigation }: any) {
  const [interventions, setInterventions] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchInterventions();
  }, []);

  const fetchInterventions = async () => {
    try {
      const res = await apiService.getInterventions();
      // Filter for list formatting
      setInterventions(Array.isArray(res) ? res : []);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  const handleFixIt = (inv: any) => {
    navigation.navigate('ActionReview', { objective: `Fix ${inv.title}`, interventionId: inv.id });
  };

  const handleRespond = async (id: string, action: string) => {
    try {
      await apiService.respondIntervention(id, action);
      fetchInterventions();
    } catch (e) {
      console.error(e);
    }
  };

  const activeInterventions = interventions.filter(i => i.status === 'SENT');
  const history = interventions.filter(i => i.status !== 'SENT');

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.headerTitle}>TESS PROACTIVE</Text>
        <Button title="Close" onPress={() => navigation.goBack()} />
      </View>

      <ScrollView style={styles.content}>
        {loading ? (
          <ActivityIndicator size="large" color="#9C27B0" style={{marginTop: 50}}/>
        ) : (
          <>
            {activeInterventions.length > 0 && (
              <View style={styles.section}>
                <Text style={styles.sectionTitle}>REQUIRES ATTENTION</Text>
                {activeInterventions.map((inv) => (
                  <View key={inv.id} style={styles.activeCard}>
                    <Text style={styles.invTitle}>{inv.title}</Text>
                    <Text style={styles.invMessage}>{inv.message}</Text>
                    <View style={styles.actions}>
                      <TouchableOpacity style={styles.btnAction} onPress={() => handleFixIt(inv)}><Text style={styles.btnText}>FIX IT</Text></TouchableOpacity>
                      <TouchableOpacity style={styles.btnActionLater} onPress={() => handleRespond(inv.id, 'LATER')}><Text style={styles.btnText}>LATER</Text></TouchableOpacity>
                      <TouchableOpacity style={styles.btnActionDismiss} onPress={() => handleRespond(inv.id, 'DISMISS')}><Text style={styles.btnTextWhite}>DISMISS</Text></TouchableOpacity>
                    </View>
                  </View>
                ))}
              </View>
            )}

            <View style={styles.section}>
              <Text style={styles.sectionTitle}>RECENT INTERVENTIONS</Text>
              {history.length === 0 && <Text style={{color: '#888'}}>No history.</Text>}
              {history.map((inv) => (
                <View key={inv.id} style={styles.historyCard}>
                  <Text style={styles.historyTitle}>{inv.title}</Text>
                  <Text style={styles.historyStatus}>Status: {inv.status}</Text>
                </View>
              ))}
            </View>
          </>
        )}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#fff' },
  header: { flexDirection: 'row', justifyContent: 'space-between', padding: 20, paddingTop: 50, backgroundColor: '#f0f0f0' },
  headerTitle: { fontSize: 20, fontWeight: 'bold', color: '#9C27B0' },
  content: { padding: 20 },
  section: { marginBottom: 30 },
  sectionTitle: { fontSize: 14, fontWeight: 'bold', color: '#888', marginBottom: 10 },
  activeCard: { backgroundColor: '#fdf0ff', padding: 15, borderRadius: 10, borderWidth: 1, borderColor: '#e1bee7', marginBottom: 15 },
  invTitle: { fontSize: 18, fontWeight: 'bold', color: '#9C27B0', marginBottom: 10 },
  invMessage: { fontSize: 15, color: '#333', marginBottom: 20 },
  actions: { flexDirection: 'row', justifyContent: 'space-between' },
  btnAction: { backgroundColor: '#4CAF50', padding: 10, borderRadius: 5, flex: 1, marginRight: 5, alignItems: 'center' },
  btnActionLater: { backgroundColor: '#FF9800', padding: 10, borderRadius: 5, flex: 1, marginRight: 5, alignItems: 'center' },
  btnActionDismiss: { backgroundColor: '#9E9E9E', padding: 10, borderRadius: 5, flex: 1, alignItems: 'center' },
  btnText: { color: '#fff', fontWeight: 'bold', fontSize: 12 },
  btnTextWhite: { color: '#fff', fontWeight: 'bold', fontSize: 12 },
  historyCard: { backgroundColor: '#f9f9f9', padding: 15, borderRadius: 5, marginBottom: 10, borderWidth: 1, borderColor: '#eee' },
  historyTitle: { fontSize: 15, fontWeight: 'bold', color: '#555' },
  historyStatus: { fontSize: 12, color: '#888', marginTop: 5 }
});
