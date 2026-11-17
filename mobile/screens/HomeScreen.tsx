import { StatusBar } from 'expo-status-bar';
import React, { useState, useEffect } from 'react';
import {
  StyleSheet,
  Text,
  View,
  TextInput,
  ScrollView,
  SafeAreaView,
  ActivityIndicator,
  TouchableOpacity,
  KeyboardAvoidingView,
  Platform
} from 'react-native';
import { apiService } from '../services/api';
import Mascot, { MascotState } from '../components/Mascot';
import { colors } from '../theme/tokens';

type Message = { id: string; content: string; role: 'user' | 'assistant' | 'system' };
type Conversation = { id: string; title: string };
type ProductivitySummary = {
  total_active: number;
  overdue: number;
  due_today: number;
  due_this_week: number;
  completed_recently: number;
};
type FuturePrediction = {
  id: string;
  prediction_type: string;
  title: string;
  description: string;
  confidence: string;
  time_horizon: string;
  evidence: string[];
};

export default function HomeScreen({ navigation }: any) {
  const [conversations, setConversations] = useState<Conversation[]>([]);
  const [currentConvId, setCurrentConvId] = useState<string | null>(null);
  const [messages, setMessages] = useState<Message[]>([]);
  const [inputText, setInputText] = useState('');
  const [mascotState, setMascotState] = useState<MascotState>('IDLE');
  const [summary, setSummary] = useState<ProductivitySummary | null>(null);
  const [predictions, setPredictions] = useState<FuturePrediction[]>([]);
  const [isSyncing, setIsSyncing] = useState(false);
  const [interventionsCount, setInterventionsCount] = useState(0);

  const getGreeting = () => {
    const hour = new Date().getHours();
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  };

  useEffect(() => {
    loadConversations();
    loadProductivity();
    loadFuture();
    loadInterventions();
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
      const newConv = await apiService.createConversation('Mobile Dialogue');
      setConversations((prev) => [newConv, ...prev]);
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
        setMascotState('WARNING');
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

  const loadInterventions = async () => {
    try {
      const invs = await apiService.getInterventions();
      const active = invs.filter((i: any) => i.status === 'SENT');
      setInterventionsCount(active.length);
      if (active.length > 0) {
        setMascotState('INTERVENING');
      }
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
      await loadInterventions();
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

    const userMsg = { id: Date.now().toString(), content: inputText.trim(), role: 'user' as const };
    setMessages((prev) => [...prev, userMsg]);
    setInputText('');

    setMascotState('THINKING');
    try {
      const response = await apiService.chat(currentConvId, userMsg.content);
      setMascotState('RESPONDING');
      const tessMsg = { id: Date.now().toString(), content: response.response, role: 'assistant' as const };
      setMessages((prev) => [...prev, tessMsg]);
      setTimeout(() => setMascotState('IDLE'), 2000);
    } catch (error) {
      setMascotState('IDLE');
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar style="light" />
      <KeyboardAvoidingView
        style={{ flex: 1 }}
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      >
        {/* TOP COMMAND HEADER */}
        <View style={styles.header}>
          <View>
            <View style={styles.brandRow}>
              <Text style={styles.brandTitle}>TESS</Text>
              <View style={styles.tagBadge}>
                <Text style={styles.tagText}>OS 2.0</Text>
              </View>
            </View>
            <Text style={styles.greetingText}>{getGreeting()}</Text>
          </View>

          {/* Quick Action Navigation Pills */}
          <View style={styles.navRow}>
            <TouchableOpacity
              onPress={() => navigation.navigate('Tomorrow')}
              style={[styles.pillBtn, styles.pillFutures]}
            >
              <Text style={[styles.pillText, { color: colors.cyan }]}>Futures</Text>
            </TouchableOpacity>

            <TouchableOpacity
              onPress={() => navigation.navigate('Interventions')}
              style={[
                styles.pillBtn,
                interventionsCount > 0 ? styles.pillAlertActive : styles.pillAlert
              ]}
            >
              <Text
                style={[
                  styles.pillText,
                  { color: interventionsCount > 0 ? colors.danger : colors.warning }
                ]}
              >
                Alerts {interventionsCount > 0 ? `(${interventionsCount})` : ''}
              </Text>
            </TouchableOpacity>

            <TouchableOpacity
              onPress={() => navigation.navigate('Settings')}
              style={styles.pillBtn}
            >
              <Text style={styles.pillText}>Settings</Text>
            </TouchableOpacity>
          </View>
        </View>

        <ScrollView
          style={styles.scrollArea}
          contentContainerStyle={{ paddingBottom: 24 }}
          showsVerticalScrollIndicator={false}
        >
          {/* LIVING HOLOGRAPHIC MASCOT HERO */}
          <View style={styles.mascotHero}>
            <Mascot state={mascotState} size="lg" showLabel={true} />
            <Text style={styles.presenceSubtext}>
              {interventionsCount > 0
                ? 'Trajectory risk detected — Intervention active'
                : 'Ambient observation & future simulation standing by'}
            </Text>
          </View>

          {/* PRODUCTIVITY TELEMETRY 4-CHIP GRID */}
          {summary && (
            <View style={styles.telemetrySection}>
              <View style={styles.sectionHeader}>
                <Text style={styles.sectionTitle}>DAILY INTELLIGENCE</Text>
                <TouchableOpacity
                  onPress={handleSync}
                  disabled={isSyncing}
                  style={styles.syncBtn}
                >
                  {isSyncing ? (
                    <ActivityIndicator size="small" color={colors.cyan} />
                  ) : (
                    <Text style={styles.syncText}>SYNC</Text>
                  )}
                </TouchableOpacity>
              </View>

              <View style={styles.grid2x2}>
                <View style={styles.telemetryCard}>
                  <Text style={styles.chipLabel}>TOTAL ACTIVE</Text>
                  <Text style={styles.chipValue}>{summary.total_active}</Text>
                  <Text style={styles.chipMeta}>Work packages</Text>
                </View>

                <View
                  style={[
                    styles.telemetryCard,
                    summary.overdue > 0 && { borderColor: 'rgba(251, 113, 133, 0.4)' }
                  ]}
                >
                  <Text
                    style={[
                      styles.chipLabel,
                      { color: summary.overdue > 0 ? colors.danger : colors.neutral }
                    ]}
                  >
                    OVERDUE
                  </Text>
                  <Text
                    style={[
                      styles.chipValue,
                      { color: summary.overdue > 0 ? colors.danger : colors.textPrimary }
                    ]}
                  >
                    {summary.overdue}
                  </Text>
                  <Text style={styles.chipMeta}>Requires focus</Text>
                </View>

                <View style={styles.telemetryCard}>
                  <Text style={[styles.chipLabel, { color: colors.warning }]}>
                    DUE TODAY
                  </Text>
                  <Text style={[styles.chipValue, { color: colors.warning }]}>
                    {summary.due_today}
                  </Text>
                  <Text style={styles.chipMeta}>Immediate priority</Text>
                </View>

                <View style={styles.telemetryCard}>
                  <Text style={[styles.chipLabel, { color: colors.success }]}>
                    COMPLETED
                  </Text>
                  <Text style={[styles.chipValue, { color: colors.success }]}>
                    {summary.completed_recently}
                  </Text>
                  <Text style={styles.chipMeta}>Recent momentum</Text>
                </View>
              </View>
            </View>
          )}

          {/* FUTURE ENGINE TRAJECTORY PREVIEW */}
          {predictions.length > 0 && (
            <View style={styles.futureSection}>
              <View style={styles.sectionHeader}>
                <View style={styles.futureTitleRow}>
                  <Text style={[styles.sectionTitle, { color: colors.cyan }]}>
                    FUTURE TRAJECTORY
                  </Text>
                </View>
                <TouchableOpacity
                  onPress={() => navigation.navigate('Tomorrow')}
                  style={styles.meetBtn}
                >
                  <Text style={styles.meetBtnText}>Simulate →</Text>
                </TouchableOpacity>
              </View>

              {predictions.slice(0, 2).map((p) => {
                const isRisk = p.prediction_type === 'RISK';
                return (
                  <View
                    key={p.id}
                    style={[
                      styles.predictionCard,
                      { borderColor: isRisk ? 'rgba(251, 113, 133, 0.35)' : 'rgba(34, 211, 238, 0.25)' }
                    ]}
                  >
                    <View style={styles.predCardHeader}>
                      <Text
                        style={[
                          styles.predCardTitle,
                          { color: isRisk ? colors.danger : colors.cyan }
                        ]}
                        numberOfLines={1}
                      >
                        {isRisk ? '⚠ ' : '✓ '}
                        {p.title}
                      </Text>
                      <View
                        style={[
                          styles.predBadge,
                          { backgroundColor: isRisk ? 'rgba(251, 113, 133, 0.15)' : 'rgba(34, 211, 238, 0.15)' }
                        ]}
                      >
                        <Text
                          style={[
                            styles.predBadgeText,
                            { color: isRisk ? colors.danger : colors.cyan }
                          ]}
                        >
                          {p.confidence}
                        </Text>
                      </View>
                    </View>
                    <Text style={styles.predDesc} numberOfLines={2}>
                      {p.description}
                    </Text>
                  </View>
                );
              })}
            </View>
          )}

          {/* ACTIVE DIALOGUE STREAM */}
          <View style={styles.dialogueSection}>
            <View style={styles.sectionHeader}>
              <Text style={styles.sectionTitle}>CONTINUOUS DIALOGUE</Text>
              <TouchableOpacity onPress={startNewConversation}>
                <Text style={styles.newChatText}>+ New</Text>
              </TouchableOpacity>
            </View>

            {messages.length === 0 ? (
              <View style={styles.emptyChatBox}>
                <Text style={styles.emptyChatText}>
                  Ask TESS to summarize your priorities, explore trajectories, or plan an action.
                </Text>
              </View>
            ) : (
              messages
                .filter((m) => m.role !== 'system')
                .slice(-6)
                .map((msg) => {
                  const isUser = msg.role === 'user';
                  return (
                    <View
                      key={msg.id}
                      style={[
                        styles.msgBubble,
                        isUser ? styles.userBubble : styles.tessBubble
                      ]}
                    >
                      <Text style={styles.msgText}>{msg.content}</Text>
                    </View>
                  );
                })
            )}
          </View>
        </ScrollView>

        {/* COMPOSER BAR */}
        <View style={styles.composerBar}>
          <TextInput
            style={styles.composerInput}
            value={inputText}
            onChangeText={setInputText}
            placeholder="Message TESS companion..."
            placeholderTextColor={colors.textMuted}
            onSubmitEditing={handleSend}
            returnKeyType="send"
          />
          <TouchableOpacity
            onPress={handleSend}
            disabled={!inputText.trim()}
            style={[
              styles.sendBtn,
              { opacity: inputText.trim() ? 1 : 0.4 }
            ]}
          >
            <Text style={styles.sendBtnText}>→</Text>
          </TouchableOpacity>
        </View>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.bgPrimary
  },
  header: {
    paddingHorizontal: 20,
    paddingTop: 12,
    paddingBottom: 14,
    backgroundColor: colors.bgSecondary,
    borderBottomWidth: 1,
    borderColor: colors.border,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center'
  },
  brandRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8
  },
  brandTitle: {
    fontSize: 18,
    fontWeight: '800',
    fontFamily: 'monospace',
    color: colors.textPrimary,
    letterSpacing: 2
  },
  tagBadge: {
    paddingHorizontal: 6,
    paddingVertical: 1,
    borderRadius: 8,
    backgroundColor: 'rgba(34, 211, 238, 0.12)',
    borderWidth: 1,
    borderColor: 'rgba(34, 211, 238, 0.3)'
  },
  tagText: {
    fontSize: 9,
    fontFamily: 'monospace',
    fontWeight: '700',
    color: colors.cyan
  },
  greetingText: {
    fontSize: 11,
    color: colors.textMuted,
    marginTop: 2,
    fontWeight: '500'
  },
  navRow: {
    flexDirection: 'row',
    gap: 6
  },
  pillBtn: {
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 8,
    backgroundColor: 'rgba(255, 255, 255, 0.04)',
    borderWidth: 1,
    borderColor: colors.border
  },
  pillFutures: {
    backgroundColor: 'rgba(34, 211, 238, 0.08)',
    borderColor: 'rgba(34, 211, 238, 0.3)'
  },
  pillAlert: {
    backgroundColor: 'rgba(251, 191, 36, 0.08)',
    borderColor: 'rgba(251, 191, 36, 0.3)'
  },
  pillAlertActive: {
    backgroundColor: 'rgba(251, 113, 133, 0.15)',
    borderColor: 'rgba(251, 113, 133, 0.45)'
  },
  pillText: {
    fontSize: 11,
    fontWeight: '600',
    color: colors.textSecondary
  },
  scrollArea: {
    flex: 1,
    paddingHorizontal: 16
  },
  mascotHero: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 20,
    marginTop: 8,
    borderRadius: 16,
    backgroundColor: 'rgba(17, 20, 38, 0.6)',
    borderWidth: 1,
    borderColor: colors.border
  },
  presenceSubtext: {
    fontSize: 11,
    color: colors.textMuted,
    marginTop: 10,
    fontFamily: 'monospace'
  },
  telemetrySection: {
    marginTop: 16
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8
  },
  sectionTitle: {
    fontSize: 11,
    fontWeight: '700',
    fontFamily: 'monospace',
    color: colors.textMuted,
    letterSpacing: 1.5
  },
  syncBtn: {
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 6,
    backgroundColor: 'rgba(34, 211, 238, 0.1)',
    borderWidth: 1,
    borderColor: 'rgba(34, 211, 238, 0.3)'
  },
  syncText: {
    fontSize: 10,
    fontFamily: 'monospace',
    fontWeight: '700',
    color: colors.cyan
  },
  grid2x2: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8
  },
  telemetryCard: {
    width: '48.5%',
    backgroundColor: colors.bgSurface,
    padding: 12,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: colors.border
  },
  chipLabel: {
    fontSize: 9,
    fontFamily: 'monospace',
    fontWeight: '700',
    color: colors.textMuted,
    letterSpacing: 1
  },
  chipValue: {
    fontSize: 22,
    fontWeight: '800',
    fontFamily: 'monospace',
    color: colors.textPrimary,
    marginVertical: 2
  },
  chipMeta: {
    fontSize: 10,
    color: colors.textMuted
  },
  futureSection: {
    marginTop: 18
  },
  futureTitleRow: {
    flexDirection: 'row',
    alignItems: 'center'
  },
  meetBtn: {
    paddingHorizontal: 8,
    paddingVertical: 3
  },
  meetBtnText: {
    fontSize: 11,
    color: colors.cyan,
    fontWeight: '600',
    fontFamily: 'monospace'
  },
  predictionCard: {
    backgroundColor: colors.bgSurface,
    padding: 12,
    borderRadius: 12,
    borderWidth: 1,
    marginTop: 8
  },
  predCardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 4
  },
  predCardTitle: {
    fontSize: 13,
    fontWeight: '700',
    flex: 1,
    marginRight: 8
  },
  predBadge: {
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4
  },
  predBadgeText: {
    fontSize: 9,
    fontFamily: 'monospace',
    fontWeight: '700'
  },
  predDesc: {
    fontSize: 11,
    color: colors.textSecondary,
    lineHeight: 16
  },
  dialogueSection: {
    marginTop: 18
  },
  newChatText: {
    fontSize: 11,
    fontFamily: 'monospace',
    color: colors.violetLight
  },
  emptyChatBox: {
    backgroundColor: 'rgba(255, 255, 255, 0.02)',
    padding: 14,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: colors.border,
    alignItems: 'center'
  },
  emptyChatText: {
    fontSize: 11,
    color: colors.textMuted,
    textAlign: 'center',
    lineHeight: 16
  },
  msgBubble: {
    padding: 12,
    borderRadius: 14,
    marginBottom: 8,
    maxWidth: '85%'
  },
  userBubble: {
    backgroundColor: 'rgba(139, 92, 246, 0.22)',
    borderWidth: 1,
    borderColor: 'rgba(139, 92, 246, 0.4)',
    alignSelf: 'flex-end'
  },
  tessBubble: {
    backgroundColor: colors.bgSurface,
    borderWidth: 1,
    borderColor: colors.border,
    alignSelf: 'flex-start'
  },
  msgText: {
    fontSize: 13,
    color: colors.textPrimary,
    lineHeight: 18
  },
  composerBar: {
    flexDirection: 'row',
    padding: 12,
    backgroundColor: colors.bgSecondary,
    borderTopWidth: 1,
    borderColor: colors.border,
    alignItems: 'center'
  },
  composerInput: {
    flex: 1,
    backgroundColor: 'rgba(5, 6, 10, 0.7)',
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 20,
    paddingHorizontal: 16,
    paddingVertical: 8,
    color: colors.textPrimary,
    fontSize: 12,
    marginRight: 10
  },
  sendBtn: {
    width: 38,
    height: 38,
    borderRadius: 19,
    backgroundColor: colors.violet,
    alignItems: 'center',
    justifyContent: 'center'
  },
  sendBtnText: {
    color: '#FFF',
    fontSize: 18,
    fontWeight: '700'
  }
});
