package pangle.custom

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Test

class PangleNativeContractTest {
    @Test fun initializesThenForwardsExactSignedLoadOnce() {
        var initialized: ((Result<Unit>) -> Unit)? = null
        val loads = mutableListOf<Pair<String, String>>()
        var failures = 0
        PangleLoadCoordinator.run(false, { initialized = it }, "placement-a", "user-a,android,v2.signed", { p, e -> loads += p to e }, { failures++ })
        initialized!!.invoke(Result.success(Unit))
        initialized!!.invoke(Result.success(Unit))
        assertEquals(listOf("placement-a" to "user-a,android,v2.signed"), loads)
        assertEquals(0, failures)
    }

    @Test fun initializationFailureCompletesFailureExactlyOnce() {
        var initialized: ((Result<Unit>) -> Unit)? = null
        var loads = 0
        var failures = 0
        PangleLoadCoordinator.run(false, { initialized = it }, "p", "u,android,v2.t", { _, _ -> loads++ }, { failures++ })
        initialized!!.invoke(Result.failure(IllegalStateException("no")))
        initialized!!.invoke(Result.failure(IllegalStateException("again")))
        assertEquals(0, loads)
        assertEquals(1, failures)
    }

    @Test fun eventContractContainsOnlyCanonicalNames() {
        assertEquals(setOf("onAdShown", "onAdClicked", "onAdDismissed", "onRewardEarned", "onRewardFailed"), PangleEventNames.all)
        assertFalse(PangleEventNames.all.any { it in setOf("onAdShowed", "onUserEarnedReward", "onUserEarnedRewardFail") })
    }
}
