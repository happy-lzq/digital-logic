import json
from pathlib import Path
from pypdf import PdfReader
from docx import Document

root = Path(r'C:\suat\ljl-digital\digital-logic-materials')
work = Path(__file__).parent
work.mkdir(parents=True, exist_ok=True)
paths = list((root / 'PPT').glob('*.pdf')) + list((root / 'quiz').glob('*.pdf'))
paths += [root / 'EXP' / 'exp2_讲义.pdf', root / 'EXP' / 'exp4' / '实验指导书.pdf']
paths += list((root / 'EXP' / 'exp5').glob('*老师版/*.pdf'))
paths += list((root / 'EXP' / 'exp6' / 'exp6_student').glob('*.pdf'))
records = []
for path in paths:
    reader = PdfReader(path)
    pages = [page.extract_text() or '' for page in reader.pages]
    records.append({'path': str(path), 'relative': str(path.relative_to(root)), 'pages': pages})
    print(json.dumps({'file':str(path.relative_to(root)), 'pages':len(pages), 'first_pages':[t[:550] for t in pages[:3]]},ensure_ascii=False))
(work / 'materials_text.json').write_text(json.dumps(records, ensure_ascii=False, indent=2), encoding='utf-8')
for record in records:
    text = '\n\n'.join(f'PAGE {i+1}\n{t}' for i,t in enumerate(record['pages']))
    (work / (Path(record['path']).stem + '.txt')).write_text(text, encoding='utf-8')
