import { Metadata } from "next";
import { LegalPage } from "@/components/LegalPage";

export const metadata: Metadata = {
  title: "Privacy Policy - RoastMyRoom",
};

export default function PrivacyPage() {
  return (
    <LegalPage title="Privacy Policy" lastUpdated="March 2, 2026">
      <p>
        RoastMyRoom (&quot;the App&quot;) is developed by Samuel Music (&quot;we&quot;, &quot;us&quot;, &quot;our&quot;).
        This Privacy Policy explains how we collect, use, and protect your information when you use
        the App.
      </p>

      <h2>1. Photos and Images</h2>
      <p>
        The App allows you to take photos of rooms using your device camera or select images from
        your photo library. When you initiate a scan:
      </p>
      <ul>
        <li>
          Your photo is <strong>compressed</strong> (JPEG quality 0.6, max resolution 768&times;576 pixels)
          and encoded in base64 format.
        </li>
        <li>
          The encoded image is sent to our backend (hosted on <strong>Supabase Edge Functions</strong>),
          which forwards it to <strong>OpenAI&apos;s GPT-4o Vision API</strong> for analysis.
        </li>
        <li>
          <strong>Photos are not stored on our servers.</strong> They are processed in real-time and
          discarded after the AI generates a response.
        </li>
        <li>
          A compressed copy of the photo is stored <strong>locally on your device</strong> (via
          SwiftData) as part of your scan history.
        </li>
      </ul>

      <h2>2. Analytics</h2>
      <p>
        We use <strong>Firebase Analytics</strong> (Google) to collect anonymous usage data. This
        helps us improve the App. We track approximately 40 events related to app behavior (e.g.,
        screens viewed, scans completed, features used). We do <strong>not</strong> collect personal
        identifiers through analytics.
      </p>
      <p>User properties collected include:</p>
      <ul>
        <li><strong>is_premium</strong> &ndash; whether you have an active subscription</li>
        <li><strong>points_balance</strong> &ndash; your current points balance</li>
        <li><strong>total_scans</strong> &ndash; total number of scans performed</li>
      </ul>
      <p>
        For more information, see{" "}
        <a href="https://policies.google.com/privacy" target="_blank" rel="noopener noreferrer">
          Google&apos;s Privacy Policy
        </a>
        .
      </p>

      <h2>3. Sign in with Apple</h2>
      <p>
        You may optionally sign in with your Apple ID. When you do, Apple may share your{" "}
        <strong>email address</strong> and <strong>name</strong> with us (depending on your
        preferences). This information is used for:
      </p>
      <ul>
        <li>Account identification and cross-device sync of your points balance.</li>
        <li>
          Storage: your authentication tokens and user ID are stored securely in the{" "}
          <strong>iOS Keychain</strong> and on <strong>Supabase Auth</strong>.
        </li>
      </ul>
      <p>
        Sign-in is <strong>not required</strong> to use the App. It adds optional cross-device
        synchronization.
      </p>

      <h2>4. Local Storage</h2>
      <p>The App stores data locally on your device using:</p>
      <ul>
        <li>
          <strong>iOS Keychain</strong> &ndash; Points balance, daily scan counter, authentication
          tokens, and preferences. Keychain data <strong>persists after app reinstallation</strong>{" "}
          for anti-abuse purposes.
        </li>
        <li>
          <strong>SwiftData</strong> &ndash; Your scan history including room photos, scores, and AI
          feedback.
        </li>
      </ul>

      <h2>5. Data Transmitted to Third Parties</h2>
      <ul>
        <li>
          <strong>Supabase</strong> (
          <a href="https://supabase.com/privacy" target="_blank" rel="noopener noreferrer">
            Privacy Policy
          </a>
          ) &ndash; Photos (via Edge Functions for processing), authentication tokens, points
          balance.
        </li>
        <li>
          <strong>OpenAI</strong> (
          <a href="https://openai.com/policies/privacy-policy" target="_blank" rel="noopener noreferrer">
            Privacy Policy
          </a>
          ) &ndash; Photos are forwarded by our backend for AI analysis. OpenAI processes images
          according to their API data usage policy.
        </li>
        <li>
          <strong>Google / Firebase</strong> (
          <a href="https://policies.google.com/privacy" target="_blank" rel="noopener noreferrer">
            Privacy Policy
          </a>
          ) &ndash; Anonymous analytics events.
        </li>
      </ul>

      <h2>6. Your Rights</h2>
      <p>You can:</p>
      <ul>
        <li>
          <strong>Delete scan history</strong> &ndash; Remove individual scans or all data from the
          History tab.
        </li>
        <li>
          <strong>Sign out</strong> &ndash; Disconnect your Apple ID from the App at any time.
        </li>
        <li>
          <strong>Request data deletion</strong> &ndash; Contact us by email to request deletion of
          any server-side data associated with your account.
        </li>
      </ul>

      <h2>7. GDPR Compliance</h2>
      <p>We process your data under the following legal bases (GDPR Art. 6):</p>
      <ul>
        <li>
          <strong>Consent</strong> &ndash; Camera access permission granted through iOS.
        </li>
        <li>
          <strong>Performance of contract</strong> &ndash; In-app purchases and subscriptions.
        </li>
        <li>
          <strong>Legitimate interest</strong> &ndash; Anonymous analytics to improve the App.
        </li>
      </ul>

      <h2>8. Children&apos;s Privacy</h2>
      <p>
        The App is not directed at children under 13. We do not knowingly collect personal
        information from children. If you believe a child has provided us with personal data, please
        contact us.
      </p>

      <h2>9. Changes to This Policy</h2>
      <p>
        We may update this Privacy Policy from time to time. Changes will be reflected by the
        &quot;Last updated&quot; date at the top of this page.
      </p>

      <h2>10. Contact</h2>
      <p>
        For any privacy-related questions, contact us at:{" "}
        <a href="mailto:samuel.neveugall@gmail.com">samuel.neveugall@gmail.com</a>
      </p>
    </LegalPage>
  );
}
