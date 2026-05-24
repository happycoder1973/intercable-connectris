import os
from PIL import Image, ImageDraw, ImageFont

# Workspace path
workspace_dir = r"f:\OneDrive - NTiC GmbH\Dokumente\GitHub\intercable-connectris"
textures_dir = os.path.join(workspace_dir, "assets", "textures")

os.makedirs(textures_dir, exist_ok=True)

def create_image(filename, color, outline, text):
    img = Image.new('RGBA', (64, 64), color=color)
    draw = ImageDraw.Draw(img)
    # Simple border
    draw.rectangle([0, 0, 63, 63], outline=outline, width=3)
    
    # Try to add text if default font is available
    try:
        # Just drawing a simple text in the middle might not look great without font control,
        # but let's try to center something.
        draw.text((10, 24), text, fill=(255,255,255,255))
    except:
        pass
        
    img.save(os.path.join(textures_dir, filename))

# Kacheln
create_image("isoliert.png", (200, 50, 50, 255), (100,0,0,255), "Iso") 
create_image("blank.png", (150, 150, 150, 255), (50,50,50,255), "Blank") 
create_image("gecrimpt.png", (50, 200, 50, 255), (0,100,0,255), "Crimp") 

# Power-ups
create_image("amx_laser.png", (200, 200, 0, 255), (255,255,255,255), "Laser") 
create_image("stilo60_beben.png", (150, 75, 0, 255), (50,25,0,255), "Quake") 
create_image("slick_cutter.png", (50, 50, 200, 255), (200,200,255,255), "Cut") 
create_image("vde_schutzschild.png", (0, 200, 200, 255), (255,255,255,255), "Shield") 

print("Graphics generated in", textures_dir)
