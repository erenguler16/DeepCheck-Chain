import os
import shutil
import random
from tqdm import tqdm


source_dir = "hazir_veri"
base_dir = "dataset"
split_ratio = 0.8 # %80 Eğitim, %20 Doğrulama

print("Veriler Eğitim (Train) ve Doğrulama (Val) olarak ayrıştırılıyor...\n")

for label in ["Gercek", "Sahte"]:
    label_dir = os.path.join(source_dir, label)
    
    if not os.path.exists(label_dir):
        print(f"Uyarı: {label_dir} klasörü bulunamadı, lütfen 2. adımı kontrol edin.")
        continue
        
    images = os.listdir(label_dir)
    # Fotoğrafları rastgele karıştıralım ki yapay zeka sırayı ezberlemesin
    random.shuffle(images)
    
    split_idx = int(len(images) * split_ratio)
    train_images = images[:split_idx]
    val_images = images[split_idx:]
    
    print(f"\n--- {label} Fotoğrafları Taşınıyor ---")
    
 
    for folder, img_list in [("train", train_images), ("val", val_images)]:
        target_folder = os.path.join(base_dir, folder, label)
        os.makedirs(target_folder, exist_ok=True)
        
        print(f"{len(img_list)} adet {label} fotoğrafı '{folder}' klasörüne kopyalanıyor:")
        for img in tqdm(img_list):
            src_path = os.path.join(label_dir, img)
            dst_path = os.path.join(target_folder, img)
            shutil.copy(src_path, dst_path)

print("\nVeriler eğitime hazır hale getirildi.")