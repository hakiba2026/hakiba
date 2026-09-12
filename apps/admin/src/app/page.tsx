import AppShell from "@haqiba/ui-kit/src/layout/AppShell";

export default function Home() {
  return (
    <AppShell>
      <div className="flex flex-col items-center justify-center min-h-[50vh]">
        <h1 className="text-3xl font-bold text-gray-800 dark:text-white mb-4">أهلاً بك في لوحة المدير</h1>
        <p className="text-gray-500 dark:text-gray-400">هذه هي لوحة تحكم الإدارةةةة (Admin Dashboard).</p>
      </div>
    </AppShell>
  );
}
