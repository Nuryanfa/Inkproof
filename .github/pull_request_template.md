## Ringkasan

<!-- Apa yang berubah dan kenapa. Rujuk item roadmap / user story (misalnya US-03, FR-3.2). -->

## Cara menguji

<!-- Test atau kasus corpus yang ditambahkan. -->

## Checklist

- [ ] `make lint test` hijau
- [ ] Test atau kasus corpus ditambahkan sebelum implementasi (untuk bug/fitur verifikasi)
- [ ] `make fuzz` dijalankan (jika menyentuh `internal/pdf`, `internal/cms`, `internal/diff`)
- [ ] Dokumentasi diperbarui (`docs/design.md`, ADR baru, atau `docs/roadmap.md`)

## Checklist keamanan (lihat docs/threat-model.md §6)

- [ ] Input baru dari dokumen punya batas ukuran/jumlah/kedalaman
- [ ] Akses jaringan baru lewat `internal/egress`
- [ ] Log baru tidak memuat isi dokumen, nama penanda tangan, atau secret
- [ ] Jalur baru menuju `TOTAL-PASSED` dibuktikan dengan test
- [ ] Dependensi baru punya alasan tertulis, `govulncheck` bersih
