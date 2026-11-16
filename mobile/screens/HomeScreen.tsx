import { StatusBar } from 'expo-status-bar';
import React, { useState, useEffect } from 'react';
import { StyleSheet, Text, View, TextInput, Button, ScrollView, SafeAreaView, ActivityIndicator, TouchableOpacity } from 'react-native';
import { apiService } from '../services/api';
import Mascot, { MascotState } from '../components/Mascot';
import { supabase } from '../lib/supabase';
import { registerForPushNotificationsAsync } from '../lib/notifications';

type Message = { id: string; content: string; role: 'user' | 'assistant' | 'system' };
type Conversation = { id: string; title: string };
type ProductivitySummary = { total_active: number, overdue: number, due_today: number, due_this_week: number, completed_recently: number };
type FuturePrediction = { id: string, prediction_type: string, title: string, description: string, confidence: string, time_horizon: string, evidence: string[] };

export default function HomeScreen({ navigation }: any) {
  const [conversations, setConversations] = useState<Conversation[]>([]);
  const [currentConvId, setCurrentConvId] = useState<string | null>(null);
  const [messages, setMessages] = useState<Message[]>([]);
  const [inputText, setInputText] = useState('');
  const [mascotState, setMascotState] = useState<MascotState>('IDLE');
  const [summary, setSummary] = useState<ProductivitySummary | null>(null);
  const [predictions, setPredictions] = useState<FuturePrediction[]>([]);
  const [isSyncing, setIsSyncing] = useState(false);

  useEffect(() => {
    loadConversations();
    loadProductivity();
    loadFuture();
    registerForPushNotificationsAsync();
  }, []);

  useEffect(() => {
    if (currentConvId) {
      loadMessages(currentConvId);
    }
  }, [currentConvId]);

  const loadConversations = async () => {
    try {
      const convs = await apiService.getConversations();
      setConversations(convs);
      if (convs.length > 0) {
        setCurrentConvId(convs[0].id);
      } else {
        startNewConversation();
      }
    } catch (e) {
      console.error(e);
    }
  };

  const startNewConversation = async () => {
    try {
      const newConv = await apiService.createConversation();
      setConversations([newConv, ...conversations]);
      setCurrentConvId(newConv.id);
      setMessages([]);
    } catch (e) {
      console.error(e);
    }
  };

  const loadMessages = async (id: string) => {
    try {
      const msgs = await apiService.getMessages(id);
      setMessages(msgs);
    } catch (e) {
      console.error(e);
    }
  };

  const loadProductivity = async () => {
    try {
      const sum = await apiService.getProductivitySummary();
      setSummary(sum);
      if (sum.overdue > 0) {
        setMascotState('WARNING' as MascotState);
      } else {
        setMascotState('IDLE');
      }
    } catch (e) {
      console.error(e);
    }
  };

  const loadFuture = async () => {
    try {
      const preds = await apiService.getFuturePredictions();
      setPredictions(preds);
    } catch (e) {
      console.error(e);
    }
  };

  const handleSync = async () => {
    setIsSyncing(true);
    setMascotState('THINKING');
    try {
      await apiService.syncOpenProject();
      setMascotState('SIMULATING');
      await apiService.analyzeFuture();
      await loadProductivity();
      await loadFuture();
      setMascotState('IDLE');
    } catch (e) {
      console.error(e);
      setMascotState('IDLE');
    } finally {
      setIsSyncing(false);
    }
  };

  const handleSend = async () => {
    if (!inputText.trim() || !currentConvId) return;

    const userMsg = { id: Date.now().toString(), content: inputText, role: 'user' as const };
    setMessages(prev => [...prev, userMsg]);
    setInputText('');
    
    setMascotState('THINKING');
    try {
      const response = await apiService.chat(currentConvId, userMsg.content);
      
      setMascotState('RESPONDING');
      const tessMsg = { id: Date.now().toString(), content: response.response, role: 'assistant' as const };
      setMessages(prev => [...prev, tessMsg]);
      
      setTimeout(() => setMascotState('IDLE'), 2000);
    } catch (error) {
      setMascotState('IDLE');
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <Mascot state={mascotState} />
        <View style={{ flexDirection: 'row' }}>
          <Button title="New Chat" onPress={startNewConversation} />
          <View style={{ width: 5 }} />
          <Button title="Settings" onPress={() => navigation.navigate('Settings')} color="gray" />
          <View style={{ width: 5 }} />
          <Button title="Proactive" onPress={() => navigation.navigate('Interventions')} color="#FF9800" />
        </View>
      </View>

      {summary && (
        <View style={styles.todaySection}>
          <View style={styles.todayHeader}>
            <Text style={styles.todayTitle}>TODAY</Text>
            {isSyncing ? <ActivityIndicator /> : <Button title="Sync" onPress={handleSync} />}
          </View>
          <Text>⚠ {summary.overdue} Overdue</Text>
          <Text>● {summary.due_today} Due Today</Text>
          <Text>○ {summary.due_this_week} Due This Week</Text>
          <Text>✓ {summary.completed_recently} Completed Recently</Text>
        </View>
      )}

      {predictions.length > 0 && (
        <View style={styles.futureSection}>
          <View style={styles.futureHeader}>
            <Text style={styles.futureTitle}>FUTURE</Text>
            <Button title="Meet Tomorrow You" onPress={() => navigation.navigate('Tomorrow')} color="#9C27B0" />
          </View>
          <Text style={styles.futureSubtitle}>Based on your current work:</Text>
          {predictions.slice(0, 2).map((p) => (
            <View key={p.id} style={styles.predictionCard}>
              <Text style={[styles.predictionTitle, p.prediction_type === 'RISK' ? styles.riskText : styles.posText]}>
                {p.prediction_type === 'RISK' ? '⚠ ' : (p.prediction_type === 'POSITIVE' ? '✓ ' : '• ')} 
                {p.title}
              </Text>
              <Text style={styles.predictionDesc}>{p.description}</Text>
              <Text style={styles.predictionMeta}>Confidence: {p.confidence} | Horizon: {p.time_horizon}</Text>
            </View>
          ))}
        </View>
      )}
      
      <ScrollView style={styles.chatArea}>
        {messages.filter(m => m.role !== 'system').map(msg => (
          <View key={msg.id} style={[styles.messageBubble, msg.role === 'user' ? styles.userMessage : styles.tessMessage]}>
            <Text style={styles.messageText}>{msg.content}</Text>
          </View>
        ))}
      </ScrollView>

      <View style={styles.inputContainer}>
        <TextInput
          style={styles.input}
          value={inputText}
          onChangeText={setInputText}
          placeholder="Message TESS..."
          onSubmitEditing={handleSend}
        />
        <Button title="Send" onPress={handleSend} />
      </View>
      <StatusBar style="auto" />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#f5f5f5' },
  header: { padding: 10, backgroundColor: '#fff', alignItems: 'center', borderBottomWidth: 1, borderColor: '#eee', flexDirection: 'row', justifyContent: 'space-between' },
  todaySection: { backgroundColor: '#eef5ff', padding: 15, borderBottomWidth: 1, borderColor: '#cce0ff' },
  todayHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 5 },
  todayTitle: { fontSize: 16, fontWeight: 'bold', color: '#0055cc' },
  futureSection: { backgroundColor: '#f9f9f9', padding: 15, borderBottomWidth: 1, borderColor: '#eee' },
  futureHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 5 },
  futureTitle: { fontSize: 16, fontWeight: 'bold', color: '#9C27B0' },
  futureSubtitle: { fontSize: 12, color: '#666', marginBottom: 10 },
  predictionCard: { backgroundColor: '#fff', padding: 10, borderRadius: 5, marginBottom: 10, borderWidth: 1, borderColor: '#ddd' },
  predictionTitle: { fontWeight: 'bold', marginBottom: 4 },
  riskText: { color: '#FF3B30' },
  posText: { color: '#00C853' },
  predictionDesc: { fontSize: 14, color: '#333', marginBottom: 6 },
  predictionMeta: { fontSize: 12, color: '#888' },
  chatArea: { flex: 1, padding: 10 },
  messageBubble: { padding: 12, borderRadius: 8, marginBottom: 10, maxWidth: '80%' },
  userMessage: { backgroundColor: '#007AFF', alignSelf: 'flex-end' },
  tessMessage: { backgroundColor: '#e5e5ea', alignSelf: 'flex-start' },
  messageText: { fontSize: 16, color: '#333' },
  inputContainer: { flexDirection: 'row', padding: 10, backgroundColor: '#fff', borderTopWidth: 1, borderColor: '#eee' },
  input: { flex: 1, borderWidth: 1, borderColor: '#ddd', borderRadius: 20, paddingHorizontal: 15, marginRight: 10, backgroundColor: '#fafafa' },
});
