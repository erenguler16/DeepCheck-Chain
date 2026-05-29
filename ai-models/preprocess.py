import cv2
import os
import glob
from tqdm import tqdm

INPUT_DIR = "dataset_klasoru"
OUTPUT_DIR = "hazir_veri"


face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')

def process_video(video_path, output_sub_dir, frame_interval=15):
    cap = cv2.VideoCapture(video_path)
    video_name = os.path.splitext(os.path.basename(video_path))[0]
    frame_count = 0
    
    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break
            
        # Bilgisayarı şişirmemek için her 15 karede bir (saniyede ~1-2 kare) yüz arayalım
        if frame_count % frame_interval == 0:
            gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
            faces = face_cascade.detectMultiScale(gray, 1.3, 5)
            
            for i, (x, y, w, h) in enumerate(faces):
                # Yüz bölgesini videodan kırp
                face = frame[y:y+h, x:x+w]
                if face.size > 0:
                    # Yapay zeka modelimizin standart kabul ettiği 224x224 boyutuna getir
                    face_resized = cv2.resize(face, (224, 224))
                    out_name = f"{video_name}_f{frame_count}_i{i}.jpg"
                    cv2.imwrite(os.path.join(output_sub_dir, out_name), face_resized)
                    
        frame_count += 1
    cap.release()


video_files = glob.glob(os.path.join(INPUT_DIR, "**", "*.mp4"), recursive=True)
print(f"Toplam {len(video_files)} adet video tespit edildi. Yüz kırpma işlemi başlıyor...")

for video_path in tqdm(video_files):
    
    if "original_sequences" in video_path:
        label = "Gercek"
    else:
        label = "Sahte"
        
    output_sub_dir = os.path.join(OUTPUT_DIR, label)
    os.makedirs(output_sub_dir, exist_ok=True)
    process_video(video_path, output_sub_dir)

print("\n🎉 2. Adım Başarıyla Tamamlandı! Tüm yüz fotoğrafları 'hazir_veri' klasörüne kaydedildi.")