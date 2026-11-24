from pathlib import Path
from pypdf import PdfReader
from PIL import Image, ImageOps, ImageDraw, ImageFont

root=Path(r'C:\suat\ljl-digital\digital-logic-materials')
out=Path(__file__).parent/'slides'
out.mkdir(exist_ok=True)
font=ImageFont.truetype(r'C:\Windows\Fonts\arial.ttf',20)
for chapter in [6,7,9]:
    directory=out/f'ch{chapter}'
    directory.mkdir(exist_ok=True)
    reader=PdfReader(root/'PPT'/f'Chapter{chapter}.pdf')
    paths=[]
    for pno,page in enumerate(reader.pages,1):
        if pno < 4:
            continue
        candidates=[im.image.copy() for im in page.images if im.image.width > 1200 and im.image.height > 700]
        if not candidates:
            continue
        slide=max(candidates,key=lambda im:im.width*im.height).convert('RGB')
        path=directory/f'page-{pno:02}.jpg'
        slide.save(path,quality=90)
        paths.append((pno,path))
    for offset in range(0,len(paths),18):
        part=paths[offset:offset+18]
        sheet=Image.new('RGB',(2100,6*365),'#e8e8e8')
        draw=ImageDraw.Draw(sheet)
        for j,(pno,path) in enumerate(part):
            x=(j%3)*700;y=(j//3)*365
            im=Image.open(path)
            im.thumbnail((680,325))
            sheet.paste(im,(x+10,y+32))
            draw.text((x+12,y+6),f'Chapter {chapter} PDF page {pno}',font=font,fill='black')
        fp=out/f'ch{chapter}-sheet-{offset//18+1}.jpg'
        sheet.save(fp,quality=90)
        print(fp)
