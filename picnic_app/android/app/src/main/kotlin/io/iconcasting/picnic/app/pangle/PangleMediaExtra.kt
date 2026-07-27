package pangle.custom

object PangleMediaExtra {
    fun requireV2(value: String): String {
        val parts = value.split(",", limit = 3)
        require(parts.size == 3)
        require(parts[0].isNotBlank())
        require(parts[1] == "android")
        require(parts[2].startsWith("v2.") && parts[2].length > 3)
        return value
    }
}
