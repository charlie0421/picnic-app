package pangle.custom

import org.junit.Assert.assertEquals
import org.junit.Test

class PangleMediaExtraTest {
    @Test fun acceptsAndPreservesSignedV2Value() {
        val value = "user-a,android,v2.signed-token"
        assertEquals(value, PangleMediaExtra.requireV2(value))
    }

    @Test(expected = IllegalArgumentException::class)
    fun rejectsMissingToken() { PangleMediaExtra.requireV2("user-a,android,v2.") }

    @Test(expected = IllegalArgumentException::class)
    fun rejectsWrongPlatform() { PangleMediaExtra.requireV2("user-a,ios,v2.token") }

    @Test(expected = IllegalArgumentException::class)
    fun rejectsEmptyUser() { PangleMediaExtra.requireV2(",android,v2.token") }
}
