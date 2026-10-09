# ==============================================================================
# Beton Dayanım Tahmini ve Regresyon Modellemesi
# Gerekli Paketlerin Yüklenmesi ve Kontrolü (Dependency Installation)
# ==============================================================================

required_packages <- c(
  "readxl",   # Excel (.xlsx) veri dosyalarını okuma
  "dplyr",    # Veri işleme, dönüştürme ve pipeline işlemleri
  "corrplot", # Korelasyon matrisi görselleştirme
  "car",      # Çoklu doğrusal bağlantı (VIF) ve model teşhis fonksiyonları
  "lmtest",   # Breusch-Pagan homoskedasite testi
  "zoo"       # Zaman serisi ve destekleyici istatistik fonksiyonları
)

cat("==============================================================================\n")
cat("Beton Dayanım Tahmini - R Paket Kontrolü ve Yükleme\n")
cat("==============================================================================\n\n")

new_packages <- required_packages[!(required_packages %in% installed.packages()[, "Package"])]

if (length(new_packages) > 0) {
  cat("Yüklenecek paketler bulundu:", paste(new_packages, collapse = ", "), "\n")
  cat("Paketler CRAN deposundan indiriliyor ve yükleniyor...\n")
  install.packages(new_packages, repos = "https://cloud.r-project.org")
  cat("\nTüm eksik paketler başarıyla yüklendi!\n")
} else {
  cat("Tüm gerekli paketler sisteminizde zaten yüklü durumda.\n")
}

cat("\nYüklü Paket Durumu:\n")
for (pkg in required_packages) {
  version <- as.character(packageVersion(pkg))
  cat(sprintf("  ✓ %-15s (v%s)\n", pkg, version))
}
cat("\nKurulum tamamlandı. 'scripts/analysis.R' dosyasını çalıştırabilirsiniz.\n")
