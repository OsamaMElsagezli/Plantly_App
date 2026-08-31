
## 📱 Mobile App — Plantly

The final, best-performing model (EfficientNetB3) was exported and integrated into **Plantly**, a cross-platform mobile application built with **Flutter and Dart**, enabling:

- Real-time plant disease detection directly from a leaf photo
- Practical, on-the-go use for farmers and agricultural workers, including in resource-limited or remote regions
- A dual execution model — cloud-hosted inference alongside a lighter on-device path for edge/local processing

## 🔬 Results Summary

- EfficientNetB3: **99.75% test accuracy**, 99.81% validation accuracy, 96.96% accuracy on the more realistic PlantDoc test set
- Confusion matrix analysis showed EfficientNetB3 had very few misclassifications, correctly classifying 320/321 images in the Tomato Yellow Leaf Curl Virus class and near-perfect results across most of the 15 classes
- ResNet50 offered strong, stable generalization with a good speed/accuracy balance
- VGG16 achieved competitive accuracy but showed signs of overfitting (fluctuating loss/accuracy curves) and had by far the largest model size and slowest training
- MobileNetV2 was the smallest and fastest model, well-suited for mobile/edge deployment, but noticeably weaker on real-field (PlantDoc) images

## 🚀 Future Work

- **Mobile app development** — further build-out of the Plantly app
- **Sensor integration** for a multi-modal, context-aware prediction system, combining image-based diagnosis with environmental sensor data (soil moisture, temperature, humidity), using hardware such as:
  - Soil moisture sensor (HW080)
  - Water level sensor (HW038)
  - Vibration/tilt sensor (SW-18010P)
  - ESP32-CAM for wireless image capture and Wi-Fi telemetry
  - DHT11 temperature & humidity module
- Broadening dataset scope to include root and stem disease anomalies
- Reducing inference latency further for low-tier/edge hardware

## 📚 References

Key related work referenced in this project includes studies using handcrafted features with Random Forest classifiers (~92.8% accuracy), ResNet50 + Vision Transformer hybrids (~90.12%), comparative CNN studies on tomato/corn leaves (~95%), and transfer-learning approaches such as AgriNet (~90.6%). Plantly's EfficientNetB3-based approach matches or outperforms these while remaining lightweight enough for practical mobile deployment. Full citations are available in the project report.

---

*This README was generated from the project report and presentation materials for the Plantly graduation project (Istanbul Bilgi University, January 2026).*
