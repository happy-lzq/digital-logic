from pathlib import Path
from copy import deepcopy
import json, math, re
from docx import Document
from docx.shared import Inches, Pt
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.text.paragraph import Paragraph
from docx.table import Table
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_CELL_VERTICAL_ALIGNMENT
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).parent
OUT=ROOT/'output'
OUT.mkdir(exist_ok=True)
EXAM_NAME='数字逻辑_期末试卷_A卷_2026版.docx'
ANSWER_NAME='数字逻辑_期末试卷_A卷_2026版_参考答案.docx'
def findp(doc,prefix):
    matches=[p for p in doc.paragraphs if p.text.startswith(prefix)]
    if len(matches)!=1: raise ValueError((prefix,len(matches)))
    return matches[0]
def setp(p,text):
    rpr=deepcopy(p.runs[0]._r.rPr) if p.runs and p.runs[0]._r.rPr is not None else None
    for e in list(p._p):
        if e.tag!=qn('w:pPr'): p._p.remove(e)
    r=p.add_run(text)
    if rpr is not None: r._r.insert(0,rpr)
    return p
def celltext(cell,text):
    p=cell.paragraphs[0]
    setp(p,text)
    for extra in cell.paragraphs[1:]: extra._element.getparent().remove(extra._element)
def insertp_before(anchor,text,template=None):
    e=OxmlElement('w:p')
    if template is not None and template._p.pPr is not None:
        e.append(deepcopy(template._p.pPr))
    anchor.addprevious(e)
    p=Paragraph(e,anchor.getparent())
    if template is not None and template.runs:
        r=p.add_run(text)
        if template.runs[0]._r.rPr is not None: r._r.insert(0,deepcopy(template.runs[0]._r.rPr))
    else: p.add_run(text)
    return p

# Reuse the original ten choices and existing page layout.
exam=Document(ROOT/'inputs'/EXAM_NAME)
setp(findp(exam,'5. 在简单处理器'),'5. 在异步时序电路中，若两个或更多状态变量在一次状态转换中需要改变，改变的先后取决于反馈通路的延时，这种现象称为（＿＿＿＿）；采用相邻状态编码仅有（＿＿＿＿）位不同的分配方式，可避免该现象。')
q=findp(exam,'2.（20 分）图 3 是')
setp(q,'2.（20 分）分析图 3 所示同步时序电路。两只 JK 触发器共用上升沿时钟 CLK，初态为 y2y1 = 00；输入为 w，输出为 z。现态按 y2y1 排列，次态按 Y2Y1 排列。各同名信号在电气上相连，输入 w 在有效时钟沿前稳定。')
image_p=Paragraph(q._p.getnext(),exam)
setp(image_p,'')
image_p.alignment=WD_ALIGN_PARAGRAPH.CENTER
image_p.add_run().add_picture(str(ROOT/'latest_page5_img0.png'),width=Inches(6.10))
setp(findp(exam,'图 3  待分析'),'图 3  待分析的双 JK 触发器同步时序电路')
items=[
'(1) 根据电路写出驱动方程 J1、K1、J2、K2 及输出方程 z（5 分）；',
'(2) 利用 JK 触发器的特性方程，求次态方程 Y1、Y2（4 分）；',
'(3) 列出状态转换表，包含全部 4 个现态在 w = 0、1 时的次态，以及各现态的输出 z（4 分）；',
'(4) 画出状态转换图，说明该电路的逻辑功能，并判断属于 Moore 型还是 Mealy 型（5 分）；',
'(5) 若依次输入 w = 1 1 1 1 0 1 1 1，写出每个时钟上升沿之后的 z 值（2 分）。'
]
start=exam.paragraphs.index(q) if False else next(i for i,p in enumerate(exam.paragraphs) if p._p is q._p)
qs=exam.paragraphs[start+3:start+7]
for p,t in zip(qs,items[:4]): setp(p,t)
insertp_before(qs[-1]._p.getnext(),items[4],qs[-1])
exam.save(OUT/EXAM_NAME)

