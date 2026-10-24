# CLAUDE.md

Konteks project untuk Claude Code. Baca ini dulu, lalu dokumen di `docs/` sesuai kebutuhan tugas.

## Project

**PDF Signature Verifier**: memverifikasi tanda tangan digital pada PDF (PAdES/CMS) dan mendeteksi perubahan setelah dokumen ditandatangani. Satu inti (`pkg/verify`) dipakai oleh CLI, REST API, dan web UI.

- Pemilik: Nur Yanfa (@Nuryanfa). Project portofolio security engineering yang juga diuji sebagai produk B2B.
- Fase saat ini: **F0 (persiapan)**. Lihat `docs/roadmap.md` untuk checklist fase aktif.
- Bahasa: kode, identifier, komentar, dan commit dalam **Bahasa Inggris**. Dokumen di `docs/` dan pesan untuk pengguna akhir dalam **Bahasa Indonesia** (pesan laporan juga punya versi Inggris).

## Dokumen rujukan

| Butuh… | Baca |
|---|---|
| Apa yang dibangun dan kenapa | `docs/prd.md` |
| Arsitektur, pipeline, aturan status | `docs/design.md` |
| Ancaman dan kontrol keamanan | `docs/threat-model.md` |
| Alasan keputusan teknis | `docs/adr/` |
| Kasus uji dan cara menambah corpus | `docs/test-plan.md` |
| Apa yang dikerjakan sekarang | `docs/roadmap.md` |

Jika implementasi menyimpang dari `docs/design.md`, perbarui dokumen di commit yang sama, atau tulis ADR baru bila itu keputusan arsitektur.

## Perintah

```bash
make test          # go test ./... -race
make lint          # golangci-lint run
make vuln          # govulncheck ./...
make fuzz          # fuzz semua target, 60 detik masing-masing
make golden        # jalankan golden test corpus; UPDATE=1 untuk menulis ulang expected.json
make run           # jalankan server lokal di :8080
make cli ARGS="check testdata/corpus/valid-basic/doc.pdf --format text"
make pki           # generate ulang PKI tiruan di testdata/pki
```

Sebelum menyatakan tugas selesai: `make lint test` harus hijau. Untuk perubahan di `internal/pdf`, `internal/cms`, atau `internal/diff`, jalankan juga `make fuzz`.

## Peta kode

```
cmd/verifier       CLI
cmd/server         HTTP server (API + web UI)
pkg/verify         API publik: Verify(ctx, io.ReaderAt, size, Options) (*Report, error)
internal/pdf       xref, revisi, signature dictionary, ByteRange
internal/cms       parse CMS, cek messageDigest, verifikasi signature
internal/chain     rantai X.509, trust store loader
internal/revocation OCSP, CRL, cache
internal/egress    http client dengan guard anti-SSRF
internal/tsp       timestamp RFC 3161
internal/diff      klasifikasi perubahan pasca-tanda-tangan, DocMDP
internal/report    model hasil, kode temuan, render JSON/HTML
internal/server    handler, middleware
trust/             root CA + manifest.yaml (dikurasi, lihat ADR-0005)
testdata/corpus    PDF uji + expected.json
testdata/pki       generator CA/OCSP/TSA tiruan
```

Arah dependensi: `cmd/*` → `pkg/verify` → `internal/*`. Paket `internal/*` hanya boleh saling mengimpor `report` dan `egress`.

## Aturan yang tidak boleh dilanggar

Ini invarian keamanan dan kebenaran. Jika sebuah tugas tampak membutuhkan pelanggaran, berhenti dan tanyakan.

