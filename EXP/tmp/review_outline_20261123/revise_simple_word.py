from pathlib import Path
from copy import deepcopy
import json
from docx import Document
from docx.table import _Row

work=Path(__file__).parent
out=work.parent.parent/'output'/'review_20261123'
source=out/'数字逻辑_期末复习提纲_2026版.docx'
target=out/'数字逻辑_期末复习提纲_2026版_修订.docx'
doc=Document(source)
table=doc.tables[0]

def set_cell_text(cell,text):
    paragraph=cell.paragraphs[0]
    props=deepcopy(paragraph.runs[0]._r.rPr) if paragraph.runs and paragraph.runs[0]._r.rPr is not None else None
    paragraph.clear()
    run=paragraph.add_run(text)
    if props is not None:run._r.insert(0,props)
    for paragraph in list(cell.paragraphs)[1:]:paragraph._p.getparent().remove(paragraph._p)

# Retain the user's wording and formatting shown in the current screenshot.
for row in table.rows:
    label=row.cells[0].text.strip()
    if label in ['MUX与总线','复杂组合逻辑']:
        set_cell_text(row.cells[0],'复杂组合逻辑')
        set_cell_text(row.cells[1],'数据选择器、译码器、编码器的功能，香农展开与逻辑函数实现，总线结构及器件数量。')
    elif label in ['有序状态机','同步状态机','有限状态机']:
        set_cell_text(row.cells[0],'有限状态机')
    elif label in ['时序电路分析','同步时序电路分析']:
        set_cell_text(row.cells[0],'同步时序电路分析')
        for paragraph in row.cells[1].paragraphs:
            for run in paragraph.runs:run.text=run.text.replace('驱动方程、','').replace('驱动方程，','').replace('驱动方程','')

analysis_row=next(row for row in table.rows if row.cells[0].text.strip()=='同步时序电路分析')
insert=deepcopy(analysis_row._tr)
analysis_row._tr.addprevious(insert)
design_row=_Row(insert,table)
set_cell_text(design_row.cells[0],'同步时序电路设计')
set_cell_text(design_row.cells[1],'功能要求与状态定义，状态图与状态表，状态分配，次态与输出逻辑，逻辑电路实现。')

for paragraph in doc.paragraphs:
    if paragraph.text.startswith('复习重点：'):
        for run in paragraph.runs:
            run.text=run.text.replace('同步时序电路分析','同步时序电路设计与分析')

doc.core_properties.subject='简版复习提纲 九个复习模块'
doc.save(target)
check=Document(target)
rows=[[cell.text for cell in row.cells] for row in check.tables[0].rows]
assert len(rows)==10
assert sum(r[0]=='同步时序电路设计' for r in rows)==1
assert '驱动方程' not in '\n'.join(v for r in rows for v in r)
assert any('(2-4)位' in r[1] for r in rows)
assert any(r[0]=='复杂组合逻辑' and '译码器、编码器' in r[1] for r in rows)
print(json.dumps({'file':str(target),'modules':len(rows)-1,'rows':rows,'bytes':target.stat().st_size},ensure_ascii=False))
