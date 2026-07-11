from pydub import AudioSegment
import io
import urllib.request


url = 'https://upload.wikimedia.org/wikipedia/commons/b/b8/Record_opus.ogg'
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
audio_bytes = urllib.request.urlopen(req).read()

audio = AudioSegment.from_file(io.BytesIO(audio_bytes))
print(f"Original sample width: {audio.sample_width}")
audio = audio.set_frame_rate(16000).set_channels(1)
print(f"After resample: {audio.sample_width}")
audio16 = audio.set_sample_width(2)

audio16.export('out_16.wav', format='wav')