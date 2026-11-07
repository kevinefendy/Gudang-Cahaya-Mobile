# Gudang Cahaya (Mobile App)

Aplikasi mobile Flutter untuk mengelola data produk gudang (inventaris), dibuat
sesuai PRD `PRD.TXT`. Terhubung ke REST API backend Node.js + Drizzle ORM
(`../Backend`).

## Fitur

- Login dengan autentikasi token (JWT) dan penyimpanan token di
  `shared_preferences`.
- Register akun baru.
- Logout (token dihapus, kembali ke halaman login) dari tab Profil.
- Navigasi bawah dengan tiga tab: **Beranda**, **Produk**, dan **Profil**.
- Beranda berisi ringkasan produk (jumlah produk, total stok, nilai inventaris)
  dan aksi cepat.
- Daftar produk dengan tampilan adaptif: list di layar sempit, grid otomatis
  saat layar lebar/landscape (2-4 kolom), plus pull-to-refresh, loading, empty,
  dan error state.
- Tambah produk, edit produk, dan hapus produk dengan dialog konfirmasi. Gambar
  produk bersifat opsional saat tambah maupun edit.
- Validasi input pada semua form (email, password, username, nama, kategori,
  harga, stok, deskripsi).
- Indikator loading dan SnackBar untuk setiap error.

## Struktur Folder

```
lib/
├── main.dart
├── models/       -> UserModel, ProductModel
├── services/     -> ApiService (http + shared_preferences)
├── screens/      -> Login, Register, Main (bottom nav), Beranda, Profil,
│                    ProductList, ProductForm
├── widgets/      -> ProductCard
└── utils/        -> validators, formatters
```

## Menjalankan

1. Jalankan backend terlebih dahulu:

   ```bash
   cd ../Backend
   npm install
   npm run dev
   ```

2. Install dependency Flutter:

   ```bash
   flutter pub get
   ```

3. Jalankan aplikasi.

   Android Emulator (default base URL `http://10.0.2.2:3000/api/v1`):

   ```bash
   flutter run
   ```

   HP fisik (ganti dengan IP LAN komputer):

   ```bash
   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000/api/v1
   ```

## Catatan

- Base URL default ada di `lib/services/api_service.dart` dan bisa dioverride
  lewat `--dart-define=API_BASE_URL=...`.
- Backend menggunakan prefix `/api/v1` dan endpoint produk memakai
  `multipart/form-data` dengan field `image` yang **opsional**. Jika gambar
  tidak dipilih saat tambah produk, backend menyimpan gambar kosong dan aplikasi
  menampilkan placeholder. Saat edit, gambar lama dipertahankan jika tidak
  memilih gambar baru.
- Password minimal 8 karakter mengikuti validasi backend.
- Minimal Android 8.0 (API 26) dan `usesCleartextTraffic` diaktifkan untuk
  koneksi HTTP ke server lokal.
