# ADR-0001: Go dan pemilihan library PDF/CMS

- Status: **Proposed** (spike tahap 1 selesai 2026-10-25; tahap 2 menunggu PDF ber-TTE asli)
- Tanggal: 2026-10-24

## Konteks

Verifier membutuhkan tiga kemampuan: membaca struktur PDF (xref, revisi, signature dictionary), mem-parsing CMS/PKCS#7, dan memvalidasi rantai X.509. Menulis kriptografi sendiri berisiko tinggi; menulis parser PDF sendiri berisiko sedang tetapi mungkin diperlukan untuk deteksi perubahan pasca-tanda-tangan.

Bahasa dipilih dengan mempertimbangkan roadmap belajar pemilik (Go), deploy di VM kecil (binary tunggal, memori rendah), dan keamanan memori untuk parser input tidak tepercaya.

## Keputusan

- Bahasa: **Go**.
- Validasi rantai X.509: **`crypto/x509` dari stdlib**.
- Parsing CMS: **`github.com/digitorus/pkcs7`** (kandidat utama).
- Parsing PDF dan verifikasi dasar: **`github.com/digitorus/pdfsign`** (kandidat utama), dengan kemungkinan parser xref/revisi ditulis sendiri di `internal/pdf` jika library tidak mengekspos struktur yang dibutuhkan `internal/diff`.
- OCSP: **`golang.org/x/crypto/ocsp`**.

## Spike F0 (kriteria untuk mengubah status menjadi Accepted)

Uji pada minimal 3 PDF ber-TTE asli dan 3 PDF dari PKI tiruan:

- [ ] Bisa membaca semua tanda tangan pada dokumen multi-signature.
- [ ] Bisa mengakses `ByteRange` mentah dan blob `/Contents`.
- [ ] Bisa memetakan tanda tangan ke revisi, atau jelas bahwa ini harus ditulis sendiri.
- [ ] CMS dengan `ETSI.CAdES.detached` dan atribut `signingCertificateV2` terbaca.
- [ ] Unsigned attribute timestamp token bisa diambil.
- [ ] Tidak ada panic pada 1 menit fuzzing awal.

Hasil spike ditulis di bagian "Hasil" di bawah.

## Alternatif yang dipertimbangkan

- **Java + Apache PDFBox / EU DSS.** DSS adalah implementasi referensi validasi AdES di Eropa dan sangat lengkap. Tidak dipilih karena berat untuk VM 4 GB, tidak sejalan dengan roadmap belajar Go, dan nilai portofolionya lebih rendah (sebagian besar logika sudah jadi).
- **Python + pyHanko.** Library verifikasi PDF yang matang. Tidak dipilih karena alasan yang sama dengan DSS, dan deploy kurang ringkas.
- **Memanggil tool eksternal (misalnya qpdf) via exec.** Disimpan sebagai cadangan untuk kasus tertentu, bukan jalur utama, karena menambah permukaan serangan dan dependensi sistem.
- **Menulis parser CMS sendiri.** Ditolak: risiko kesalahan kriptografi terlalu tinggi.

## Konsekuensi

- Ekosistem PDF di Go lebih kecil daripada Java/Python; sebagian kemampuan mungkin harus ditulis sendiri.
- Parser yang ditulis sendiri wajib di-fuzz dan dibatasi input-nya (lihat CLAUDE.md aturan 5 dan 6).
- Jika spike gagal di kriteria inti, ADR ini digantikan ADR baru (misalnya sidecar pyHanko di belakang API internal).

## Hasil spike

Tahap 1 (2026-10-25) memakai PKI tiruan: root, intermediate, dua penanda tangan dengan EKU Document Signing, TSA RFC 3161 lokal. PDF uji dibuat dengan `pdfsign/sign`. Versi: `pdfsign v0.9.0`, `pdf v0.1.2`, `pkcs7` dan `timestamp` pseudo-version 2026-09-14. Kode spike ada di `spike/` (tidak di-commit).

