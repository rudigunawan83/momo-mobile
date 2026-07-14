# Momo UI/UX Reference Guide

## Referensi Visual Utama

Semua keputusan UI/UX untuk aplikasi Momo **HARUS** berpatokan pada dua gambar referensi berikut:

### 1. UI Utama Momo

- **File:** `ui utama momo.png` (root project)
- **Fungsi:** Menjadi acuan utama untuk layout, warna, spacing, dan keseluruhan tampilan aplikasi Momo.
- **Gunakan untuk:** Struktur halaman, navigasi, komposisi elemen UI, tema warna, dan proporsi karakter terhadap UI.

### 2. UI Karakter Momo (Ciri Khas)

- **File:** `ui karakter momo.png` (root project)
- **Fungsi:** Menjadi acuan untuk desain karakter Momo — termasuk bentuk, proporsi, ekspresi, dan ciri khas visual.
- **Gunakan untuk:** Implementasi karakter Rive, ekspresi wajah, proporsi mata/mulut/jambul, warna karakter, dan style animasi.

## Prinsip Implementasi

1. **Karakter-first**: UI mengikuti karakter, bukan sebaliknya (80% Robot, 20% UI)
2. **Konsistensi visual**: Setiap widget dan screen harus selaras dengan referensi gambar di atas
3. **Floating Head**: Karakter Momo menggunakan desain floating head sesuai referensi
4. **Warna utama**: Ivory White (shell), Glossy Black OLED (face), Big Cyan Eyes, Pink Blush (pipi)
5. **Jambul ekspresif**: Jambul adalah ikon pembeda Momo — harus dinamis dan responsif terhadap emosi

## Catatan untuk Developer

Saat mengimplementasikan UI atau karakter Momo, selalu buka kedua file gambar ini sebagai referensi visual sebelum membuat keputusan desain.
