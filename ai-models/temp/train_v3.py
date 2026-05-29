import torch
import torch.nn as nn
import torch.optim as optim
from torchvision import datasets, transforms, models
from torch.utils.data import DataLoader
import os
from tqdm import tqdm
import copy

def main():
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    print(f"--- EĞİTİM BAŞLIYOR ---")
    print(f"Kullanılan Güçlü Cihaz: {device}")

    # 1. Veri Artırma (Modelin ezberlemesini önlemek için fotoğrafları biraz büküyoruz)
    data_transforms = {
        'train': transforms.Compose([
            transforms.Resize((224, 224)),
            transforms.RandomHorizontalFlip(),
            transforms.RandomRotation(15),
            transforms.ColorJitter(brightness=0.2, contrast=0.2), # Işık değişimlerine karşı direnç
            transforms.ToTensor(),
            transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
        ]),
        'val': transforms.Compose([
            transforms.Resize((224, 224)),
            transforms.ToTensor(),
            transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
        ]),
    }

    data_dir = 'dataset'
    image_datasets = {x: datasets.ImageFolder(os.path.join(data_dir, x), data_transforms[x]) for x in ['train', 'val']}
    dataloaders = {x: DataLoader(image_datasets[x], batch_size=64, shuffle=True, num_workers=2) for x in ['train', 'val']}
    dataset_sizes = {x: len(image_datasets[x]) for x in ['train', 'val']}
    class_names = image_datasets['train'].classes

    # Sınıf Dengesi
    train_dir = os.path.join(data_dir, 'train')
    class_counts = [len(os.listdir(os.path.join(train_dir, c))) for c in class_names]
    weights = [1.0 / count for count in class_counts]
    weights = torch.FloatTensor(weights).to(device)
    criterion = nn.CrossEntropyLoss(weight=weights)

    # Model Hazırlığı (Tüm katmanlar açık)
    model = models.resnet18(weights=models.ResNet18_Weights.DEFAULT)
    model.fc = nn.Linear(model.fc.in_features, 2)
    model = model.to(device)

    optimizer = optim.Adam(model.parameters(), lr=1e-4)
    
    # Her 5 turda bir öğrenme hızını %10'una düşür
    scheduler = optim.lr_scheduler.StepLR(optimizer, step_size=5, gamma=0.1)

    # En iyi modeli takip etmek için değişkenler
    best_model_wts = copy.deepcopy(model.state_dict())
    best_acc = 0.0
    
    num_epochs = 15 # Tur sayısını 15'e çıkardık

    for epoch in range(num_epochs):
        print(f"\nEpoch {epoch+1}/{num_epochs} (Mevcut LR: {scheduler.get_last_lr()[0]:.6f})")
        print("-" * 30)
        
        for phase in ['train', 'val']:
            if phase == 'train':
                model.train()
            else:
                model.eval()
                
            running_loss = 0.0
            running_corrects = 0
            
            for inputs, labels in tqdm(dataloaders[phase], desc=f"{phase.capitalize()}"):
                inputs = inputs.to(device)
                labels = labels.to(device)
                
                optimizer.zero_grad()
                
                with torch.set_grad_enabled(phase == 'train'):
                    outputs = model(inputs)
                    _, preds = torch.max(outputs, 1)
                    loss = criterion(outputs, labels)
                    
                    if phase == 'train':
                        loss.backward()
                        optimizer.step()
                        
                running_loss += loss.item() * inputs.size(0)
                running_corrects += torch.sum(preds == labels.data)
                
            if phase == 'train':
                scheduler.step() # Vites küçültme zamanı geldi mi kontrol et
                
            epoch_loss = running_loss / dataset_sizes[phase]
            epoch_acc = running_corrects.double() / dataset_sizes[phase]
            
            print(f"{phase.capitalize()} Başarımı -> Hata: {epoch_loss:.4f} | Doğruluk: {epoch_acc:.4f}")
            
            # Eğer bu turdaki doğruluk oranı eskisinden iyiyse hafızaya al
            if phase == 'val' and epoch_acc > best_acc:
                best_acc = epoch_acc
                best_model_wts = copy.deepcopy(model.state_dict())

    print(f"\nEğitim Tamamlandı. En Yüksek Val Doğruluğu: %{best_acc*100:.2f}")
    
    # En akıllı anındaki beyni yüklüyoruz ve kaydediyoruz
    model.load_state_dict(best_model_wts)
    torch.save(model.state_dict(), 'deepfake_detector_v3.pth')
    print(" MODEL 'deepfake_detector_v3.pth' OLARAK KAYDEDİLDİ!")

if __name__ == '__main__':
    main()