import React, { useState } from 'react';
import { Compass, ArrowRight, AlertTriangle, ShieldCheck, ChevronDown, ChevronUp, Sparkles } from 'lucide-react';
import { FuturePrediction } from '../../types';
import { ScreenTab } from '../Sidebar';

interface FutureTrajectoryPreviewProps {
  predictions: FuturePrediction[];
  onNavigate: (tab: ScreenTab) => void;
}

export const FutureTrajectoryPreview: React.FC<FutureTrajectoryPreviewProps> = ({
  predictions,
  onNavigate
}) => {
  const [expandedId, setExpandedId] = useState<string | null>(null);

  const toggleExpand = (id: string) => {
    setExpandedId((prev) => (prev === id ? null : id));
  };

  return (
    <div
      className="tess-card p-5 h-full flex flex-col justify-between"
      style={{
        borderColor: 'rgba(169, 154, 217, 0.35)',
        background: 'linear-gradient(135deg, rgba(169, 154, 217, 0.05) 0%, rgba(17, 20, 38, 0.85) 100%)'
      }}
    >
      <div>
        {/* Section Header */}
        <div className="flex items-center justify-between pb-3 mb-3 border-b border-[rgba(255,255,255,0.06)]">
          <div className="flex items-center gap-2">
            <Compass style={{ width: '1.1rem', height: '1.1rem', color: '#A99AD9' }} />
            <div>
              <span className="text-xs font-bold text-primary font-mono tracking-wider uppercase">
                Future Trajectory & Simulation
              </span>
            </div>
          </div>
          <button
            onClick={() => onNavigate('futures')}
            className="text-xs font-mono text-[#A99AD9] hover:text-[#BDF2E4] flex items-center gap-1 cursor-pointer transition-colors"
            style={{ background: 'none', border: 'none' }}
          >
            <span>Explore Engine</span>
            <ArrowRight style={{ width: '0.75rem', height: '0.75rem' }} />
          </button>
        </div>

        {/* Core Philosophy Banner */}
        <div
          className="p-3 mb-3.5 rounded-xl border flex items-center gap-2.5"
          style={{
            backgroundColor: 'rgba(169, 154, 217, 0.08)',
            borderColor: 'rgba(169, 154, 217, 0.25)'
          }}
        >
          <Sparkles style={{ width: '1rem', height: '1rem', color: '#A99AD9', flexShrink: 0 }} />
          <p className="text-[11px] text-[#BDF2E4] font-medium leading-relaxed m-0 italic">
            "Show me the most likely version of myself that I'm currently creating."
          </p>
        </div>

        {/* Prediction Cards */}
        {predictions.length === 0 ? (
          <div className="py-8 text-center text-muted">
            <Compass style={{ width: '1.75rem', height: '1.75rem', color: '#A99AD9', margin: '0 auto', opacity: 0.6 }} />
            <div className="text-xs font-semibold text-primary mt-2">
              No Active Trajectories Generated
            </div>
            <p className="text-[11px] text-muted mt-1 max-w-xs mx-auto">
              Simulate 24h, 3-day, or 7-day probabilistic trajectories to uncover potential bottlenecks before they happen.
            </p>
            <button
              onClick={() => onNavigate('futures')}
              className="mt-3.5 px-3 py-1.5 rounded-lg text-xs font-semibold bg-[rgba(169,154,217,0.15)] text-[#A99AD9] border border-[rgba(169,154,217,0.3)] hover:bg-[rgba(169,154,217,0.25)] transition-all cursor-pointer"
            >
              Run Future Simulation
            </button>
          </div>
        ) : (
          <div className="space-y-2.5">
            {predictions.slice(0, 3).map((pred) => {
              const isRisk = pred.prediction_type === 'RISK' || pred.probability >= 0.7;
              const probPercent = Math.round(pred.probability * 100);
              const isExpanded = expandedId === pred.id;

              return (
                <div
                  key={pred.id}
                  className="p-3 rounded-xl border transition-all duration-200"
                  style={{
                    backgroundColor: 'var(--bg-secondary)',
                    borderColor: isRisk ? 'rgba(251, 113, 133, 0.3)' : 'rgba(169, 154, 217, 0.25)'
                  }}
                >
                  <div className="flex items-start justify-between gap-2">
                    <div className="min-w-0">
                      <div className="flex items-center gap-2 mb-1">
                        <span
                          className="text-[9px] font-mono font-bold px-1.5 py-0.2 rounded"
                          style={{
                            backgroundColor: isRisk ? 'rgba(251,113,133,0.15)' : 'rgba(53,185,165,0.15)',
                            color: isRisk ? '#FB7185' : '#35B9A5',
                            border: `1px solid ${isRisk ? 'rgba(251,113,133,0.3)' : 'rgba(53,185,165,0.3)'}`
                          }}
                        >
                          {pred.prediction_type}
                        </span>
                        <span className="text-[10px] font-mono text-muted">
                          {pred.time_horizon} Horizon
                        </span>
                        {pred.confidence && (
                          <span className="text-[10px] font-mono text-muted/70">
                            Confidence: {pred.confidence}
                          </span>
                        )}
                      </div>

                      <div className="text-xs font-semibold text-primary">
                        {pred.title}
                      </div>

                      <p className="text-[11px] text-muted mt-1 leading-relaxed m-0">
                        {pred.description}
                      </p>
                    </div>

                    <div className="flex flex-col items-end gap-1 shrink-0">
                      <span
                        className="font-mono text-xs font-bold px-2 py-0.5 rounded-full"
                        style={{
                          backgroundColor: isRisk ? 'rgba(251,113,133,0.15)' : 'rgba(169,154,217,0.15)',
                          color: isRisk ? '#FB7185' : '#A99AD9',
                          border: `1px solid ${isRisk ? 'rgba(251,113,133,0.3)' : 'rgba(169,154,217,0.3)'}`
                        }}
                      >
                        {probPercent}% Prob
                      </span>

                      {(pred.reasoning || (pred.evidence && pred.evidence.length > 0)) && (
                        <button
                          onClick={() => toggleExpand(pred.id)}
                          className="text-[10px] font-mono text-muted hover:text-primary flex items-center gap-0.5 cursor-pointer mt-1"
                          style={{ background: 'none', border: 'none' }}
                        >
                          <span>{isExpanded ? 'Less' : 'Details'}</span>
                          {isExpanded ? (
                            <ChevronUp style={{ width: '0.75rem', height: '0.75rem' }} />
                          ) : (
                            <ChevronDown style={{ width: '0.75rem', height: '0.75rem' }} />
                          )}
                        </button>
                      )}
                    </div>
                  </div>

                  {/* Expandable Reasoning & Evidence */}
                  {isExpanded && (
                    <div className="mt-2.5 pt-2 border-t border-[rgba(255,255,255,0.06)] text-[11px]">
                      {pred.reasoning && (
                        <div className="mb-1.5">
                          <span className="text-muted font-medium">Model Reasoning: </span>
                          <span className="text-secondary">{pred.reasoning}</span>
                        </div>
                      )}
                      {pred.evidence && pred.evidence.length > 0 && (
                        <div>
                          <span className="text-muted font-medium">Supporting Signals: </span>
                          <span className="text-secondary">{pred.evidence.join(' • ')}</span>
                        </div>
                      )}
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* Model Disclaimer */}
      <div className="pt-3 border-t border-[rgba(255,255,255,0.06)] text-[10px] font-mono text-muted flex items-center justify-between">
        <span>Probabilistic model guidance • Non-deterministic</span>
        <button
          onClick={() => onNavigate('futures')}
          className="text-[#A99AD9] hover:underline cursor-pointer"
          style={{ background: 'none', border: 'none' }}
        >
          Explore All Scenarios
        </button>
      </div>
    </div>
  );
};
