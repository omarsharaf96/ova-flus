'use client';

import { Button } from '@/components/ui/Button';
import { useLinkedAccounts, useUnlinkAccount, useSyncTransactions } from '@/lib/hooks/usePlaid';

export function LinkedAccountsList() {
  const { data: accounts, isLoading } = useLinkedAccounts();
  const unlinkAccount = useUnlinkAccount();
  const syncTransactions = useSyncTransactions();

  if (isLoading) {
    return (
      <div className="space-y-3">
        {[1, 2].map((i) => (
          <div key={i} className="h-16 animate-pulse rounded-lg bg-[hsl(var(--muted))]" />
        ))}
      </div>
    );
  }

  if (!accounts || accounts.length === 0) {
    return (
      <p className="text-sm text-[hsl(var(--muted-foreground))]">
        No bank accounts connected yet. Click below to link your first account.
      </p>
    );
  }

  return (
    <div className="space-y-3">
      {accounts.map((account) => (
        <div
          key={account.id}
          className="flex items-center justify-between rounded-lg border border-[hsl(var(--border))] p-3"
        >
          <div>
            <p className="text-sm font-medium">{account.name}</p>
            <p className="text-xs text-[hsl(var(--muted-foreground))]">
              {account.type}{account.mask ? ` ••••${account.mask}` : ''}
              {account.currentBalance != null && ` · $${account.currentBalance.toFixed(2)}`}
            </p>
          </div>
          <div className="flex gap-2">
            <Button
              variant="secondary"
              onClick={() => syncTransactions.mutate(account.id)}
              disabled={syncTransactions.isPending}
            >
              Sync
            </Button>
            <Button
              variant="ghost"
              onClick={() => unlinkAccount.mutate(account.id)}
              disabled={unlinkAccount.isPending}
            >
              Unlink
            </Button>
          </div>
        </div>
      ))}
    </div>
  );
}
