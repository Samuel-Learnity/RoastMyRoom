import Link from "next/link";

const features = [
  {
    icon: "📸",
    title: "Scan",
    description: "Take a photo of any room with your camera or pick from your gallery.",
  },
  {
    icon: "🎯",
    title: "Score",
    description: "AI analyzes your space and rates it on cleanliness, style, lighting, and more.",
  },
  {
    icon: "🔥",
    title: "Share",
    description: "Get a savage roast, design tips, and a shareable score card for your friends.",
  },
];

const steps = [
  { number: "01", title: "Snap a photo", description: "Point your camera at your room and tap." },
  { number: "02", title: "AI analyzes", description: "GPT-4o Vision scores 5 categories in seconds." },
  { number: "03", title: "Get roasted", description: "Receive your score, a brutal roast, and tips to improve." },
];

export default function Home() {
  return (
    <div className="flex flex-col">
      {/* Hero */}
      <section className="relative flex min-h-screen flex-col items-center justify-center px-6 text-center">
        <div className="pointer-events-none absolute inset-0 overflow-hidden">
          <div className="absolute left-1/2 top-1/4 h-96 w-96 -translate-x-1/2 rounded-full bg-ai-purple/20 blur-[128px]" />
          <div className="absolute right-1/4 top-1/3 h-64 w-64 rounded-full bg-ai-pink/15 blur-[96px]" />
          <div className="absolute left-1/4 bottom-1/3 h-72 w-72 rounded-full bg-ai-light-blue/15 blur-[96px]" />
        </div>
        <div className="relative z-10">
          <div className="mb-4 inline-block rounded-full border border-white/10 bg-white/5 px-4 py-1.5 text-sm text-muted backdrop-blur-sm">
            AI-Powered Room Rating
          </div>
          <h1 className="mb-6 text-5xl font-bold leading-tight tracking-tight sm:text-7xl">
            How does your
            <br />
            room <span className="gradient-text">really</span> look?
          </h1>
          <p className="mx-auto mb-10 max-w-lg text-lg text-muted">
            Snap a photo. Get an AI score out of 10. Receive a savage roast and
            actionable tips. Share with friends.
          </p>
          <Link
            href="https://apps.apple.com"
            className="gradient-border inline-flex items-center gap-2 rounded-full bg-white/5 px-8 py-3.5 font-medium transition-colors hover:bg-white/10"
          >
            <svg className="h-5 w-5" viewBox="0 0 24 24" fill="currentColor">
              <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" />
            </svg>
            Download on the App Store
          </Link>
        </div>
      </section>

      {/* Features */}
      <section className="mx-auto max-w-5xl px-6 py-24">
        <h2 className="mb-4 text-center text-3xl font-bold tracking-tight sm:text-4xl">
          Three steps to the <span className="gradient-text">truth</span>
        </h2>
        <p className="mx-auto mb-16 max-w-md text-center text-muted">
          No more guessing. AI tells it like it is.
        </p>
        <div className="grid gap-6 sm:grid-cols-3">
          {features.map((f) => (
            <div
              key={f.title}
              className="glass-card rounded-2xl p-6 transition-colors hover:border-white/20"
            >
              <div className="mb-4 text-4xl">{f.icon}</div>
              <h3 className="mb-2 text-lg font-semibold">{f.title}</h3>
              <p className="text-sm leading-relaxed text-muted">{f.description}</p>
            </div>
          ))}
        </div>
      </section>

      {/* How it works */}
      <section className="mx-auto max-w-5xl px-6 py-24">
        <h2 className="mb-16 text-center text-3xl font-bold tracking-tight sm:text-4xl">
          How it works
        </h2>
        <div className="grid gap-12 sm:grid-cols-3">
          {steps.map((s) => (
            <div key={s.number} className="text-center">
              <div className="gradient-text mb-4 text-5xl font-bold">{s.number}</div>
              <h3 className="mb-2 text-lg font-semibold">{s.title}</h3>
              <p className="text-sm text-muted">{s.description}</p>
            </div>
          ))}
        </div>
      </section>

      {/* CTA */}
      <section className="relative px-6 py-24 text-center">
        <div className="pointer-events-none absolute inset-0 overflow-hidden">
          <div className="absolute left-1/2 top-1/2 h-80 w-80 -translate-x-1/2 -translate-y-1/2 rounded-full bg-ai-deep-purple/20 blur-[128px]" />
        </div>
        <div className="relative z-10">
          <h2 className="mb-4 text-3xl font-bold tracking-tight sm:text-4xl">
            Ready to get <span className="gradient-text">roasted</span>?
          </h2>
          <p className="mx-auto mb-8 max-w-md text-muted">
            Download RoastMyRoom and find out what AI really thinks about your
            space.
          </p>
          <Link
            href="https://apps.apple.com"
            className="gradient-border inline-flex items-center gap-2 rounded-full bg-white/5 px-8 py-3.5 font-medium transition-colors hover:bg-white/10"
          >
            Get the app — it&apos;s free
          </Link>
        </div>
      </section>
    </div>
  );
}
