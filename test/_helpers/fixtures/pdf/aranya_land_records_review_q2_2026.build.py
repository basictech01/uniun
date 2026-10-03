# Builds aranya_land_records_review_q2_2026.pdf (fictional state, no real data).
# Needs: python3 + Pillow + matplotlib, LibreOffice (soffice), poppler (pdfunite),
# fonts DejaVu Serif and Noto Sans Devanagari.  Usage: python3 this.py <workdir>
import random, subprocess, math, os
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageChops
import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt

random.seed(7)
import sys
OUT = sys.argv[1] if len(sys.argv) > 1 else "."
SERIF = "/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf"
SERIFB = "/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf"
DEV = "/usr/share/fonts/truetype/noto/NotoSansDevanagari-Regular.ttf"
DEVB = "/usr/share/fonts/truetype/noto/NotoSansDevanagari-Bold.ttf"

def font(p, s): return ImageFont.truetype(p, s)

def paper(w, h, lines, hindi=False):
    """lines: (text, style) style in title/head/body/right/small"""
    im = Image.new("L", (w, h), 246)
    d = ImageDraw.Draw(im)
    y = 70
    for text, style in lines:
        if text == "":
            y += 28; continue
        has_dev = any('\u0900' <= c <= '\u097f' for c in text)
        base = (DEVB if style in ("title", "head") else DEV) if hindi and has_dev else None
        f = {"title": font(base or SERIFB, 40), "head": font(base or SERIFB, 34),
             "body": font(base or SERIF, 31), "small": font(base or SERIF, 26),
             "right": font(base or SERIFB, 31)}[style]
        if text == "":
            y += 28; continue
        tw = d.textlength(text, font=f)
        x = (w - tw) / 2 if style == "title" else (w - tw - 90 if style == "right" else 90)
        d.text((x, y), text, font=f, fill=25)
        y += int(f.size * 1.55)
    return im

def scanify(im, angle=1.2):
    im = im.rotate(angle, expand=True, fillcolor=250, resample=Image.BICUBIC)
    noise = Image.effect_noise(im.size, 14).point(lambda v: v - 128 + 128)
    im = ImageChops.multiply(im, ImageChops.lighter(noise, Image.new("L", im.size, 200)))
    return im.filter(ImageFilter.GaussianBlur(0.6))

def photoify(im, angle=-3.0):
    bg = Image.new("L", (im.width + 260, im.height + 260), 55)
    pg = im.rotate(angle, expand=True, fillcolor=55, resample=Image.BICUBIC)
    bg.paste(pg, (130, 130))
    grad = Image.linear_gradient("L").resize(bg.size).rotate(90)
    bg = ImageChops.multiply(bg, ImageChops.lighter(grad, Image.new("L", bg.size, 150)))
    return bg.filter(ImageFilter.GaussianBlur(0.9)).convert("L")

# ---- scanned / photo pages ---------------------------------------------
sanction = paper(1240, 1754, [
    ("Government of Aranya", "title"), ("Department of Revenue and Land Records", "small"),
    ("No. RLR/Mod/2026/771        Dated 9 October 2026", "small"), ("", ""),
    ("SANCTION ORDER", "head"), ("", ""),
    ("Subject: Sanction of funds for digitisation of village land", "body"),
    ("records in Nalanda Division, Phase II.", "body"), ("", ""),
    ("1. Sanction is accorded for Rs. 3,84,50,000 (Rupees three", "body"),
    ("crore eighty-four lakh fifty thousand only) for scanning and", "body"),
    ("indexing of 212 village record sets.", "body"), ("", ""),
    ("2. The amount is released in three instalments: 40 per cent on", "body"),
    ("issue of this order, 40 per cent after 50 per cent of villages", "body"),
    ("are completed, and 20 per cent after audit certification.", "body"), ("", ""),
    ("3. The work shall be completed by 31 March 2027. Delay beyond", "body"),
    ("this date attracts a penalty of 0.5 per cent per week.", "body"), ("", ""), ("", ""),
    ("(R. K. Vasudevan)", "right"), ("Deputy Secretary to Government", "right"),
])
scanify(sanction).convert("L").save(f"{OUT}/p3_scan.png", dpi=(150,150))

