import Link from "next/link";

export function Footer() {
  return (
    <footer className="border-t border-white/5 bg-bg-base">
      <div className="mx-auto flex max-w-5xl flex-col items-center gap-4 px-6 py-8 text-sm text-muted sm:flex-row sm:justify-between">
        <p>&copy; {new Date().getFullYear()} RoastMyRoom. All rights reserved.</p>
        <div className="flex gap-6">
          <Link href="/privacy" className="transition-colors hover:text-white">
            Privacy Policy
          </Link>
          <Link href="/terms" className="transition-colors hover:text-white">
            Terms of Service
          </Link>
          <Link href="/eula" className="transition-colors hover:text-white">
            EULA
          </Link>
          <Link href="/support" className="transition-colors hover:text-white">
            Support
          </Link>
        </div>
      </div>
    </footer>
  );
}
