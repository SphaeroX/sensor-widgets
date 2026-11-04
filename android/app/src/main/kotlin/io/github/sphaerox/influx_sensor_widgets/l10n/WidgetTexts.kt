package io.github.sphaerox.influx_sensor_widgets.l10n

import android.content.Context
import androidx.annotation.StringRes
import io.github.sphaerox.influx_sensor_widgets.R
import io.github.sphaerox.influx_sensor_widgets.formula.FormulaErrorKind
import io.github.sphaerox.influx_sensor_widgets.formula.FormulaException

/**
 * Texts from `res/values/strings.xml` (English, fallback) and the
 * `res/values-<lang>/strings.xml` files in the device language
 * for code that runs without a Compose context: worker, alerts,
 * cache mapping. Production uses [of]; JVM tests read the XML files directly.
 */
fun interface WidgetTexts {
    fun get(
        @StringRes id: Int,
        vararg args: Any,
    ): String

    companion object {
        fun of(context: Context): WidgetTexts = WidgetTexts { id, args -> context.getString(id, *args) }
    }
}

/** Translated text of a formula error. */
fun WidgetTexts.formulaError(e: FormulaException): String {
    fun a(i: Int) = e.args.getOrElse(i) { "" }
    return when (e.kind) {
        FormulaErrorKind.EMPTY_FORMULA -> get(R.string.formula_error_empty)
        FormulaErrorKind.UNEXPECTED_CHARACTER -> get(R.string.formula_error_unexpected_character, a(0))
        FormulaErrorKind.UNEXPECTED_ASSIGN -> get(R.string.formula_error_unexpected_assign)
        FormulaErrorKind.INVALID_NUMBER -> get(R.string.formula_error_invalid_number, a(0))
        FormulaErrorKind.UNKNOWN_OPERATOR -> get(R.string.formula_error_unknown_operator, a(0))
        FormulaErrorKind.MISSING_OPENING_PAREN -> get(R.string.formula_error_missing_opening_paren)
        FormulaErrorKind.MISSING_OPERATOR -> get(R.string.formula_error_missing_operator)
        FormulaErrorKind.INCOMPLETE_EXPRESSION -> get(R.string.formula_error_incomplete)
        FormulaErrorKind.UNCLOSED_PAREN -> get(R.string.formula_error_unclosed_paren)
        FormulaErrorKind.INVALID_STEP_NAME -> get(R.string.formula_error_invalid_step_name, a(0))
        FormulaErrorKind.STEP_NAME_IS_FUNCTION -> get(R.string.formula_error_step_name_is_function, a(0))
        FormulaErrorKind.DUPLICATE_NAME -> get(R.string.formula_error_duplicate_name, a(0))
        FormulaErrorKind.STEP_SELF_REFERENCE -> get(R.string.formula_error_step_self_reference, a(0))
        FormulaErrorKind.STEP_FORWARD_REFERENCE -> get(R.string.formula_error_step_forward_reference, a(0))
        FormulaErrorKind.DIVISION_BY_ZERO -> get(R.string.formula_error_division_by_zero)
        FormulaErrorKind.MISSING_VARIABLE -> get(R.string.formula_error_missing_variable, a(0))
        FormulaErrorKind.UNKNOWN_FUNCTION -> get(R.string.formula_error_unknown_function, a(0))
        FormulaErrorKind.WRONG_ARGUMENT_COUNT -> {
            val expected =
                when {
                    a(2).isEmpty() -> get(R.string.formula_arity_at_least, a(1))
                    a(1) == a(2) -> a(1)
                    else -> get(R.string.formula_arity_range, a(1), a(2))
                }
            get(R.string.formula_error_wrong_argument_count, a(0), expected, a(3))
        }
        FormulaErrorKind.CLAMP_BOUNDS -> get(R.string.formula_error_clamp_bounds)
        FormulaErrorKind.SQRT_NEGATIVE -> get(R.string.formula_error_sqrt_negative)
        FormulaErrorKind.LN_NON_POSITIVE -> get(R.string.formula_error_ln_non_positive)
        FormulaErrorKind.LOG10_NON_POSITIVE -> get(R.string.formula_error_log10_non_positive)
        FormulaErrorKind.NOT_FINITE ->
            if (a(0).isEmpty()) {
                get(R.string.formula_error_result_not_finite)
            } else {
                get(R.string.formula_error_not_finite, a(0))
            }
        FormulaErrorKind.NO_FORMULA -> get(R.string.formula_error_no_formula)
    }
}
