# ==============================================================================
# Beton Dayanım Tahmini ve Regresyon Modellemesi
# (Concrete Compressive Strength Prediction & Regression Modeling)
#
# Proje Ekibi:
#   - Ayşenur Altınkaya
#   - Gökhan Tanrıöven
#   - Giray Baysal
#   - Kaan Boztaş
#
# Kurum: Dokuz Eylül Üniversitesi (DEÜ)
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Ortam ve Kütüphane Hazırlığı
# ------------------------------------------------------------------------------
suppressPackageStartupMessages({
  library(readxl)
  library(dplyr)
  library(corrplot)
  library(car)
  library(lmtest)
})

figures_dir <- "figures"
if (!dir.exists(figures_dir)) {
  dir.create(figures_dir, recursive = TRUE)
}

cat("==============================================================================\n")
cat("BETON BASINC DAYANIMI REGRESYON MODELLEMESI ANALIZI BASLATILIYOR\n")
cat("==============================================================================\n\n")

# ------------------------------------------------------------------------------
# 2. Veri Yukleme ve On Isleme
# ------------------------------------------------------------------------------
data_path <- if (file.exists(file.path("data", "Beton1.xlsx"))) {
  file.path("data", "Beton1.xlsx")
} else if (file.exists("Beton1.xlsx")) {
  "Beton1.xlsx"
} else {
  stop("HATA: 'Beton1.xlsx' veri dosyasi bulunamadi!")
}

cat("[1/7] Veri seti yukleniyor: ", data_path, "\n")
raw_data <- readxl::read_excel(data_path)

# Uluslararasi ve sistemler arasi uyumluluk icin standart temiz degisken isimleri:
column_names <- c(
  "Basinc_Dayanimi",
  "Cimento",
  "Yuksek_Firin_Curufu",
  "Ucucu_Kul",
  "Su",
  "Super_Akiskanlastirici",
  "Iri_Agrega",
  "Ince_Agrega",
  "Kur_Suresi"
)
colnames(raw_data) <- column_names

# Sayisal tipe donusturme
data <- raw_data %>%
  dplyr::mutate(across(everything(), as.numeric))

# CSV dosyasinin olusturulmasi (GitHub dogrudan onizleme ve acik kaynak erisimi)
csv_path <- file.path("data", "concrete_data.csv")
if (!file.exists(csv_path)) {
  write.csv(data, csv_path, row.names = FALSE)
  cat("  -> 'data/concrete_data.csv' basariyla olusturuldu.\n")
}

# Logaritmik donusumlerde sifir (0) degerlerinin log(0) hatasi vermemesi icin +0.001 eklenmesi
data <- data %>%
  dplyr::mutate(across(where(is.numeric), ~ .x + 0.001))

cat("  -> Veri boyutu: ", nrow(data), "satir, ", ncol(data), "sutun\n")
cat("  -> Degiskenler ve Tipleri:\n")
str(data)
cat("\nTanimlayici Istatistikler:\n")
print(summary(data))

# ------------------------------------------------------------------------------
# 3. Kesifsel Veri Analizi (EDA) ve Korelasyon Matrisi
# ------------------------------------------------------------------------------
cat("\n[2/7] Kesifsel Veri Analizi (EDA) ve Korelasyon Grafigi Hazirlaniyor...\n")

cor_matrix <- cor(data)

# Korelasyon Grafigi Cizimi ve Kaydedilmesi
png(file.path(figures_dir, "01_correlation_matrix.png"), width = 1600, height = 1400, res = 200)
corrplot(
  cor_matrix,
  method = "color",
  type = "upper",
  order = "hclust",
  tl.col = "black",
  tl.srt = 45,
  addCoef.col = "black",
  number.cex = 0.75,
  col = colorRampPalette(c("#D73027", "#FC8D59", "#FEE08B", "#D9EF8B", "#91CF60", "#1A9850"))(200),
  title = "Beton Bilesenleri Korelasyon Matrisi",
  mar = c(0, 0, 2, 0)
)
dev.off()
cat("  -> 'figures/01_correlation_matrix.png' kaydedildi.\n")

# ------------------------------------------------------------------------------
# 4. Egitim ve Test Kumelerine Ayirma (Train / Test Split - 75% / 25%)
# ------------------------------------------------------------------------------
cat("\n[3/7] Egitim (%75) ve Test (%25) Kumeleri Olusturuluyor...\n")
set.seed(123)
smp_size <- floor(0.75 * nrow(data))
train_ind <- sample(nrow(data), size = smp_size, replace = FALSE)

train <- data[train_ind, ]
test  <- data[-train_ind, ]

cat("  -> Egitim Kumesi Boyutu :", nrow(train), "gozlem\n")
cat("  -> Test Kumesi Boyutu   :", nrow(test), "gozlem\n")

