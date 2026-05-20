from fastapi import FastAPI, UploadFile, File
import hashlib
import subprocess
from datetime import datetime
import json

app = FastAPI()

# ----------------- AYARLAR -----------------
# Blokzinciri komutlarını çalıştıracağımız asıl klasör yolu
TEST_NETWORK_DIR = "/home/ereng/deepcheck-fabric/fabric-samples/test-network"

# Ortam değişkenleri (Senin terminale tek tek yazdığın o yetkilendirme listesi)
FABRIC_ENV = """
export PATH=$PWD/../bin:$PATH
export FABRIC_CFG_PATH=$PWD/../config/
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$PWD/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=$PWD/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051
"""

# Hayalet terminal fonksiyonumuz: Komutu alır, test-network klasörüne gider ve görünmez bir bash terminalinde çalıştırır.
def run_ghost_terminal(command):
    full_command = f"cd {TEST_NETWORK_DIR} && {command}"
    result = subprocess.run(full_command, shell=True, capture_output=True, text=True, executable='/bin/bash')
    return result
# -------------------------------------------

@app.get("/")
def read_root():
    return {"mesaj": "Merhaba TEKNOFEST! DeepCheck-Chain Backend'i ve Blokzinciri Köprüsü Tamamen Ayakta!"}

@app.post("/upload-media")
async def upload_media(file: UploadFile = File(...)):
    # 1. Dosyayı oku ve Hash (Parmak İzi) hesapla
    contents = await file.read()
    sha256_hash = hashlib.sha256(contents).hexdigest()

    # 2. Blokzinciri için gerekli verileri hazırla
    dosya_adi = file.filename
    uploader_id = "user_eren123" # Şimdilik sabit, ileride mobil uygulamadan gelecek
    ai_sonucu = "Gercek" # Şimdilik sabit, ileride Yapay Zeka modelimizden gelecek
    zaman_damgasi = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    # 3. Blokzinciri Yazma (Invoke) Komutunu Dinamik Olarak Hazırla
    # Python değişkenlerini komutun içine gömüyoruz (f-string)
    invoke_cmd = f"""
    {FABRIC_ENV}
    peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$PWD/organizations/ordererOrganizations/example.com/tlsca/tlsca.example.com-cert.pem" -C mychannel -n deepcheck --peerAddresses localhost:7051 --tlsRootCertFiles "$PWD/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" --peerAddresses localhost:9051 --tlsRootCertFiles "$PWD/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt" -c '{{"function":"UploadMediaHash","Args":["{sha256_hash}","{dosya_adi}","{uploader_id}","{ai_sonucu}","{zaman_damgasi}"]}}'
    """

    # 4. Hayalet terminalde komutu ateşle!
    result = run_ghost_terminal(invoke_cmd)

     # 5. Sonucu kontrol et ve mobil uygulamaya cevap dön
    if "status:200" in result.stderr or "status:200" in result.stdout:
         return {
            "durum": "BAŞARILI! Dosyanın parmak izi tahrif edilemez şekilde blokzincirine mühürlendi.",
            "hash_kodu": sha256_hash,
            "dosya_adi": dosya_adi,
            "ai_sonucu": ai_sonucu,
            "zaman": zaman_damgasi
        }
    else:
        return {
        "durum": "HATA! Blokzincirine yazılamadı.",
        "detay": result.stderr
    }

@app.get("/verify-media/{file_hash}")
def verify_media(file_hash: str):
    # 1. Blokzinciri Okuma (Query) Komutunu Hazırla
    query_cmd = f"""
    {FABRIC_ENV}
    peer chaincode query -C mychannel -n deepcheck -c '{{"Args":["QueryMediaHash","{file_hash}"]}}'
    """

    # 2. Hayalet terminalde sorguyu çalıştır
    result = run_ghost_terminal(query_cmd)

    # 3. Sonucu analiz et ve JSON olarak döndür
    if "Error" in result.stderr or "error" in result.stderr.lower():
        return {"durum": "BULUNAMADI", "mesaj": "Bu hash koduna ait blokzinciri kaydı yok."}

    try:
        # Fabric'ten gelen JSON metnini gerçek Python verisine çeviriyoruz
        blokzinciri_verisi = json.loads(result.stdout)
        return {
            "durum": "DOĞRULANDI! Dosya orijinal ve blokzincirinde kayıtlı.",
            "veri": blokzinciri_verisi
        }
    except Exception as e:
        return {"durum": "HATA", "detay": str(e), "ham_cikti": result.stdout}

