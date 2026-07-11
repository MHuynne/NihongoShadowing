"""
Debug: Lay danh sach bai NHK Web Easy tu RSS chinh thuc
"""
import httpx
import xml.etree.ElementTree as ET
from bs4 import BeautifulSoup
import re

headers = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
    "Accept-Language": "ja",
}


rss_urls = [
    "https://www3.nhk.or.jp/rss/news/cat0.xml",
    "https://www3.nhk.or.jp/rss/news/cat1.xml",
    "https://www3.nhk.or.jp/rss/news/cat2.xml",
    "https://www3.nhk.or.jp/rss/news/cat3.xml",
]

all_links = []
for rss_url in rss_urls:
    try:
        r = httpx.get(rss_url, headers=headers, follow_redirects=True, timeout=10)
        root = ET.fromstring(r.text)
        items = root.findall(".//item")
        for item in items:
            link = item.findtext("link")
            title = item.findtext("title")
            if link and title:
                all_links.append({"title": title, "link": link})
        print(f"{rss_url} -> {len(items)} items")
    except Exception as e:
        print(f"{rss_url} -> ERROR: {e}")

print(f"\nTong: {len(all_links)} bai")


if all_links:
    art = all_links[0]
    print(f"\nThu bai: {art['title']}")
    print(f"URL: {art['link']}")
    try:
        r2 = httpx.get(art["link"], headers=headers, follow_redirects=True, timeout=10)
        print(f"Status: {r2.status_code}")
        soup = BeautifulSoup(r2.text, "html.parser")


        selectors = [
            "div.content--detail-main",
            "section.content--body",
            "div#js-article-body",
            "div.article-main__body",
            "div.module--detail",
            "main",
        ]
        for sel in selectors:
            el = soup.select_one(sel)
            if el:
                print(f"[Found: {sel}]")

                for rt in el.find_all("rt"): rt.decompose()
                for rp in el.find_all("rp"): rp.decompose()
                text = el.get_text(separator="。", strip=True)
                sentences = [s.strip() + "。" for s in text.split("。") if len(s.strip()) > 5]
                print(f"So cau: {len(sentences)}")
                for i, s in enumerate(sentences[:4]):
                    print(f"  {i+1}. {s[:100]}")
                break
        else:
            print("Khong tim thay content div")

            print("HTML:", r2.text[:600])
    except Exception as e:
        print(f"ERROR: {e}")