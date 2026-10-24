# ADR-0001: Go dan pemilihan library PDF/CMS

- Status: **Proposed** (difinalkan setelah spike F0)
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

_Belum dijalankan._
