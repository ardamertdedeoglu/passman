# 🔐 Passman - Secure Password Manager

Passman, modern mimari ve güvenlik en iyi uygulamalarıyla inşa edilmiş, tam özellikli bir şifre yöneticisi uygulamasıdır. Flutter tabanlı mobil arayüzü ve Go tabanlı arka uç API'si ile masaüstü ve mobil platformlarda sorunsuz çalışır.

## 📋 İçindekiler

- [Özellikler](#-özellikler)
- [Teknoloji Yığını](#-teknoloji-yığını)
- [Proje Yapısı](#-proje-yapısı)
- [Gereksinimleri](#-gereksinimleri)
- [Kurulum](#-kurulum)
- [Çalıştırma](#-çalıştırma)
- [Mimari](#-mimari)
- [Geliştirme](#-geliştirme)

## ✨ Özellikler

### Frontend (Flutter)

- 🔐 **Güvenli Depolama**: Hassas verileri için sistem şifreleme
- 🔒 **Biometrik Kimlik Doğrulama**: Parmak izi/Yüz tanıma desteği
- 📱 **Çoklu Platform**: iOS, Android, Web ve Windows desteği
- 🔄 **Senkronizasyon**: Bulut senkronizasyonu ile verileriniz her zaman güncel
- 🎨 **Modern UI**: Material Design arayüzü ile kullanıcı dostu deneyim
- 🌍 **Uluslararası Dil Desteği**: Çoklu dil desteği (intl)
- 🔍 **Güçlü Arama**: Hızlı ve verimli şifre araması

### Backend (Go)

- 🚀 **Yüksek Performanslı API**: Chi router ile hızlı istek işleme
- 🔐 **JWT Kimlik Doğrulama**: Güvenli token tabanlı kimlik doğrulama
- 🗄️ **PostgreSQL Veritabanı**: ACID özellikli veri saklama
- 🛡️ **CORS Desteği**: Güvenli çapraz kaynak istekleri
- 🔒 **Şifre Şifreleme**: Veriler sunucuya şifreli biçimde gönderilir

## 🛠️ Teknoloji Yığını

### Frontend Stack

| Teknoloji                  | Amaç                       |
| -------------------------- | -------------------------- |
| **Flutter**                | UI Framework (v3.10.8+)    |
| **Dart**                   | Programlama Dili           |
| **Riverpod**               | State Management           |
| **Cryptography**           | Şifrelenmiş Veri Saklama   |
| **SQLite**                 | Yerel Veritabanı           |
| **Flutter Secure Storage** | Güvenli Veri Saklama       |
| **Local Auth**             | Biometrik Kimlik Doğrulama |
| **Go Router**              | Navigation & Routing       |
| **HTTP**                   | API İletişimi              |

### Backend Stack

| Teknoloji      | Amaç                   |
| -------------- | ---------------------- |
| **Go**         | Backend Dili (1.25.6+) |
| **Chi**        | Web Router Framework   |
| **PostgreSQL** | Veritabanı             |
| **JWT**        | Kimlik Doğrulama       |
| **pgx**        | PostgreSQL Driver      |
| **UUID**       | Benzersiz ID Oluşturma |
| **Godotenv**   | Ortam Değişkenleri     |

## 📁 Proje Yapısı

```
password-manager/
├── passman_frontend/           # Flutter Mobile App
│   ├── lib/
│   │   ├── main.dart          # Uygulama Giriş Noktası
│   │   ├── core/              # Çekirdek Fonksiyonlar
│   │   ├── crypto/            # Şifreleme İşlemleri
│   │   ├── features/          # Özellik Modülleri
│   │   └── services/          # İşletme Servisleri
│   ├── android/               # Android Platformu
│   ├── ios/                   # iOS Platformu
│   ├── web/                   # Web Platformu
│   ├── windows/               # Windows Platformu
│   ├── macos/                 # macOS Platformu
│   ├── linux/                 # Linux Platformu
│   ├── test/                  # Test Dosyaları
│   ├── pubspec.yaml           # Flutter Bağımlılıkları
│   └── README.md              # Dokümantasyon
│
└── passman-backend/           # Go Backend API
    ├── cmd/
    │   └── server/            # Sunucu Giriş Noktası
    ├── internal/
    │   ├── api/               # API İşleyicileri
    │   ├── models/            # Veri Modelleri
    │   ├── repository/        # Veritabanı İşlemleri
    │   └── service/           # İşletme Mantığı
    ├── docker-compose.yml     # Docker Konfigürasyonu
    ├── init.sql               # Veritabanı Şeması
    ├── go.mod                 # Go Bağımlılıkları
    └── main.go                # Sunucu Başlatma
```

## 📦 Gereksinimleri

### Frontend

- **Flutter SDK**: 3.10.8 veya üzeri
- **Dart SDK**: Flutter ile birlikte gelir
- **Platform Gereksinimleri**:
  - **Android**: Android SDK 21+ (Android Studio veya CLI)
  - **iOS**: Xcode 14+ ve CocoaPods
  - **Web**: Chrome, Firefox, Safari veya Edge
  - **Windows**: Visual Studio Build Tools
  - **Linux**: GCC ve gerekli kütüphaneler

### Backend

- **Go**: 1.25.6 veya üzeri
- **PostgreSQL**: 13 veya üzeri
- **Docker** (isteğe bağlı): Docker ve Docker Compose

### Genel Araçlar

- **Git**: Versiyon kontrol için
- **VS Code** veya **Android Studio/Xcode**: Geliştirme için

## 🚀 Kurulum

### Frontend Kurulumu

1. **Depo Klonlama**

   ```bash
   cd password-manager
   cd passman_frontend
   ```

2. **Bağımlılıkları Yükleme**

   ```bash
   flutter pub get
   ```

3. **Platform Spesifik Kurulumlar**

   **Android**:

   ```bash
   cd android
   ./gradlew build
   cd ..
   ```

   **iOS**:

   ```bash
   cd ios
   pod install
   cd ..
   ```

### Backend Kurulumu

1. **Backend Klasörüne Gitme**

   ```bash
   cd passman-backend
   ```

2. **PostgreSQL Veritabanı Ayarlama**

   **Seçenek 1: Docker ile (Önerilen)**

   ```bash
   docker-compose up -d
   ```

   **Seçenek 2: Manuel Kurulum**

   ```bash
   createdb passman
   psql passman < init.sql
   ```

3. **Ortam Değişkenlerini Ayarlama**

   ```bash
   cp .env.example .env
   # .env dosyasını konfigüre edin
   ```

4. **Go Bağımlılıklarını Yükleme**
   ```bash
   go mod download
   go mod tidy
   ```

## ▶️ Çalıştırma

### Backend Başlatma

```bash
cd passman-backend
go run cmd/server/main.go
```

Başarılı çıktı:

```
Server starting on :8080
Connected to PostgreSQL
```

### Frontend Başlatma

```bash
cd passman_frontend

# Android
flutter run -d android

# iOS
flutter run -d ios

# Web
flutter run -d web

# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Linux
flutter run -d linux

# Tüm cihazlar
flutter run
```

## 🏗️ Mimari

### İletişim Akışı

```
┌─────────────────────────────────────────────────────┐
│              Flutter Mobile App                      │
│  ┌──────────────────────────────────────────────┐   │
│  │  UI Layer (Screens, Widgets)                 │   │
│  └──────────────────────────────────────────────┘   │
│                        ↕                             │
│  ┌──────────────────────────────────────────────┐   │
│  │  State Management (Riverpod)                 │   │
│  └──────────────────────────────────────────────┘   │
│                        ↕                             │
│  ┌──────────────────────────────────────────────┐   │
│  │  Services (API, Local Storage, Crypto)       │   │
│  └──────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
               ↓ HTTPS/REST API ↓
┌─────────────────────────────────────────────────────┐
│            Go Backend API Server                     │
│  ┌──────────────────────────────────────────────┐   │
│  │  API Handlers (Chi Router)                   │   │
│  └──────────────────────────────────────────────┘   │
│                        ↕                             │
│  ┌──────────────────────────────────────────────┐   │
│  │  Service Layer (Business Logic)              │   │
│  └──────────────────────────────────────────────┘   │
│                        ↕                             │
│  ┌──────────────────────────────────────────────┐   │
│  │  Repository Layer (Data Access)              │   │
│  └──────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
               ↓ SQL Queries ↓
         PostgreSQL Database
```

### Güvenlik Katmanları

1. **Frontend**:
   - Biometrik kimlik doğrulama
   - Cihaz güvenli depolama
   - AES şifreleme

2. **Backend**:
   - JWT token kimlik doğrulama
   - TLS/HTTPS iletişimi
   - Veri şifrelemesi

3. **Veritabanı**:
   - ACID güvenliği
   - Şifreli bağlantı

## 👨‍💻 Geliştirme

### Projeyi Geliştireceğiniz Takdirde

1. **İlk Kurulum**

   ```bash
   git clone https://github.com/yourusername/password-manager.git
   cd password-manager
   ```

2. **Frontend Geliştirme**

   ```bash
   cd passman_frontend
   flutter pub get
   flutter run -d <device-name>
   ```

3. **Backend Geliştirme**
   ```bash
   cd passman-backend
   go run cmd/server/main.go
   ```

### Test Çalıştırma

**Frontend Testleri**:

```bash
cd passman_frontend
flutter test
```

**Backend Testleri**:

```bash
cd passman-backend
go test ./...
```

### Code Style

- **Flutter**: `flutter analyze`
- **Go**: `gofmt` ve `golangci-lint`

```bash
# Flutter
flutter analyze

# Go
gofmt -s -w .
golangci-lint run
```

## 📝 Örnek API Endpoint'leri

### Kimlik Doğrulama

- `POST /api/auth/register` - Yeni hesap oluştur
- `POST /api/auth/login` - Giriş yap
- `POST /api/auth/refresh` - Token yenile

### Şifre Yönetimi

- `GET /api/passwords` - Tüm şifreleri getir
- `POST /api/passwords` - Yeni şifre ekle
- `GET /api/passwords/{id}` - Belirli şifreyi getir
- `PUT /api/passwords/{id}` - Şifreyi güncelle
- `DELETE /api/passwords/{id}` - Şifreyi sil

## 🤝 Katkıda Bulunun

1. Depoyu fork edin
2. Özellik dalı oluşturun (`git checkout -b feature/AmazingFeature`)
3. Değişiklikleri commit edin (`git commit -m 'Add AmazingFeature'`)
4. Dala push edin (`git push origin feature/AmazingFeature`)
5. Pull Request açın

## 📄 Lisans

Bu proje MIT Lisansı altında lisanslanmıştır - detaylar için [LICENSE](LICENSE) dosyasına bakın.

## 📧 İletişim

Sorularınız veya önerileriniz için:

- E-posta: info@passman.dev
- GitHub: [github.com/passman](https://github.com/passman)

## 🙏 Teşekkürler

- Flutter ve Dart toplumuna
- Go ve açık kaynak projelerine
- Tüm katkıda bulunanlar ve destekçilere

---

**Passman** ile şifrelerinizi güvenle yönetin! 🔐
