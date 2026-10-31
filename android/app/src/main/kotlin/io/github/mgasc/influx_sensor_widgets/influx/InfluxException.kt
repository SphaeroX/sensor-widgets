package io.github.mgasc.influx_sensor_widgets.influx

sealed class InfluxException(
    message: String,
    cause: Throwable? = null,
) : Exception(message, cause)

class InfluxAuthException(
    message: String = "Authentication failed (HTTP 401)",
) : InfluxException(message)

class InfluxNotFoundException(
    message: String = "InfluxDB resource not found (HTTP 404)",
) : InfluxException(message)

class InfluxQueryException(
    message: String,
) : InfluxException(message)

class InfluxNetworkException(
    message: String,
    cause: Throwable? = null,
) : InfluxException(message, cause)
