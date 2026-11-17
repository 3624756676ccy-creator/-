"""生成 App 图标 (1024x1024, RGB, 无 alpha)。超采样绘制后降采样，边缘更干净。"""
import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

S = 2048  # 超采样画布
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                   "PomodoroFocus", "Assets.xcassets", "AppIcon.appiconset", "AppIcon.png")

CORAL = (0xFF, 0x5E, 0x6C)
PEACH = (0xFF, 0xB1, 0x99)
TOP = (0x18, 0x10, 0x1E)
BOTTOM = (0x3C, 0x15, 0x26)


def vertical_gradient(size, top, bottom, horizontal_bias=0.0):
    y = np.linspace(0.0, 1.0, size)[:, None]
    x = np.linspace(0.0, 1.0, size)[None, :]
    t = np.clip(y * (1 - horizontal_bias) + x * horizontal_bias, 0, 1)
    t = t[..., None]
    img = (1 - t) * np.array(top, dtype=float) + t * np.array(bottom, dtype=float)
    return img


# ---------- 背景 ----------
base = vertical_gradient(S, TOP, BOTTOM, horizontal_bias=0.25)

yy, xx = np.mgrid[0:S, 0:S].astype(float)
cx, cy = S * 0.5, S * 0.47
dist = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2) / (S * 0.66)
glow = np.clip(1.0 - dist, 0, 1) ** 2.2
base = base + glow[..., None] * np.array([86.0, 24.0, 46.0])

# 顶部微光
vdist = np.clip(1.0 - (yy / (S * 0.9)), 0, 1) ** 2
base = base + vdist[..., None] * np.array([10.0, 8.0, 16.0])

img = Image.fromarray(np.clip(base, 0, 255).astype(np.uint8), "RGB").convert("RGBA")

# ---------- 进度环 ----------
RING_R = S * 0.395
RING_W = int(S * 0.032)
START_DEG, SWEEP = -90.0, 292.0

mask = Image.new("L", (S, S), 0)
md = ImageDraw.Draw(mask)
box = [cx - RING_R, cy - RING_R, cx + RING_R, cy + RING_R]
md.arc(box, START_DEG, START_DEG + SWEEP, fill=255, width=RING_W)
for ang in (START_DEG, START_DEG + SWEEP):
    a = math.radians(ang)
    ex, ey = cx + RING_R * math.cos(a), cy + RING_R * math.sin(a)
    md.ellipse([ex - RING_W / 2, ey - RING_W / 2, ex + RING_W / 2, ey + RING_W / 2], fill=255)

# 环的渐变漆
ring_grad = vertical_gradient(S, CORAL, PEACH, horizontal_bias=0.55)
ring_rgb = Image.fromarray(np.clip(ring_grad, 0, 255).astype(np.uint8), "RGB")

# 外发光
halo = mask.filter(ImageFilter.GaussianBlur(S * 0.022))
halo_rgb = Image.new("RGB", (S, S), (0xFF, 0x6A, 0x72))
img.paste(halo_rgb, (0, 0), halo.point(lambda v: int(v * 0.55)))
img.paste(ring_rgb, (0, 0), mask)

# 环上的高光点（进度头）
head = Image.new("L", (S, S), 0)
hd = ImageDraw.Draw(head)
a = math.radians(START_DEG + SWEEP)
hx, hy = cx + RING_R * math.cos(a), cy + RING_R * math.sin(a)
hr = RING_W * 0.62
hd.ellipse([hx - hr, hy - hr, hx + hr, hy + hr], fill=255)
head = head.filter(ImageFilter.GaussianBlur(S * 0.004))
img.paste(Image.new("RGB", (S, S), (0xFF, 0xF1, 0xEA)), (0, 0), head)

# ---------- 番茄投影 ----------
TOM_W, TOM_H = S * 0.440, S * 0.385
tcx, tcy = cx, cy + S * 0.030
tb = [tcx - TOM_W / 2, tcy - TOM_H / 2, tcx + TOM_W / 2, tcy + TOM_H / 2]

shadow = Image.new("L", (S, S), 0)
sd = ImageDraw.Draw(shadow)
sd.ellipse([tb[0] + S * 0.02, tb[3] - TOM_H * 0.28, tb[2] - S * 0.02, tb[3] + TOM_H * 0.12], fill=140)
shadow = shadow.filter(ImageFilter.GaussianBlur(S * 0.028))
img.paste(Image.new("RGB", (S, S), (0x08, 0x02, 0x06)), (0, 0), shadow)

