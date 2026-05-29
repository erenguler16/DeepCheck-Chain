import torch
import torch.nn as nn
from torchvision import models, transforms
from PIL import Image
import os

def main():
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

    model = models.resnet18()
    model.fc = nn.Linear(model.fc.in_features, 2)
    model.load_state_dict(torch.load('deepfake_detector_v4.pth', map_location=device, weights_only=True))
    model = model.to(device)
    model.eval()

    transform = transforms.Compose([
        transforms.Resize((224, 224)),
        transforms.ToTensor(),
        transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
    ])

    class_names = ['Gercek', 'Sahte']

    def predict_pure_image(image_path):
        if not os.path.exists(image_path):
            print(f"Hata: {image_path} bulunamadı!")
            return
            
        image = Image.open(image_path).convert('RGB')
        input_tensor = transform(image).unsqueeze(0).to(device)
        
        with torch.no_grad():
            outputs = model(input_tensor)
            probabilities = torch.nn.functional.softmax(outputs, dim=1)[0]
            confidence, predicted = torch.max(probabilities, 0)
            
        print(f"\n🔍 {image_path} SONUCU: %{confidence.item()*100:.2f} {class_names[predicted.item()]}")

  
    predict_pure_image("test_image/1.jpg")
    predict_pure_image("test_image/2.jpeg")
    predict_pure_image("test_image/3.jpg")
    predict_pure_image("test_image/4.jpg")
    predict_pure_image("test_image/5.jpg")
    predict_pure_image("test_image/6.png")
    predict_pure_image("test_image/7.png")
    predict_pure_image("test_image/8.jpg")
    predict_pure_image("test_image/9.jpeg")
    predict_pure_image("test_image/10.jpg")

if __name__ == '__main__':
    main()