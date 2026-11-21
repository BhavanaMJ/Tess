import React from 'react';

export const DashboardSkeleton: React.FC = () => {
  return (
    <div className="flex-1 overflow-y-auto p-6 space-y-5 animate-pulse" style={{ height: 'calc(100vh - 68px)' }}>
      {/* Hero Welcome Skeleton */}
      <div
        className="tess-card p-6 rounded-2xl"
        style={{ height: '180px', backgroundColor: 'var(--bg-secondary)', borderColor: 'var(--border)' }}
      >
        <div className="flex justify-between items-center h-full">
          <div className="space-y-3 flex-1">
            <div className="w-48 h-5 rounded-md bg-[rgba(255,255,255,0.06)]" />
            <div className="w-80 h-8 rounded-md bg-[rgba(255,255,255,0.08)]" />
            <div className="w-96 h-4 rounded-md bg-[rgba(255,255,255,0.04)]" />
          </div>
          <div className="w-24 h-24 rounded-full bg-[rgba(255,255,255,0.05)]" />
        </div>
      </div>

      {/* Metric Cards Skeleton */}
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-3">
        {[1, 2, 3, 4, 5].map((i) => (
          <div
            key={i}
            className="tess-card p-4 rounded-xl space-y-2.5"
            style={{ height: '100px', backgroundColor: 'var(--bg-secondary)', borderColor: 'var(--border)' }}
          >
            <div className="w-20 h-4 rounded bg-[rgba(255,255,255,0.05)]" />
            <div className="w-12 h-7 rounded bg-[rgba(255,255,255,0.08)]" />
            <div className="w-24 h-3 rounded bg-[rgba(255,255,255,0.03)]" />
          </div>
        ))}
      </div>

      {/* Main Grid Skeleton */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-5">
        <div className="lg:col-span-7 space-y-5">
          <div
            className="tess-card p-5 rounded-xl h-72"
            style={{ backgroundColor: 'var(--bg-secondary)', borderColor: 'var(--border)' }}
          />
          <div
            className="tess-card p-5 rounded-xl h-64"
            style={{ backgroundColor: 'var(--bg-secondary)', borderColor: 'var(--border)' }}
          />
        </div>
        <div className="lg:col-span-5 space-y-5">
          <div
            className="tess-card p-5 rounded-xl h-72"
            style={{ backgroundColor: 'var(--bg-secondary)', borderColor: 'var(--border)' }}
          />
          <div
            className="tess-card p-5 rounded-xl h-64"
            style={{ backgroundColor: 'var(--bg-secondary)', borderColor: 'var(--border)' }}
          />
        </div>
      </div>
    </div>
  );
};

