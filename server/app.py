import io
from typing import Dict, Any

import torch
import torch.nn.functional as F
import timm
from PIL import Image
from fastapi import FastAPI, UploadFile, File, Query
from fastapi.middleware.cors import CORSMiddleware

# =======================
# Paths to your bundles
# =======================
BUNDLE_EFFB3 = r"../efficientnet_b3_bundle_20251223-132415.pth"
BUNDLE_MNV2  = r"../mobilenetv2_100_bundle_20251223-135331.pth"

app = FastAPI(title="Plant Disease Inference API")

# allow Flutter to call it
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # ok for local demo
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

DEVICE = "cuda" if torch.cuda.is_available() else "cpu"

# =======================
# Load bundles
# =======================
def load_bundle(path: str) -> Dict[str, Any]:
    bundle = torch.load(path, map_location="cpu")
    required = ["model_name", "num_classes", "class_names", "state_dict", "preprocess_spec"]
    missing = [k for k in required if k not in bundle]
    if missing:
        raise RuntimeError(f"Bundle missing keys: {missing}")
    return bundle

bundle_eff = load_bundle(BUNDLE_EFFB3)
bundle_mnv = load_bundle(BUNDLE_MNV2)

# =======================
# Build models
# =======================
def build_model(bundle: Dict[str, Any]) -> torch.nn.Module:
    model_name = bundle["model_name"]
    num_classes = int(bundle["num_classes"])
    model = timm.create_model(model_name, pretrained=False, num_classes=num_classes)
    model.load_state_dict(bundle["state_dict"], strict=True)
    model.eval()
    model.to(DEVICE)
    return model

model_eff = build_model(bundle_eff)
model_mnv = build_model(bundle_mnv)

# =======================
# Preprocess
# =======================
def preprocess(image: Image.Image, input_size: int, mean, std) -> torch.Tensor:
    image = image.convert("RGB")
    image = image.resize((input_size, input_size))  # simple resize (matches your spec letterbox=False)
    x = torch.tensor(list(image.getdata()), dtype=torch.float32).view(input_size, input_size, 3)
    x = x.permute(2, 0, 1) / 255.0  # CHW, 0..1

    mean_t = torch.tensor(mean).view(3, 1, 1)
    std_t  = torch.tensor(std).view(3, 1, 1)
    x = (x - mean_t) / std_t

    return x.unsqueeze(0)  # NCHW

def pick_bundle_and_model(which: str):
    which = which.lower().strip()
    if which in ["efficientnetb3", "efficientnet_b3", "effb3"]:
        return bundle_eff, model_eff
    if which in ["mobilenetv2", "mobilenetv2_100", "mnv2"]:
        return bundle_mnv, model_mnv
    # default
    return bundle_eff, model_eff

@app.get("/health")
def health():
    return {"ok": True, "device": DEVICE}

@app.post("/predict")
async def predict(
    file: UploadFile = File(...),
    model: str = Query("efficientnet_b3"),
    topk: int = Query(3),
):
    bundle, net = pick_bundle_and_model(model)

    content = await file.read()
    img = Image.open(io.BytesIO(content))

    spec = bundle["preprocess_spec"]
    input_size = int(spec["input_size"][bundle["model_name"]])
    mean = spec["mean"]
    std = spec["std"]

    x = preprocess(img, input_size, mean, std).to(DEVICE)

    with torch.no_grad():
        logits = net(x)
        probs = F.softmax(logits, dim=1)[0]

    topk = max(1, min(int(topk), probs.numel()))
    vals, idxs = torch.topk(probs, k=topk)

    class_names = bundle["class_names"]
    results = []
    for v, i in zip(vals.tolist(), idxs.tolist()):
        results.append({
            "class_index": int(i),
            "class_name": str(class_names[i]),
            "confidence": float(v),
        })

    return {
        "model_used": bundle["model_name"],
        "topk": results,
    }
