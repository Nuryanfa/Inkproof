# PRD — Inkproof

| | |
|---|---|
| **Status** | Draft v0.1 |
| **Produk** | Inkproof |
| **Pemilik** | Nur Yanfa (@Nuryanfa) |
| **Terakhir diperbarui** | 2026-10-24 |
| **Dokumen terkait** | [design.md](design.md) · [threat-model.md](threat-model.md) · [roadmap.md](roadmap.md) · [test-plan.md](test-plan.md) |

> Cek ketersediaan domain dan merek dagang sebelum launch publik.

---

## 1. Ringkasan

Inkproof memeriksa apakah sebuah PDF ditandatangani dengan sertifikat yang dipercaya **dan** apakah isinya berubah sejak ditandatangani. Pembedanya dari verifier biasa: ia juga mendeteksi manipulasi struktural yang sering lolos dari ikon "centang hijau" di PDF viewer, seperti incremental update setelah penandatanganan dan `ByteRange` yang tidak mencakup seluruh file.

Produk hadir dalam tiga bentuk dari satu inti yang sama: **library Go**, **CLI**, dan **REST API + web UI**.

## 2. Latar belakang dan masalah

- Dokumen ber-TTE (tanda tangan elektronik tersertifikasi) makin banyak beredar di Indonesia: kontrak, SK, ijazah digital, surat keterangan, dokumen klaim.
- Verifikator resmi gratis sudah ada (BSrE dan Komdigi), tetapi semuanya **manual, satu file sekali unggah**, tanpa API untuk otomatisasi.
- Penerima dokumen sering salah paham: QR code dianggap tanda tangan, atau ikon centang di viewer dianggap bukti tidak ada perubahan.
- Riset keamanan publik (misalnya pdf-insecurity.org) menunjukkan banyak viewer PDF bisa ditipu oleh incremental saving attack, signature wrapping, dan shadow attack.

**Pernyataan masalah:** organisasi yang menerima banyak dokumen ber-TTE tidak punya cara otomatis dan andal untuk memastikan dokumen itu asli, utuh, dan tidak dimanipulasi setelah ditandatangani.

## 3. Tujuan

### Tujuan produk
1. Memberi verdict yang benar dan bisa dijelaskan untuk PDF bertanda tangan (PAdES/CMS).
2. Mendeteksi perubahan setelah penandatanganan, bukan hanya validitas kriptografis.
3. Bisa diotomatisasi lewat API dan CLI.
4. Tidak menyimpan dokumen pengguna.

### Tujuan personal
1. Menjadi project portofolio security engineering yang menonjol untuk lamaran kerja remote.
2. Memvalidasi apakah ada organisasi yang mau membayar verifikasi massal.

### Bukan tujuan (non-goals)
- **Bukan** layanan penandatanganan dokumen. Produk ini tidak menerbitkan sertifikat atau membubuhkan TTE.
- **Bukan** penentu keabsahan hukum. Produk hanya melaporkan hasil pemeriksaan teknis dan kriptografis.
- **Bukan** pendeteksi tanda tangan basah/gambar tanda tangan (computer vision).
- **Bukan** penyimpanan atau manajemen dokumen.
- MVP **tidak** mendukung XAdES, CAdES lepas, atau format selain PDF.

## 4. Pengguna dan persona

| Persona | Konteks | Kebutuhan utama | Antarmuka |
|---|---|---|---|
| **Rina, staf HR** | Menyaring ratusan ijazah dan surat referensi digital per bulan | Tahu cepat mana dokumen yang aman dan mana yang perlu dicek manual | Web UI (nanti: upload massal) |
| **Andi, backend engineer di fintech/koperasi** | Dokumen pendukung pinjaman masuk lewat aplikasi | Memanggil verifikasi otomatis saat dokumen diunggah | REST API |
| **Dewi, auditor/legal** | Sengketa keaslian kontrak | Laporan teknis lengkap yang bisa dilampirkan | Web UI, laporan HTML/JSON |
| **Developer/security engineer** | Ingin menguji atau mengintegrasikan verifikasi | Tool baris perintah dan library yang bisa dipakai di pipeline | CLI, library Go |

## 5. User stories

Prioritas: **P0** = wajib MVP, **P1** = setelah MVP, **P2** = komersial.

