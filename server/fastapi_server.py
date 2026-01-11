import torch
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse
from torchvision import models, transforms
from PIL import Image
import json
import torch.nn.functional as F
import numpy as np
import io

# Load models with error handling
def load_model(model_path: str):
    try:
        model = torch.load(model_path, map_location=torch.device('cpu'))
        model.eval()
        return model
    except Exception as e:
        raise RuntimeError(f"Failed to load model from {model_path}: {e}")

# Load model files
model_eff = load_model("models/efficientnet_b3_bundle_20251223-132415.pth")
model_mob = load_model("models/mobilenetv2_100_bundle_20251223-135331.pth")

# Load labels with error handling
def load_labels(labels_path: str):
    try:
        with open(labels_path, "r") as f:
            return json.load(f)
    except Exception as e:
        raise RuntimeError(f"Failed to load labels from {labels_path}: {e}")

labels = load_labels("labels (1).json")

# Load config with error handling
def load_config(config_path: str):
    try:
        with open(config_path, "r") as f:
            return json.load(f)
    except Exception as e:
        raise RuntimeError(f"Failed to load config from {config_path}: {e}")

config = load_config("config.json")

# Initialize FastAPI
app = FastAPI()

# Image preprocessing function (based on config)
def preprocess_image(image: Image.Image):
    transform = transforms.Compose([
        transforms.Resize((config["input_size"], config["input_size"])),
        transforms.ToTensor(),
        transforms.Normalize(mean=config["mean"], std=config["std"]),
    ])
    return transform(image).unsqueeze(0)  # Add batch dimension

# Helper function for inference
def predict(image_bytes: bytes):
    # Load image from bytes
    try:
        image = Image.open(io.BytesIO(image_bytes))
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Error processing the image: {e}")
    
    # Preprocess image
    input_tensor = preprocess_image(image)

    # Inference using EfficientNetB3
    with torch.no_grad():
        output_eff = model_eff(input_tensor)
        output_mob = model_mob(input_tensor)

    # Softmax to get probabilities
    probs_eff = F.softmax(output_eff[0], dim=0)
    probs_mob = F.softmax(output_mob[0], dim=0)

    # Get top predictions
    topk_eff = torch.topk(probs_eff, k=config["topk"]).indices.tolist()
    topk_mob = torch.topk(probs_mob, k=config["topk"]).indices.tolist()

    # Map indices to labels
    topk_eff_labels = [labels[str(idx)] for idx in topk_eff]
    topk_mob_labels = [labels[str(idx)] for idx in topk_mob]

    return topk_eff, topk_mob, topk_eff_labels, topk_mob_labels

@app.post("/predict")
async def predict_endpoint(file: UploadFile = File(...)):
    try:
        # Read file
        image_bytes = await file.read()

        # Get predictions from both models
        topk_eff, topk_mob, topk_eff_labels, topk_mob_labels = predict(image_bytes)

        # Create response data
        response_data = {
            "model_used": "both",
            "eff_model_predictions": {
                "topk_indices": topk_eff,
                "topk_labels": topk_eff_labels,
            },
            "mob_model_predictions": {
                "topk_indices": topk_mob,
                "topk_labels": topk_mob_labels,
            },
        }

        return JSONResponse(content=response_data)
    
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"An error occurred during inference: {e}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
