import torch
import torch.nn as nn
import torch.optim as optim
from torchvision import datasets, transforms, models
from torch.utils.data import DataLoader
import os
from tqdm import tqdm

def main():
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    print(f"Kullanılan Cihaz: {device}")

    # 1. Veri Ön İşleme
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

    data_dir = 'dataset'
    image_datasets = {x: datasets.ImageFolder(os.path.join(data_dir, x), data_transforms[x]) for x in ['train', 'val']}
    dataloaders = {x: DataLoader(image_datasets[x], batch_size=64, shuffle=True, num_workers=2) for x in ['train', 'val']}

    dataset_sizes = {x: len(image_datasets[x]) for x in ['train', 'val']}
    class_names = image_datasets['train'].classes

    # 2. Sınıf Dengesizliğini Çözme (Class Weights)
    # Hangi sınıftan kaç fotoğraf olduğunu sayıp, az olana yüksek ağırlık veriyoruz
    train_dir = os.path.join(data_dir, 'train')
    class_counts = [len(os.listdir(os.path.join(train_dir, c))) for c in class_names]
    print(f"Fotoğraf Dağılımı: {class_names[0]}: {class_counts[0]} | {class_names[1]}: {class_counts[1]}")
    
    weights = [1.0 / count for count in class_counts]
    weights = torch.FloatTensor(weights).to(device)
    # Ağırlıkları Loss (Hata) fonksiyonuna ekliyoruz
    criterion = nn.CrossEntropyLoss(weight=weights)

    # 3. Modelin Bütün Katmanlarını Açma (Fine-Tuning)
    model = models.resnet18(weights=models.ResNet18_Weights.DEFAULT)
    # NOT: param.requires_grad = False satırını SİLDİK! Artık tüm ağ öğreniyor.
    
    num_ftrs = model.fc.in_features
    model.fc = nn.Linear(num_ftrs, 2)
    model = model.to(device)

    # Bütün ağı eğittiğimiz için Öğrenme Hızını (Learning Rate) çok düşük tutuyoruz (0.0001) 
    # ki bildiklerini unutmasın, sadece deepfake piksellerine odaklansın.
    optimizer = optim.Adam(model.parameters(), lr=1e-4)

    # 4. Eğitim Döngüsü
    num_epochs = 5

    for epoch in range(num_epochs):
        print(f"\nEpoch {epoch+1}/{num_epochs}")
        print("-" * 15)
        
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
            
            print(f"{phase.capitalize()} Hatası (Loss): {epoch_loss:.4f} | Doğruluk (Acc): {epoch_acc:.4f}")

    torch.save(model.state_dict(), 'deepfake_detector_v2.pth')
    print("\n MODEL EĞİTİLDİ VE 'deepfake_detector_v2.pth' OLARAK KAYDEDİLDİ!")

if __name__ == '__main__':
    main()