1. **Fail closed.** Kondisi yang tidak bisa dipastikan menghasilkan `INDETERMINATE`, tidak pernah `TOTAL-PASSED`. Jangan menambah jalur yang "lolos secara default".
2. **Dokumen tidak pernah disimpan.** Tidak ada `os.CreateTemp`, tulis ke disk, atau log yang memuat isi dokumen atau nama penanda tangan. Yang boleh dicatat: `doc_sha256`, status, durasi, kode temuan (ADR-0002).
3. **Semua request keluar lewat `internal/egress`.** Jangan memakai `http.DefaultClient` atau `http.Get` di mana pun. URL dari sertifikat adalah input penyerang (ADR-0004).
4. **Jangan menulis kriptografi sendiri.** Hash, signature, dan parsing ASN.1 memakai stdlib atau library yang sudah dipilih (ADR-0001). Parsing struktur PDF boleh ditulis sendiri.
5. **Input selalu dibatasi.** Setiap loop atas data dari dokumen punya batas (jumlah objek, kedalaman rekursi, ukuran stream). Setiap fungsi yang membaca dokumen menerima `context.Context` dan menghormati deadline.
6. **Tidak ada panic yang lolos.** Parser mengembalikan error; server punya `recover` per request. Index slice dari data dokumen selalu dicek batasnya.
7. **Trust store hanya berubah lewat `trust/manifest.yaml`** dengan sumber dan fingerprint. Jangan menambah root CA di kode.
8. **Kode temuan stabil.** Kode di `internal/report/codes.go` tidak boleh diganti nama atau dihapus setelah dirilis; tambahkan yang baru saja.

## Konvensi kode

- Go versi sesuai `go.mod`. Format dengan `gofmt`/`goimports`.
- Error dibungkus dengan konteks: `fmt.Errorf("parse xref at offset %d: %w", off, err)`. Error sentinel di paket masing-masing (`var ErrNoSignature = errors.New(...)`).
- Bedakan **kegagalan sistem** (dikembalikan sebagai `error`) dari **temuan verifikasi** (dicatat di `Report`). PDF rusak adalah temuan, bukan error.
- Tidak ada global state yang bisa diubah. Dependensi (clock, fetcher, trust store) masuk lewat `Options` agar bisa diuji.
- Test berbentuk table-driven. Nama test menjelaskan perilaku: `TestByteRange_RejectsGapNotCoveringContents`.
- Log memakai `log/slog`. Jangan `fmt.Println` di luar `cmd/verifier`.
- Dependensi baru butuh alasan di deskripsi PR; untuk dependensi kriptografi atau parsing, tulis ADR.

## Alur kerja yang diharapkan

1. Baca bagian relevan di `docs/design.md` dan kasus uji terkait di `docs/test-plan.md`.
2. Untuk bug atau fitur verifikasi: **tambahkan kasus corpus atau test yang gagal dulu**, baru implementasi.
3. Implementasi perubahan sekecil mungkin yang membuat test lolos.
4. Jalankan `make lint test` (dan `make fuzz` bila menyentuh parser).
5. Perbarui dokumentasi bila perilaku berubah. Centang item di `docs/roadmap.md` bila selesai.
6. Commit dengan Conventional Commits: `feat(diff): classify annotation-only revisions`.

## Hal yang sering keliru

- `ByteRange` yang valid secara kriptografis belum tentu menutupi seluruh file. Selalu cek struktur (FR-2.4, FR-2.5 di PRD), bukan hanya digest.
- `signingTime` di CMS adalah klaim penanda tangan, bukan waktu terpercaya. Waktu terpercaya hanya dari timestamp RFC 3161 yang valid.
- Sertifikat dicabut **setelah** waktu tanda tangan terpercaya tidak menggagalkan tanda tangan; dicabut **sebelum** menggagalkan.
- Incremental update yang hanya menambah tanda tangan baru atau DSS itu normal pada dokumen multi-signature. Jangan dilaporkan sebagai manipulasi.
- PDF bisa punya beberapa xref section dan xref stream; jangan berasumsi hanya ada satu `trailer`.

## Status saat ini

Perbarui bagian ini di akhir setiap sesi kerja yang signifikan.

- **Fase:** F0
- **Terakhir dikerjakan:** dokumentasi awal (PRD, design, threat model, ADR, test plan)
- **Berikutnya:** spike library di `spike/` (lihat roadmap F0), hasilnya memperbarui ADR-0001
- **Keputusan tertunda:** lisensi repo, nama produk final
