import httpx
import asyncio

k = 'AIzaSyDTHLl7TtD844cbr188SpIXzw7Chvzw7Yc'

async def test():
    async with httpx.AsyncClient() as client:
        # A 1-second empty 16kHz linear16 wav file
        import base64
        import wave
        import io
        
        buf = io.BytesIO()
        with wave.open(buf, 'wb') as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(16000)
            w.writeframes(b'\x00' * 32000)
            
        audio_b64 = base64.b64encode(buf.getvalue()).decode('utf-8')
        
        payload = {
            "config": {
                "languageCode": "ja-JP",
                "encoding": "LINEAR16",
                "sampleRateHertz": 16000
            },
            "audio": {"content": audio_b64}
        }
        
        r = await client.post(
            f'https://speech.googleapis.com/v1/speech:recognize?key={k}', 
            json=payload
        )
        print("Status:", r.status_code)
        print("Response:", r.text[:200])

asyncio.run(test())
