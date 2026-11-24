from pathlib import Path
import json, re, html
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak, Flowable, KeepTogether
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.enums import TA_LEFT, TA_CENTER
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import cm

WORK=Path(__file__).parent
OUT=WORK.parent.parent/'output'/'review_20261123'
NAME='数字逻辑_期末复习提纲_2026版'
pages=json.loads((WORK/'outline_content.json').read_text(encoding='utf-8'))
pdfmetrics.registerFont(TTFont('SimSun',r'C:\Windows\Fonts\simsun.ttc'))
pdfmetrics.registerFont(TTFont('SimHei',r'C:\Windows\Fonts\simhei.ttf'))

body=ParagraphStyle('body',fontName='SimSun',fontSize=10.5,leading=15.5,spaceAfter=5,wordWrap='CJK',splitLongWords=False,textColor=colors.black)
bullet=ParagraphStyle('bullet',parent=body,leftIndent=10,firstLineIndent=-10,spaceAfter=4,leading=15)
h1=ParagraphStyle('h1',fontName='SimHei',fontSize=15,leading=20,spaceAfter=10,keepWithNext=True,textColor=colors.black)
h2=ParagraphStyle('h2',fontName='SimHei',fontSize=11.7,leading=17,spaceBefore=7,spaceAfter=4,keepWithNext=True,textColor=colors.black)
title=ParagraphStyle('title',fontName='SimHei',fontSize=21,leading=28,spaceAfter=6,textColor=colors.black)
subtitle=ParagraphStyle('subtitle',fontName='SimSun',fontSize=10,leading=15,spaceAfter=12,textColor=colors.black)
tablebody=ParagraphStyle('tablebody',fontName='SimSun',fontSize=9.3,leading=13.5,wordWrap='CJK',splitLongWords=False)
tablehead=ParagraphStyle('tablehead',parent=tablebody,fontName='SimHei',fontSize=9.5)

def formatted(text):
    text=html.escape(text.replace('−','-'))
    for a,b in [('2^(n-1)','2<super>n-1</super>'),('2^n','2<super>n</super>'),('2^k','2<super>k</super>')]:text=text.replace(a,b)
    return text

def parse_math(src):
    nodes=[];i=0
    def group_at(pos):
        if src[pos]=='{':
            depth=1;j=pos+1
            while j<len(src) and depth:
                if src[j]=='{':depth+=1
                if src[j]=='}':depth-=1
                j+=1
            return src[pos+1:j-1],j
        return src[pos],pos+1
    while i<len(src):
        if src.startswith('\\bar',i):
            content,j=group_at(i+4);nodes.append(('bar',parse_math(content)));i=j
        elif src[i] in '_^' and nodes:
            content,j=group_at(i+1);nodes.append(('sub' if src[i]=='_' else 'sup',[nodes.pop()],parse_math(content)));i=j
        else:nodes.append(('text',src[i]));i+=1
    return nodes

def glyphfont(ch):
    if ch.isascii():return 'Times-Italic' if ch.isalpha() else 'Times-Roman'
    return 'SimSun'

def math_width(nodes,size):
    width=0
    for n in nodes:
        if n[0]=='text':width+=pdfmetrics.stringWidth(n[1],glyphfont(n[1]),size)
        elif n[0]=='bar':width+=math_width(n[1],size)
        else:width+=math_width(n[1],size)+math_width(n[2],size*.7)
    return width

def draw_math(canvas,nodes,x,y,size):
    for n in nodes:
        if n[0]=='text':
            canvas.setFont(glyphfont(n[1]),size);canvas.drawString(x,y,n[1]);x+=pdfmetrics.stringWidth(n[1],glyphfont(n[1]),size)
        elif n[0]=='bar':
            width=math_width(n[1],size)
            draw_math(canvas,n[1],x,y,size)
            canvas.setLineWidth(.5);canvas.line(x,y+size*.92,x+width,y+size*.92);x+=width
        else:
            width=math_width(n[1],size)
            draw_math(canvas,n[1],x,y,size)
            shift=-size*.27 if n[0]=='sub' else size*.44
            draw_math(canvas,n[2],x+width,y+shift,size*.7)
            x+=width+math_width(n[2],size*.7)
    return x

