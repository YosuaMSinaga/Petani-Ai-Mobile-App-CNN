from flask import Flask, request, jsonify
import torch
import torch.nn as nn
from torchvision import transforms, models
from PIL import Image
import torch.nn.functional as F
import os
import mysql.connector

app = Flask(__name__)

# ================= DATABASE CONNECTION =================
try:
    db = mysql.connector.connect(
        host="localhost",
        user="root",
        password="",
        database="petani_ai"
    )
    cursor = db.cursor(dictionary=True)
    print("✅ Database Connected!")
except Exception as e:
    print("❌ Database Error:", e)


# ================= DEVICE =================
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

LAND_MODEL_PATH = os.path.join(BASE_DIR, "cnn_kondisi_tanah.pth")
PLANT_MODEL_PATH = os.path.join(BASE_DIR, "cnn_penyakit_tanaman.pth")

transform = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor()
])

# ================= MODEL TANAH =================
checkpoint_land = torch.load(LAND_MODEL_PATH, map_location=device)
land_classes = checkpoint_land["class_names"]

land_model = models.resnet50(weights=None)
land_model.fc = nn.Sequential(
    nn.Linear(land_model.fc.in_features, 512),
    nn.ReLU(),
    nn.Dropout(0.5),
    nn.Linear(512, len(land_classes))
)

land_model.load_state_dict(checkpoint_land["model_state_dict"])
land_model = land_model.to(device)
land_model.eval()

print("✅ Model Lahan Loaded!")


# ================= MODEL TANAMAN =================
checkpoint_plant = torch.load(PLANT_MODEL_PATH, map_location=device)
plant_classes = checkpoint_plant["class_names"]

plant_model = models.resnet50(weights=None)
plant_model.fc = nn.Sequential(
    nn.Linear(plant_model.fc.in_features, 512),
    nn.ReLU(),
    nn.Dropout(0.5),
    nn.Linear(512, len(plant_classes))
)

plant_model.load_state_dict(checkpoint_plant["model_state_dict"])
plant_model = plant_model.to(device)
plant_model.eval()

print("✅ Model Penyakit Loaded!")


# ================= PREDICT FUNCTION =================
def run_predict(model, class_names, image):
    image = transform(image).unsqueeze(0).to(device)

    with torch.no_grad():
        outputs = model(image)
        probs = F.softmax(outputs, dim=1)
        confidence, predicted = torch.max(probs, 1)

    label = class_names[predicted.item()]
    conf = float(confidence.item() * 100)

    return label, conf


# ================= HOME =================
@app.route('/')
def home():
    return "Flask API + DB + AI ACTIVE"


# ================= PREDIKSI LAHAN =================
@app.route('/predict_land', methods=['POST'])
def predict_land():
    try:
        if 'image' not in request.files:
            return jsonify({"success": False, "message": "No image uploaded"})

        file = request.files['image']
        image = Image.open(file).convert("RGB")

        label, conf = run_predict(land_model, land_classes, image)

        return jsonify({
            "success": True,
            "prediction": label,
            "confidence": round(conf, 2)
        })

    except Exception as e:
        return jsonify({"success": False, "message": str(e)})


# ================= PREDIKSI TANAMAN =================
@app.route('/predict_plant', methods=['POST'])
def predict_plant():
    try:
        if 'image' not in request.files:
            return jsonify({"success": False, "message": "No image uploaded"})

        file = request.files['image']
        image = Image.open(file).convert("RGB")

        label, conf = run_predict(plant_model, plant_classes, image)

        return jsonify({
            "success": True,
            "prediction": label,
            "confidence": round(conf, 2)
        })

    except Exception as e:
        return jsonify({"success": False, "message": str(e)})


# ================= REGISTER =================
@app.route('/register', methods=['POST'])
def register():
    data = request.json

    try:
        sql = """
        INSERT INTO users (username, email, password, google_id, photo)
        VALUES (%s, %s, %s, %s, %s)
        """

        cursor.execute(sql, (
            data.get("username"),
            data.get("email"),
            data.get("password"),
            data.get("google_id"),
            data.get("photo")
        ))

        db.commit()

        return jsonify({"success": True, "message": "User registered"})

    except Exception as e:
        return jsonify({"success": False, "error": str(e)})


