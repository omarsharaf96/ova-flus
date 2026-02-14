'use client';

import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { Button } from '@/components/ui/Button';

const registerSchema = z
  .object({
    displayName: z.string().min(2, 'Display name must be at least 2 characters'),
    email: z.string().email('Invalid email address'),
    password: z.string().min(8, 'Password must be at least 8 characters'),
    confirmPassword: z.string(),
  })
  .refine((data) => data.password === data.confirmPassword, {
    message: 'Passwords do not match',
    path: ['confirmPassword'],
  });

type RegisterForm = z.infer<typeof registerSchema>;

export default function RegisterPage() {
  const router = useRouter();
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<RegisterForm>({
    resolver: zodResolver(registerSchema),
  });

  async function onSubmit(data: RegisterForm) {
    // TODO: integrate with auth service
    console.log('Register:', data);
    router.push('/login');
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
      <div>
        <label htmlFor="displayName" className="mb-1 block text-sm font-medium">
          Display Name
        </label>
        <input
          id="displayName"
          type="text"
          {...register('displayName')}
          className="w-full rounded-lg border bg-[hsl(var(--input))] px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-brand-500"
          placeholder="Your name"
        />
        {errors.displayName && (
          <p className="mt-1 text-xs text-danger">{errors.displayName.message}</p>
        )}
      </div>

      <div>
        <label htmlFor="email" className="mb-1 block text-sm font-medium">
          Email
        </label>
        <input
          id="email"
          type="email"
          {...register('email')}
          className="w-full rounded-lg border bg-[hsl(var(--input))] px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-brand-500"
          placeholder="you@example.com"
        />
        {errors.email && (
          <p className="mt-1 text-xs text-danger">{errors.email.message}</p>
        )}
      </div>

      <div>
        <label htmlFor="password" className="mb-1 block text-sm font-medium">
          Password
        </label>
        <input
          id="password"
          type="password"
          {...register('password')}
          className="w-full rounded-lg border bg-[hsl(var(--input))] px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-brand-500"
          placeholder="At least 8 characters"
        />
        {errors.password && (
          <p className="mt-1 text-xs text-danger">{errors.password.message}</p>
        )}
      </div>

      <div>
        <label htmlFor="confirmPassword" className="mb-1 block text-sm font-medium">
          Confirm Password
        </label>
        <input
          id="confirmPassword"
          type="password"
          {...register('confirmPassword')}
          className="w-full rounded-lg border bg-[hsl(var(--input))] px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-brand-500"
          placeholder="Repeat your password"
        />
        {errors.confirmPassword && (
          <p className="mt-1 text-xs text-danger">{errors.confirmPassword.message}</p>
        )}
      </div>

      <Button type="submit" className="w-full" disabled={isSubmitting}>
        {isSubmitting ? 'Creating account...' : 'Create account'}
      </Button>

      <p className="text-center text-sm text-[hsl(var(--muted-foreground))]">
        Already have an account?{' '}
        <Link href="/login" className="font-medium text-brand-600 hover:underline">
          Sign in
        </Link>
      </p>
    </form>
  );
}
