from fastapi import FastAPI, Form
from fastapi.responses import JSONResponse
import requests

app = FastAPI()
BASE_URL = "http://localhost:5000"  # LibreTranslate running locally

@app.get("/translate/languages")
def list_languages():
    resp = requests.get(f"{BASE_URL}/languages")
    return resp.json()

@app.post("/translate")
def translate_subtitles(lang: str = Form(...)):
    with open("temp/subtitles_en.srt", "r", encoding="utf-8") as f:
        text = f.read()

    response = requests.post(
        f"{BASE_URL}/translate",
        data={
            "q": text,
            "source": "en",
            "target": lang,
            "format": "text"
        }
    )

    if response.status_code == 200:
        with open(f"temp/subtitles_{lang}.srt", "w", encoding="utf-8") as out:
            out.write(response.text)
        return {"status": "success", "file": f"subtitles_{lang}.srt"}
    else:
        return {"status": "failed", "details": response.text}
