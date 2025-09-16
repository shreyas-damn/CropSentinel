PROBLEM STATEMENT:

AI crop health monitoring:

FEATURES:

1.Crop health

2.Soil conditions

3.Pest infestation

HYPERSPECTRAL IMAGING:

What is it?

A normal photo (RGB) has 3 bands
A hyperspectral image has tens to hundreds of channels (bands).
Each band captures a narrow slice of light at a specific wavelength.
Example: 220 bands between 400–2500 nm (Indian Pines dataset).

BAND: 

Is a small wavelength range 
In our project we are using Indian pines dataset which has around 200 bands. The hyper-spectral imaging is captured by ARIVIS sensor. This sensor captures wavelengths ranging from 400nm ~ 2500nm. Each of the 200 bands corresponds to specific wavelength between 400 and 2500

 Spectral Signature
 
A spectral signature is basically the “fingerprint” of a material in light.
Every material reflects, absorbs, and transmits light differently across wavelengths.
When you plot reflectance vs wavelength, the curve you get is the spectral signature.

How to find whether the plant is healthy or not:

NDVI - Normalised Difference Vegetation Index:

It tells us how healthy or green the vegetation is.
Healthy plants reflect strongly in NIR (near-infrared) and absorb red light for photosynthesis.

High NDVI: lush, healthy plants

Low NDVI: bare soil, unhealthy crops, or water

NDWI - Normalised Difference Water Index:

It tells us about the water content in the soil or vegetation.
Water absorbs SWIR light, so areas with more water reflect less SWIR.

High NDWI: healthy water-rich vegetation or wet soil

Low NDWI: dry vegetation or bare soil

CIRE - Chlorophyll Index Red Edge:

It tells us about the amount of chlorophyll present in the leaves.Red-edge (~740 nm) is the sharp transition between red and NIR reflectance in plants.

High CIRE: healthy green vegetation

Low CIRE: stressed or dying plants

Iot data:

Dataset containing soil moisture, air temperature, humidity, and leaf wetness is synthetically generated then used with a time-series.

How do you find pest infestation:

Pests thrive under specific environmental conditions. IoT + hyperspectral data can capture both direct and indirect indicators.


PREDICTIONS:

Hyperspectral patch → CNN → spatial-spectral features

IoT time-series → LSTM → temporal features

Concatenate features → Fully Connected Layer → Multi-output Prediction:

Crop health (Healthy / Stressed / Unhealthy)

Soil condition (Dry / Optimal / Wet)

Pest risk (Low / Medium / High)
