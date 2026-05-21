import httpx
import asyncio

k = 'AIzaSyDz3MQEz5JvdqascBeaa0wQlUPuSADt1ms'

async def test():
    async with httpx.AsyncClient() as client:
        r = await client.get(f'https://generativelanguage.googleapis.com/v1beta/models?key={k}')
        models = r.json().get('models', [])
        for m in models:
            if 'generateContent' in m.get('supportedGenerationMethods', []):
                print(m['name'])

asyncio.run(test())