ans=Document(ROOT/'inputs'/ANSWER_NAME)
setp(findp(ans,'1. 本卷覆盖'),'1. 本卷覆盖 ch.2—ch.9 相关内容。异步时序电路在选择题与填空题中考查；第四大题由同步时序电路设计题和分析题组成。每题在【来源与变异】中给出小测题号或讲义页码。')
fill=next(t for t in ans.tables if t.cell(0,0).text=='小题')
celltext(fill.rows[5].cells[1],'竞争；1（一）')
celltext(fill.rows[5].cells[2],'Chapter8.pdf 第 21 页（竞争与状态分配）。变异：由延时引起状态变量改变次序的分析改为概念与编码条件填空。')
anchor=findp(ans,'三、组合逻辑电路')
insertp_before(anchor._p,'第 5 小题说明：竞争源于多个状态变量的改变次序受反馈通路延时影响。相邻转换状态仅一位不同，可避免多位状态变量竞争；本题不要求区分临界竞争与非临界竞争。',findp(ans,'第 4 小题说明'))
# Apply corrections already present in the latest answer.
mt=next(t for t in ans.tables if t.cell(0,0).text=='状态' and len(t.columns)==7)
for row,values in zip(mt.rows[1:],[['00','0','1','0','1','0','0'],['01','0','1','0','0','0','0'],['11','0','1','1','1','0','0'],['10','0','1','1','1','0','1']]):
    for c,v in zip(row.cells,values): celltext(c,v)
p=findp(ans,'第 1—4 位构成')
setp(p,p.text.replace('第 5—7 位','第 4—7 位'))
# Correct the one inconsistent truth-table entry against F = AB + B-bar C.
tt=next(t for t in ans.tables if t.cell(0,0).text=='A B C')
assert tt.cell(4,0).text=='0 1 1'
celltext(tt.cell(4,1),'0')

# Draw the synchronous circuit's complete Moore graph with eight transitions.
W,H=2400,960
im=Image.new('RGB',(W,H),'white')
dr=ImageDraw.Draw(im)
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',58)
small=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',52)
centers=[(260,310),(860,310),(1460,310),(2060,310)]
R=112
def line(points,width=6): dr.line(points,fill='black',width=width,joint='curve')
def arrow(points):
    line(points)
    x,y=points[-1]; px,py=points[-2]
    a=math.atan2(y-py,x-px)
    length=27; wing=0.46
    dr.polygon([(x,y),(x-length*math.cos(a-wing),y-length*math.sin(a-wing)),(x-length*math.cos(a+wing),y-length*math.sin(a+wing))],fill='black')
def txt(x,y,text,f=small): dr.text((x,y),text,font=f,fill='black',anchor='mm')
def bezier(p0,p1,p2,p3):
    pts=[]
    for i in range(121):
        t=i/120; u=1-t
        pts.append((u*u*u*p0[0]+3*u*u*t*p1[0]+3*u*t*t*p2[0]+t*t*t*p3[0],u*u*u*p0[1]+3*u*u*t*p1[1]+3*u*t*t*p2[1]+t*t*t*p3[1]))
    return pts
for (x,y),name in zip(centers,['A / 0','B / 0','C / 0','D / 1']):
    dr.ellipse((x-R,y-R,x+R,y+R),outline='black',width=6)
    txt(x,y,name,font)
arrow([(35,310),(145,310)])
for i in range(3):
    x,y=centers[i]; nx,ny=centers[i+1]
    arrow([(x+R,y),(nx-R,ny)])
    txt((x+nx)/2,y-45,'1')
arrow(bezier((205,212),(45,-30),(475,-30),(314,212))); txt(260,58,'0')
arrow(bezier((2004,212),(1830,-30),(2260,-30),(2117,212)));txt(2060,58,'1')
for j,depth in [(1,575),(2,735),(3,895)]:
    x,y=centers[j]
    targetx=260+[-0,18,48,77][j]
    # Return arcs meet distinct points on state A and avoid the other circles.
    end=(targetx,310+math.sqrt(R*R-(targetx-260)**2))
    points=bezier((x,422),(x,depth),(targetx,depth),end)
    arrow(points); txt((x+targetx)/2,depth-38,'0')
graph=ROOT/'sync_moore_states.png'
im.save(graph)

# Replace the older asynchronous analysis by the latest synchronous analysis.
old=findp(ans,'2.（20 分）基本型异步时序电路分析')
appendix=findp(ans,'附表 1')
title_template=deepcopy(old._p)
body_template=deepcopy(findp(ans,'(1) 割环插延时')._p)
for e in list(ans.element.body):
    if e is old._p: deleting=True
    if e is appendix._p: break
    if 'deleting' in locals() and deleting: ans.element.body.remove(e)
def addp(text='',title=False):
    tmpl=title_template if title else body_template
    e=deepcopy(tmpl); appendix._p.addprevious(e)
    p=Paragraph(e,ans)
    setp(p,text)
    p.paragraph_format.page_break_before=True if title else False
    p.paragraph_format.keep_with_next=True if title else False
    if not title:
        p.paragraph_format.space_before=Pt(1)
        p.paragraph_format.space_after=Pt(2)
    return p
