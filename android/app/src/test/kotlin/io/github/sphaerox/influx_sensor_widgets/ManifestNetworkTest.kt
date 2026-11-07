package io.github.sphaerox.influx_sensor_widgets

import org.junit.Assert.assertEquals
import org.junit.Test
import org.w3c.dom.Element
import java.io.File
import javax.xml.parsers.DocumentBuilderFactory

/**
 * The editor preview (Dart `HttpClient`) ignores Android's network security policy, the native
 * widget refresh (OkHttp) does not. Without cleartext permission an `http://` InfluxDB
 * (typical for Home Assistant) shows in the preview but never reaches the home-screen widget.
 */
class ManifestNetworkTest {
    @Test
    fun `release manifest allows plain http InfluxDB servers`() {
        val factory = DocumentBuilderFactory.newInstance().apply { isNamespaceAware = true }
        val doc = factory.newDocumentBuilder().parse(File("src/main/AndroidManifest.xml"))
        val application = doc.getElementsByTagName("application").item(0) as Element

        assertEquals(
            "true",
            application.getAttributeNS("http://schemas.android.com/apk/res/android", "usesCleartextTraffic"),
        )
    }
}