# ------------------------------------------------------------------------------
# 5. Baslangic Modeli (OLS) ve Aykiri Deger Analizi
# ------------------------------------------------------------------------------
cat("\n[4/7] Baslangic OLS Modeli Kuruluyor ve Aykiri Degerler Saptaniyor...\n")

model_initial <- lm(
  Basinc_Dayanimi ~ Cimento + Yuksek_Firin_Curufu + Ucucu_Kul + Su +
    Super_Akiskanlastirici + Iri_Agrega + Ince_Agrega + Kur_Suresi,
  data = train
)

cat("  -> Baslangic Modeli R2     :", round(summary(model_initial)$r.squared, 4), "\n")
cat("  -> Baslangic Modeli Duz. R2:", round(summary(model_initial)$adj.r.squared, 4), "\n")

# Baslangic Modeli Teshis Grafikleri
png(file.path(figures_dir, "02_initial_model_diagnostics.png"), width = 1800, height = 1400, res = 200)
par(mfrow = c(2, 2))
plot(model_initial)
par(mfrow = c(1, 1))
dev.off()
cat("  -> 'figures/02_initial_model_diagnostics.png' kaydedildi.\n")

# Standartlastirilmis artiklar (|r| > 3)
rstd <- rstandard(model_initial)
outlier_rstd <- which(abs(rstd) > 3)
cat("  -> Standartlastirilmis artik kriteri (|r| > 3) ile saptanan aykiri gozlem sayisi:", length(outlier_rstd), "\n")

# Cook's Distance (Esik = 4 / n)
cooksd <- cooks.distance(model_initial)
n_train <- nrow(train)
cook_threshold <- 4 / n_train
outlier_cook <- which(cooksd > cook_threshold)
cat("  -> Cook's Distance esigini (4/n =", round(cook_threshold, 5), ") asan etkili gozlem sayisi:", length(outlier_cook), "\n")

# Cook's Distance Grafigi
png(file.path(figures_dir, "03_cooks_distance.png"), width = 1600, height = 1000, res = 200)
plot(
  cooksd,
  pch = 19,
  col = ifelse(cooksd > cook_threshold, "#D73027", "#4575B4"),
  cex = 0.8,
  main = "Etkili Gozlemler (Cook's Distance Analizi)",
  ylab = "Cook's Distance",
  xlab = "Gozlem Indeksi"
)
abline(h = cook_threshold, col = "#D73027", lwd = 2, lty = 2)
legend("topright", legend = c(sprintf("Esik Deger (4/n = %.4f)", cook_threshold), "Etkili Gozlemler"),
       col = c("#D73027", "#D73027"), lty = c(2, NA), pch = c(NA, 19), bty = "n")
dev.off()
cat("  -> 'figures/03_cooks_distance.png' kaydedildi.\n")

# Iki yontemin birlesimi
outlier_all <- union(outlier_rstd, outlier_cook)
cat("  -> Toplam filtrelenecek aykiri/etkili gozlem sayisi:", length(outlier_all), "\n")

# Temiz egitim kumesinin olusturulmasi
train_clean <- train[-outlier_all, ]
cat("  -> Temizlenmis Egitim Kumesi Boyutu:", nrow(train_clean), "gozlem\n")

# ------------------------------------------------------------------------------
# 6. Model Iyilestirme ve Alternatif Modeller
# ------------------------------------------------------------------------------
cat("\n[5/7] Alternatif Modeller Kuruluyor (Temiz Veri Seti Ile)...\n")

# 6.1 Temiz veriyle temel OLS
model_clean <- lm(
  Basinc_Dayanimi ~ Cimento + Yuksek_Firin_Curufu + Ucucu_Kul +
    Su + Super_Akiskanlastirici + Iri_Agrega + Ince_Agrega + Kur_Suresi,
  data = train_clean
)

# 6.2 Alternatif Model: Bagimli degiskene log donusumu
alternatif_model <- lm(
  log(Basinc_Dayanimi) ~ Cimento + Yuksek_Firin_Curufu + Ucucu_Kul +
    Su + Super_Akiskanlastirici + Iri_Agrega + Ince_Agrega + Kur_Suresi,
  data = train_clean
)

# 6.3 Stepwise Regresyon (AIC tabanli bidirectional secim)
null_model <- lm(Basinc_Dayanimi ~ 1, data = train_clean)
full_linear <- lm(
  Basinc_Dayanimi ~ Cimento + Yuksek_Firin_Curufu + Ucucu_Kul +
    Su + Super_Akiskanlastirici + Iri_Agrega + Ince_Agrega + Kur_Suresi,
  data = train_clean
)
step_model <- step(
  null_model,
  scope = list(lower = null_model, upper = full_linear),
  direction = "both",
  trace = 0
)