def addtable(data,widths=None):
    # Copy the established answer table's layout and typography.
    src=tt
    t=ans.add_table(rows=len(data),cols=len(data[0]))
    t.style=src.style
    t.alignment=WD_TABLE_ALIGNMENT.CENTER
    for rn,row in enumerate(data):
        for cn,value in enumerate(row):
            c=t.cell(rn,cn); c.vertical_alignment=WD_CELL_VERTICAL_ALIGNMENT.CENTER
            pp=c.paragraphs[0]
            pp.alignment=WD_ALIGN_PARAGRAPH.CENTER
            pp.paragraph_format.space_before=Pt(2);pp.paragraph_format.space_after=Pt(2)
            r=pp.add_run(value);r.font.name='Times New Roman';r.font.size=Pt(9.5)
            r._element.get_or_add_rPr().rFonts.set(qn('w:eastAsia'),'宋体')
            r.bold=rn==0
            tcpr=c._tc.get_or_add_tcPr()
            borders=OxmlElement('w:tcBorders')
            for edge in ['top','left','bottom','right']:
                edge_el=OxmlElement('w:'+edge);edge_el.set(qn('w:val'),'single');edge_el.set(qn('w:sz'),'4');edge_el.set(qn('w:color'),'BFBFBF');borders.append(edge_el)
            tcpr.append(borders)
            if rn==0:
                shd=OxmlElement('w:shd');shd.set(qn('w:fill'),'EEEEEE');tcpr.append(shd)
        trpr=t.rows[rn]._tr.get_or_add_trPr()
        cs=OxmlElement('w:cantSplit');trpr.append(cs)
    appendix._p.addprevious(t._tbl)
    return t

def math_run(text):
    e=OxmlElement('m:r'); pr=OxmlElement('m:rPr');sty=OxmlElement('m:sty');sty.set(qn('m:val'),'p');pr.append(sty);e.append(pr)
    t=OxmlElement('m:t');t.text=text;e.append(t);return e
def sub(base,index,bar=False):
    s=OxmlElement('m:sSub');e=OxmlElement('m:e');e.append(math_run(base));su=OxmlElement('m:sub');su.append(math_run(str(index)));s.append(e);s.append(su)
    if not bar:return s
    acc=OxmlElement('m:bar');props=OxmlElement('m:barPr');pos=OxmlElement('m:pos');pos.set(qn('m:val'),'top');props.append(pos);acc.append(props);b=OxmlElement('m:e');b.append(s);acc.append(b);return acc
def bar(text):
    b=OxmlElement('m:bar');p=OxmlElement('m:barPr');pos=OxmlElement('m:pos');pos.set(qn('m:val'),'top');p.append(pos);b.append(p);e=OxmlElement('m:e');e.append(math_run(text));b.append(e);return b
def eq(parts):
    p=addp('')
    p.alignment=WD_ALIGN_PARAGRAPH.CENTER
    om=OxmlElement('m:oMath')
    for part in parts: om.append(math_run(part) if isinstance(part,str) else part)
    p._p.append(om)
    return p

addp('2.（20 分）双 JK 触发器同步时序电路分析',True)
addp('【来源与变异】Chapter7.pdf 第 68 页（同步时序电路分析步骤）、第 69—71 页（双 JK 触发器电路及驱动方程、状态表）。沿用课件电路的功能连接，仅给定初态，增设状态图、Moore/Mealy 判别与输入序列验证。')
addp('(1) 驱动方程与输出方程（5 分）：')
eq([sub('J',1),' = w， ',sub('K',1),' = ',bar('w'),' + ',sub('y',2,True),'， ',sub('J',2),' = w',sub('y',1),'， ',sub('K',2),' = ',bar('w'),'， z = ',sub('y',1),sub('y',2)])
addp('(2) 代入 JK 触发器特性方程，得到（4 分）：')
eq([sub('Y',1),' = ',sub('J',1),sub('y',1,True),' + ',sub('K',1,True),sub('y',1),' = w',sub('y',1,True),' + w',sub('y',1),sub('y',2)])
eq([sub('Y',2),' = ',sub('J',2),sub('y',2,True),' + ',sub('K',2,True),sub('y',2),' = w',sub('y',1),sub('y',2,True),' + w',sub('y',2)])
addp('(3) 状态转换表（4 分）：A = 00，B = 01，C = 10，D = 11。现态和次态均按高位 y2、低位 y1 排列。')
addtable([['现态 y2y1','w = 0：Y2Y1','w = 1：Y2Y1','输出 z'],['00（A）','00','01','0'],['01（B）','00','10','0'],['10（C）','00','11','0'],['11（D）','00','11','1']])
addp('(4) 状态图与逻辑功能（5 分）：圆内标注“状态名 / 输出 z”，弧上标注输入 w；初态为 A。')
gp=addp('');gp.alignment=WD_ALIGN_PARAGRAPH.CENTER
gp.add_run().add_picture(str(graph),width=Inches(6.0))
addp('状态含义：A 表示连续 1 的个数为 0，B 为 1，C 为 2，D 为至少 3。输入 0 时，从任一状态回到 A；输入 1 时依次 A→B→C→D，D 在继续输入 1 时保持。')
addp('功能：检测连续三个或更多个 1。读入第三个连续 1 的时钟沿后 z 置 1，继续输入 1 时保持；读入 0 的时钟沿后 z 清零。z 只由现态 y1、y2 决定，故属于 Moore 型。')
addp('(5) 输入序列验证（2 分）：w = 1 1 1 1 0 1 1 1；各时钟沿后的状态依次为 01、10、11、11、00、01、10、11；z 依次为 0、0、1、1、0、0、0、1。')
addp('评分标准：驱动及输出方程 5 分（每式 1 分）；次态方程 4 分（每式 2 分，等价式均可）；状态表 4 分（8 个次态各 0.375 分，4 个输出各 0.25 分）；状态图 3 分（8 条转移 2 分、初态与状态输出 1 分），功能 1 分，Moore 判别及理由 1 分；序列验证 2 分（每个输出 0.25 分）。')

