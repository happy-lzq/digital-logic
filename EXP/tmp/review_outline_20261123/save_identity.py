import json,sys,subprocess
from pathlib import Path
w=Path(__file__).parent
r=json.loads((w/'direct_save_result.json').read_text(encoding='utf-8'))
paths=[r'C:\suat\ljl-digital\digital-logic-materials\EXP\output\review_20261123\数字逻辑_期末复习提纲_2026版.pdf',r'C:\suat\ljl-digital\digital-logic-materials\EXP\output\review_20261123\数字逻辑_期末复习提纲_2026版.md']
for path,x in zip(paths,r.get('results',[])):
 ident=x.get('library_file_id')
 if not ident:
  print(json.dumps({'path':path,'status':x.get('status'),'keys':list(x)},ensure_ascii=False));continue
 p=subprocess.run([sys.executable,str(w/'library_helpers'/'library_file_transfer.py'),'apply-xattrs',path,ident],input=json.dumps(x.get('xattrs',[])),text=True,capture_output=True,encoding='utf-8')
 print(json.dumps({'path':path,'library_file_id':ident,'identity_exit':p.returncode,'identity_result':p.stdout,'identity_error':p.stderr},ensure_ascii=False))

