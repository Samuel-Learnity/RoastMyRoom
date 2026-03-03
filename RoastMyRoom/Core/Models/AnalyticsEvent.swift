import Foundation

struct AnalyticsEvent: Sendable {
    let name: String
    let parameters: [String: String]?

    init(name: String, parameters: [String: String]? = nil) {
        self.name = name
        self.parameters = parameters
    }
}

// MARK: - Onboarding

extension AnalyticsEvent {
    static func onboardingCompleted() -> AnalyticsEvent {
        AnalyticsEvent(name: "onboarding_completed")
    }

    static func cameraPermissionResult(granted: Bool) -> AnalyticsEvent {
        AnalyticsEvent(name: "camera_permission_result", parameters: [
            "granted": String(granted)
        ])
    }
}

// MARK: - Scan

extension AnalyticsEvent {
    static func scanPhotoCaptured(source: String) -> AnalyticsEvent {
        AnalyticsEvent(name: "scan_photo_captured", parameters: [
            "source": source
        ])
    }

    static func scanFlashChanged(mode: String) -> AnalyticsEvent {
        AnalyticsEvent(name: "scan_flash_changed", parameters: [
            "mode": mode
        ])
    }

    static func scanLensSwitched(lens: String) -> AnalyticsEvent {
        AnalyticsEvent(name: "scan_lens_switched", parameters: [
            "lens": lens
        ])
    }

    static func scanLimitReached(remainingPoints: Int) -> AnalyticsEvent {
        AnalyticsEvent(name: "scan_limit_reached", parameters: [
            "remaining_points": String(remainingPoints)
        ])
    }

    static func scanLimitPaywallShown() -> AnalyticsEvent {
        AnalyticsEvent(name: "scan_limit_paywall_shown")
    }
}

// MARK: - Analysis

extension AnalyticsEvent {
    static func analysisStarted() -> AnalyticsEvent {
        AnalyticsEvent(name: "analysis_started")
    }

    static func analysisSuccess(score: Double, style: String, durationMs: Int) -> AnalyticsEvent {
        AnalyticsEvent(name: "analysis_success", parameters: [
            "score": String(format: "%.1f", score),
            "style": style,
            "duration_ms": String(durationMs)
        ])
    }

    static func analysisError(error: String) -> AnalyticsEvent {
        AnalyticsEvent(name: "analysis_error", parameters: [
            "error": error
        ])
    }
}

// MARK: - Result

extension AnalyticsEvent {
    static func resultViewOpened(score: Double, style: String, isPremium: Bool) -> AnalyticsEvent {
        AnalyticsEvent(name: "result_view_opened", parameters: [
            "score": String(format: "%.1f", score),
            "style": style,
            "is_premium": String(isPremium)
        ])
    }

    static func resultShareClicked(score: Double) -> AnalyticsEvent {
        AnalyticsEvent(name: "result_share_clicked", parameters: [
            "score": String(format: "%.1f", score)
        ])
    }

    static func resultShareCompleted(score: Double) -> AnalyticsEvent {
        AnalyticsEvent(name: "result_share_completed", parameters: [
            "score": String(format: "%.1f", score)
        ])
    }

    static func resultUnlockClicked(score: Double) -> AnalyticsEvent {
        AnalyticsEvent(name: "result_unlock_clicked", parameters: [
            "score": String(format: "%.1f", score)
        ])
    }

    static func resultUnlockSuccess(score: Double, pointsRemaining: Int) -> AnalyticsEvent {
        AnalyticsEvent(name: "result_unlock_success", parameters: [
            "score": String(format: "%.1f", score),
            "points_remaining": String(pointsRemaining)
        ])
    }
}

// MARK: - Paywall

extension AnalyticsEvent {
    static func paywallOpened(source: String) -> AnalyticsEvent {
        AnalyticsEvent(name: "paywall_opened", parameters: [
            "source": source
        ])
    }

    static func paywallTabSwitched(tab: String) -> AnalyticsEvent {
        AnalyticsEvent(name: "paywall_tab_switched", parameters: [
            "tab": tab
        ])
    }

    static func paywallCtaClicked(tab: String, productId: String) -> AnalyticsEvent {
        AnalyticsEvent(name: "paywall_cta_clicked", parameters: [
            "tab": tab,
            "product_id": productId
        ])
    }

    static func paywallClosed(tab: String) -> AnalyticsEvent {
        AnalyticsEvent(name: "paywall_closed", parameters: [
            "tab": tab
        ])
    }

    static func paywallRestoreClicked() -> AnalyticsEvent {
        AnalyticsEvent(name: "paywall_restore_clicked")
    }
}

// MARK: - Purchase

