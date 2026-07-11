import os

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
            fixed_content = content.encode('windows-1252').decode('utf-8')
            if has_bom:
                fixed_content = '\ufeff' + fixed_content

            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(fixed_content)
            print(f"Fixed {file_path}")
        except Exception as e:
            print(f"Error in {file_path} with windows-1252: {e}")
            try:
                fixed_content = content.encode('cp1258').decode('utf-8')
                if has_bom:
                    fixed_content = '\ufeff' + fixed_content
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(fixed_content)
                print(f"Fixed {file_path} with cp1258")
            except Exception as e2:
                print(f"Error in {file_path} with cp1258: {e2}")
    except Exception as e:
        pass

for root, _, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            fix_mojibake(os.path.join(root, file))