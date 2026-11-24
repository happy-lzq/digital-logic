import json, shutil, sys
from pathlib import Path
from docx import Document
from docx.table import Table
from docx.text.paragraph import Paragraph
from pypdf import PdfReader
from PIL import Image
root=Path(__file__).parent
out=root/'inputs'
out.mkdir(exist_ok=True)
for n in ['数字逻辑_期末试卷_A卷_2026版.docx','数字逻辑_期末试卷_A卷_2026版_参考答案.docx']:
    p=Path('C:/Users/lzq/Downloads')/n
    shutil.copy2(p,out/n)
    d=Document(p)
    print('\nDOCUMENT',n)
    for i,b in enumerate(d.element.body):
        if b.tag.endswith('}p'):
            pp=Paragraph(b,d)
            print('P',i,repr(pp.text), 'IMG',len(b.xpath('.//w:drawing')), 'MATH',len(b.xpath('.//m:oMath')))
        elif b.tag.endswith('}tbl'):
            t=Table(b,d)
            print('TABLE',i,[ [c.text for c in row.cells] for row in t.rows])
    (root/(('answer' if '参考' in n else 'exam')+'_body.xml')).write_bytes(d.element.xml.encode('utf-8'))
pdf=Path('C:/Users/lzq/Desktop/数字逻辑_期末试卷_A卷_2026版--.pdf')
shutil.copy2(pdf,out/'latest_exam.pdf')
r=PdfReader(pdf)
print('\nPDF PAGES',len(r.pages))
for pno,page in enumerate(r.pages):
    print('PDF PAGE',pno+1,'IMAGES',[(im.name,len(im.data)) for im in page.images])
    if pno in [2,4]:
        print(page.extract_text())
        for i,im in enumerate(page.images):
            fp=root/f'latest_page{pno+1}_img{i}.png'
            im.image.save(fp)
            print('EXTRACTED',str(fp),im.image.size)