# ---------- 番茄本体 ----------
body = Image.new("L", (S, S), 0)
bd = ImageDraw.Draw(body)
bd.ellipse(tb, fill=255)

tgrad = vertical_gradient(S, (0xFF, 0x8A, 0x76), (0xD8, 0x2C, 0x48), horizontal_bias=0.15)
# 左右轻微球面暗化
sph = 1.0 - 0.30 * np.clip((np.abs(xx - tcx) / (TOM_W * 0.62)) ** 2.4, 0, 1)
tgrad = tgrad * sph[..., None]
body_rgb = Image.fromarray(np.clip(tgrad, 0, 255).astype(np.uint8), "RGB")
img.paste(body_rgb, (0, 0), body)

# 高光
spec = Image.new("L", (S, S), 0)
pd = ImageDraw.Draw(spec)
pd.ellipse([tb[0] + TOM_W * 0.13, tb[1] + TOM_H * 0.10,
            tb[0] + TOM_W * 0.47, tb[1] + TOM_H * 0.38], fill=118)
spec = spec.filter(ImageFilter.GaussianBlur(S * 0.020))
# 限制在番茄内
spec = Image.composite(spec, Image.new("L", (S, S), 0), body)
img.paste(Image.new("RGB", (S, S), (0xFF, 0xFF, 0xFF)), (0, 0), spec)

# 底部反光
rim = Image.new("L", (S, S), 0)
rd = ImageDraw.Draw(rim)
rd.arc([tb[0] + TOM_W * 0.16, tb[1] + TOM_H * 0.52,
        tb[2] - TOM_W * 0.16, tb[3] - TOM_H * 0.06], 30, 150, fill=95, width=int(S * 0.012))
rim = rim.filter(ImageFilter.GaussianBlur(S * 0.008))
rim = Image.composite(rim, Image.new("L", (S, S), 0), body)
img.paste(Image.new("RGB", (S, S), (0xFF, 0xC9, 0xB6)), (0, 0), rim)

# ---------- 叶子 + 果柄 ----------
leaf_top = (tcx, tb[1] + TOM_H * 0.055)
leaves = Image.new("RGBA", (S, S), (0, 0, 0, 0))
for ang_deg, scale, tone in ((-62, 0.86, (0x3F, 0xC1, 0x7E)), (-26, 1.0, (0x55, 0xE0, 0x95)),
                             (26, 1.0, (0x55, 0xE0, 0x95)), (62, 0.86, (0x3F, 0xC1, 0x7E)),
                             (0, 1.12, (0x6B, 0xF0, 0xA8))):
    blade = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    bw, bh = S * 0.115, S * 0.230
    bdraw = ImageDraw.Draw(blade)
    bdraw.ellipse([leaf_top[0] - bw / 2, leaf_top[1] - bh, leaf_top[0] + bw / 2, leaf_top[1] + bh * 0.10],
                  fill=tone + (255,))
    blade = blade.rotate(-ang_deg, center=leaf_top, resample=Image.BICUBIC)
    leaves = Image.alpha_composite(leaves, blade)

stem = Image.new("RGBA", (S, S), (0, 0, 0, 0))
st = ImageDraw.Draw(stem)
sw = S * 0.030
st.rounded_rectangle([leaf_top[0] - sw / 2, leaf_top[1] - S * 0.105,
                      leaf_top[0] + sw / 2, leaf_top[1] + S * 0.020],
                     radius=sw * 0.5, fill=(0x37, 0x9E, 0x60, 255))
leaves = Image.alpha_composite(leaves, stem)

# 叶子柔和投影
lshadow = leaves.split()[3].filter(ImageFilter.GaussianBlur(S * 0.012)).point(lambda v: int(v * 0.55))
img.paste(Image.new("RGB", (S, S), (0x40, 0x08, 0x10)), (0, 0), lshadow)
img = Image.alpha_composite(img, leaves)

# ---------- 收尾 ----------
final = img.convert("RGB").resize((1024, 1024), Image.LANCZOS)

# 轻微暗角
fy, fx = np.mgrid[0:1024, 0:1024].astype(float)
d = np.sqrt((fx - 512) ** 2 + (fy - 512) ** 2) / 735.0
vig = np.clip(1.0 - 0.42 * np.clip(d - 0.55, 0, 1) ** 1.8, 0, 1)[..., None]
arr = np.asarray(final, dtype=float) * vig
final = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGB")

os.makedirs(os.path.dirname(OUT), exist_ok=True)
final.save(OUT, "PNG")
print("saved", OUT, final.size, final.mode)
