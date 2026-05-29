import torch
import torch.nn as nn
from torchvision import models, transforms
from PIL import Image
import os
import cv2  # Yüz algılamak için OpenCV'yi dahil ettik

def main():
    print("Yapay zeka modeli yükleniyor, lütfen bekleyin...")
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

    model = models.resnet18()
    num_ftrs = model.fc.in_features
    model.fc = nn.Linear(num_ftrs, 2)
    
    model_path = 'deepfake_detector.pth'
    
    # UYARIYI ÇÖZDÜK: weights_only=True parametresini ekledik
    model.load_state_dict(torch.load(model_path, map_location=device, weights_only=True))
    model = model.to(device)
    model.eval()

    transform = transforms.Compose([
        transforms.Resize((224, 224)),
        transforms.ToTensor(),
        transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
    ])

    class_names = ['Gercek', 'Sahte']
    
    # OpenCV Yüz Algılayıcısı
    face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')

    def predict_image(image_path):
        if not os.path.exists(image_path):
            print(f"\nHata: '{image_path}' bulunamadı!")
            return

        # 1. Fotoğrafı oku ve yüzü bul
        img = cv2.imread(image_path)
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        faces = face_cascade.detectMultiScale(gray, 1.1, 4)

        # 2. Eğer yüz bulunursa sadece yüzü kırp, bulunamazsa orijinali kullan
        if len(faces) == 0:
            print("\n⚠️ Uyarı: Fotoğrafta net bir yüz bulunamadı! Model tüm arka planı analiz edecek.")
            image_pil = Image.open(image_path).convert('RGB')
        else:
            x, y, w, h = faces[0]
            face_img = img[y:y+h, x:x+w]
            # OpenCV'nin renk formatını (BGR), yapay zekanın formatına (RGB) çeviriyoruz
            face_rgb = cv2.cvtColor(face_img, cv2.COLOR_BGR2RGB)
            image_pil = Image.fromarray(face_rgb)
            print("\n✅ Başarılı: Yüz tespit edildi, arka plan atıldı. Sadece yüz analiz ediliyor...")

        input_tensor = transform(image_pil).unsqueeze(0).to(device)
        
        with torch.no_grad():
            outputs = model(input_tensor)
            probabilities = torch.nn.functional.softmax(outputs, dim=1)[0]
            confidence, predicted = torch.max(probabilities, 0)
            
        label = class_names[predicted.item()]
        score = confidence.item() * 100
        
        print(f"\n" + "="*30)
        print(f"🔍 ANALİZ SONUCU")
        print(f"="*30)
        print(f"İncelenen Görsel : {image_path}")
        print(f"Yapay Zeka Kararı: %{score:.2f} ihtimalle {label}")
        print(f"="*30 + "\n")

    predict_image("test_sahte.jpg")

if __name__ == '__main__':
    main()