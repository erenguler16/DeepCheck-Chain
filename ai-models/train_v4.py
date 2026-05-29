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
    print(f"\n--- MODERN DEEPFAKE V4 İNCE AYAR (FINE-TUNING) BAŞLIYOR ---")
    print(f"Kullanılan Cihaz: {device}\n")

    data_transforms = {
        'train': transforms.Compose([
            transforms.Resize((224, 224)),
            transforms.RandomHorizontalFlip(),
            transforms.RandomRotation(10),
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
    dataloaders = {x: DataLoader(image_datasets[x], batch_size=32, shuffle=True) for x in ['train', 'val']}
    dataset_sizes = {x: len(image_datasets[x]) for x in ['train', 'val']}

    criterion = nn.CrossEntropyLoss()

    model = models.resnet18()
    model.fc = nn.Linear(model.fc.in_features, 2)
    
    # ÜZERİNE EKLEME İÇİN
    if os.path.exists('deepfake_detector_v3.pth'):
        model.load_state_dict(torch.load('deepfake_detector_v3.pth', map_location=device, weights_only=True))
        print(" BAŞARI: 'deepfake_detector_v3.pth' hafızası yüklendi. Sıfırdan başlanmıyor, üzerine ekleniyor.")
    else:
        print(" HATA: 'deepfake_detector_v3.pth' ana dizinde bulunamadı!")
        return

    model = model.to(device)
    optimizer = optim.Adam(model.parameters(), lr=1e-5)

    best_model_wts = copy.deepcopy(model.state_dict())
    best_acc = 0.0
    num_epochs = 4 

    for epoch in range(num_epochs):
        print(f"\nEpoch {epoch+1}/{num_epochs}")
        print("-" * 20)
        
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
                
            epoch_loss = running_loss / dataset_sizes[phase]
            epoch_acc = running_corrects.double() / dataset_sizes[phase]
            
            print(f"{phase.capitalize()} -> Hata: {epoch_loss:.4f} | Doğruluk: {epoch_acc:.4f}")
            
            if phase == 'val' and epoch_acc > best_acc:
                best_acc = epoch_acc
                best_model_wts = copy.deepcopy(model.state_dict())

    print(f"\n V4 Eğitimi Bitti. En Yüksek Val Doğruluğu: %{best_acc*100:.2f}")
    
    model.load_state_dict(best_model_wts)
   
    torch.save(model.state_dict(), 'deepfake_detector_v4.pth')
    print("'deepfake_detector_v4.pth' ADIYLA KAYDEDİLDİ!")

if __name__ == '__main__':
    main()