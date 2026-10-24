# Test Plan — TrueSign

| | |
|---|---|
| **Status** | Draft v0.1 |
| **Terakhir diperbarui** | 2026-10-24 |

Tujuan test plan ini: membuktikan bahwa verifier **tidak pernah memberi `TOTAL-PASSED` pada dokumen yang seharusnya gagal**, dan bahwa setiap status punya alasan yang benar.

---

## 1. Lapisan pengujian

| Lapisan | Alat | Dijalankan |
|---|---|---|
| Unit test | `go test` table-driven | Setiap commit (CI) |
| Golden test corpus | `testdata/corpus/*/expected.json` | Setiap commit (CI) |
| Fuzzing | Go native fuzzing | 60 detik per target di CI; 1 jam sebelum rilis |
| Integrasi API | `httptest` + corpus | Setiap commit (CI) |
| Uji silang | Verifier Komdigi / BSrE, manual | Setiap rilis dan setiap perubahan `internal/cms` atau `internal/chain` |
| Smoke test produksi | `curl` ke `/healthz` + 1 PDF contoh | Setiap deploy |
| Load test | `k6` atau `vegeta` | Sebelum fase komersial |

## 2. PKI tiruan (`testdata/pki`)

Generator Go (`make pki`) membuat seluruh infrastruktur uji secara deterministik dari seed tetap, sehingga test tidak butuh internet dan hasilnya stabil:

- Root CA uji, intermediate CA uji.
- Sertifikat penanda tangan: valid, kedaluwarsa, belum berlaku, dicabut sebelum tanda tangan, dicabut setelah tanda tangan, key usage salah, RSA 1024, ECDSA P-256.
- OCSP responder (`httptest.Server`) yang bisa diatur membalas good/revoked/unknown/timeout/respons tidak ditandatangani.
- CRL untuk skenario fallback.
- TSA tiruan untuk timestamp RFC 3161.
- Root CA "asing" yang **tidak** ada di trust store uji.

Kunci privat PKI tiruan hanya untuk test dan diberi nama jelas `*-TEST-ONLY.key`.

## 3. Struktur corpus

```
testdata/corpus/
  valid-basic/
    doc.pdf
    expected.json     # status, sub_indication, finding codes per signature
    README.md         # cara dokumen ini dibuat dan apa yang diuji
  modified-content-after-signing/
    ...
```

`expected.json` hanya berisi field yang stabil (status, sub-indikasi, kode temuan, jumlah tanda tangan), bukan waktu atau ID.

## 4. Kasus uji corpus (minimal untuk MVP)

| # | Kasus | Status dokumen yang diharapkan | Kode temuan utama | Ancaman (threat-model) |
|---|---|---|---|---|
| C-01 | Satu tanda tangan valid, dengan timestamp | TOTAL-PASSED | — | — |
| C-02 | Satu tanda tangan valid, tanpa timestamp | TOTAL-PASSED (waktu `claimed`) | `SIGNING_TIME_CLAIMED` (info) | V-09 |
| C-03 | Dua tanda tangan berurutan, keduanya valid | TOTAL-PASSED | — | — |
| C-04 | Satu byte konten diubah di dalam rentang ByteRange | TOTAL-FAILED | `HASH_FAILURE` | — |
| C-05 | Incremental update mengubah isi halaman setelah tanda tangan | TOTAL-FAILED | `MODIFIED_AFTER_SIGNING` | V-01 |
| C-06 | Incremental update hanya mengisi form field, tanpa DocMDP | TOTAL-PASSED + peringatan | `FORM_FILLED_AFTER_SIGNING` (warning) | V-01 |
| C-07 | Certification signature DocMDP P=1, lalu form diisi | TOTAL-FAILED | `MODIFIED_AFTER_SIGNING` (DocMDP) | V-01 |
| C-08 | Anotasi ditambahkan, DocMDP P=3 | TOTAL-PASSED + info | `ANNOTATION_ADDED` | — |
| C-09 | ByteRange tidak dimulai dari 0 | TOTAL-FAILED | `FORMAT_FAILURE` | V-02 |
| C-10 | ByteRange tidak mencakup akhir revisi | TOTAL-FAILED | `FORMAT_FAILURE` | V-02 |
| C-11 | Celah ByteRange lebih lebar dari `/Contents` | TOTAL-FAILED | `FORMAT_FAILURE` | V-02 |
| C-12 | `/Contents` kosong atau signature null | TOTAL-FAILED | `FORMAT_FAILURE` | V-03 |
| C-13 | Sertifikat dari root yang tidak ada di trust store | INDETERMINATE | `NO_CERTIFICATE_CHAIN_FOUND` | V-07 |
| C-14 | Sertifikat kedaluwarsa saat tanda tangan, tanpa timestamp | INDETERMINATE | `OUT_OF_BOUNDS_NO_POE` | V-09 |
| C-15 | Sertifikat dicabut sebelum waktu tanda tangan | TOTAL-FAILED | `REVOKED` | V-08 |
| C-16 | Sertifikat dicabut setelah waktu tanda tangan (ada timestamp) | TOTAL-PASSED + peringatan | `REVOKED_AFTER_SIGNING` | V-08 |
| C-17 | OCSP responder timeout, CRL tidak ada | INDETERMINATE | `TRY_LATER` | — |
| C-18 | Respons OCSP tidak ditandatangani dengan benar | INDETERMINATE | `REVOCATION_UNAVAILABLE` | V-11 |
| C-19 | Signature SHA-1 | INDETERMINATE | `CRYPTO_CONSTRAINTS_FAILURE` | V-10 |
| C-20 | PDF tanpa tanda tangan | INDETERMINATE | `NO_SIGNATURE` | V-13 |
| C-21 | PDF rusak/terpotong | INDETERMINATE | `FORMAT_FAILURE` | — |
| C-22 | Data tambahan setelah `%%EOF` terakhir | Minimal INDETERMINATE | `TRAILING_DATA` | V-12 |
| C-23 | URL OCSP di sertifikat menunjuk ke `127.0.0.1` | INDETERMINATE | `REVOCATION_UNAVAILABLE` + egress ditolak | SSRF |
| C-24 | 51 field tanda tangan | Diproses 50, sisanya dilaporkan | `SIGNATURE_LIMIT_REACHED` | DoS |

