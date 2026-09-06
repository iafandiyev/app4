# 📱 Kitabça Admin - iPhone (.IPA) İdarəetmə Tətbiqi

Bu layihə **Kitabça.az** satış sistemi üçün xüsusi hazırlanmış yerli (native) SwiftUI iPhone tətbiqidir.

---

## 🚀 Xüsusiyyətlər
1. **Canlı Sifariş Siyahısı ("Kimin nə verdiyi sifariş"):**
   - Müştərinin əlaqə nömrəsi, sifariş kodu (`AZ-XXXX`), sifariş etdiyi kitabça və məbləğ (`5 AZN` / `3 AZN`).
   - 1 toxunuşla **WhatsApp** açma və ya birbaşa **Zəng etmə** düymələri.
2. **Yer və Status Seçimi ("Hansı yerdə olduğunu seçim"):**
   - Çatdırılma mərhələləri: `Gözləmədə`, `Hazırlanır`, `Çatdırılmada`, `Təhvil verildi`.
   - Məkan seçici: "Kuryerdə (Yoldadır)", "28 May metrosunda", "Koroğlu metrosunda", "Anbarda" və ya istənilən dəqiq ünvan qeydi.
   - Yadda saxlandıqda müştərinin canlı izləmə ekranında anında əks olunur.
3. **Avtomatik Bildiriş & Səs Siqnalı ("Sifariş gələndə bildiriş gəlsin"):**
   - Yeni sifariş daxil olduqda sistem səs siqnalı və bildiriş göndərir.

---

## 🛠️ GitHub Actions ilə .IPA Faylının Qurulması (Build)

Layihədə `.github/workflows/build-ipa.yml` konfiqurasiya edilib.

### Addımlar:
1. Kodu GitHub-a göndərin (`git push origin main`).
2. GitHub-da reponuzun **Actions** bölməsinə keçin:
   👉 `https://github.com/iafandiyev/app4/actions`
3. **"Build iPhone App (.IPA)"** iş axınının tamamlanmasını gözləyin (təxminən 2-3 dəqiqə).
4. Bitdikdən sonra **Artifacts** bölməsindən **`KitabcaAdmin-iOS-IPA`** faylını (KitabcaAdmin.ipa) kompüterinizə və ya birbaşa iPhone-a yükləyin!

---

## 📲 .IPA Faylını iPhone-a Quraşdırma Yolları

Apple Developer hesabı olmadan pulsuz şəkildə quraşdırmaq üçün:

1. **Sideloadly (Tövsiyə olunur - Windows/Mac):**
   - [sideloadly.io](https://sideloadly.io) proqramını kompüterə yükləyin.
   - iPhone-u kabel ilə kompüterə qoşun.
   - Endirdiyiniz `KitabcaAdmin.ipa` faylını Sideloadly pəncərəsinə atın.
   - Apple ID-nizi yazıb **Start** düyməsinə basın. Tətbiq iPhone-a yazılacaq!
   - iPhone-da: *Ayarlar (Settings) -> Ümumi (General) -> VPN və Cihaz İdarəetməsi* bölməsindən sertifikata "Etibar et (Trust)" deyin.

2. **AltStore (Windows/Mac):**
   - [altstore.io](https://altstore.io) vasitəsilə quraşdırın və IPA faylını telefona ötürün.

3. **Scarlet (Birbaşa iPhone brauzeri ilə):**
   - [usescarlet.com](https://usescarlet.com) saytından Scarlet quraşdırın və daxilində IPA faylını seçib quraşdırın.

---

## ⚙️ Server Ünvanını Tənzimləmək
Tətbiqi açdıqdan sonra yuxarı sağ küncdəki **Çarx (Settings)** ikonuna toxunun:
- Öz serverinizin IP ünvanını yazın: `http://192.168.x.x:8000` (və ya ngrok / domen ünvanınızı).