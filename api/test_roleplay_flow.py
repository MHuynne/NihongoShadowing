import urllib.request
import urllib.parse
import json
import time

BASE_URL = "http://localhost:8000"

def test_api():
    print("="*50)
    print("🚀 BẮT ĐẦU TEST LUỒNG API ROLEPLAY 🚀")
    print("="*50 + "\n")

    # BƯỚC 1: Lấy danh sách Scenarios
    print("👉 Bước 1: Gọi GET /roleplay/scenarios ...")
    req = urllib.request.Request(f"{BASE_URL}/roleplay/scenarios", method="GET")
    try:
        with urllib.request.urlopen(req) as response:
            scenarios = json.loads(response.read().decode())
            print(f"✅ Đã tìm thấy {len(scenarios)} kịch bản.")
            if not scenarios:
                print("❌ Không có kịch bản nào, hãy kiểm tra lại Database.")
                return
            
            scenario = scenarios[0]
            print(f"   ► Chọn kịch bản ID {scenario['id']}: {scenario['title']}")
    except Exception as e:
        print(f"❌ Lỗi kết nối (Server đã bật chưa?): {e}")
        return

    print("\n" + "-"*50 + "\n")

    # BƯỚC 2: Tạo Session mới
    print("👉 Bước 2: Gọi POST /roleplay/session ... (Chế độ KEIGO)")
    session_data = {
        "scenario_id": scenario['id'],
        "user_id": 1,
        "mode": "keigo" # Ép phải dùng kính ngữ
    }
    req = urllib.request.Request(
        f"{BASE_URL}/roleplay/session",
        data=json.dumps(session_data).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST"
    )
    with urllib.request.urlopen(req) as response:
        session = json.loads(response.read().decode())
        session_id = session["id"]
        print(f"✅ Đã tạo phòng (Session) thành công. Session ID: {session_id}")

    print("\n" + "-"*50 + "\n")

    # BƯỚC 3: Gửi tin nhắn Chat
    user_message = "Chao sep, toi den phong van day." # Cố tình nói trống không
    print(f"👉 Bước 3: Gửi tin nhắn chat...\n   👤 User gửi: \"{user_message}\"")
    print("   ⏳ Đang chờ AI Gemini xử lý (Có thể mất 3-5 giây)...")
    
    chat_data = {
        "session_id": session_id,
        "message": user_message
    }
    req = urllib.request.Request(
        f"{BASE_URL}/roleplay/chat",
        data=json.dumps(chat_data).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST"
    )
    
    start_time = time.time()
    with urllib.request.urlopen(req) as response:
        chat_resp = json.loads(response.read().decode())
        ai_reply = chat_resp.get("ai_reply", "")
        suggestions = chat_resp.get("suggestions", [])
        grammar_correction = chat_resp.get("grammar_correction", None)
        
        print(f"✅ Xử lý xong trong {round(time.time() - start_time, 2)} giây!\n")
        print("🤖 AI PHẢN HỒI:")
        print(f"   ➤ AI Reply: {ai_reply}")
        
        print("\n💡 GỢI Ý CÂU TIẾP THEO:")
        for i, sug in enumerate(suggestions):
            print(f"   {i+1}. {sug}")
            
        print("\n📝 SỬA LỖI NGỮ PHÁP (AI BÓC LỖI):")
        if grammar_correction:
            print(f"   ❌ Lỗi sai: {grammar_correction.get('error')}")
            print(f"   ✅ Sửa lại: {grammar_correction.get('correction')}")
            print(f"   ℹ️ Giải thích: {grammar_correction.get('explanation')}")
        else:
            print("   ✅ Câu của bạn hoàn hảo, không có lỗi nào!")

    print("\n" + "="*50)
    print("🎉 KẾT THÚC BÀI TEST 🎉")

if __name__ == "__main__":
    test_api()
