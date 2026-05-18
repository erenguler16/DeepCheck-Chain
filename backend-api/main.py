from fastapi import FastAPI, UploadFile, File
import hashlib

app = FastAPI()

@app.get("/")
def read_root():
    return {"mesaj": "Merhaba TEKNOFEST! DeepCheck-Chain Backend'i Ayakta!"}

@app.post("/upload-media")
async def upload_media(file: UploadFile = File(...)):
    # Gelen dosyanın içeriğini (bayt olarak) okuyoruz
    contents = await file.read()
    
    # Dosyanın SHA-256 Hash (parmak izi) değerini hesaplıyoruz
    sha256_hash = hashlib.sha256(contents).hexdigest()
    
    # Hesaplanan bu değerleri mobil uygulamaya yanıt olarak geri döndürüyoruz
    return {
        "dosya_adi": file.filename,
        "icerik_turu": file.content_type,
        "sha256": sha256_hash,
        "durum": "Hash başarıyla hesaplandı. Blokzinciri kaydına hazır."
    }