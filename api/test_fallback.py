import pykakasi
from janome.tokenizer import Tokenizer

def _fallback_word_analysis(expected_text: str, recognized_text: str) -> list:
    try:
        t = Tokenizer()
        kks = pykakasi.kakasi()
        words_analysis = []
        rec_clean = recognized_text.replace(' ', '').replace('、', '').replace('。', '')

        tokens = [token.surface for token in t.tokenize(expected_text)]
        for token in tokens:
            if token in '。、！？!?.,・ー…「」『』【】〔〕（）()':
                words_analysis.append({'text': token, 'is_correct': True})
                continue

            if token in rec_clean:
                words_analysis.append({'text': token, 'is_correct': True})

            else:
                token_hira = ''.join([i['hira'] for i in kks.convert(token)])
                if token_hira in rec_clean:
                    words_analysis.append({'text': token, 'is_correct': True})
                else:
                    words_analysis.append({'text': token, 'is_correct': False})

        merged = []
        for item in words_analysis:
            if merged and merged[-1]['is_correct'] == item['is_correct']:
                merged[-1]['text'] += item['text']
            else:
                merged.append(item)
        return merged
    except Exception as e:
        print("[Fallback Word Analysis Error]", e)
        return [{"text": expected_text, "is_correct": False}]

import json
with open('out.json', 'w', encoding='utf-8') as f:
    f.write(json.dumps(_fallback_word_analysis("昨日は雨でした。", "きのうはあめでした"), ensure_ascii=False))