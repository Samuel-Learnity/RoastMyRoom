import Link from "next/link";

export function Header() {
  return (
    <header className="fixed top-0 z-50 w-full border-b border-white/5 bg-bg-base/80 backdrop-blur-xl">
      <nav className="mx-auto flex h-16 max-w-5xl items-center justify-between px-6">
        <Link href="/" className="text-lg font-bold tracking-tight">
          <span className="gradient-text">RoastMyRoom</span>
        </Link>
        <div className="flex items-center gap-6 text-sm text-muted">
          <Link href="/privacy" className="transition-colors hover:text-white">
            Privacy
          </Link>
          <Link href="/terms" className="transition-colors hover:text-white">
            Terms
          </Link>
          <Link href="/support" className="transition-colors hover:text-white">
            Support
          </Link>
        </div>
      </nav>
    </header>
  );
}