| ID | Sebagai… | Saya ingin… | Supaya… | Prioritas |
|---|---|---|---|---|
| US-01 | pengguna web | mengunggah satu PDF dan melihat hasil verifikasi | tahu apakah dokumen bisa dipercaya | P0 |
| US-02 | pengguna web | melihat ringkasan dalam bahasa awam dan detail teknis yang bisa dibuka | paham hasilnya tanpa harus mengerti PKI | P0 |
| US-03 | pengguna mana pun | diberi tahu jika dokumen diubah setelah ditandatangani | tidak tertipu oleh centang hijau | P0 |
| US-04 | pengguna mana pun | melihat setiap tanda tangan pada dokumen multi-signature secara terpisah | tahu siapa menandatangani apa dan kapan | P0 |
| US-05 | developer | menjalankan `inkproof check file.pdf --format json` | memakai hasilnya di script/pipeline | P0 |
| US-06 | developer | memanggil `POST /v1/verify` dan menerima JSON terstruktur | mengotomatisasi verifikasi | P0 |
| US-07 | developer | memakai trust store sendiri | memverifikasi dokumen dari CA internal | P0 |
| US-08 | pengguna mana pun | tahu apakah sertifikat penanda tangan sudah dicabut | tidak menerima dokumen dari sertifikat yang dicabut | P0 |
| US-09 | auditor | mengunduh laporan HTML yang memuat hash dokumen dan ID verifikasi | melampirkannya sebagai bukti pemeriksaan | P0 |
| US-10 | pengguna mana pun | yakin dokumen saya tidak disimpan | aman mengunggah dokumen sensitif | P0 |
| US-11 | auditor | memverifikasi tanda tangan lama dengan data revocation yang tertanam (LTV) | dokumen arsip tetap bisa dinilai | P1 |
| US-12 | pengguna web | diberi peringatan jika ada indikasi shadow attack | mendeteksi manipulasi tingkat lanjut | P1 |
| US-13 | staf HR | mengunggah ZIP berisi banyak PDF dan mendapat ringkasan per file | menyaring dokumen secara massal | P2 |
| US-14 | admin organisasi | mengelola API key dan melihat pemakaian kuota | mengontrol biaya | P2 |
| US-15 | auditor | menerima laporan yang ditandatangani server | laporan tidak bisa dipalsukan | P2 |

## 6. Kebutuhan fungsional (MVP)

