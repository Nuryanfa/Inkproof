# ADR-0005: Trust store dikurasi di repo dengan manifest

- Status: **Accepted**
- Tanggal: 2026-10-24

## Konteks

Seluruh verdict bergantung pada daftar root CA yang dipercaya. Pilihan sumbernya: trust store sistem operasi, daftar pihak ketiga (misalnya Adobe Approved Trust List), atau daftar yang dikurasi sendiri. Trust store OS ditujukan untuk TLS, bukan tanda tangan dokumen, dan isinya berbeda antar-mesin. Pengguna di Indonesia terutama membutuhkan root CA nasional dan PSrE yang berinduk ke Komdigi.

## Keputusan

Trust store bawaan disimpan di `trust/roots/*.pem` dengan `trust/manifest.yaml` yang mencatat untuk setiap root: nama, SHA-256, URL sumber resmi, dan tanggal pengambilan. Loader memverifikasi fingerprint saat startup dan menolak berjalan jika ada ketidakcocokan. Versi manifest dicantumkan di setiap laporan.

Pengguna CLI dan self-hosted bisa memakai trust store sendiri (`--trust <dir>`), yang menggantikan bawaan.

## Alternatif yang dipertimbangkan

- **Trust store OS.** Ditolak: tujuan berbeda (TLS), tidak deterministik, dan tidak memuat root khusus tanda tangan dokumen.
- **Mengunduh daftar dari internet saat runtime.** Ditolak: menambah ketergantungan jaringan dan permukaan serangan; perubahan tidak bisa direview.

## Konsekuensi

- Perubahan trust store terlihat di riwayat git dan bisa direview.
- Ada pekerjaan rutin: mengecek pembaruan root CA dari sumber resmi (dijadwalkan bulanan).
- Hasil verifikasi bisa direproduksi: versi kode + versi trust store + dokumen yang sama menghasilkan verdict yang sama (kecuali status revocation yang berubah seiring waktu).
