'use client';

import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { Button } from '@/components/ui/Button';

const loginSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(8, 'Password must be at least 8 characters'),
  rememberMe: z.boolean().optional(),
});

type LoginForm = z.infer<typeof loginSchema>;

export default function LoginPage() {
  const router = useRouter();
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<LoginForm>({
    resolver: zodResolver(loginSchema),
  });

  async function onSubmit(data: LoginForm) {
    // TODO: integrate with auth service
    console.log('Login:', data);
    router.push('/');
  }

  function handleBypass() {
    document.cookie = 'auth-token=dev-bypass; path=/; max-age=86400';
    router.push('/');
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
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
          placeholder="Enter your password"
        />
        {errors.password && (
          <p className="mt-1 text-xs text-danger">{errors.password.message}</p>
        )}
      </div>

      <div className="flex items-center gap-2">
        <input
          id="rememberMe"
          type="checkbox"
          {...register('rememberMe')}
          className="rounded border-gray-300"
        />
        <label htmlFor="rememberMe" className="text-sm">
          Remember me
        </label>
      </div>

      <Button type="submit" className="w-full" disabled={isSubmitting}>
        {isSubmitting ? 'Signing in...' : 'Sign in'}
      </Button>

      <p className="text-center text-sm text-[hsl(var(--muted-foreground))]">
        Don&apos;t have an account?{' '}
        <Link href="/register" className="font-medium text-brand-600 hover:underline">
          Sign up
        </Link>
      </p>

      <div className="relative">
        <div className="absolute inset-0 flex items-center">
          <span className="w-full border-t border-dashed opacity-40" />
        </div>
        <div className="relative flex justify-center text-xs uppercase">
          <span className="bg-[hsl(var(--card))] px-2 text-[hsl(var(--muted-foreground))]">dev only</span>
        </div>
      </div>

      <button
        type="button"
        onClick={handleBypass}
        className="w-full rounded-lg border border-dashed border-yellow-400 bg-yellow-50 py-2 text-sm font-medium text-yellow-700 hover:bg-yellow-100 dark:bg-yellow-950 dark:text-yellow-300 dark:hover:bg-yellow-900"
      >
        Bypass Login (Dev)
      </button>
    </form>
  );
}