bilingual = paper(1240, 1754, [
    ("कार्यालय आदेश", "title"), ("Office Order", "small"), ("", ""),
    ("क्रमांक: भू-अभि/2026/318            दिनांक: 12 अक्टूबर 2026", "small"), ("", ""),
    ("विषय: ग्राम अभिलेख निरीक्षण की समय-सारणी", "head"),
    ("Subject: Timetable for village record inspection", "body"), ("", ""),
    ("1. सभी तहसील कार्यालयों में अभिलेख निरीक्षण प्रत्येक बुधवार को", "body"),
    ("    प्रातः 10:00 बजे से अपराह्न 1:00 बजे तक होगा।", "body"),
    ("2. Inspection of records shall be held every Wednesday from", "body"),
    ("    10:00 AM to 1:00 PM at all tahsil offices.", "body"), ("", ""),
    ("3. निरीक्षण शुल्क प्रति खसरा 20 रुपये निर्धारित किया गया है।", "body"),
    ("4. The inspection fee is fixed at Rs. 20 per khasra.", "body"), ("", ""), ("", ""),
    ("(सुनीता वर्मा)", "right"), ("District Collector, Nalanda", "right"),
], hindi=True)
scanify(bilingual, -0.8).convert("L").save(f"{OUT}/p7_scan.png", dpi=(150,150))

photo = paper(1100, 1300, [
    ("Government of Aranya", "title"), ("Nalanda Tahsil Office", "small"), ("", ""),
    ("PUBLIC NOTICE", "head"), ("", ""),
    ("The mutation camp for Rajgir block will be held on", "body"),
    ("18 and 19 November 2026 at the Block Development", "body"),
    ("Office, between 10:30 AM and 4:30 PM.", "body"), ("", ""),
    ("Applicants must bring the sale deed, the previous", "body"),
    ("khatauni and two passport-size photographs. The", "body"),
    ("mutation fee is Rs. 150 per application.", "body"), ("", ""),
    ("(Tahsildar, Nalanda)", "right"),
])
photoify(photo).resize((880,1040)).save(f"{OUT}/photo_notice.jpg", quality=72)

# ---- chart ----------------------------------------------------------------
fig, ax = plt.subplots(figsize=(7.2, 4.2), dpi=120)
vals = {"Rajgir": 78, "Islampur": 64, "Hilsa": 51, "Asthawan": 89, "Noorsarai": 42}
ax.bar(vals.keys(), vals.values(), color="#3b5b8c")
for i, v in enumerate(vals.values()): ax.text(i, v + 1.5, f"{v}%", ha="center", fontsize=11)
ax.set_ylim(0, 100); ax.set_ylabel("Villages digitised (%)")
ax.set_title("Digitisation progress by block, 30 September 2026", fontsize=12)
ax.spines[["top", "right"]].set_visible(False); fig.tight_layout()
fig.savefig(f"{OUT}/chart.png"); plt.close(fig)

# ---- logo + signature (small, must NOT be OCRed) --------------------------------
lg = Image.new("RGB", (240, 240), "white"); dd = ImageDraw.Draw(lg)
dd.ellipse((10,10,230,230), outline="#7a1f1f", width=10); dd.ellipse((60,60,180,180), fill="#7a1f1f")
lg.save(f"{OUT}/logo.png")
sg = Image.new("RGB", (420, 130), "white"); ds = ImageDraw.Draw(sg)
pts = [(10 + i*4, 70 + 35*math.sin(i/6.0) * math.exp(-i/60)) for i in range(100)]
ds.line(pts, fill="#1a237e", width=4); sg.save(f"{OUT}/signature.png")

# ---- typed pages (HTML -> PDF via LibreOffice) ------------------------------
CSS = """<style>body{font-family:'DejaVu Serif';font-size:11pt;line-height:1.45}
h1{font-size:15pt}h2{font-size:12.5pt}table{border-collapse:collapse;width:100%}
td,th{border:1px solid #444;padding:4px 7px;font-size:10.5pt}th{background:#e6e6e6}
.c{text-align:center}.hd{font-size:9.5pt;color:#333}</style>"""
def html(name, body):
    open(f"{OUT}/{name}.html", "w").write(f"<html><head><meta charset='utf-8'>{CSS}</head><body>{body}</body></html>")
    subprocess.run(["soffice","--headless","--convert-to","pdf","--outdir",OUT,f"{OUT}/{name}.html"],check=True,capture_output=True)

