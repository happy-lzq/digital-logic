from pathlib import Path
import json,subprocess,sys
w=Path(__file__).parent
for row in json.loads((w/'simplified_replace_results.json').read_text(encoding='utf-8')):
 r=row['receipt'];rs=r.get('results',[r])
 for x in rs:
  ident=x.get('library_file_id')
  if not ident:continue
  p=subprocess.run([sys.executable,str(w/'library_helpers'/'library_file_transfer.py'),'apply-xattrs',row['local_path'],ident],input=json.dumps(x.get('xattrs',[])),text=True,capture_output=True,encoding='utf-8')
  print(json.dumps({'path':row['local_path'],'exit':p.returncode,'error':p.stderr},ensure_ascii=False))

