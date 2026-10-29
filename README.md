# Inkproof

> Status: **dalam pengembangan (fase F0)**.

Verifier tanda tangan digital PDF yang memeriksa dua hal:

1. **Apakah dokumen ditandatangani oleh sertifikat yang dipercaya** — rantai sertifikat, masa berlaku, status pencabutan (OCSP/CRL), dan timestamp.
2. **Apakah dokumen diubah setelah ditandatangani** — termasuk manipulasi yang lolos dari ikon "centang hijau" di banyak PDF viewer, seperti incremental saving attack dan signature wrapping.

Tersedia sebagai **library Go**, **CLI**, dan **REST API + web UI**.

<!-- TODO: demo GIF -->

## Kenapa project ini ada

Dokumen ber-TTE (tanda tangan elektronik tersertifikasi) makin umum di Indonesia, tetapi verifikasi masih manual satu per satu, dan banyak orang menganggap QR code atau ikon centang di viewer sebagai bukti keaslian. Riset keamanan publik menunjukkan banyak viewer PDF bisa ditipu oleh dokumen yang diubah setelah ditandatangani. Project ini membuat verifikasi yang bisa diotomatisasi dan jujur soal apa yang bisa dan tidak bisa dipastikan.

## Fitur (target MVP)

- Verifikasi tanda tangan PAdES / CMS (`adbe.pkcs7.detached`, `ETSI.CAdES.detached`)
- Validasi rantai X.509 ke trust store yang dikurasi (root CA Indonesia dan PSrE)
- Cek pencabutan OCSP dengan fallback CRL
- Verifikasi timestamp RFC 3161
- Deteksi perubahan pasca-tanda-tangan dan izin DocMDP
- Status mengikuti ETSI EN 319 102-1: `TOTAL-PASSED`, `TOTAL-FAILED`, `INDETERMINATE`
- Laporan JSON dan HTML, pesan dalam Bahasa Indonesia dan Inggris
- **Dokumen tidak pernah disimpan**

## Pemakaian

```bash
# CLI
inkproof check kontrak.pdf
inkproof check kontrak.pdf --format json --trust ./my-trust-store
inkproof check kontrak.pdf --offline

# API
curl -F file=@kontrak.pdf https://<domain>/v1/verify
```

Exit code CLI: `0` lolos, `1` gagal, `2` tidak dapat dipastikan.

## Arsitektur

Satu inti (`pkg/verify`) dipakai oleh CLI dan server. Semua akses jaringan ke OCSP/CRL melewati egress guard yang mencegah SSRF. Detail di [docs/design.md](docs/design.md).

## Keamanan

- Threat model: [docs/threat-model.md](docs/threat-model.md)
- Parser di-fuzz secara rutin
- Container non-root dengan filesystem read-only

Menemukan celah keamanan? Mohon laporkan secara privat lewat GitHub Security Advisory, bukan issue publik.

## Batasan (penting)

- Hasil verifier ini adalah **pemeriksaan teknis dan kriptografis, bukan pernyataan keabsahan hukum**.
- Shadow attack tingkat lanjut (konten yang disiapkan sebelum penandatanganan) belum dideteksi penuh.
- Validasi jangka panjang (PAdES-LT/LTA) belum didukung di MVP.
- Verdict bergantung pada trust store; lihat [ADR-0005](docs/adr/0005-trust-store-curated.md).

## Dokumentasi

| Dokumen | Isi |
|---|---|
| [docs/prd.md](docs/prd.md) | Kebutuhan produk |
| [docs/design.md](docs/design.md) | Desain teknis |
| [docs/threat-model.md](docs/threat-model.md) | Threat model |
| [docs/test-plan.md](docs/test-plan.md) | Rencana pengujian dan corpus |
| [docs/roadmap.md](docs/roadmap.md) | Roadmap dan progres |
| [docs/adr/](docs/adr/) | Catatan keputusan arsitektur |
| [docs/api/openapi.yaml](docs/api/openapi.yaml) | Spesifikasi API |

## Pengembangan

```bash
make test lint      # wajib hijau sebelum commit
make fuzz           # untuk perubahan parser
make run            # server lokal di :8080
```

## Lisensi

[Apache License 2.0](LICENSE). Copyright 2026 Nur Yanfa.