### FR-1 Parsing tanda tangan
- FR-1.1 Menemukan semua field tanda tangan (`/FT /Sig`) yang berisi nilai.
- FR-1.2 Membaca `/ByteRange` dan `/Contents` (blob CMS/PKCS#7) untuk setiap tanda tangan.
- FR-1.3 Mendukung `adbe.pkcs7.detached` dan `ETSI.CAdES.detached` sebagai `/SubFilter`. SubFilter lain dilaporkan sebagai tidak didukung, bukan gagal diam-diam.
- FR-1.4 Mendeteksi revisi PDF (jumlah bagian `%%EOF` / xref section) dan memetakan tiap tanda tangan ke revisinya.

### FR-2 Integritas
- FR-2.1 Menghitung digest dari rentang `ByteRange` dengan algoritma yang dinyatakan di CMS.
- FR-2.2 Mencocokkan digest dengan atribut `messageDigest` di CMS.
- FR-2.3 Memverifikasi signature CMS dengan public key sertifikat penanda tangan.
- FR-2.4 Memastikan `ByteRange` dimulai dari offset 0, celahnya tepat menutupi `/Contents`, dan tidak ada tumpang tindih.
- FR-2.5 Untuk tanda tangan **terakhir**, memastikan rentang berakhir di akhir revisinya dan melaporkan byte apa pun setelahnya.

### FR-3 Perubahan setelah penandatanganan
- FR-3.1 Menghitung incremental update setelah setiap tanda tangan.
- FR-3.2 Mengklasifikasikan perubahan: (a) tanda tangan berikutnya / DSS / timestamp dokumen, (b) form field atau anotasi, (c) perubahan konten halaman atau struktur.
- FR-3.3 Membaca izin DocMDP (`/P 1`, `2`, `3`) jika ada, lalu menandai perubahan yang melanggar izin itu.
- FR-3.4 Melaporkan kelas perubahan beserta objek yang berubah, dengan bahasa yang bisa dipahami.

### FR-4 Validasi sertifikat
- FR-4.1 Membangun rantai dari sertifikat penanda tangan ke root CA di trust store, memakai sertifikat yang tertanam di CMS sebagai intermediate.
- FR-4.2 Mengecek masa berlaku pada **waktu tanda tangan terbaik yang diketahui**: timestamp RFC 3161 jika ada dan valid, jika tidak `signingTime` (ditandai tidak terpercaya), jika tidak waktu sekarang.
- FR-4.3 Mengecek key usage (`digitalSignature` atau `nonRepudiation`).
- FR-4.4 Trust store bawaan berisi root CA Indonesia yang terdokumentasi sumbernya; pengguna bisa menambah atau mengganti trust store.

### FR-5 Revocation
- FR-5.1 Mengecek OCSP dari URL AIA; fallback ke CRL dari CRL Distribution Point.
- FR-5.2 Semua request keluar melewati egress guard (lihat threat model).
- FR-5.3 Cache respons sesuai `nextUpdate`.
- FR-5.4 Jika revocation tidak bisa dipastikan, hasil menjadi `INDETERMINATE` dengan alasan, bukan `PASSED`.
- FR-5.5 Mode offline (`--offline`) melewati cek revocation dan menyatakannya di laporan.

### FR-6 Timestamp
- FR-6.1 Membaca signature timestamp token (atribut unsigned `id-aa-signatureTimeStampToken`).
- FR-6.2 Memverifikasi token: imprint cocok dengan signature, rantai TSA valid.

### FR-7 Laporan
- FR-7.1 Status per tanda tangan dan status dokumen keseluruhan: `TOTAL-PASSED`, `TOTAL-FAILED`, `INDETERMINATE` (mengikuti istilah ETSI EN 319 102-1), dengan sub-indikasi.
- FR-7.2 Setiap temuan punya kode stabil (misalnya `MODIFIED_AFTER_SIGNING`), tingkat keparahan, pesan Indonesia, dan pesan Inggris.
- FR-7.3 Output JSON (skema berversi) dan HTML.
- FR-7.4 Laporan memuat SHA-256 dokumen, ID verifikasi, versi verifier, waktu verifikasi, dan versi trust store.

### FR-8 Antarmuka
- FR-8.1 Library Go `pkg/verify` dengan API stabil.
- FR-8.2 CLI `inkproof check <file> [--format json|text|html] [--trust <dir>] [--offline]`, exit code 0/1/2 untuk passed/failed/indeterminate.
- FR-8.3 REST API `POST /v1/verify` (multipart), `GET /healthz`, `GET /v1/trust` (info trust store).
- FR-8.4 Web UI: satu halaman upload, satu halaman hasil.

## 7. Kebutuhan non-fungsional

| ID | Kategori | Kebutuhan |
|---|---|---|
| NFR-1 | Performa | p95 di bawah 2 detik untuk PDF 5 MB tanpa cek revocation; di bawah 5 detik dengan cek revocation (cache dingin) |
| NFR-2 | Batas sumber daya | Maksimal 20 MB per file, 50 tanda tangan per dokumen, timeout 15 detik per verifikasi |
| NFR-3 | Kapasitas | Berjalan stabil di VM 2 vCPU / 4 GB RAM bersama layanan lain |
| NFR-4 | Privasi | Dokumen tidak pernah ditulis ke disk atau log; hanya hash dan hasil yang disimpan |
| NFR-5 | Keamanan | Lolos threat model; fuzzing parser minimal 1 jam tanpa panic sebelum rilis |
| NFR-6 | Keandalan | Panic di satu request tidak menjatuhkan proses; health check untuk restart otomatis |
| NFR-7 | Observability | Log terstruktur JSON, metrik Prometheus (jumlah verifikasi, latensi, status, error) |
| NFR-8 | Kualitas | Cakupan test untuk paket `internal/*` minimal 80%; CI wajib hijau sebelum merge |
| NFR-9 | Reproducibility | Seluruh deploy bisa dibangun ulang dari repo dalam kurang dari 1 jam |
| NFR-10 | Bahasa | Pesan pengguna dalam Bahasa Indonesia dan Inggris |

## 8. UX

### Alur utama (web)
1. Pengguna membuka halaman utama → melihat penjelasan singkat dan area drag-and-drop.
2. Pengguna mengunggah PDF → indikator proses.
3. Halaman hasil menampilkan:
   - **Banner verdict** besar: hijau (lolos), merah (gagal), kuning (tidak dapat dipastikan), dengan satu kalimat penjelasan.
   - **Kartu per tanda tangan:** nama penanda tangan, penerbit sertifikat, waktu tanda tangan (dan sumbernya), status.
   - **Peringatan perubahan** jika ada, dijelaskan dalam bahasa awam.
   - **Detail teknis** yang bisa dibuka: rantai sertifikat, hasil OCSP, ByteRange, revisi.
   - Tombol **unduh laporan** (HTML/JSON).
4. Footer tetap: *"Dokumen Anda tidak disimpan. Hasil ini adalah pemeriksaan teknis, bukan pernyataan keabsahan hukum."*

### Prinsip copy
- Verdict ditulis sebagai fakta yang diperiksa: *"Isi dokumen tidak berubah sejak ditandatangani"*, bukan *"Dokumen sah"*.
- Setiap status kuning menjelaskan **apa yang tidak bisa dipastikan** dan **apa yang bisa dilakukan** (misalnya coba lagi nanti, atau verifikasi di layanan resmi).

## 9. Metrik keberhasilan

| Area | Metrik | Target |
|---|---|---|
| Kebenaran | Kecocokan hasil dengan `tte.komdigi.go.id/verifyPDF` pada sampel PDF ber-TTE asli | 100% untuk status valid/tidak valid |
| Kebenaran | Test corpus lolos | 100% |
| Performa | p95 latensi (NFR-1) | Tercapai |
| Portofolio | Repo lengkap + artikel blog + live demo | Selesai di akhir fase 3 |
| Bisnis | Wawancara calon pengguna | 10 |
| Bisnis | Pilot | 1 organisasi |
| Bisnis | Organisasi bersedia membayar | 1 |

## 10. Rilis dan fase

| Fase | Isi | Gate keluar |
|---|---|---|
| F0 | Persiapan, spike library, VM | Library terpilih, VM siap |
| F1 | Inti verifikasi + CLI | CLI lolos test corpus dasar |
| F2 | Revocation, API, web UI, deploy | Live di VM dengan HTTPS |
| F3 | Deteksi perubahan, fuzzing, dokumentasi | **MVP selesai** (kriteria §11) |
| F4 | Validasi pasar | Ada yang mau membayar? |
| F5 | Fitur komersial | — |

Detail per fase ada di [roadmap.md](roadmap.md).

## 11. Kriteria MVP selesai

- [ ] Semua kebutuhan P0 (§5) dan FR-1 sampai FR-8 terimplementasi.
- [ ] Lolos seluruh test corpus (minimal 20 kasus, lihat [test-plan.md](test-plan.md)).
- [ ] Hasil 5 PDF ber-TTE asli sama dengan verifier Komdigi.
- [ ] Fuzzing parser minimal 1 jam tanpa panic.
- [ ] Live dengan HTTPS dan deploy otomatis.
- [ ] README, threat model, dan ADR lengkap.

## 12. Risiko dan asumsi

**Asumsi**
- `digitorus/pkcs7` cukup untuk parsing CMS. Struktur PDF (xref, revisi, signature dictionary) ditulis sendiri di `internal/pdf`, tanpa menulis kriptografi sendiri (hasil spike tahap 1, ADR-0001).
- Root CA PSrE Indonesia bisa diperoleh dari sumber resmi publik.
- Sampel PDF ber-TTE asli bisa diperoleh secara sah (dokumen milik sendiri atau publik).

**Risiko utama** ada di [planning](https://claude.ai/artifact/3LdQAt1yMyW5PWhmgKunu6) dan [threat-model.md](threat-model.md).

## 13. Pertanyaan terbuka

- [ ] Nama produk final dan domain.
- [ ] Segmen pertama untuk validasi pasar: HR atau koperasi/leasing?
- [ ] Apakah layanan berbayar nanti wajib terdaftar sebagai PSE Lingkup Privat? Perlu dicek sebelum menerima pembayaran.
- [x] Lisensi repo: **Apache-2.0** (diputuskan 2026-10-30). Layanan hosted tetap bisa menjadi produk berbayar; kode tetap terbuka.

## 14. Glosarium

| Istilah | Arti |
|---|---|
| **TTE** | Tanda Tangan Elektronik. Yang tersertifikasi memakai sertifikat dari PSrE. |
| **PSrE** | Penyelenggara Sertifikasi Elektronik, CA yang diakui Komdigi (misalnya BSrE, Privy, VIDA, Peruri). |
| **PAdES** | Standar ETSI untuk tanda tangan di PDF (level B, T, LT, LTA). |
| **CMS / PKCS#7** | Format struktur data tanda tangan yang disimpan di `/Contents`. |
| **ByteRange** | Dua rentang byte file yang ditandatangani, mengapit slot `/Contents`. |
| **Incremental update** | Perubahan PDF yang ditambahkan di akhir file tanpa menulis ulang isi lama. |
| **DocMDP** | Izin perubahan yang ditetapkan penanda tangan pertama (certification signature). |
| **OCSP / CRL** | Mekanisme mengecek apakah sertifikat sudah dicabut. |
| **LTV** | Long-Term Validation, data validasi tertanam agar tanda tangan bisa dinilai bertahun-tahun kemudian. |
| **TSA** | Time-Stamping Authority, penerbit timestamp RFC 3161. |
