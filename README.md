# Xyvonix Core v3.0

**Xyvonix Core** adalah toolkit WebUI untuk **AxManager (non-root)** yang dibuat dan dikembangkan oleh **RonzX7 Developer** — menyatukan kontrol performance, network, gaming, background-app dan diagnostics dalam satu interface.

## Identitas

```text
Name        : Xyvonix Core
Version     : 3.0
VersionCode : 300
Author      : RonzX7 Developer
Target      : AxManager / Axeron WebUI
Root        : Tidak dibutuhkan sebagai desain target
```

## Fitur utama

### Performance Engine
Tiga mode utama:

- **Performance** — memprioritaskan respons dan workload berat.
- **Balanced** — mode harian dengan tuning yang lebih konservatif.
- **Battery** — mengutamakan pengurangan konsumsi daya.

Runtime memilih governor CPU/GPU yang benar-benar tersedia pada perangkat. Animation scale, Activity Manager hints, memory maintenance, cache trimming dan storage trim juga tersedia.

### Network Lab

- Private DNS **Automatic**
- Private DNS **Off**
- **Google DNS** — `dns.google`
- **Cloudflare** — `one.one.one.one`
- **Quad9** — `dns.quad9.net`
- **AdGuard** — `dns.adguard-dns.com`
- **Custom DNS hostname**
- Network optimization profile
- Wi-Fi low-latency mode bila perintah Android tersedia
- Live latency graph
- Speed test dengan animasi ring dan progress real-time

Speed test menggunakan endpoint download Cloudflare dari WebUI; jumlah data yang digunakan bergantung pada kondisi test.

### Graphics & Tuning

- Render performance hints untuk SurfaceFlinger/HWUI/RenderEngine
- Advanced background-blur capability hint
- High refresh-rate mode berdasarkan refresh tertinggi yang dilaporkan sistem
- Device compatibility panel: model, Android/API, HyperOS, SoC, RAM, battery + temperature, thermal status, kernel, CPU governor, storage free

### Gaming

- Discover package game/aplikasi, tambah/hapus package manual
- **Deteksi foreground app secara live** (tanpa root, berbasis `dumpsys`)
- **Auto Game Mode** — begitu package yang dilacak terdeteksi di foreground, profile otomatis pindah ke Performance; saat game ditutup, profile sebelumnya dikembalikan
- Game yang dilacak otomatis dimasukkan ke Doze/App-Standby whitelist supaya tetap lancar di background
- Boost melalui `AxManager.optimizeApp()` ketika API tersebut tersedia
- ART `speed` / `speed-profile` compilation
- Gaming profile satu-tap berbasis mode Performance

### Background App Manager

- **Close background apps** — force-stop semua app pihak ketiga di background yang bukan app aktif, bukan game yang dilacak, dan tidak ada di keep-alive list
- Keep-alive list supaya app tertentu (chat, musik, dll) tidak pernah disentuh

## Target Redmi 13X + HyperOS 3 + Android 16

Xyvonix Core **ditujukan untuk** penggunaan pada Redmi/Xiaomi/POCO dan Android modern, termasuk konfigurasi **Redmi 13X / HyperOS / Android 16**.

Namun, karena kontrol Android dan vendor dapat berbeda antar-build, Xyvonix Core tidak menganggap satu path kernel atau satu property sebagai universal. Semua fitur hardware-level menggunakan pendekatan runtime-adaptive:

1. Deteksi kemampuan perangkat.
2. Gunakan interface yang memang tersedia.
3. Lewati interface yang tidak tersedia atau ditolak.
4. Simpan state sebelum perubahan yang bisa dipulihkan.
5. Sediakan reset untuk mengembalikan pengaturan yang disimpan.

Karena paket ini tidak dijalankan pada Redmi 13X fisik dalam percakapan ini, klaim kompatibilitas harus dibaca sebagai **target desain dan best-effort**, bukan hasil pengujian hardware langsung.

## Non-root & batas keamanan

Xyvonix Core dirancang untuk berjalan melalui otoritas yang diberikan **AxManager/Axeron**. Paket ini tidak memasukkan:

- thermal bypass / thermal-killer
- SELinux/sepolicy bypass
- KernelSU, Magisk atau APatch installer
- root-only binary opaque
- pemaksaan permission ke node kernel yang dilindungi

Jika Android atau AxManager menolak sebuah operasi, UI akan gagal secara aman daripada mencoba melewati pembatas tersebut. "Close background apps" hanya memakai `am force-stop` standar (setara tombol Force Stop di Pengaturan Android) — bukan task-kill tingkat kernel.

## Perubahan di v3.0

- **Perbaikan bug DNS/game package**: perintah `dns hostname ...`, `game-add ...`, dll sebelumnya membungkus argumen dengan tanda kutip, padahal bridge exec AxManager memisahkan command berdasarkan spasi saja dan tidak memahami tanda kutip. Akibatnya karakter kutip ikut terkirim apa adanya, validasi hostname/package di sisi CLI menolaknya, dan perubahan diam-diam batal — inilah yang membuat pilihan DNS terlihat "balik lagi ke Automatic". Argumen sekarang dikirim tanpa tanda kutip (sudah divalidasi bebas-spasi), dan CLI juga membersihkan tanda kutip nyasar sebagai lapisan pengaman tambahan.
- **Logo & banner diganti** dengan logo X milik RonzX7 Developer, dan hero section digambar ulang supaya logo tidak lagi terpotong (masalah sebelumnya: gambar banner lama di-crop paksa oleh kotak 170px sehingga baris ikon di bagian bawah terpotong).
- **Semua emoji diganti SVG** — seluruh ikon di WebUI sekarang inline SVG buatan sendiri, bukan karakter emoji/dingbat.
- **Fitur baru**: Background App Manager (tutup app background + keep-alive list) dan Game Auto-Detect + Auto Game Mode.
- Bridge exec sekarang punya timeout, supaya tombol tidak "menggantung" tanpa pesan kalau AxManager tidak merespons.

Catatan jujur soal pesan **"Error invoking exec: Method not found"** yang muncul di beberapa tombol: pesan itu berasal dari sisi AxManager sendiri (bukan dari script Xyvonix Core), jadi tidak bisa dipastikan penyebabnya tanpa source AxManager. Semua perintah baru di v3.0 sengaja memakai jalur `bridge.exec(...)` yang **persis sama** dengan perintah lama yang sudah berhasil (profile, memory, trim, dll), supaya tidak menambah kemungkinan gagal baru. Kalau setelah update ini masih ada tombol tertentu yang menampilkan pesan itu, coba catat tombol mana saja persisnya — itu akan mempersempit apakah masalahnya ada di path instalasi plugin atau di versi AxManager yang dipakai.

## Struktur

```text
Xyvonix-Core-v3.0/
├── module.prop
├── customize.sh
├── action.sh
├── service.sh
├── uninstall.sh
├── FEATURES.txt
├── README.md
├── banner.png
├── bin/
│   └── xyvonix_cli.sh
├── system/bin/
│   └── xyvonix
├── config/
│   ├── defaults.conf
│   └── device_profiles.conf
└── webroot/
    ├── index.html
    ├── style.css
    ├── app.js
    ├── icons.js
    ├── banner.png
    └── developer.png
```

## Credits

**Xyvonix Core dibuat oleh RonzX7 Developer.**

---

**Xyvonix Core v3.0 • RonzX7 Developer**
