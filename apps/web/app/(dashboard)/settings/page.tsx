'use client';

import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { useUIStore } from '@/lib/store/uiStore';
import { LinkedAccountsList } from '@/components/plaid/LinkedAccountsList';
import { PlaidLink } from '@/components/plaid/PlaidLink';

export default function SettingsPage() {
  const { theme, setTheme } = useUIStore();

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">Settings</h1>

      <Card>
        <h2 className="mb-4 text-lg font-semibold">Connected Bank Accounts</h2>
        <p className="mb-4 text-sm text-[hsl(var(--muted-foreground))]">
          Connect your bank accounts to automatically import transactions.
        </p>
        <LinkedAccountsList />
        <div className="mt-4">
          <PlaidLink />
        </div>
      </Card>

      <Card>
        <h2 className="mb-4 text-lg font-semibold">Profile</h2>
        <div className="space-y-3">
          <div>
            <label className="mb-1 block text-sm font-medium">Display Name</label>
            <input
              type="text"
              defaultValue="John Doe"
              className="w-full rounded-lg border bg-[hsl(var(--input))] px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-brand-500"
            />
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium">Email</label>
            <input
              type="email"
              defaultValue="john@example.com"
              disabled
              className="w-full rounded-lg border bg-[hsl(var(--muted))] px-3 py-2 text-sm"
            />
          </div>
          <Button>Save Changes</Button>
        </div>
      </Card>

      <Card>
        <h2 className="mb-4 text-lg font-semibold">Appearance</h2>
        <div className="flex gap-2">
          <button
            onClick={() => setTheme('light')}
            className={`rounded-lg px-4 py-2 text-sm ${
              theme === 'light' ? 'bg-brand-600 text-white' : 'bg-[hsl(var(--muted))]'
            }`}
          >
            Light
          </button>
          <button
            onClick={() => setTheme('dark')}
            className={`rounded-lg px-4 py-2 text-sm ${
              theme === 'dark' ? 'bg-brand-600 text-white' : 'bg-[hsl(var(--muted))]'
            }`}
          >
            Dark
          </button>
        </div>
      </Card>

      <Card>
        <h2 className="mb-4 text-lg font-semibold">Notifications</h2>
        <div className="space-y-3">
          <label className="flex items-center gap-3">
            <input type="checkbox" defaultChecked className="rounded" />
            <span className="text-sm">Budget alerts</span>
          </label>
          <label className="flex items-center gap-3">
            <input type="checkbox" defaultChecked className="rounded" />
            <span className="text-sm">Portfolio updates</span>
          </label>
          <label className="flex items-center gap-3">
            <input type="checkbox" className="rounded" />
            <span className="text-sm">Weekly summary email</span>
          </label>
        </div>
      </Card>

      <Card>
        <h2 className="mb-4 text-lg font-semibold">Data</h2>
        <div className="flex gap-2">
          <Button variant="secondary">Export Data</Button>
        </div>
      </Card>

      <Card>
        <h2 className="mb-4 text-lg font-semibold">Account</h2>
        <Button variant="destructive">Delete Account</Button>
      </Card>
    </div>
  );
}
