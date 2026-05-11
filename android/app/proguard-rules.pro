# Flutter Background Service
-keep class id.flutter.flutter_background_service.** { *; }
-keep class androidx.work.** { *; }

# Flutter Local Notifications
-keep class com.dexterous.** { *; }

# Geolocator
-keep class com.baseflow.geolocator.** { *; }

# Dart/Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Mantener clases anotadas con @pragma vm:entry-point
-keep @interface dart.vm.entrypoint.**
-keep class * {
    @dart.vm.entrypoint <methods>;
}