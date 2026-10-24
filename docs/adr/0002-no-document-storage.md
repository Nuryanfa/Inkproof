# ADR-0002: Dokumen tidak pernah disimpan

- Status: **Accepted**
- Tanggal: 2026-10-24

## Konteks

Dokumen yang diverifikasi (ijazah, kontrak, dokumen pinjaman, dokumen klaim) berisi data pribadi dan bisa bersifat rahasia. Menyimpannya menambah kewajiban di bawah UU Pelindungan Data Pribadi, menambah dampak jika server dibobol, dan menurunkan kepercayaan calon pengguna. Di sisi lain, menyimpan dokumen akan memudahkan debugging dan fitur "lihat ulang hasil".

## Keputusan

Dokumen hanya ada di memori selama verifikasi berlangsung. Tidak ada penulisan ke disk, file sementara, object storage, atau log. Yang boleh disimpan: SHA-256 dokumen, `verification_id`, status, sub-indikasi, kode temuan, durasi, dan ID API key.

## Alternatif yang dipertimbangkan

- **Simpan sementara (misalnya 24 jam) untuk unduh ulang laporan.** Ditolak: manfaat kecil, risiko dan kewajiban hukum tetap ada.
- **Simpan terenkripsi.** Ditolak untuk MVP: tetap menimbulkan kewajiban pengelolaan kunci dan retensi.

## Konsekuensi

- Klaim pemasaran yang kuat dan mudah dijelaskan: *"Dokumen Anda tidak disimpan."*
- Debugging kasus pengguna membutuhkan pengguna mengirim ulang dokumen secara sukarela.
- Batas ukuran file wajib, karena seluruh dokumen ada di RAM. Worker pool harus dibatasi agar total memori aman.
- Laporan hanya bisa diunduh pada respons yang sama; tidak ada riwayat isi laporan di server.
- Container berjalan dengan filesystem read-only sebagai penegak teknis keputusan ini.
