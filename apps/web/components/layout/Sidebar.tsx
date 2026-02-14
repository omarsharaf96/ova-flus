'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useUIStore } from '@/lib/store/uiStore';

const navItems = [
  { href: '/', label: 'Dashboard', icon: 'grid' },
  { href: '/budgets', label: 'Budgets', icon: 'wallet' },
  { href: '/portfolio', label: 'Portfolio', icon: 'trending-up' },
  { href: '/watchlist', label: 'Watchlist', icon: 'eye' },
  { href: '/settings', label: 'Settings', icon: 'settings' },
];

const iconMap: Record<string, string> = {
  grid: 'M4 4h6v6H4zM14 4h6v6h-6zM4 14h6v6H4zM14 14h6v6h-6z',
  wallet: 'M21 12V7H5a2 2 0 010-4h14v4M3 5v14a2 2 0 002 2h16v-5M18 14a1 1 0 100 2 1 1 0 000-2z',
  'trending-up': 'M23 6l-9.5 9.5-5-5L1 18',
  eye: 'M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z M12 9a3 3 0 100 6 3 3 0 000-6z',
  settings: 'M12 15a3 3 0 100-6 3 3 0 000 6z',
};

export function Sidebar() {
  const pathname = usePathname();
  const sidebarOpen = useUIStore((s) => s.sidebarOpen);

  return (
    <aside
      className={`hidden md:flex w-64 flex-col border-r border-[hsl(var(--border))] bg-[hsl(var(--card))] ${
        !sidebarOpen ? 'md:hidden' : ''
      }`}
    >
      <div className="flex h-14 items-center border-b border-[hsl(var(--border))] px-4">
        <span className="text-xl font-bold text-brand-600">OvaFlus</span>
      </div>

      <nav className="flex-1 space-y-1 p-3">
        {navItems.map((item) => {
          const isActive = item.href === '/' ? pathname === '/' : pathname.startsWith(item.href);
          return (
            <Link
              key={item.href}
              href={item.href}
              className={`flex items-center gap-3 rounded-lg px-3 py-2 text-sm transition-colors ${
                isActive
                  ? 'bg-brand-50 font-medium text-brand-700 dark:bg-brand-950 dark:text-brand-300'
                  : 'text-[hsl(var(--muted-foreground))] hover:bg-[hsl(var(--muted))]'
              }`}
            >
              <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                <path strokeLinecap="round" strokeLinejoin="round" d={iconMap[item.icon] || ''} />
              </svg>
              {item.label}
            </Link>
          );
        })}
      </nav>

      <div className="border-t border-[hsl(var(--border))] p-4">
        <div className="flex items-center gap-3">
          <div className="flex h-8 w-8 items-center justify-center rounded-full bg-brand-100 text-sm font-medium text-brand-700">
            JD
          </div>
          <div className="text-sm">
            <p className="font-medium">John Doe</p>
            <p className="text-xs text-[hsl(var(--muted-foreground))]">john@example.com</p>
          </div>
        </div>
      </div>
    </aside>
  );
}
