import os
import sys
from janome.tokenizer import Tokenizer
import pykakasi

kakasi = pykakasi.kakasi()

tokenizer = Tokenizer()
text = "首相は日本の経済について話しました。"
tokens = tokenizer.tokenize(text)

extracted_vocabs = []
for token in tokens:
    pos = token.part_of_speech.split(',')[0]
    if pos in ['名詞', '動詞', '形容詞']: # Noun, Verb, Adjective
        word = token.surface
        reading = token.reading
        if reading == '*':
            reading = word
        # Convert reading (kana) to romaji or hiragana using kakasi
        conv = kakasi.convert(word)
        romaji = "".join([c['hepburn'] for c in conv])
        hiragana = "".join([c['hira'] for c in conv])
        extracted_vocabs.append({"word": word, "reading": hiragana, "romaji": romaji})

print(extracted_vocabs)
