<div align="center">

<img src="images/logo.png" alt="Logo Petani AI" width="160"/>

# Petani AI

## Implementasi Metode Convolutional Neural Network (CNN) dengan Arsitektur ResNet-50 pada Aplikasi Mobile untuk Deteksi Penyakit Tanaman Pertanian dan Analisis Kondisi Lahan

</div>

---

## Tentang Aplikasi

Petani AI merupakan aplikasi mobile yang dikembangkan sebagai implementasi metode **Convolutional Neural Network (CNN)** dengan arsitektur **ResNet-50** untuk mendeteksi penyakit tanaman pertanian berdasarkan citra daun serta menganalisis kondisi lahan. Aplikasi ini bertujuan membantu pengguna memperoleh informasi secara cepat dan akurat sebagai pendukung pengambilan keputusan dalam pengelolaan tanaman.

---

## Dokumentasi Aplikasi

### 1. Halaman Beranda

Halaman utama aplikasi yang menyediakan akses ke fitur **Deteksi Penyakit Tanaman** dan **Analisis Kondisi Lahan**.

<p align="center">
  <img src="images/beranda.png" alt="Halaman Beranda" width="160">
</p>

---

### 2. Deteksi Penyakit Tanaman

Pengguna dapat mengambil gambar melalui kamera atau memilih gambar dari galeri. Citra daun yang dipilih kemudian diproses menggunakan model **Convolutional Neural Network (CNN)** dengan arsitektur **ResNet-50** untuk mengidentifikasi jenis penyakit tanaman. Setelah proses deteksi selesai, aplikasi menampilkan hasil klasifikasi penyakit tanaman beserta nilai **confidence** sebagai tingkat keyakinan model terhadap hasil prediksi. Selain itu, aplikasi memanfaatkan **Gemini AI** untuk memberikan penjelasan mengenai hasil deteksi, meliputi informasi penyakit yang teridentifikasi, karakteristik penyakit, serta rekomendasi penanganan yang dapat dijadikan sebagai referensi oleh pengguna.

<p align="center">
  <img src="images/deteksi.png" alt="Halaman Deteksi Penyakit" width="150">
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <img src="images/hasil.png" alt="Hasil Deteksi Penyakit" width="150">
</p>

---

### 3. Analisis Kondisi Lahan

Pengguna mengisi parameter yang diperlukan untuk melakukan analisis kondisi lahan. Selanjutnya, sistem memproses data yang diberikan untuk menentukan kondisi lahan berdasarkan model yang telah dikembangkan. Setelah proses analisis selesai, aplikasi menampilkan hasil analisis serta memanfaatkan **Gemini AI** untuk memberikan penjelasan mengenai kondisi lahan, interpretasi hasil analisis, dan rekomendasi yang dapat dipertimbangkan dalam pengelolaan lahan pertanian.

<p align="center">
  <img src="images/lahan.png" alt="Analisis Kondisi Lahan" width="150">
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <img src="images/hasil_lahan.png" alt="Hasil Analisis Kondisi Lahan" width="150">
</p>

---

## Hak Cipta

Repository ini dibuat sebagai dokumentasi kode program penelitian tugas akhir.

Seluruh kode program dan dokumentasi yang terdapat pada repository ini merupakan hak cipta penulis dan digunakan untuk keperluan akademik.

© 2026 Yosua Marcelinus Sinaga
