#!/usr/bin/env python3
"""
Convert an imageseg .h5 file ➜ Core ML .mlmodel (ML Program backend)
"""

import os, argparse, coremltools as ct, tensorflow as tf

"""
python converter_new.py \
    --model imageseg_canopy_model.h5 \
    --desc "Predicts canopy vs sky per pixel" \
    --input_desc "RGB image 256×256" \
    --output_desc "Probability mask (1 = sky)" \
    --author "Juergen Niedballa" \
    --license "MIT"
"""

def parse():
    p = argparse.ArgumentParser()
    p.add_argument("--model",        required=True)
    p.add_argument("--desc",         default="")
    p.add_argument("--input_desc",   default="")
    p.add_argument("--output_desc",  default="")
    p.add_argument("--author",       default="")
    p.add_argument("--license",      default="")
    return p.parse_args()

def main():
    args   = parse()
    h5     = args.model
    stem   = os.path.splitext(h5)[0]

    # ---- 1  load with tf.keras  ----
    model  = tf.keras.models.load_model(h5, compile=False)

    # ---- 2  Core ML conversion  ----
    mlmodel = ct.convert(
        model,
        source="tensorflow",
        convert_to="mlprogram",               # modern backend
        inputs=[ct.ImageType(
            name="input_img",
            shape=(1, 256, 256, 3),          # NHWC; adjust if your input differs
            scale=1/255.0                    # same pre-processing as imageseg
        )],
        minimum_deployment_target=ct.target.iOS15
    )

    # ---- 3  Metadata ----
    mlmodel.short_description               = args.desc
    mlmodel.author                          = args.author
    mlmodel.license                         = args.license
    mlmodel.input_description["input_img"]  = args.input_desc
    mlmodel.output_description["Identity"]    = args.output_desc  # auto output name

    mlmodel.save(f"{stem}.mlpackage")
    print(f"Saved ➜ {stem}.mlpackage")

if __name__ == "__main__":
    main()
