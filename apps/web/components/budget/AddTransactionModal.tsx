'use client';

import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Modal } from '@/components/ui/Modal';
import { Button } from '@/components/ui/Button';

const transactionSchema = z.object({
  description: z.string().min(1, 'Description is required'),
  amount: z.coerce.number().positive('Amount must be positive'),
  category: z.string().min(1, 'Category is required'),
  date: z.string().min(1, 'Date is required'),
});

type TransactionForm = z.infer<typeof transactionSchema>;

interface AddTransactionModalProps {
  open: boolean;
  onClose: () => void;
}

export function AddTransactionModal({ open, onClose }: AddTransactionModalProps) {
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
    reset,
  } = useForm<TransactionForm>({
    resolver: zodResolver(transactionSchema),
  });

  async function onSubmit(data: TransactionForm) {
    // TODO: integrate with transaction service
    console.log('Add transaction:', data);
    reset();
    onClose();
  }

  return (
    <Modal open={open} onClose={onClose} title="Add Transaction">
      <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
        <div>
          <label className="mb-1 block text-sm font-medium">Description</label>
          <input
            {...register('description')}
            className="w-full rounded-lg border bg-[hsl(var(--input))] px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-brand-500"
            placeholder="Coffee at Starbucks"
          />
          {errors.description && <p className="mt-1 text-xs text-danger">{errors.description.message}</p>}
        </div>

        <div>
          <label className="mb-1 block text-sm font-medium">Amount ($)</label>
          <input
            type="number"
            step="0.01"
            {...register('amount')}
            className="w-full rounded-lg border bg-[hsl(var(--input))] px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-brand-500"
            placeholder="0.00"
          />
          {errors.amount && <p className="mt-1 text-xs text-danger">{errors.amount.message}</p>}
        </div>

        <div>
          <label className="mb-1 block text-sm font-medium">Category</label>
          <select
            {...register('category')}
            className="w-full rounded-lg border bg-[hsl(var(--input))] px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-brand-500"
          >
            <option value="">Select category</option>
            <option value="groceries">Groceries</option>
            <option value="entertainment">Entertainment</option>
            <option value="transport">Transport</option>
            <option value="dining">Dining</option>
            <option value="utilities">Utilities</option>
            <option value="other">Other</option>
          </select>
          {errors.category && <p className="mt-1 text-xs text-danger">{errors.category.message}</p>}
        </div>

        <div>
          <label className="mb-1 block text-sm font-medium">Date</label>
          <input
            type="date"
            {...register('date')}
            className="w-full rounded-lg border bg-[hsl(var(--input))] px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-brand-500"
          />
          {errors.date && <p className="mt-1 text-xs text-danger">{errors.date.message}</p>}
        </div>

        <div className="flex justify-end gap-2">
          <Button type="button" variant="ghost" onClick={onClose}>Cancel</Button>
          <Button type="submit" disabled={isSubmitting}>
            {isSubmitting ? 'Adding...' : 'Add Transaction'}
          </Button>
        </div>
      </form>
    </Modal>
  );
}
