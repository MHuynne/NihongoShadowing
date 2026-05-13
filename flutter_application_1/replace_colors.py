import os
import glob

directory = r"d:\MinhHuyen\Learning\HK2-2025-2026\pj\mhuyncode\application_demo_flutter\flutter_application_1\lib\features\admin\presentation\screens\pages"

replacements = {
    "AppColors.textDark": "AdminPalette.textPrimary",
    "AppColors.slate500": "AdminPalette.textMuted",
    "AppColors.slate600": "AdminPalette.textSecondary",
    "AppColors.slate400": "AdminPalette.textSecondary",
    "AppColors.errorRed": "AdminPalette.errorRed",
}

for filepath in glob.glob(os.path.join(directory, "*.dart")):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    modified = False
    for old, new in replacements.items():
        if old in content:
            content = content.replace(old, new)
            modified = True
            
    if modified:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated {filepath}")
