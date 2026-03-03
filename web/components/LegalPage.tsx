interface LegalPageProps {
  title: string;
  lastUpdated: string;
  children: React.ReactNode;
}

export function LegalPage({ title, lastUpdated, children }: LegalPageProps) {
  return (
    <article className="mx-auto max-w-3xl px-6 pt-28 pb-16">
      <h1 className="mb-2 text-3xl font-bold tracking-tight">{title}</h1>
      <p className="mb-10 text-sm text-muted">Last updated: {lastUpdated}</p>
      <div className="prose prose-invert max-w-none prose-headings:font-semibold prose-headings:tracking-tight prose-h2:mt-10 prose-h2:mb-4 prose-h2:text-xl prose-h3:mt-6 prose-h3:mb-2 prose-h3:text-lg prose-p:text-muted prose-p:leading-7 prose-li:text-muted prose-a:text-ai-purple prose-a:no-underline hover:prose-a:underline prose-strong:text-foreground prose-ul:my-3 prose-li:my-1">
        {children}
      </div>
    </article>
  );
}
