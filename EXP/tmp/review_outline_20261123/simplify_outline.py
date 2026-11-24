from pathlib import Path
import json, html
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import cm
from pypdf import PdfReader

work=Path(__file__).parent
out=work.parent.parent/'output'/'review_20261123'
name='数字逻辑_期末复习提纲_2026版'
modules=[
 ('数制与编码','常用进制转换，补码表示与运算，溢出，格雷码。'),
 ('逻辑代数与CMOS','基本逻辑运算、德摩根定理、逻辑函数化简与冗余项，CMOS门电路及上下拉网络。'),
 ('组合逻辑','真值表与逻辑表达式，卡诺图化简与无关项，组合电路的功能分析与波形。'),
 ('MUX与总线','数据选择器的功能，香农展开与逻辑函数实现，总线结构及器件数量。'),
 ('存储与计数器','锁存器及D、T、JK触发器，触发方式与复位，寄存器与计数器的工作过程。'),
 ('同步状态机','Mealy与Moore型状态机，状态图与状态转换表，状态编码，序列检测与重叠检测。'),
 ('时序电路分析','驱动方程、次态方程与输出方程，状态转换表与状态图，电路功能及逐拍输出。'),
 ('异步时序基础','基本型异步电路及其工作约束，流程表，稳态与非稳态，竞争与状态分配。'),
]
focus='复习重点：卡诺图化简、MUX实现、序列检测器设计、同步时序电路分析。'
reference='复习资料：课程PPT、quiz1～5及相关实验资料。'

pdfmetrics.registerFont(TTFont('ReviewSong',r'C:\Windows\Fonts\simsun.ttc'))
pdfmetrics.registerFont(TTFont('ReviewHei',r'C:\Windows\Fonts\simhei.ttf'))
title=ParagraphStyle('title',fontName='ReviewHei',fontSize=21,leading=29,spaceAfter=8,textColor=colors.black)
sub=ParagraphStyle('sub',fontName='ReviewSong',fontSize=10.5,leading=16,spaceAfter=17,textColor=colors.black)
body=ParagraphStyle('body',fontName='ReviewSong',fontSize=11,leading=18,wordWrap='CJK',textColor=colors.black)
label=ParagraphStyle('label',parent=body,fontName='ReviewHei',fontSize=11)
header=ParagraphStyle('header',parent=label,fontSize=11.5)
note=ParagraphStyle('note',parent=body,spaceAfter=8)

data=[[Paragraph('复习模块',header),Paragraph('核心内容',header)]]
data += [[Paragraph(html.escape(a),label),Paragraph(html.escape(b),body)] for a,b in modules]
table=Table(data,colWidths=[4.0*cm,12.4*cm],hAlign='LEFT')
table.setStyle(TableStyle([
 ('GRID',(0,0),(-1,-1),.4,colors.HexColor('#D9D9D9')),
 ('BACKGROUND',(0,0),(-1,0),colors.HexColor('#DFEAF3')),
 ('ROWBACKGROUNDS',(0,1),(-1,-1),[colors.white,colors.HexColor('#F7F9FB')]),
 ('VALIGN',(0,0),(-1,-1),'MIDDLE'),
 ('LEFTPADDING',(0,0),(-1,-1),9),('RIGHTPADDING',(0,0),(-1,-1),9),
 ('TOPPADDING',(0,0),(-1,-1),10),('BOTTOMPADDING',(0,0),(-1,-1),10),
]))

story=[Paragraph('数字逻辑期末复习提纲',title),Paragraph('2026—2027学年第一学期',sub),table,Spacer(1,17),Paragraph(focus,note),Paragraph(reference,note)]
pdf_path=out/(name+'.pdf')
doc=SimpleDocTemplate(str(pdf_path),pagesize=A4,leftMargin=2.3*cm,rightMargin=2.3*cm,topMargin=2.0*cm,bottomMargin=2.0*cm,title='数字逻辑期末复习提纲',author='')
doc.build(story)

md=['# 数字逻辑期末复习提纲','','2026—2027学年第一学期','','| 复习模块 | 核心内容 |','| --- | --- |']
md.extend(f'| {a} | {b} |' for a,b in modules)
md.extend(['',focus,'',reference,''])
md_path=out/(name+'.md');md_path.write_text('\n'.join(md),encoding='utf-8')
reader=PdfReader(pdf_path)
assert len(reader.pages)==1
text=reader.pages[0].extract_text()
for a,b in modules:assert a in text
assert '判断方法' not in text and '第1步' not in text
print(json.dumps({'pages':len(reader.pages),'pdf':str(pdf_path),'markdown':str(md_path),'modules':len(modules)},ensure_ascii=False))
