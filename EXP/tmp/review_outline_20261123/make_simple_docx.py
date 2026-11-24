from pathlib import Path
import json
from docx import Document
from docx.shared import Cm, Pt, RGBColor
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_CELL_VERTICAL_ALIGNMENT
from docx.oxml import OxmlElement
from docx.oxml.ns import qn

work=Path(__file__).parent
out=work.parent.parent/'output'/'review_20261123'
source=out/'数字逻辑_期末复习提纲_2026版.md'
lines=source.read_text(encoding='utf-8').splitlines()
rows=[]
for line in lines:
    if line.startswith('|'):
        vals=[x.strip() for x in line.strip('|').split('|')]
        if vals[0]!='---':rows.append(vals)
assert len(rows)==9
notes=[x for x in lines if x.startswith('复习重点：') or x.startswith('复习资料：')]
doc=Document();s=doc.sections[0]
s.page_width=Cm(21);s.page_height=Cm(29.7)
s.top_margin=Cm(2);s.bottom_margin=Cm(2);s.left_margin=Cm(2.3);s.right_margin=Cm(2.3)
for name,font,size in [('Normal','宋体',11),('Title','黑体',21),('Subtitle','宋体',10.5)]:
    st=doc.styles[name];st.font.name=font;st.font.size=Pt(size);st.font.color.rgb=RGBColor(0,0,0)
    st.element.get_or_add_rPr().rFonts.set(qn('w:eastAsia'),font)
    for el in list(st.element.xpath('.//w:color')):
        for k in ['themeColor','themeTint','themeShade']:el.attrib.pop(qn('w:'+k),None)
    for el in list(st.element.xpath('.//w:pBdr')):el.getparent().remove(el)
doc.styles['Normal'].paragraph_format.line_spacing=1.15
doc.styles['Normal'].paragraph_format.space_after=Pt(8)
doc.styles['Title'].paragraph_format.space_after=Pt(8)
doc.styles['Subtitle'].paragraph_format.space_after=Pt(17)
doc.add_paragraph('数字逻辑期末复习提纲','Title')
doc.add_paragraph('2026—2027学年第一学期','Subtitle')
t=doc.add_table(rows=0,cols=2);t.alignment=WD_TABLE_ALIGNMENT.LEFT;t.autofit=False
widths=[4,12.4]
for c,w in zip(t.columns,widths):c.width=Cm(w)
props=t._tbl.tblPr
borders=OxmlElement('w:tblBorders')
for side in ['top','left','bottom','right','insideH','insideV']:
    e=OxmlElement('w:'+side);e.set(qn('w:val'),'single');e.set(qn('w:sz'),'4');e.set(qn('w:color'),'D9D9D9');borders.append(e)
props.append(borders)
for idx,vals in enumerate(rows):
    row=t.add_row();cant=OxmlElement('w:cantSplit');row._tr.get_or_add_trPr().append(cant)
    if idx==0:
        repeat=OxmlElement('w:tblHeader');row._tr.get_or_add_trPr().append(repeat)
    for col,(cell,text) in enumerate(zip(row.cells,vals)):
        cell.width=Cm(widths[col]);cell.vertical_alignment=WD_CELL_VERTICAL_ALIGNMENT.CENTER
        cp=cell._tc.get_or_add_tcPr()
        shading=OxmlElement('w:shd');shading.set(qn('w:fill'),'DFEAF3' if idx==0 else ('FFFFFF' if idx%2 else 'F7F9FB'));cp.append(shading)
        mar=OxmlElement('w:tcMar')
        for side,n in [('top',130),('bottom',130),('left',115),('right',115)]:
            x=OxmlElement('w:'+side);x.set(qn('w:w'),str(n));x.set(qn('w:type'),'dxa');mar.append(x)
        cp.append(mar)
        p=cell.paragraphs[0];p.paragraph_format.space_before=Pt(0);p.paragraph_format.space_after=Pt(0);p.paragraph_format.line_spacing=1.15
        r=p.add_run(text);r.font.name='黑体' if idx==0 or col==0 else '宋体';r._element.get_or_add_rPr().rFonts.set(qn('w:eastAsia'),r.font.name);r.font.size=Pt(11);r.font.color.rgb=RGBColor(0,0,0)
after=doc.add_paragraph();after.paragraph_format.space_after=Pt(2);after.paragraph_format.space_before=Pt(0);after.paragraph_format.line_spacing=1;after.add_run().font.size=Pt(2)
for n in notes:doc.add_paragraph(n)
doc.core_properties.title='数字逻辑期末复习提纲'
doc.core_properties.subject='一页简版 八个复习模块'
doc.core_properties.author=''
path=out/'数字逻辑_期末复习提纲_2026版.docx';doc.save(path)
check=Document(path)
assert len(check.tables)==1 and len(check.tables[0].rows)==9
assert [c.text for row in check.tables[0].rows for c in row.cells]==[v for vals in rows for v in vals]
print(json.dumps({'docx':str(path),'bytes':path.stat().st_size,'modules':8,'editable':True},ensure_ascii=False))
