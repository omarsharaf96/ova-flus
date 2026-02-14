import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getBudgets, getBudget, createBudget, updateBudget, deleteBudget, type CreateBudgetInput } from '@/lib/api/budgets';

export function useBudgets() {
  return useQuery({ queryKey: ['budgets'], queryFn: getBudgets });
}

export function useBudget(id: string) {
  return useQuery({ queryKey: ['budgets', id], queryFn: () => getBudget(id) });
}

export function useCreateBudget() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (input: CreateBudgetInput) => createBudget(input),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['budgets'] }),
  });
}

export function useUpdateBudget() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ id, input }: { id: string; input: Partial<CreateBudgetInput> }) =>
      updateBudget(id, input),
    onSuccess: (_, { id }) => {
      queryClient.invalidateQueries({ queryKey: ['budgets'] });
      queryClient.invalidateQueries({ queryKey: ['budgets', id] });
    },
  });
}

export function useDeleteBudget() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => deleteBudget(id),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['budgets'] }),
  });
}
