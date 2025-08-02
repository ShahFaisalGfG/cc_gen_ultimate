from fastapi import FastAPI, UploadFile, File, Form
from fastapi.responses import JSONResponse
from faster_whisper import WhisperModel
import os
import shutil

app = FastAPI()
model_cache = {}

@app.get("/models/list")
def list_models():
    return ["tiny", "base", "small", "medium", "large-v2"]

@app.post("/models/download")
def download_model(model: str = Form(...)):
    if model not in model_cache:
        WhisperModel(model, download_root="./whisper_models", device="cpu", compute_type="int8")
        model_cache[model] = True
    return {"status": "downloaded", "model": model}

@app.post("/transcribe")
async def transcribe_audio(file: UploadFile = File(...), model: str = Form("base")):
    if model not in model_cache:
        WhisperModel(model, download_root="./whisper_models", device="cpu", compute_type="int8")
        model_cache[model] = True

    file_path = f"temp/{file.filename}"
    os.makedirs("temp", exist_ok=True)
    with open(file_path, "wb") as f:
        shutil.copyfileobj(file.file, f)

    model_instance = WhisperModel(model, download_root="./whisper_models", device="cpu", compute_type="int8")
    segments, info = model_instance.transcribe(file_path, beam_size=5)

    subtitles = []
    for seg in segments:
        subtitles.append({
            "start": seg.start,
            "end": seg.end,
            "text": seg.text.strip()
        })

    os.remove(file_path)
    return JSONResponse(content={"segments": subtitles, "language": info.language})
