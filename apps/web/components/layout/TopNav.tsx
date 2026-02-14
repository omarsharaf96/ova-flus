'use client';

import { useUIStore } from '@/lib/store/uiStore';

export function TopNav() {
  const toggleSidebar = useUIStore((s) => s.toggleSidebar);

  return (
    <header className="flex h-14 items-center gap-4 border-b border-[hsl(var(--border))] bg-[hsl(var(--card))] px-4">
      <button
        onClick={toggleSidebar}
        className="rounded-lg p-1.5 hover:bg-[hsl(var(--muted))] md:hidden"
        aria-label="Toggle sidebar"
      >
        <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
          <path strokeLinecap="round" strokeLinejoin="round" d="M4 6h16M4 12h16M4 18h16" />
        </svg>
      </button>

      <div className="flex-1">
        <input
          type="search"
          placeholder="Search transactions, budgets..."
          className="w-full max-w-sm rounded-lg border bg-[hsl(var(--input))] px-3 py-1.5 text-sm outline-none focus:ring-2 focus:ring-brand-500"
        />
      </div>

      <button className="relative rounded-lg p-1.5 hover:bg-[hsl(var(--muted))]" aria-label="Notifications">
        <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
          <path strokeLinecap="round" strokeLinejoin="round" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
        </svg>
        <span className="absolute right-1 top-1 h-2 w-2 rounded-full bg-danger" />
      </button>

      <button className="flex h-8 w-8 items-center justify-center rounded-full bg-brand-100 text-sm font-medium text-brand-700">
        JD
      </button>
    </header>
  );
}
