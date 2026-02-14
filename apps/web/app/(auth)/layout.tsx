export default function AuthLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex min-h-screen items-center justify-center bg-[hsl(var(--muted))] px-4">
      <div className="w-full max-w-md rounded-xl bg-[hsl(var(--card))] p-8 shadow-lg">
        <div className="mb-6 text-center">
          <h1 className="text-2xl font-bold text-brand-600">OvaFlus</h1>
          <p className="mt-1 text-sm text-[hsl(var(--muted-foreground))]">
            Personal Finance Manager
          </p>
        </div>
        {children}
      </div>
    </div>
  );
}
