# Flutter'ın kendi keep kuralları Flutter Gradle eklentisi tarafından otomatik
# eklenir; buraya yalnızca ek kurallar yazılır.

# Play Core (Flutter deferred components API'si referans veriyor; uygulama
# kullanmadığı için R8'in "missing class" hatası vermemesi adına dontwarn.)
-dontwarn com.google.android.play.core.**
