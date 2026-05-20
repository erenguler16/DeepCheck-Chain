package main

import (
	"encoding/json"
	"fmt"
	"log"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// SmartContract, Hyperledger Fabric sözleşme yapısını miras alır
type SmartContract struct {
	contractapi.Contract
}

// MediaAsset, blokzincirine kaydedilecek medyanın veri yapısıdır
type MediaAsset struct {
	ID         string `json:"id"`          // Dosyanın SHA-256 Hash değeri (Benzersiz Anahtar)
	FileName   string `json:"fileName"`    // Dosyanın orijinal adı
	UploaderID string `json:"uploaderId"`  // Yükleyen kullanıcının veya cihazın ID'si
	AIResult   string `json:"aiResult"`    // Yapay zeka analiz sonucu (Deepfake / Gerçek)
	Timestamp  string `json:"timestamp"`   // Kayıt zamanı
}

// UploadMediaHash, yeni bir medya hash değerini ve analiz detaylarını blokzincirine kaydeder
func (s *SmartContract) UploadMediaHash(ctx contractapi.TransactionContextInterface, id string, fileName string, uploaderId string, aiResult string, timestamp string) error {
	
	// Önce bu hash değeri daha önce kaydedilmiş mi kontrol ediyoruz
	exists, err := s.AssetExists(ctx, id)
	if err != nil {
		return err
	}
	if exists {
		return fmt.Errorf("bu dosya hash değeri (%s) blokzincirinde zaten kayıtlı", id)
	}

	// Veri yapımızı dolduruyoruz
	asset := MediaAsset{
		ID:         id,
		FileName:   fileName,
		UploaderID: uploaderId,
		AIResult:   aiResult,
		Timestamp:  timestamp,
	}

	// Go nesnesini blokzincirinin anlayacağı JSON formatına (byte dizisine) çeviriyoruz
	assetBytes, err := json.Marshal(asset)
	if err != nil {
		return err
	}

	// PutState fonksiyonu ile veriyi dünya durumuna (Ledger) kalıcı olarak yazıyoruz
	return ctx.GetStub().PutState(id, assetBytes)
}

// QueryMediaHash, hash değeri verilen bir medyanın blokzinciri kayıtlarını sorgular
func (s *SmartContract) QueryMediaHash(ctx contractapi.TransactionContextInterface, id string) (*MediaAsset, error) {
	
	// Veriyi hash (ID) üzerinden blokzincirinden çekiyoruz
	assetBytes, err := ctx.GetStub().GetState(id)
	if err != nil {
		return nil, fmt.Errorf("blokzincirinden okuma yapılırken hata oluştu: %v", err)
	}
	if assetBytes == nil {
		return nil, fmt.Errorf("bu hash değerine ait bir kayıt bulunamadı: %s", id)
	}

	// Çektiğimiz ham byte verisini tekrar anlamlı Go nesnesine (MediaAsset) dönüştürüyoruz
	var asset MediaAsset
	err = json.Unmarshal(assetBytes, &asset)
	if err != nil {
		return nil, err
	}

	return &asset, nil
}

// AssetExists, verilen ID'nin ağda olup olmadığını kontrol eden yardımcı fonksiyondur
func (s *SmartContract) AssetExists(ctx contractapi.TransactionContextInterface, id string) (bool, error) {
	assetBytes, err := ctx.GetStub().GetState(id)
	if err != nil {
		return false, err
	}
	return assetBytes != nil, nil
}

func main() {
	// Akıllı sözleşmeyi başlatıyoruz
	assetChaincode, err := contractapi.NewChaincode(&SmartContract{})
	if err != nil {
		log.Panicf("Chaincode oluşturulurken hata: %v", err)
	}

	if err := assetChaincode.Start(); err != nil {
		log.Panicf("Chaincode başlatılırken hata: %v", err)
	}
}