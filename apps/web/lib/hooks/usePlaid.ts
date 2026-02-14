import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getLinkedAccounts, createLinkToken, exchangeToken, syncTransactions, unlinkAccount } from '@/lib/api/plaid';

export function useLinkedAccounts() {
  return useQuery({ queryKey: ['linkedAccounts'], queryFn: getLinkedAccounts });
}

export function useCreateLinkToken() {
  return useMutation({
    mutationFn: () => createLinkToken(),
  });
}

export function useExchangeToken() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ publicToken, institutionId, institutionName }: { publicToken: string; institutionId: string; institutionName: string }) =>
      exchangeToken(publicToken, institutionId, institutionName),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['linkedAccounts'] }),
  });
}

export function useSyncTransactions() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (accountId?: string) => syncTransactions(accountId),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['linkedAccounts'] }),
  });
}

export function useUnlinkAccount() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (accountId: string) => unlinkAccount(accountId),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['linkedAccounts'] }),
  });
}