HEAD = "<p class='c hd'><b>GOVERNMENT OF ARANYA</b><br>Department of Revenue and Land Records · Nalanda Division</p><hr>"
html("p1", HEAD + """<h1>Quarterly Review Report — Land Records Modernisation, July–September 2026</h1>
<p><b>Report No.</b> RLR/QR/2026-27/02 &nbsp; <b>Prepared by</b> Divisional Monitoring Cell</p>
<h2>1. Summary</h2><p>During the quarter the Division received 4,912 applications for certified copies of land records
against 4,388 in the previous quarter. Average time to issue a certified copy fell from 9 working days to 6.
The Division employs 47 record keepers across 5 blocks, of whom 31 have completed the scanning-software training.</p>
<h2>2. Applications received by block</h2>
<table><tr><th>Block</th><th>Applications</th><th>Pending at quarter end</th></tr>
<tr><td>Rajgir</td><td>1,204</td><td>62</td></tr><tr><td>Islampur</td><td>987</td><td>48</td></tr>
<tr><td>Hilsa</td><td>803</td><td>71</td></tr><tr><td>Asthawan</td><td>1,266</td><td>39</td></tr>
<tr><td>Noorsarai</td><td>652</td><td>84</td></tr><tr><th>Total</th><th>4,912</th><th>304</th></tr></table>
<h2>3. Grievances</h2><p>A total of 173 grievances were registered on the state portal; 158 were disposed within the
prescribed 15 days, giving a disposal rate of 91 per cent. The most frequent complaint concerned delay in mutation entries.</p>""")
html("p2", HEAD + f"""<h1>4. Field notice of the Rajgir mutation camp</h1>
<p>The Tahsildar's public notice for the Rajgir mutation camp, as displayed on the Block Development Office
notice board and photographed by the inspecting officer, is reproduced below for the record.</p>
<p class='c'><img src="photo_notice.jpg" style="width:11.5cm;height:13.6cm"></p>
<p>The Division notes that attendance at the previous camp was low because the notice was displayed only three days in advance.</p>""")
html("p4", f"""<table style="border:none"><tr><td style="border:none;width:2.4cm"><img src="logo.png" style="width:1.8cm;height:1.8cm"></td>
<td style="border:none"><b>Office of the District Collector, Nalanda</b><br>Collectorate Campus, Bihar Sharif</td></tr></table><hr>
<h1>5. Staffing and training</h1>
<p>Training on the scanning software was conducted in three batches. Batch A (14 record keepers) completed on 22 August,
Batch B (17) on 5 September, and Batch C (16) is scheduled for 19 October 2026 at the Divisional Training Institute.
Each participant receives a certificate and a one-time incentive of Rs. 2,500.</p>
<h2>Hindi summary / हिंदी सारांश</h2>
<p style="font-family:'Noto Sans Devanagari'">इस तिमाही में प्रभाग के 47 अभिलेख-पालकों में से 31 ने स्कैनिंग सॉफ़्टवेयर का प्रशिक्षण पूरा किया।
तीसरे बैच का प्रशिक्षण 19 अक्टूबर 2026 को मंडलीय प्रशिक्षण संस्थान में होगा।</p>
<p>Approved by:</p><p><img src="signature.png" style="width:4.2cm;height:1.3cm"><br>District Collector, Nalanda</p>""")
html("p5", HEAD + """<h1>6. Digitisation progress</h1>
<p>The chart below shows the share of villages fully digitised, block by block, as on 30 September 2026.
Asthawan leads; Noorsarai lags because 11 villages still hold records in bound volumes that require repair before scanning.</p>
<p class='c'><img src="chart.png" style="width:15cm;height:8.8cm"></p>
<p>Overall, 136 of the Division's 212 villages (64 per cent) are complete.</p>""")
html("p8", HEAD + """<h1>8. Decisions and contacts</h1>
<table><tr><th>Decision</th><th>Owner</th><th>By</th></tr>
<tr><td>Repair of bound volumes in Noorsarai</td><td>Executive Engineer, Nalanda</td><td>15 December 2026</td></tr>
<tr><td>Extend notice period for camps to 10 days</td><td>Divisional Commissioner</td><td>1 November 2026</td></tr>
<tr><td>Release of second instalment</td><td>Deputy Secretary, Revenue</td><td>After 50 per cent completion</td></tr></table>
<h2>Contact</h2><p>Divisional Monitoring Cell, Room 214, Collectorate Campus, Bihar Sharif. Helpline 1800-233-0421, open 10:00 AM to 5:00 PM on working days.</p>""")

# ---- scans -> PDF pages ---------------------------------------------------
def img_pdf(png, pdf):
    Image.open(png).convert("L").resize((930,1316)).save(pdf, "PDF", resolution=112, quality=55)
img_pdf(f"{OUT}/p3_scan.png", f"{OUT}/p3.pdf")
img_pdf(f"{OUT}/p7_scan.png", f"{OUT}/p7.pdf")
# blank page
Image.new("L",(93,132),255).save(f"{OUT}/p6.pdf","PDF",resolution=11.2)
order = ["p1","p2","p3","p4","p5","p6","p7","p8"]
subprocess.run(["pdfunite",*[f"{OUT}/{p}.pdf" for p in order],f"{OUT}/aranya_land_records_review_q2_2026.pdf"],check=True)
print("done")
