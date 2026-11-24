from pathlib import Path
import json,sys,subprocess
w=Path(__file__).parent
x=json.loads((w/'revised_word_save.json').read_text(encoding='utf-8'))
p=subprocess.run([sys.executable,str(w/'library_helpers'/'library_file_transfer.py'),'apply-xattrs',r'C:\suat\ljl-digital\digital-logic-materials\EXP\output\review_20261123\数字逻辑_期末复习提纲_2026版_修订.docx',x['library_file_id']],input=json.dumps(x.get('xattrs',[])),capture_output=True,text=True,encoding='utf-8')
print(json.dumps({'identity_exit':p.returncode,'error':p.stderr}))

