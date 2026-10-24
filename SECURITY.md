# Security Policy

## Melaporkan Kerentanan

Jika kamu menemukan celah keamanan pada TrueSign, mohon **jangan** buka issue publik.

Laporkan secara privat lewat **GitHub Security Advisory**:
[https://github.com/Nuryanfa/TrueSign/security/advisories/new](https://github.com/Nuryanfa/TrueSign/security/advisories/new)

Sertakan:
- Deskripsi kerentanan dan dampaknya
- Langkah reproduksi atau proof-of-concept
- Versi yang terpengaruh

Kami akan merespons dalam **7 hari kerja** dan berkoordinasi untuk memperbaiki sebelum pengungkapan publik.

## Scope

Yang termasuk scope:
- `pkg/verify` dan semua paket `internal/*`
- REST API (`cmd/server`)
- CLI (`cmd/verifier`)
- Bypass deteksi manipulasi PDF (false negative pada serangan yang terdokumentasi di threat model)

Yang di luar scope untuk saat ini:
- Shadow attack tingkat lanjut (V-04 s.d. V-06) — sudah terdokumentasi sebagai batasan yang diketahui di MVP

## Versi yang Didukung

| Versi | Didukung |
|---|---|
| main (pre-release) | Ya |
