package pangle.custom

import java.util.concurrent.atomic.AtomicBoolean

object PangleEventNames {
    const val AD_SHOWN = "onAdShown"
    const val AD_CLICKED = "onAdClicked"
    const val AD_DISMISSED = "onAdDismissed"
    const val REWARD_EARNED = "onRewardEarned"
    const val REWARD_FAILED = "onRewardFailed"
    val all = setOf(AD_SHOWN, AD_CLICKED, AD_DISMISSED, REWARD_EARNED, REWARD_FAILED)
}

object PangleLoadCoordinator {
    fun run(
        initialized: Boolean,
        initialize: (((Result<Unit>) -> Unit) -> Unit),
        placementId: String,
        mediaExtra: String,
        load: (String, String) -> Unit,
        fail: (Throwable) -> Unit,
    ) {
        if (initialized) {
            load(placementId, mediaExtra)
            return
        }
        val completed = AtomicBoolean(false)
        initialize { result ->
            if (!completed.compareAndSet(false, true)) return@initialize
            result.fold(
                onSuccess = { load(placementId, mediaExtra) },
                onFailure = fail,
            )
        }
    }
}
