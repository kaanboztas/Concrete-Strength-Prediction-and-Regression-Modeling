# 📊 Veri Seti Açıklaması (Dataset Documentation)

Bu veri seti, beton bileşenlerinin ve kür süresinin betonun basınç dayanımı (*Compressive Strength*) üzerindeki etkilerini modellemek amacıyla kullanılmıştır. Orijinal veri, Prof. I-Cheng Yeh tarafından yürütülen deneysel çalışmalardan elde edilmiş olup Kaggle ve UCI Machine Learning Repository üzerinde açık kaynak olarak paylaşılmıştır.

---

## 📁 Dosyalar

- **`Beton1.xlsx`**: Excel formatındaki ham veri seti (1030 satır, 9 sütun).
- **`concrete_data.csv`**: GitHub üzerinde doğrudan görüntülenebilen ve farklı programlama dilleriyle (Python, R, Julia vb.) kolayca yüklenebilen CSV formatı.

---

## 🧱 Değişkenler ve Birimler (Data Dictionary)

| Değişken Adı (R) | Orijinal İngilizce Adı | Açıklama | Birim | Tür |
| :--- | :--- | :--- | :--- | :--- |
| **`Basınç_Dayanımı`** | Concrete compressive strength | Betonun nihai basınç dayanımı (**Bağımlı Değişken / Hedef**) | MPa (Megapaskal) | Sayısal (Sürekli) |
| **`Çimento`** | Cement | Karışımdaki çimento miktarı | $kg / m^3$ | Sayısal (Sürekli) |
| **`Yüksek_Fırın_Cürufu`** | Blast furnace slag | Karışımdaki yüksek fırın cürufu miktarı | $kg / m^3$ | Sayısal (Sürekli) |
| **`Uçucu_Kül`** | Fly ash | Karışımdaki uçucu kül miktarı | $kg / m^3$ | Sayısal (Sürekli) |
| **`Su`** | Water | Karışımdaki net su miktarı | $kg / m^3$ | Sayısal (Sürekli) |
| **`Süper_Akışkanlaştırıcı`**| Superplasticizer | Kimyasal süper akışkanlaştırıcı katkı miktarı | $kg / m^3$ | Sayısal (Sürekli) |
| **`İri_Agrega`** | Coarse aggregate | Kaba agrega (çakıl / kırık taş) miktarı | $kg / m^3$ | Sayısal (Sürekli) |
| **`İnce_Agrega`** | Fine aggregate | İnce agrega (kum vb.) miktarı | $kg / m^3$ | Sayısal (Sürekli) |
| **`Kür_Süresi`** | Age | Betonun test edilene kadar kürlenme süresi | Gün (Days, 1 - 365) | Sayısal (Ayrık / Sürekli) |

---

## ⚙️ Ön İşleme Adımları

1. **Sıfır Değerlerinin Düzenlenmesi**: Logaritmik dönüşümler sırasında tanımsız değerlerin ($\log(0)$) önüne geçmek amacıyla tüm sayısal değişkenlere $+0.001$ sabiti eklenmiştir.
2. **Eğitim / Test Ayrımı**: Veri seti %75 Eğitim ($n_{train} = 772$) ve %25 Test ($n_{test} = 258$) olarak `set.seed(123)` ile ayrılmıştır.
3. **Aykırı Değer Temizliği**: Eğitim setinde standartlaştırılmış artıklar ($|r| > 3$) ve Cook's Distance ($D_i > 4/n$) kriterleri birleştirilerek modele orantısız etki eden 52 gözlem ayıklanmıştır ($n_{clean} = 720$).

---

## 🔗 Veri Kaynağı & Atıf

- **Kaggle Veri Kaynağı**: [Kaggle - Mutu Beton Dataset](https://www.kaggle.com/datasets/ainalirham/mutubeton/data)
- **Orijinal Çalışma**: Yeh, I-C. (1998). "Modeling of strength of high-performance concrete using artificial neural networks." *Cement and Concrete Research*, 28(12), 1797-1808.
