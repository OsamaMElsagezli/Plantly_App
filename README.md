
## 📱 Mobile App: Plantly

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

1. Dolatabadian, A., Neik, T. X., Danilevicz, M. F., Upadhyaya, S. R., Batley, J., & Edwards, D. (2024). Image-based crop disease detection using machine learning. *Journal of Applied Machine Learning in Agriculture*.
2. Food and Agriculture Organization of the United Nations. (2023, July). *New AI technology to fight plant pests and diseases.*
3. Kulkarni, P., Karwande, A., Kolhe, T., Kamble, S., Joshi, A., & Wyawahare, M. (2020). Plant disease detection using image processing and machine learning. *International Journal of Emerging Trends in Engineering and Technology*.
4. Kabir Oni, M., & Tanzin Prama, T. (2025). Optimized custom CNN for real-time tomato leaf disease detection. *Journal of Agricultural Informatics*.
5. Rezaei, M., Diepeveen, D., Laga, H., Jones, M. G. K., & Sohel, F. (2024). Plant disease recognition in a low-data scenario using few-shot learning. *Computers and Electronics in Agriculture*.

---

*This README was generated from the project report and presentation materials for the Plantly graduation project (Istanbul Bilgi University, January 2026).*