| PDF uji | Isi |
|---|---|
| `gen-single-ts` | 1 tanda tangan + timestamp |
| `gen-single-nots` | 1 tanda tangan tanpa timestamp |
| `gen-multi` | 2 tanda tangan (incremental update) |
| `tamper-append` | byte ditambahkan setelah tanda tangan |
| `tamper-byte` | 1 byte diubah di dalam stream yang ditandatangani |
| `tamper-syntax` | 1 byte diubah di objek catalog (sintaks rusak) |

**Per kriteria:**

- [x] Semua tanda tangan terbaca pada multi-signature (walk `AcroForm/Fields` dan scan xref sama-sama menemukan 2).
- [x] `ByteRange` mentah dan `/Contents` bisa diakses lewat `digitorus/pdf`; pengecekan struktur (gap tepat menutupi string hex, menutupi seluruh file) harus ditulis sendiri.
- [x] Pemetaan ke revisi: **harus ditulis sendiri.** `digitorus/pdf` menggabungkan semua xref menjadi satu tampilan, tidak ada tampilan per revisi. Pemetaan via posisi `%%EOF` terhadap `c+d` bekerja untuk semua PDF uji.
- [~] `signingCertificateV2` terbaca. **`ETSI.CAdES.detached` belum teruji**: `pdfsign` menghasilkan `adbe.pkcs7.detached`. Parsing CMS tidak bergantung pada SubFilter, tetapi tetap harus dibuktikan dengan PDF asli.
- [x] Timestamp token terbaca dari unsigned attribute; message imprint cocok dengan signature value.
- [ ] Tidak ada panic: **gagal untuk `digitorus/pdf`.** Library ini melaporkan error lewat `panic` sebagai desain (`lex.go` `errorf`); fuzzing menemukan panic dalam ±4 detik, dan `tamper-syntax` memicu panic saat resolve objek. `digitorus/pkcs7`: ±600 ribu eksekusi dalam 60 detik tanpa panic.

**Temuan penting tentang `pdfsign/verify`** (alasan tidak dipakai sebagai inti):

1. `tamper-append` dilaporkan `valid=true` tanpa error: tidak ada pengecekan bahwa ByteRange menutupi file (FR-2.4).
2. Validasi rantai hanya ke system root pool (`Roots: nil`). Tidak ada cara memberi trust store sendiri; bertentangan dengan ADR-0005.
3. Tanda tangan yang gagal di-parse **dilewati diam-diam** (`continue`), bukan dilaporkan; melanggar fail closed.
4. Memakai `http.DefaultClient`/`http.Get` untuk revocation; melanggar ADR-0004.
5. Tidak menerima `context.Context`, tidak ada batas input, dan iterasi atas seluruh xref.

Yang bekerja baik: `pkcs7.Verify()` mendeteksi `tamper-byte` (digest mismatch), dan rantai `crypto/x509` dengan pool root kustom serta `CurrentTime` = waktu timestamp lolos untuk semua tanda tangan.

**Arah keputusan (menunggu tahap 2):**

- `crypto/x509`, `digitorus/pkcs7`, `digitorus/timestamp`, `golang.org/x/crypto/ocsp`: **dipakai**. Kedua paket digitorus tidak punya tag rilis, jadi dipin ke pseudo-version dan setiap update di-review.
- `internal/pdf`: **parser sendiri** (xref table dan stream, revisi, signature dictionary) dengan batas input, `context.Context`, dan error, bukan panic. `digitorus/pdf` tidak dipakai di jalur produksi.
- `digitorus/pdfsign`: **hanya `sign`, untuk membangkitkan corpus** di `testdata/pki`. `verify` tidak dipakai, tetapi tetap berguna sebagai pembanding di uji silang.

Tahap 2 (syarat status Accepted): jalankan `spike check` pada minimal 3 PDF ber-TTE asli, terutama untuk SubFilter `ETSI.CAdES.detached`, xref stream, dan rantai PSrE.
