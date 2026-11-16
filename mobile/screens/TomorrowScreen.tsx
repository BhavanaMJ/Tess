import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, Button, ActivityIndicator, ScrollView } from 'react-native';
import { apiService } from '../services/api';

export default function TomorrowScreen({ navigation }: any) {
  const [horizon, setHorizon] = useState('24h');
  const [simResult, setSimResult] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    runSimulation(horizon);
  }, [horizon]);

  const runSimulation = async (hz: string) => {
    setLoading(true);
    try {
      const result = await apiService.analyzeFuture(); // In a real app we'd pass horizon, but for now our API handles it
      // Actually, we need to call simulate!
      const sim = await fetch('http://10.0.2.2:8000/api/v1/future/simulate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ horizon: hz })
      }).then(r => r.json());
      setSimResult(sim);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.headerTitle}>MEET TOMORROW YOU</Text>
        <Button title="Close" onPress={() => navigation.goBack()} />
      </View>

      <View style={styles.horizonSelector}>
        <Button title="24h" onPress={() => setHorizon('24h')} color={horizon === '24h' ? '#9C27B0' : '#888'} />
        <Button title="3d" onPress={() => setHorizon('3d')} color={horizon === '3d' ? '#9C27B0' : '#888'} />
        <Button title="7d" onPress={() => setHorizon('7d')} color={horizon === '7d' ? '#9C27B0' : '#888'} />
      </View>

      {loading ? (
        <ActivityIndicator size="large" color="#9C27B0" style={{marginTop: 50}}/>
      ) : simResult && simResult.scenario ? (
        <ScrollView style={styles.content}>
          <Text style={styles.trajectoryTitle}>YOUR CURRENT TRAJECTORY</Text>
          <Text style={styles.subtitle}>If you continue as you are...</Text>

          <View style={styles.timeline}>
            {simResult.scenario.events.map((ev: any, index: number) => (
              <View key={ev.id} style={styles.eventItem}>
                <Text style={styles.eventTime}>{ev.relative_time}</Text>
                <Text style={styles.eventTitle}>{ev.title}</Text>
                <Text style={styles.eventDesc}>{ev.description}</Text>
                {index < simResult.scenario.events.length - 1 && <Text style={styles.arrow}>↓</Text>}
              </View>
            ))}
          </View>

          <Text style={styles.resultText}>Result: {simResult.scenario.summary}</Text>
          <Text style={styles.metaText}>Likelihood: {simResult.scenario.confidence}</Text>
          <Text style={styles.metaText}>A possible future — not a prediction of certainty.</Text>

          {simResult.alternative && (
            <View style={styles.altSection}>
              <Text style={styles.altTitle}>ONE CHANGE</Text>
              <Text style={styles.altSubtitle}>There is another possible path.</Text>
              
              <Text style={styles.altAction}>{simResult.alternative.action}</Text>
              
              <Text style={styles.altLabel}>ALTERNATIVE TRAJECTORY</Text>
              <Text style={styles.altEffect}>↓ {simResult.alternative.expected_effect}</Text>
            </View>
          )}
        </ScrollView>
      ) : (
        <Text>Failed to load simulation.</Text>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#fff' },
  header: { flexDirection: 'row', justifyContent: 'space-between', padding: 20, paddingTop: 50, backgroundColor: '#f0f0f0' },
  headerTitle: { fontSize: 20, fontWeight: 'bold', color: '#9C27B0' },
  horizonSelector: { flexDirection: 'row', justifyContent: 'space-around', padding: 10, backgroundColor: '#eee' },
  content: { padding: 20 },
  trajectoryTitle: { fontSize: 18, fontWeight: 'bold', marginBottom: 5 },
  subtitle: { fontSize: 14, color: '#666', marginBottom: 20 },
  timeline: { borderLeftWidth: 2, borderColor: '#ddd', paddingLeft: 15, marginLeft: 10, marginBottom: 20 },
  eventItem: { marginBottom: 15 },
  eventTime: { fontSize: 12, color: '#888', fontWeight: 'bold' },
  eventTitle: { fontSize: 16, fontWeight: 'bold', color: '#333' },
  eventDesc: { fontSize: 14, color: '#555' },
  arrow: { fontSize: 20, color: '#aaa', marginTop: 10, textAlign: 'center' },
  resultText: { fontSize: 16, fontWeight: 'bold', color: '#FF3B30', marginTop: 10 },
  metaText: { fontSize: 12, color: '#888', marginTop: 5, fontStyle: 'italic' },
  altSection: { marginTop: 30, padding: 20, backgroundColor: '#f9f9f9', borderRadius: 10, borderWidth: 1, borderColor: '#eee' },
  altTitle: { fontSize: 16, fontWeight: 'bold', color: '#00C853' },
  altSubtitle: { fontSize: 14, color: '#666', marginBottom: 15 },
  altAction: { fontSize: 16, fontWeight: 'bold', color: '#333', marginBottom: 20 },
  altLabel: { fontSize: 14, fontWeight: 'bold', color: '#888', marginBottom: 10 },
  altEffect: { fontSize: 15, color: '#00C853', fontWeight: 'bold' }
});