# 6.4 Agirlikli En Kucuk Kareler (WLS) Modeli
res2 <- resid(model_clean)^2
fit_vals <- fitted(model_clean)
var_model <- lm(res2 ~ fit_vals)
weights_wls <- 1 / fitted(var_model)
weights_wls[weights_wls <= 0] <- min(weights_wls[weights_wls > 0])

wls_model <- lm(
  Basinc_Dayanimi ~ Cimento + Yuksek_Firin_Curufu + Ucucu_Kul +
    Su + Super_Akiskanlastirici + Iri_Agrega + Ince_Agrega + Kur_Suresi,
  data = train_clean,
  weights = weights_wls
)

# 6.5 Genellestirilmis Dogrusal Model (GLM - Gamma family, log link)
glm_model <- glm(
  Basinc_Dayanimi ~ Cimento + Yuksek_Firin_Curufu + Ucucu_Kul +
    Su + Super_Akiskanlastirici + Iri_Agrega + Ince_Agrega + Kur_Suresi,
  data = train_clean,
  weights = weights_wls,
  family = Gamma(link = "log")
)

# 6.6 Nihai Model: WLS + poly(Su, 2) + log(Kur_Suresi)
wls_final_model <- lm(
  Basinc_Dayanimi ~ Cimento + Yuksek_Firin_Curufu + Ucucu_Kul +
    poly(Su, 2) + Super_Akiskanlastirici + Iri_Agrega + Ince_Agrega + log(Kur_Suresi),
  data = train_clean,
  weights = weights_wls
)

# Nihai model teshis grafikleri
png(file.path(figures_dir, "04_final_model_diagnostics.png"), width = 1800, height = 1400, res = 200)
par(mfrow = c(2, 2))
plot(wls_final_model)
par(mfrow = c(1, 1))
dev.off()
cat("  -> 'figures/04_final_model_diagnostics.png' kaydedildi.\n")

# ------------------------------------------------------------------------------
# 7. Model Karsilastirma Matrisi ve Varsayim Testleri
# ------------------------------------------------------------------------------
cat("\n[6/7] Modeller Karsilastiriliyor ve Varsayimlar Test Ediliyor...\n")

rmse_fun <- function(actual, predicted) {
  sqrt(mean((actual - predicted)^2))
}

train$pred_log       <- exp(predict(alternatif_model, newdata = train))
train$pred_step      <- predict(step_model, newdata = train)
train$pred_wls       <- predict(wls_model, newdata = train)
train$pred_wls_final <- predict(wls_final_model, newdata = train)
train$pred_glm       <- predict(glm_model, newdata = train, type = "response")

model_names <- c("Alternatif Model (Log)", "Stepwise Model", "WLS Model", "WLS Final Model", "GLM (Gamma)")

model_comparison <- data.frame(
  Model = model_names,
  R2 = c(
    summary(alternatif_model)$r.squared,
    summary(step_model)$r.squared,
    summary(wls_model)$r.squared,
    summary(wls_final_model)$r.squared,
    NA
  ),
  Adj_R2 = c(
    summary(alternatif_model)$adj.r.squared,
    summary(step_model)$adj.r.squared,
    summary(wls_model)$adj.r.squared,
    summary(wls_final_model)$adj.r.squared,
    NA
  ),
  RMSE = c(
    rmse_fun(train$Basinc_Dayanimi, train$pred_log),
    rmse_fun(train$Basinc_Dayanimi, train$pred_step),
    rmse_fun(train$Basinc_Dayanimi, train$pred_wls),
    rmse_fun(train$Basinc_Dayanimi, train$pred_wls_final),
    rmse_fun(train$Basinc_Dayanimi, train$pred_glm)
  ),
  AIC = c(
    AIC(alternatif_model),
    AIC(step_model),
    AIC(wls_model),
    AIC(wls_final_model),
    AIC(glm_model)
  ),
  Breusch_Pagan_p = c(
    bptest(alternatif_model)$p.value,
    bptest(step_model)$p.value,
    bptest(wls_model)$p.value,
    bptest(wls_final_model)$p.value,
    NA
  ),
  Shapiro_Wilk_p = c(
    shapiro.test(alternatif_model$residuals)$p.value,
    shapiro.test(step_model$residuals)$p.value,
    shapiro.test(wls_model$residuals)$p.value,
    shapiro.test(wls_final_model$residuals)$p.value,
    NA
  )
)

cat("\n========================= MODEL KARSILASTIRMA TABLOSU =========================\n")
print(format(model_comparison, digits = 4))

cat("\nNihai Model (WLS Final Model) Ozeti:\n")
print(summary(wls_final_model))

