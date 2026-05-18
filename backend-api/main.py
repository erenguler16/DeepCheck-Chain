from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def read_root():
    return {"mesaj": "Merhaba TEKNOFEST! DeepCheck-Chain Backend'i Ayakta!"}