extension AnalyticsEvent {
    static func purchaseStarted(productId: String, productType: String) -> AnalyticsEvent {
        AnalyticsEvent(name: "purchase_started", parameters: [
            "product_id": productId,
            "product_type": productType
        ])
    }

    static func purchaseSuccess(productId: String, productType: String, price: String) -> AnalyticsEvent {
        AnalyticsEvent(name: "purchase_success", parameters: [
            "product_id": productId,
            "product_type": productType,
            "price": price
        ])
    }

    static func purchaseError(productId: String, error: String) -> AnalyticsEvent {
        AnalyticsEvent(name: "purchase_error", parameters: [
            "product_id": productId,
            "error": error
        ])
    }

    static func purchaseCancelled(productId: String) -> AnalyticsEvent {
        AnalyticsEvent(name: "purchase_cancelled", parameters: [
            "product_id": productId
        ])
    }

    static func purchaseRestored() -> AnalyticsEvent {
        AnalyticsEvent(name: "purchase_restored")
    }
}

// MARK: - Points

extension AnalyticsEvent {
    static func pointsUnlockUsed(pointsRemaining: Int, score: Double) -> AnalyticsEvent {
        AnalyticsEvent(name: "points_unlock_used", parameters: [
            "points_remaining": String(pointsRemaining),
            "score": String(format: "%.1f", score)
        ])
    }
}

// MARK: - History

extension AnalyticsEvent {
    static func historyCardTapped(score: Double, style: String) -> AnalyticsEvent {
        AnalyticsEvent(name: "history_card_tapped", parameters: [
            "score": String(format: "%.1f", score),
            "style": style
        ])
    }

    static func historyDeleteConfirmed(score: Double) -> AnalyticsEvent {
        AnalyticsEvent(name: "history_delete_confirmed", parameters: [
            "score": String(format: "%.1f", score)
        ])
    }
}

// MARK: - Profile

extension AnalyticsEvent {
    static func profileUpgradeClicked() -> AnalyticsEvent {
        AnalyticsEvent(name: "profile_upgrade_clicked")
    }

    static func profileShareAppClicked() -> AnalyticsEvent {
        AnalyticsEvent(name: "profile_share_app_clicked")
    }
}

// MARK: - Auth

extension AnalyticsEvent {
    static func authSignInStarted() -> AnalyticsEvent {
        AnalyticsEvent(name: "auth_sign_in_started")
    }

    static func authSignInSuccess() -> AnalyticsEvent {
        AnalyticsEvent(name: "auth_sign_in_success")
    }

    static func authSignInError(error: String) -> AnalyticsEvent {
        AnalyticsEvent(name: "auth_sign_in_error", parameters: [
            "error": error
        ])
    }

    static func authSignOut() -> AnalyticsEvent {
        AnalyticsEvent(name: "auth_sign_out")
    }

    static func pointsSyncStarted() -> AnalyticsEvent {
        AnalyticsEvent(name: "points_sync_started")
    }

    static func pointsSyncSuccess(localBalance: Int, remoteBalance: Int, mergedBalance: Int) -> AnalyticsEvent {
        AnalyticsEvent(name: "points_sync_success", parameters: [
            "local_balance": String(localBalance),
            "remote_balance": String(remoteBalance),
            "merged_balance": String(mergedBalance)
        ])
    }

    static func pointsSyncConflict(localBalance: Int, remoteBalance: Int) -> AnalyticsEvent {
        AnalyticsEvent(name: "points_sync_conflict", parameters: [
            "local_balance": String(localBalance),
            "remote_balance": String(remoteBalance)
        ])
    }

    static func authPromptShown(source: String) -> AnalyticsEvent {
        AnalyticsEvent(name: "auth_prompt_shown", parameters: [
            "source": source
        ])
    }

    static func authPromptDismissed() -> AnalyticsEvent {
        AnalyticsEvent(name: "auth_prompt_dismissed")
    }
}

// MARK: - ATT

extension AnalyticsEvent {
    static func attPrePromptShown() -> AnalyticsEvent {
        AnalyticsEvent(name: "att_pre_prompt_shown")
    }

    static func attPrePromptContinue() -> AnalyticsEvent {
        AnalyticsEvent(name: "att_pre_prompt_continue")
    }

    static func attPermissionResult(status: String) -> AnalyticsEvent {
        AnalyticsEvent(name: "att_permission_result", parameters: [
            "status": status
        ])
    }
}

// MARK: - Navigation

extension AnalyticsEvent {
    static func tabSwitched(tab: String) -> AnalyticsEvent {
        AnalyticsEvent(name: "tab_switched", parameters: [
            "tab": tab
        ])
    }

    static func screenView(screenName: String) -> AnalyticsEvent {
        AnalyticsEvent(name: "screen_view", parameters: [
            "screen_name": screenName
        ])
    }
}