mapping=next(t for t in ans.tables if t.cell(0,0).text=='题号' and len(t.columns)==5)
for row in mapping.rows[1:]:
    label=row.cells[0].text.replace(' ','')
    if label=='二5':
        for c,v in zip(row.cells,['二 5','2','—（ch.8）','Chapter8.pdf 第 21 页','竞争定义与单变量状态转换填空']): celltext(c,v)
    if label=='四2':
        for c,v in zip(row.cells,['四 2','20','—（ch.7 分析例题）','Chapter7.pdf 第 68—71 页','同步双 JK 电路分析、类型与序列验证']): celltext(c,v)
dist=next(t for t in ans.tables if t.cell(0,0).text=='项目')
celltext(dist.cell(3,2),'ch.2/3/8')
celltext(dist.cell(3,4),'ch.7')
setp(findp(ans,'说明：新增的 ch.8'),'说明：ch.8（异步时序电路）共 6 分，分布为选择题 2 分、填空题 4 分；第四大题 40 分全部考查同步时序逻辑，分别为设计题 20 分、分析题 20 分。全卷分值为 20 + 10 + 30 + 40 = 100 分。')
# Keep appendix on a fresh page, as in the reference layout.
appendix.paragraph_format.page_break_before=True
ans.save(OUT/ANSWER_NAME)

# Meaningful content checks and exhaustive circuit truth-table checks.
def alltext(d):
    return '\n'.join([p.text for p in d.paragraphs]+[c.text for t in d.tables for row in t.rows for c in row.cells])
for fn in [EXAM_NAME,ANSWER_NAME]:
    d=Document(OUT/fn); txt=alltext(d)
    assert '简单处理器' not in txt and 'ESP' not in txt
    assert '共 18 分' not in txt and '共 12 分' not in txt
    assert '同步时序' in txt
ed=Document(OUT/EXAM_NAME)
parts=[p.text for p in ed.paragraphs]
i1=next(i for i,t in enumerate(parts) if t.startswith('一、'))
i2=next(i for i,t in enumerate(parts) if t.startswith('二、'))
i3=next(i for i,t in enumerate(parts) if t.startswith('三、'))
assert len([x for x in parts[i1:i2] if re.match(r'^\d+\.',x)])==10
assert len([x for x in parts[i2:i3] if re.match(r'^\d+\.',x)])==5
for y2 in [0,1]:
 for y1 in [0,1]:
  for w in [0,1]:
   j1=w;k1=(1-w)|(1-y2);j2=w&y1;k2=1-w
   Y1=(j1&(1-y1))|((1-k1)&y1)
   Y2=(j2&(1-y2))|((1-k2)&y2)
   expected=0 if not w else min(2*y2+y1+1,3)
   assert 2*Y2+Y1==expected
for state,values in zip([0,1,3,2],[['00',0,1,0,1,0,0],['01',0,1,0,0,0,0],['11',0,1,1,1,0,0],['10',0,1,1,1,0,1]]):
 y1=state>>1;y0=state&1
 for x in [0,1]:
  assert (y1|((1-y0)&x))==values[3+x]
print(json.dumps({'output':[str(OUT/EXAM_NAME),str(OUT/ANSWER_NAME)],'checks':'10 choices, 5 fill questions, 100 points, synchronous final question, eight JK transitions and Mealy Y0 table verified'},ensure_ascii=False))

