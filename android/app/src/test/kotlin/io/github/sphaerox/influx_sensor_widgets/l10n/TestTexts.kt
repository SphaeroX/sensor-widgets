package io.github.sphaerox.influx_sensor_widgets.l10n

import io.github.sphaerox.influx_sensor_widgets.R
import org.w3c.dom.Element
import java.io.File
import java.util.Locale
import javax.xml.parsers.DocumentBuilderFactory

/**
 * [WidgetTexts] backed by the real `res/values*` string files, so JVM tests
 * (no Android resources) check the shipped texts. Like Android, a language
 * without a text falls back to `values/strings.xml` (English).
 */
object TestTexts {
    val english: WidgetTexts by lazy { texts(englishStrings) }
    val german: WidgetTexts by lazy { texts(englishStrings + strings("values-de")) }

    val englishStrings: Map<String, String> by lazy { strings("values") }

    /** Raw texts of `res/<dir>/strings.xml` by resource name. */
    fun strings(dir: String): Map<String, String> {
        val file = File("src/main/res/$dir/strings.xml")
        val doc = DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(file)
        val nodes = doc.getElementsByTagName("string")
        return (0 until nodes.length).associate { i ->
            val element = nodes.item(i) as Element
            element.getAttribute("name") to unescape(element.textContent)
        }
    }

    private val namesById: Map<Int, String> by lazy {
        R.string::class.java.fields.associate { it.getInt(null) to it.name }
    }

    private fun texts(strings: Map<String, String>): WidgetTexts =
        WidgetTexts { id, args ->
            val name = namesById.getValue(id)
            val pattern = strings[name] ?: error("No text for $name")
            String.format(Locale.ROOT, pattern, *args)
        }

    private fun unescape(text: String): String =
        text
            .replace("\\\"", "\"")
            .replace("\\'", "'")
            .replace("\\n", "\n")
}
