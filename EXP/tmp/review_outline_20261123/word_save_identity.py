import json,sys,subprocess
from pathlib import Path
w=Path(__file__).parent
x=json.loads((w/'word_save_20261124.json').read_text(encoding='utf-8'))
p=subprocess.run([sys.executable,str(w/'library_helpers'/'library_file_transfer.py'),'apply-xattrs',r'C:\suat\ljl-digital\digital-logic-materials\EXP\output\review_20261123\数字逻辑_期末复习提纲_2026版.docx',x['library_file_id']],input=json.dumps(x.get('xattrs',[])),text=True,capture_output=True,encoding='utf-8')
print(json.dumps({'identity_exit':p.returncode,'error':p.stderr}))

