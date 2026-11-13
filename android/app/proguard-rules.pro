# R8 rules for the release build (isMinifyEnabled = true).
#
# Keep this file small: every -keep lowers the DEX optimization and
# obfuscation score Google Play reports. Flutter (via the Flutter Gradle
# plugin), AndroidX (Glance, Compose, WorkManager, security-crypto), OkHttp
# and Tink ship their own consumer rules. Manifest components (MainActivity,
# widget receiver, config activity) are kept by AAPT automatically.

# Glance creates ActionCallbacks by class name (actionRunCallback<T>()).
-keep class * implements androidx.glance.appwidget.action.ActionCallback {
    <init>();
}

# Room (used by WorkManager) loads "<Database>_Impl" by class name. Without
# this rule the release build crashed at startup in
# androidx.startup.InitializationProvider ("Failed to create an instance of
# class androidx.work.impl.WorkDatabase"), see commit 827330b.
-keep class * extends androidx.room.RoomDatabase {
    <init>();
}

# WorkManager creates InputMergers by class name. Without this rule work
# (including Glance's session worker) failed with "Could not create Input
# Merger androidx.work.OverwritingInputMerger".
-keep class * extends androidx.work.InputMerger {
    public <init>();
}

# The Flutter embedding references Play Core deferred components, which this
# app does not use or bundle.
-dontwarn com.google.android.play.core.**
