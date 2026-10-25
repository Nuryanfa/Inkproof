# Architecture Decision Records

Catatan keputusan arsitektur. Satu file per keputusan, tidak diedit setelah `Accepted` kecuali untuk mengubah status menjadi `Superseded by ADR-XXXX`.

| No | Judul | Status |
|---|---|---|
| [0001](0001-go-and-library-choice.md) | Go dan pemilihan library PDF/CMS | Proposed (spike tahap 1 selesai, menunggu PDF asli) |
| [0002](0002-no-document-storage.md) | Dokumen tidak pernah disimpan | Accepted |
| [0003](0003-etsi-status-model.md) | Model status mengikuti ETSI EN 319 102-1 | Accepted |
| [0004](0004-egress-guard.md) | Semua akses keluar lewat egress guard | Accepted |
| [0005](0005-trust-store-curated.md) | Trust store dikurasi di repo dengan manifest | Accepted |

## Template

```markdown
# ADR-XXXX: <Judul>

- Status: Proposed | Accepted | Superseded by ADR-YYYY
- Tanggal: YYYY-MM-DD

## Konteks
Masalah apa dan batasan apa yang ada.

## Keputusan
Apa yang diputuskan, dalam satu atau dua kalimat tegas.

## Alternatif yang dipertimbangkan
- Opsi A — kenapa tidak dipilih.

## Konsekuensi
Apa yang jadi lebih mudah, apa yang jadi lebih sulit.
```
