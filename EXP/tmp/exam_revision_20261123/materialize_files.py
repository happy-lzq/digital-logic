import json, subprocess, sys
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
root=Path(__file__).parent
payload=json.loads((root/'materialize_result.json').read_text(encoding='utf-8'))
def run(t):
    dest=root/'inputs'/t['suggested_path']
    dest.parent.mkdir(parents=True,exist_ok=True)
    p=subprocess.run([sys.executable,str(root/'helpers/library_file_transfer.py'),'materialize',str(dest)],input=json.dumps(t),text=True,capture_output=True,encoding='utf-8')
    return {'name':t['file_name'],'path':str(dest),'code':p.returncode,'stdout':p.stdout,'stderr':p.stderr}
with ThreadPoolExecutor(max_workers=5) as pool:
    results=list(pool.map(run,payload['transfers']))
(root/'materialize_status.json').write_text(json.dumps(results,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(results,ensure_ascii=False))