class MathLine(Flowable):
    def __init__(self,text):
        super().__init__();self.nodes=parse_math(text.replace('−','-'));self.size=11;self.height=23;self.spaceAfter=3
    def wrap(self,availWidth,availHeight):
        self.width=availWidth;self.actual=math_width(self.nodes,self.size)
        if self.actual>availWidth:self.size*=availWidth/self.actual;self.actual=availWidth
        return self.width,self.height
    def draw(self):draw_math(self.canv,self.nodes,(self.width-self.actual)/2,7,self.size)

def make_table(headers,rows,widths):
    data=[[Paragraph(formatted(s),tablehead) for s in headers]]+[[Paragraph(formatted(s),tablebody) for s in row] for row in rows]
    tbl=Table(data,colWidths=[w*cm for w in widths],hAlign='CENTER',repeatRows=1)
    tbl.setStyle(TableStyle([
        ('GRID',(0,0),(-1,-1),.4,colors.HexColor('#D9D9D9')),
        ('BACKGROUND',(0,0),(-1,0),colors.HexColor('#DFEAF3')),
        ('ROWBACKGROUNDS',(0,1),(-1,-1),[colors.white,colors.HexColor('#F7F9FB')]),
        ('VALIGN',(0,0),(-1,-1),'MIDDLE'),
        ('LEFTPADDING',(0,0),(-1,-1),6),('RIGHTPADDING',(0,0),(-1,-1),6),
        ('TOPPADDING',(0,0),(-1,-1),5),('BOTTOMPADDING',(0,0),(-1,-1),5),
    ]))
    return tbl

story=[]
for index,record in enumerate(pages):
    if index:story.append(PageBreak())
    else:
        story.append(Paragraph('数字逻辑期末复习提纲',title))
        story.append(Paragraph('2026—2027学年第一学期　2026年11月23日',subtitle))
    story.append(Paragraph(record['title'],h1))
    for item in record['blocks']:
        if item[0]=='h':story.append(Paragraph(item[1],h2))
        elif item[0]=='p':story.append(Paragraph(formatted(item[1]),body))
        elif item[0]=='b':story.append(Paragraph('• '+formatted(item[1]),bullet))
        elif item[0]=='m':story.append(MathLine(item[1]))
        elif item[0]=='table':story.extend([make_table(item[1],item[2],item[3]),Spacer(1,5)])

def footer(canvas,doc):
    canvas.saveState();canvas.setFont('SimSun',8.5);canvas.setFillColor(colors.HexColor('#555555'))
    canvas.drawRightString(A4[0]-2*cm,.85*cm,f'数字逻辑期末复习提纲  |  {doc.page}')
    canvas.restoreState()

path=OUT/(NAME+'.pdf')
doc=SimpleDocTemplate(str(path),pagesize=A4,rightMargin=2*cm,leftMargin=2*cm,topMargin=1.6*cm,bottomMargin=1.6*cm,title='数字逻辑期末复习提纲',author='')
doc.build(story,onFirstPage=footer,onLaterPages=footer)

# Keep an editable text version with the same content and real source filenames.
md=['# 数字逻辑期末复习提纲','','2026—2027学年第一学期　2026年11月23日','']
for record in pages:
    md.extend(['## '+record['title'],''])
    for item in record['blocks']:
        k=item[0]
        if k=='h':md.extend(['### '+item[1],''])
        elif k=='p':md.extend([item[1],''])
        elif k=='b':md.extend(['- '+item[1],''])
        elif k=='m':
            source=item[1].replace('；',r'\qquad ').replace('JK特性方程：',r'\text{JK特性方程}\quad ')
            md.extend(['$$',source,'$$',''])
        elif k=='table':
            md.append('| '+' | '.join(item[1])+' |')
            md.append('| '+' | '.join(['---']*len(item[1]))+' |')
            md.extend('| '+' | '.join(row)+' |' for row in item[2]);md.append('')
md_path=OUT/(NAME+'.md');md_path.write_text('\n'.join(md),encoding='utf-8')
print(json.dumps({'pdf':str(path),'editable':str(md_path)},ensure_ascii=False))
