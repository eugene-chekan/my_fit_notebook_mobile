# Preserve generic signatures so GSON's TypeToken can read them. Without this,
# flutter_local_notifications throws "Missing type parameter" when it
# (de)serialises scheduled notifications under R8.
-keepattributes Signature
-keepattributes *Annotation*

# GSON + flutter_local_notifications model classes it serialises.
-keep class com.google.gson.** { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep public class * implements java.lang.reflect.Type
-keep class com.dexterous.flutterlocalnotifications.** { *; }
