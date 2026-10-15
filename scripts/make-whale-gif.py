"""Build the animated whale-girl mascot asset from the three generated frames."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "assets" / "generated"
OUT_GIF = ROOT / "assets" / "whale_girl.gif"
OUT_C = ROOT / "source-changes" / "files" / "main" / "display" / "deepseek_whale_gif.c"
W, H = 240, 176

frames = []
for name in ("whale_girl_frame1.jpg", "whale_girl_frame2.jpg", "whale_girl_frame3.jpg"):
    image = Image.open(SRC / name).convert("RGB")
    image.thumbnail((H, H), Image.Resampling.LANCZOS)
    canvas = Image.new("RGB", (W, H), (174, 224, 247))
    canvas.paste(image, ((W - image.width) // 2, (H - image.height) // 2))
    frames.append(canvas)

frames[0].save(OUT_GIF, save_all=True, append_images=frames[1:], duration=240,
               loop=0, disposal=2, optimize=True)
data = OUT_GIF.read_bytes()
with OUT_C.open("w", encoding="utf-8", newline="\n") as output:
    output.write("#include <lvgl.h>\n#include <stdint.h>\n\n")
    output.write("const uint8_t deepseek_whale_gif_data[] = {\n")
    for offset in range(0, len(data), 16):
        output.write("    " + ", ".join(f"0x{byte:02x}" for byte in data[offset:offset + 16]) + ",\n")
    output.write("};\n\n")
    output.write("const lv_img_dsc_t deepseek_whale_gif = {\n")
    output.write("    .header.magic = LV_IMAGE_HEADER_MAGIC,\n")
    output.write("    .header.cf = LV_COLOR_FORMAT_RAW,\n")
    output.write("    .header.flags = 0,\n")
    output.write("    .header.w = 240,\n")
    output.write("    .header.h = 176,\n")
    output.write("    .header.stride = 0,\n")
    output.write("    .data_size = sizeof(deepseek_whale_gif_data),\n")
    output.write("    .data = deepseek_whale_gif_data,\n")
    output.write("};\n")

print(f"created {OUT_GIF} ({len(data)} bytes)")
print(f"created {OUT_C} ({OUT_C.stat().st_size} bytes)")
