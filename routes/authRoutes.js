const express = require("express");
const router = express.Router();
const User = require("../models/User");

// ==============================
// REGISTER
// ==============================
router.post("/register", async (req, res) => {
  try {
    console.log("BODY MASUK:", req.body); // 🔥 DEBUG

    const { name, email, password } = req.body;

    if (!name || !email || !password) {
      return res.json({
        success: false,
        message: "Semua field wajib diisi",
      });
    }

    // cek email sudah ada
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.json({
        success: false,
        message: "Email sudah terdaftar",
      });
    }

    // simpan user
    const user = new User({ name, email, password });
    await user.save();

    res.json({
      success: true,
      message: "Registrasi berhasil",
    });

  } catch (err) {
    console.error(err);
    res.status(500).json({
      success: false,
      message: "Server error",
    });
  }
});

module.exports = router;