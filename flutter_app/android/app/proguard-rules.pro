# Keep the Tink library classes
-keep class com.google.crypto.tink.** { *; }

# Keep the javax.annotation classes
-keep class javax.annotation.** { *; }

# Prevent warnings related to missing classes
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**
-dontwarn com.google.api.client.http.GenericUrl
-dontwarn com.google.api.client.http.HttpHeaders
-dontwarn com.google.api.client.http.HttpRequest
-dontwarn com.google.api.client.http.HttpRequestFactory
-dontwarn com.google.api.client.http.HttpResponse
-dontwarn com.google.api.client.http.HttpTransport
-dontwarn com.google.api.client.http.javanet.NetHttpTransport$Builder
-dontwarn com.google.api.client.http.javanet.NetHttpTransport
-dontwarn org.joda.time.Instant