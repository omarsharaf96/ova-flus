'use client';

import { useCallback, useEffect } from 'react';
import { usePlaidLink } from 'react-plaid-link';
import { Button } from '@/components/ui/Button';
import { useCreateLinkToken, useExchangeToken } from '@/lib/hooks/usePlaid';

interface PlaidLinkProps {
  onSuccess?: () => void;
}

export function PlaidLink({ onSuccess }: PlaidLinkProps) {
  const createLinkToken = useCreateLinkToken();
  const exchangeToken = useExchangeToken();

  const onPlaidSuccess = useCallback(
    (publicToken: string, metadata: { institution: { institution_id: string; name: string } | null }) => {
      exchangeToken.mutate(
        {
          publicToken,
          institutionId: metadata.institution?.institution_id ?? '',
          institutionName: metadata.institution?.name ?? '',
        },
        { onSuccess }
      );
    },
    [exchangeToken, onSuccess]
  );

  const { open, ready } = usePlaidLink({
    token: createLinkToken.data?.linkToken ?? null,
    onSuccess: onPlaidSuccess,
  });

  useEffect(() => {
    if (createLinkToken.data?.linkToken && ready) {
      open();
    }
  }, [createLinkToken.data?.linkToken, ready, open]);

  const handleClick = () => {
    if (createLinkToken.data?.linkToken && ready) {
      open();
    } else {
      createLinkToken.mutate();
    }
  };

  return (
    <Button
      onClick={handleClick}
      disabled={createLinkToken.isPending || exchangeToken.isPending}
    >
      {createLinkToken.isPending
        ? 'Connecting...'
        : exchangeToken.isPending
          ? 'Linking Account...'
          : 'Connect Bank Account'}
    </Button>
  );
}
