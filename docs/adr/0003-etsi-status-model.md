# ADR-0003: Model status mengikuti ETSI EN 319 102-1

- Status: **Accepted**
- Tanggal: 2026-10-24

## Konteks

Verdict sederhana "valid/tidak valid" menyesatkan. Banyak kondisi bukan gagal, tetapi juga tidak bisa dipastikan lolos: server OCSP tidak bisa dihubungi, rantai ke root tidak ditemukan, atau sertifikat sudah kedaluwarsa tanpa bukti waktu. Auditor dan integrator butuh istilah yang sudah dikenal industri.

## Keputusan

Memakai tiga status utama dari ETSI EN 319 102-1 — `TOTAL-PASSED`, `TOTAL-FAILED`, `INDETERMINATE` — beserta sub-indikasi bernama dari standar itu bila ada padanannya (misalnya `HASH_FAILURE`, `SIG_CRYPTO_FAILURE`, `REVOKED`, `NO_CERTIFICATE_CHAIN_FOUND`, `OUT_OF_BOUNDS_NO_POE`, `TRY_LATER`, `CRYPTO_CONSTRAINTS_FAILURE`, `FORMAT_FAILURE`).

Temuan khas produk ini yang tidak ada di standar (misalnya `MODIFIED_AFTER_SIGNING`) diberi kode sendiri dan didokumentasikan sebagai ekstensi.

Produk **tidak** mengklaim kepatuhan penuh terhadap ETSI EN 319 102-1; standar dipakai sebagai kerangka istilah dan urutan pemeriksaan.

## Alternatif yang dipertimbangkan

- **Boolean valid/tidak valid.** Ditolak: memaksa kondisi tidak pasti menjadi salah satu sisi, melanggar prinsip fail closed.
- **Skema status buatan sendiri.** Ditolak: menyulitkan integrator dan auditor yang sudah mengenal istilah ETSI.

## Konsekuensi

- UI harus menerjemahkan status teknis ke bahasa awam (hijau/merah/kuning dengan penjelasan).
- Aturan penentuan status didokumentasikan sebagai tabel berurutan di `docs/design.md` §5 dan diuji per baris.
- Setiap jalur menuju `TOTAL-PASSED` harus punya test yang membuktikan semua syarat diperiksa.