# ================= LOGIN =================
@app.route('/login', methods=['POST'])
def login():
    data = request.json

    try:
        sql = "SELECT * FROM users WHERE email=%s AND password=%s"
        cursor.execute(sql, (data.get("email"), data.get("password")))
        user = cursor.fetchone()

        if user:
            return jsonify({"success": True, "user": user})

        return jsonify({"success": False, "message": "Login gagal"})

    except Exception as e:
        return jsonify({"success": False, "message": str(e)})


# ================= GOOGLE LOGIN & REGISTER (INTEGRATED) =================
@app.route('/google_login', methods=['POST'])
def google_login():
    data = request.json

    try:
        email = data.get("email")
        name = data.get("name")
        google_id = data.get("google_id")
        photo = data.get("photo")

        if not email:
            return jsonify({"success": False, "message": "Email tidak boleh kosong"})

        # 1. CEK APAKAH USER SUDAH ADA
        # Kita cek berdasarkan email karena email bersifat UNIQUE di database kamu
        cursor.execute("SELECT * FROM users WHERE email=%s", (email,))
        user = cursor.fetchone()

        if user:
            # JIKA SUDAH ADA: Langsung kirim data user (Proses Login)
            return jsonify({
                "success": True, 
                "message": "Login berhasil",
                "user": user
            })
        else:
            # JIKA BELUM ADA: Buat akun baru (Proses Registrasi Otomatis)
            # Password diisi NULL karena ini akun Google
            sql_insert = """
                INSERT INTO users (username, email, google_id, photo, password)
                VALUES (%s, %s, %s, %s, NULL)
            """
            cursor.execute(sql_insert, (name, email, google_id, photo))
            db.commit()

            # Ambil data user yang baru saja di-insert untuk dikirim ke Flutter
            cursor.execute("SELECT * FROM users WHERE email=%s", (email,))
            new_user = cursor.fetchone()

            return jsonify({
                "success": True, 
                "message": "Registrasi Google berhasil",
                "user": new_user
            })

    except Exception as e:
        db.rollback()
        print(f"DEBUG ERROR: {str(e)}") # Muncul di terminal Flask kamu
        return jsonify({
            "success": False, 
            "message": "Terjadi kesalahan pada server"
        })

# ================= CHECK EMAIL =================
@app.route('/check_email', methods=['POST'])
def check_email():
    data = request.json

    try:
        cursor.execute("SELECT * FROM users WHERE email=%s", (data.get("email"),))
        user = cursor.fetchone()

        if user:
            return jsonify({"success": True, "message": "Email ditemukan"})

        return jsonify({"success": False, "message": "Email tidak terdaftar"})

    except Exception as e:
        return jsonify({"success": False, "message": str(e)})


# ================= RESET PASSWORD =================
@app.route('/reset_password', methods=['POST'])
def reset_password():
    data = request.json

    try:
        email = data.get("email")
        new_password = data.get("password")

        cursor.execute("SELECT * FROM users WHERE email=%s", (email,))
        user = cursor.fetchone()

        if not user:
            return jsonify({"success": False, "message": "User tidak ditemukan"})

        if user["google_id"]:
            return jsonify({"success": False, "message": "Akun Google tidak pakai password"})

        cursor.execute(
            "UPDATE users SET password=%s WHERE email=%s",
            (new_password, email)
        )

        db.commit()

        return jsonify({"success": True, "message": "Password berhasil diperbarui"})

    except Exception as e:
        return jsonify({"success": False, "message": str(e)})


# ================= UPLOAD PHOTO =================
@app.route('/upload_photo', methods=['POST'])
def upload_photo():
    data = request.json

    try:
        user_id = data.get("id")
        photo_base64 = data.get("photo")

        if not user_id or not photo_base64:
            return jsonify({"success": False, "message": "Data tidak lengkap"})

        cursor.execute(
            "UPDATE users SET photo=%s WHERE id=%s",
            (photo_base64, user_id)
        )

        db.commit()

        return jsonify({"success": True, "message": "Foto berhasil diupdate"})

    except Exception as e:
        db.rollback()
        return jsonify({"success": False, "error": str(e)})


# ================= RUN SERVER =================
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)