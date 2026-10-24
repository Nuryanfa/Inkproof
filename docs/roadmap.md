# Roadmap — TrueSign

Estimasi memakai sekitar **8 jam per minggu**. Setiap fase ditutup oleh gate; jangan lanjut sebelum gate terpenuhi.

Planning lengkap (konteks pasar dan strategi): [dokumen planning](https://claude.ai/artifact/3LdQAt1yMyW5PWhmgKunu6).

---

## F0 — Persiapan (minggu 1)

- [ ] Buat repo `pdf-verifier`, `go mod init`, struktur folder sesuai `docs/design.md` §2
- [ ] CI dasar: `golangci-lint`, `go test -race`, `govulncheck`
- [ ] Makefile dengan target di CLAUDE.md
- [ ] Spike library di `spike/` (kriteria di ADR-0001), tulis hasilnya, ubah status ADR-0001
- [ ] Kumpulkan root CA Indonesia dari sumber resmi, isi `trust/manifest.yaml`
- [ ] Kumpulkan minimal 3 PDF ber-TTE asli untuk uji silang
- [ ] Siapkan VM: user non-root, SSH key-only, firewall, swap 2 GB, Docker
- [ ] Putuskan nama produk dan lisensi

**Gate F0:** library terpilih (ADR-0001 Accepted), VM siap.

## F1 — Inti verifikasi (minggu 2–4)

- [ ] `testdata/pki`: generator CA, sertifikat, OCSP responder tiruan
- [ ] `internal/pdf`: xref, revisi, signature field, ByteRange
- [ ] `internal/cms`: digest dan verifikasi signature
- [ ] `internal/chain`: rantai, trust store loader dengan cek fingerprint
- [ ] `internal/report`: model, kode temuan, render JSON dan teks
- [ ] `pkg/verify.Verify` menyatukan pipeline (tanpa revocation, mode offline)
- [ ] CLI `verifier check` dengan exit code
- [ ] Corpus C-01, C-03, C-04, C-09–C-14, C-20, C-21
- [ ] Fuzz target `FuzzParsePDF`, `FuzzByteRange`

**Gate F1:** CLI lolos corpus dasar.

## F2 — Service dan deploy (minggu 5–6)

- [ ] `internal/egress` dengan seluruh test SSRF
- [ ] `internal/revocation`: OCSP, CRL, cache
- [ ] `internal/tsp`: verifikasi timestamp
- [ ] Corpus C-15–C-19, C-23
- [ ] `cmd/server`: `/v1/verify`, `/healthz`, `/readyz`, middleware, worker pool
- [ ] Web UI: halaman upload dan hasil, render laporan HTML
- [ ] Dockerfile multi-stage (distroless, non-root), `deploy/docker-compose.yml`, `Caddyfile`
- [ ] GitHub Actions: build, Trivy, push GHCR, deploy via SSH, smoke test
- [ ] Domain dan HTTPS aktif

**Gate F2:** live di VM dengan HTTPS dan deploy otomatis.

## F3 — Pembeda dan kematangan (minggu 7–8)

- [ ] `internal/diff`: klasifikasi revisi dan DocMDP
- [ ] Corpus C-05–C-08, C-22, C-24
- [ ] Fuzz target `FuzzParseCMS`, `FuzzVerify`; fuzzing 1 jam per target
- [ ] Uji silang dengan verifier Komdigi, isi `docs/cross-check.md`
- [ ] Metrik Prometheus dan log terstruktur
- [ ] README final: demo GIF, arsitektur, batasan, cara pakai
- [ ] Perbarui threat model dengan temuan selama implementasi

**Gate F3 — MVP selesai:** semua kriteria di `docs/prd.md` §11 tercentang.

## F4 — Validasi pasar (minggu 9–12)

- [ ] Pilih satu segmen (HR atau koperasi/leasing)
- [ ] Siapkan panduan wawancara
- [ ] 10 wawancara, rangkum temuan di `docs/research/`
- [ ] Artikel blog 1: QR code bukan tanda tangan, cara cek TTE yang benar
- [ ] Artikel blog 2: deteksi perubahan setelah tanda tangan (teknis)
- [ ] Pilot gratis 1–2 organisasi
- [ ] Cek kewajiban pendaftaran PSE Lingkup Privat

**Gate F4:** ada minimal 1 organisasi yang bersedia membayar? Jika tidak, project selesai sebagai portofolio.

## F5 — Komersial (minggu 13+)

Prioritas ditentukan dari hasil pilot. Kandidat:

- [ ] API key, kuota, PostgreSQL (`docs/design.md` §12)
- [ ] Upload massal (ZIP) dengan ringkasan per file
- [ ] Dashboard organisasi
- [ ] Billing
- [ ] Validasi LTV (PAdES-LT/LTA)
- [ ] Deteksi shadow attack dengan perbandingan render
- [ ] Laporan yang ditandatangani server

---

## Log progres

| Tanggal | Fase | Catatan |
|---|---|---|
| 2026-10-24 | F0 | Dokumentasi awal dibuat: PRD, design, threat model, ADR 0001–0005, test plan |
