import torch
import torch.nn as nn
import torch.optim as optim
from torchvision import datasets, transforms, models
from torch.utils.data import DataLoader
import os
from tqdm import tqdm

def main():
    # 1. Cihaz Kontrolü
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    print(f"--- EĞİTİM BAŞLIYOR ---")
    print(f"Kullanılan Cihaz: {device} ({torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'CPU'})")

    # 2. Veri Artırma ve Ön İşleme
    data_transforms = {
        'train': transforms.Compose([
            transforms.Resize((224, 224)),
            transforms.RandomHorizontalFlip(),
            transforms.RandomRotation(15),
            transforms.ToTensor(),
            transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
        ]),
        'val': transforms.Compose([
            transforms.Resize((224, 224)),
            transforms.ToTensor(),
            transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
        ]),
    }

    # 3. Verileri Yükleme
    data_dir = 'dataset'
    image_datasets = {x: datasets.ImageFolder(os.path.join(data_dir, x), data_transforms[x]) for x in ['train', 'val']}
    

    dataloaders = {x: DataLoader(image_datasets[x], batch_size=64, shuffle=True, num_workers=2) for x in ['train', 'val']}

    dataset_sizes = {x: len(image_datasets[x]) for x in ['train', 'val']}
    class_names = image_datasets['train'].classes
    print(f"Sınıflar: {class_names} -> (Gerçek mi, Sahte mi?)")
    print(f"Eğitim görseli sayısı: {dataset_sizes['train']}, Doğrulama görseli sayısı: {dataset_sizes['val']}\n")

    # 4. Hazır Model Yükleme (ResNet18)
    model = models.resnet18(weights=models.ResNet18_Weights.DEFAULT)
    for param in model.parameters():
        param.requires_grad = False

    num_ftrs = model.fc.in_features
    model.fc = nn.Linear(num_ftrs, 2)
    model = model.to(device)

    # 5. Kayıp Fonksiyonu ve Optimizasyon
    criterion = nn.CrossEntropyLoss()
    optimizer = optim.Adam(model.fc.parameters(), lr=0.001)

    # 6. EĞİTİM DÖNGÜSÜ
    num_epochs = 5

    for epoch in range(num_epochs):
        print(f"Epoch {epoch+1}/{num_epochs}")
        print("-" * 10)
        
        for phase in ['train', 'val']:
            if phase == 'train':
                model.train()
            else:
                model.eval()
                
            running_loss = 0.0
            running_corrects = 0
            
            for inputs, labels in tqdm(dataloaders[phase], desc=f"{phase.capitalize()} Aşaması"):
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
                
            epoch_loss = running_loss / dataset_sizes[phase]
            epoch_acc = running_corrects.double() / dataset_sizes[phase]
            
            print(f"{phase.capitalize()} Hatası (Loss): {epoch_loss:.4f} | Doğruluk (Acc): {epoch_acc:.4f}\n")

    # 7. Modeli Kaydetme
    torch.save(model.state_dict(), 'deepfake_detector.pth')
    print(" MODEL BAŞARIYLA EĞİTİLDİ VE 'deepfake_detector.pth' OLARAK KAYDEDİLDİ!")

if __name__ == '__main__':
    main()