cat("\nNihai Model Coklu Dogrusal Baglanti (VIF) Degerleri:\n")
print(vif(wls_final_model))

# ------------------------------------------------------------------------------
# 8. Test Seti Dogrulamasi ve Yeni Gozlem Tahmini
# ------------------------------------------------------------------------------
cat("\n[7/7] Test Seti Performansi ve Ornek Tahmin Hesaplaniyor...\n")

test$pred <- predict(wls_final_model, newdata = test)
test_rmse <- rmse_fun(test$Basinc_Dayanimi, test$pred)
test_mae  <- mean(abs(test$Basinc_Dayanimi - test$pred))
SSE <- sum((test$Basinc_Dayanimi - test$pred)^2)
SST <- sum((test$Basinc_Dayanimi - mean(test$Basinc_Dayanimi))^2)
test_r2   <- 1 - (SSE / SST)

cat(sprintf("  -> Test Seti R2   : %.4f\n", test_r2))
cat(sprintf("  -> Test Seti RMSE : %.4f MPa\n", test_rmse))
cat(sprintf("  -> Test Seti MAE  : %.4f MPa\n", test_mae))

# Gercek vs Tahmin grafigi
png(file.path(figures_dir, "05_actual_vs_predicted.png"), width = 1600, height = 1400, res = 200)
plot(
  test$Basinc_Dayanimi,
  test$pred,
  pch = 19,
  col = rgb(0.1, 0.4, 0.7, 0.7),
  xlab = "Gercek Basinc Dayanimi (MPa)",
  ylab = "Tahmin Edilen Basinc Dayanimi (MPa)",
  main = sprintf("Test Seti: Gercek vs Tahmin (R2 = %.4f)", test_r2)
)
abline(0, 1, col = "#D73027", lwd = 2.5, lty = 2)
grid()
legend("topleft", legend = c("Ideal Dogru (y = x)", "Test Gozlemleri"),
       col = c("#D73027", rgb(0.1, 0.4, 0.7)), lty = c(2, NA), pch = c(NA, 19), bty = "n")
dev.off()
cat("  -> 'figures/05_actual_vs_predicted.png' kaydedildi.\n")

# Test artiklari dagilim grafigi
test$residuals <- test$Basinc_Dayanimi - test$pred
png(file.path(figures_dir, "06_test_residuals_distribution.png"), width = 1800, height = 900, res = 200)
par(mfrow = c(1, 2))
hist(
  test$residuals,
  breaks = 20,
  col = "#6BAED6",
  border = "white",
  main = "Test Artıkları Histogramı",
  xlab = "Artik Degeri (Residual)",
  ylab = "Frekans"
)
plot(
  test$pred,
  test$residuals,
  pch = 19,
  col = rgb(0.2, 0.6, 0.5, 0.7),
  xlab = "Tahmin Edilen Deger",
  ylab = "Artik",
  main = "Test Artıkları vs Tahmin"
)
abline(h = 0, col = "#D73027", lwd = 2, lty = 2)
grid()
par(mfrow = c(1, 1))
dev.off()
cat("  -> 'figures/06_test_residuals_distribution.png' kaydedildi.\n")

# Ornek Yeni Gozlem icin Guven ve Kestirim Araliklari
new_obs <- data.frame(
  Cimento = 281,
  Yuksek_Firin_Curufu = 73,
  Ucucu_Kul = 54,
  Su = 181,
  Super_Akiskanlastirici = 6,
  Iri_Agrega = 972,
  Ince_Agrega = 773,
  Kur_Suresi = 45
)

point_pred <- predict(wls_final_model, newdata = new_obs)
ci_95 <- predict(wls_final_model, newdata = new_obs, interval = "confidence", level = 0.95)
suppressWarnings({
  pi_95 <- predict(wls_final_model, newdata = new_obs, interval = "prediction", level = 0.95)
})

cat("\n====================== YENI GOZLEM ICIN TAHMIN SONUCLARI ======================\n")
cat("Girdi Degerleri:\n")
print(new_obs)
cat(sprintf("\nNokta Tahmini (Ortalama)                 : %.2f MPa\n", point_pred))
cat(sprintf("%%95 Guven Araligi (Confidence Interval)  : [%.3f, %.3f] MPa\n", ci_95[2], ci_95[3]))
cat(sprintf("%%95 Kestirim Araligi (Prediction Interval): [%.2f, %.2f] MPa\n", pi_95[2], pi_95[3]))

cat("\n==============================================================================\n")
cat("ANALIZ VE GORSELLESTIRME BASARIYLA TAMAMLANDI!\n")
cat("Tum grafikler 'figures/' klasorune kaydedildi.\n")
cat("==============================================================================\n")
