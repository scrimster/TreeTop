import coremltools as ct
from PIL import Image
import numpy as np

# Load the .mlpackage
mlmodel = ct.models.MLModel("imageseg_canopy_model.mlpackage")

# Open & resize
img = Image.open("forest_sample.png").convert("RGB")
img_resized = img.resize((256, 256))

# Run inference with a PIL.Image
out = mlmodel.predict({"input_img": img_resized})
# Inspect your output name
print("Outputs available:", list(out.keys()))

# Suppose the output key is "Identity":
mask = out["Identity"]            # this is a (256,256,1) numpy array of floats

# Convert to an 8-bit image (white=sky)
mask_img = Image.fromarray((mask.squeeze() * 255).astype(np.uint8))
mask_img.save("mask_out.png")

print("mean sky fraction:", mask.mean())
