import { Metadata } from "next";
import { LegalPage } from "@/components/LegalPage";

export const metadata: Metadata = {
  title: "EULA - RoastMyRoom",
};

export default function EulaPage() {
  return (
    <LegalPage title="End User License Agreement (EULA)" lastUpdated="March 2, 2026">
      <p>
        This End User License Agreement (&quot;EULA&quot;) is a legal agreement between you and
        Samuel Music (&quot;Licensor&quot;) for the use of the RoastMyRoom mobile application
        (&quot;the App&quot;). By downloading, installing, or using the App, you agree to be bound
        by this EULA.
      </p>

      <h2>1. License Grant</h2>
      <p>
        The Licensor grants you a <strong>non-exclusive, non-transferable, revocable license</strong>{" "}
        to use the App on any Apple-branded device that you own or control, subject to the Usage
        Rules set forth in the{" "}
        <a
          href="https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
          target="_blank"
          rel="noopener noreferrer"
        >
          Apple Media Services Terms and Conditions
        </a>
        .
      </p>

      <h2>2. Restrictions</h2>
      <p>You may not:</p>
      <ul>
        <li>
          <strong>Redistribute</strong> the App or make it available over a network where it could
          be used by multiple devices at the same time.
        </li>
        <li>
          <strong>Reverse engineer</strong>, decompile, disassemble, or attempt to derive the source
          code of the App.
        </li>
        <li>
          <strong>Copy, modify, or create derivative works</strong> based on the App.
        </li>
        <li>
          <strong>Rent, lease, lend, sell, or sublicense</strong> the App to third parties.
        </li>
        <li>
          Remove, alter, or obscure any <strong>proprietary notices</strong> in the App.
        </li>
      </ul>

      <h2>3. Intellectual Property</h2>
      <p>
        The App, including its code, design, graphics, and content (excluding user-provided photos),
        is the intellectual property of the Licensor. This EULA does not grant you any rights to
        trademarks or service marks of the Licensor.
      </p>

      <h2>4. Third-Party Services</h2>
      <p>
        The App uses third-party services (Supabase, OpenAI, Firebase) that are subject to their own
        terms and policies. The Licensor is not responsible for the availability or behavior of
        third-party services.
      </p>

      <h2>5. Disclaimer of Warranties</h2>
      <p>
        The App is provided <strong>&quot;AS IS&quot;</strong> without warranty of any kind. The
        Licensor does not warrant that the App will be error-free, uninterrupted, or free of harmful
        components.
      </p>

      <h2>6. Limitation of Liability</h2>
      <p>
        To the maximum extent permitted by applicable law, the Licensor shall not be liable for any
        indirect, incidental, special, consequential, or punitive damages, regardless of the cause
        of action.
      </p>

      <h2>7. Termination</h2>
      <p>
        This EULA is effective until terminated. Your rights under this EULA will terminate
        automatically if you fail to comply with any of its terms. Upon termination, you must cease
        all use of the App and delete all copies.
      </p>

      <h2>8. Apple-Specific Terms</h2>
      <p>This EULA is entered into between you and the Licensor only, not with Apple. However:</p>
      <ul>
        <li>
          Apple has no obligation to provide maintenance, support, or warranty services for the App.
        </li>
        <li>
          Apple is not responsible for addressing any claims related to the App (intellectual
          property, product liability, consumer protection, etc.).
        </li>
        <li>
          Apple and its subsidiaries are third-party beneficiaries of this EULA and may enforce it
          against you.
        </li>
        <li>
          The Licensor, not Apple, is solely responsible for the App and its content.
        </li>
      </ul>

      <h2>9. Governing Law</h2>
      <p>
        This EULA is governed by the laws of <strong>France</strong>.
      </p>

      <h2>10. Contact</h2>
      <p>
        For questions about this EULA, contact:{" "}
        <a href="mailto:samuel.neveugall@gmail.com">samuel.neveugall@gmail.com</a>
      </p>
    </LegalPage>
  );
}