Kasus C-05, C-07, C-09–C-12 adalah inti nilai produk dan **wajib ada sebelum gate F1**.

## 5. Unit test penting per paket

| Paket | Yang diuji |
|---|---|
| `internal/pdf` | xref tabel dan stream, beberapa revisi, objek duplikat, offset di luar file, rekursi dalam |
| `internal/cms` | digest cocok/tidak, algoritma tidak dikenal, atribut hilang, sertifikat penanda tangan tidak ada di CMS |
| `internal/chain` | rantai lengkap, intermediate hilang, waktu validasi, key usage, loop rantai |
| `internal/revocation` | good/revoked/unknown, fallback CRL, cache hit/miss, `nextUpdate` lewat |
| `internal/egress` | setiap rentang IP terlarang (v4 dan v6, termasuk IPv4-mapped), port terlarang, redirect ke IP privat, DNS rebinding, respons melebihi batas |
| `internal/diff` | setiap kelas objek, DocMDP P=1/2/3, tanpa DocMDP |
| `internal/report` | setiap baris tabel status di `design.md` §5 punya test sendiri |

## 6. Fuzzing

| Target | Input | Invarian |
|---|---|---|
| `FuzzParsePDF` | byte acak + seed dari corpus | Tidak panic, selesai dalam batas waktu, memori dibatasi |
| `FuzzParseCMS` | blob `/Contents` dari corpus + mutasi | Tidak panic |
| `FuzzByteRange` | array ByteRange dan ukuran file acak | Tidak panic, tidak pernah dinyatakan valid jika di luar batas file |
| `FuzzVerify` | PDF dari corpus + mutasi | Tidak panic; **mutasi di dalam rentang yang ditandatangani tidak pernah menghasilkan TOTAL-PASSED** |

Crash yang ditemukan disimpan di `testdata/fuzz/` sebagai regression test.

## 7. Uji silang dengan verifier resmi

Untuk setiap PDF ber-TTE asli yang dipakai (dokumen milik sendiri atau dokumen publik, tidak disimpan di repo publik bila mengandung data pribadi):

1. Unggah ke `tte.komdigi.go.id/verifyPDF` dan/atau `bsre.bssn.go.id/verify`, catat hasil.
2. Jalankan `verifier check`.
3. Catat di `docs/cross-check.md`: tanggal, PSrE penerbit, hasil resmi, hasil verifier, catatan perbedaan.

Setiap perbedaan harus dijelaskan (misalnya trust store berbeda, atau verifier ini mendeteksi perubahan yang tidak dicek layanan resmi), bukan diabaikan.

## 8. Kriteria lolos rilis

- [ ] Semua unit test dan golden test hijau dengan `-race`.
- [ ] Cakupan `internal/*` ≥ 80%.
- [ ] Fuzzing 1 jam per target tanpa crash baru.
- [ ] `govulncheck` dan Trivy bersih untuk temuan high/critical yang bisa diperbaiki.
- [ ] Uji silang terbaru tanpa perbedaan yang belum dijelaskan.
