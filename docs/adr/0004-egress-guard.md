# ADR-0004: Semua akses keluar lewat egress guard

- Status: **Accepted**
- Tanggal: 2026-10-24

## Konteks

Cek revocation dan timestamp mengharuskan server mengambil URL yang tertulis di dalam sertifikat (AIA untuk OCSP, CRL Distribution Point). Sertifikat datang dari PDF yang diunggah siapa saja, sehingga URL itu sepenuhnya dikendalikan penyerang. Tanpa kontrol, ini celah **SSRF** klasik: penyerang bisa membuat server mengakses metadata cloud (`169.254.169.254`), layanan internal di VM (PostgreSQL, layanan portofolio lain), atau memakai server sebagai alat pemindai jaringan.

## Keputusan

Semua request HTTP keluar dari kode verifikasi memakai satu klien di `internal/egress`. Klien ini:

1. Hanya mengizinkan skema `http` dan `https`, port 80 dan 443.
2. Me-resolve nama host sendiri, menolak semua IP non-publik (loopback, privat RFC 1918, link-local, CGNAT 100.64.0.0/10, multicast, unspecified, dan padanan IPv6 termasuk IPv4-mapped).
3. Melakukan dial langsung ke IP yang sudah dicek, untuk mencegah DNS rebinding.
4. Membatasi redirect (maksimal 2) dan mengecek ulang setiap hop.
5. Membatasi ukuran respons dan waktu per request.
6. Membatasi jumlah URL unik per verifikasi.

Penggunaan `http.DefaultClient`, `http.Get`, atau `http.Client` baru di luar `internal/egress` dilarang dan dicek dengan linter (`forbidigo`).

## Alternatif yang dipertimbangkan

- **Allowlist domain PSrE.** Lebih ketat, tetapi rapuh saat PSrE mengganti URL dan memblokir dokumen dari CA di luar Indonesia. Bisa ditambahkan nanti sebagai mode opsional.
- **Proxy keluar terpisah (misalnya Smokescreen).** Lebih kuat sebagai pertahanan berlapis, tetapi menambah komponen di VM kecil. Dipertimbangkan setelah MVP.
- **Tidak mengecek revocation sama sekali.** Ditolak: verdict menjadi tidak bisa dipercaya.

## Konsekuensi

- Satu titik untuk diuji dan diaudit; test khusus untuk setiap rentang IP terlarang dan skenario rebinding.
- Server tidak bisa memverifikasi dokumen dari CA internal yang OCSP-nya hanya ada di jaringan privat; pengguna seperti itu memakai mode offline atau versi self-hosted dengan konfigurasi berbeda.
- Kontrol ini juga dijelaskan di README sebagai bagian dari nilai portofolio.
