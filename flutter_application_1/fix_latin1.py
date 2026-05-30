import os

def to_bytes(s):
    res = bytearray()
    for char in s:
        try:
            res.append(char.encode('windows-1252')[0])
        except UnicodeEncodeError:
            # Fallback for \x8d, \x8f, \x90, \x9d etc which are undefined in windows-1252
            # but were likely inserted as their raw byte values
            res.append(ord(char))
    return bytes(res)

def fix_mojibake(file_path):
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            
        if 'Ã' not in content and 'Ä' not in content and 'á' not in content and 'Æ' not in content:
            return
            
        has_bom = False
        if content.startswith('\ufeff'):
            content = content[1:]
            has_bom = True
            
        try:
            raw_bytes = to_bytes(content)
            fixed_content = raw_bytes.decode('utf-8')
            
            if has_bom:
                fixed_content = '\ufeff' + fixed_content
                
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(fixed_content)
            print(f"Fixed {file_path}")
        except Exception as e:
            print(f"Error in {file_path}: {e}")
    except Exception as e:
        pass

for root, _, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            fix_mojibake(os.path.join(root, file))
