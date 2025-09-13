const statusText = document.getElementById("status-text");
const vegBox = document.getElementById("veg-box");
const waterBox = document.getElementById("water-box");
const healthBox = document.getElementById("health-box");

function handleClick() {
  const selectedElement = document.querySelector('input[name="mode"]:checked');

  if (!selectedElement) {
    alert("Please select a mode first!");
    return;
  }

  const selectedMode = selectedElement.value;

  if (selectedMode === "demo") {
    showDemo();
  } else {
    statusText.textContent = "Crop Health Status: Upload images individually 🌱";
  }
}

function showDemo() {
  statusText.textContent = "Crop Health Status: Healthy 🌿";

  vegBox.innerHTML = `
    <h3>Vegetation Stress</h3>
    <img class="demo-img" src="https://i.ibb.co/5WwY9mf/veg-stress.jpg" alt="Vegetation Stress">
    <button onclick="triggerFileInput('veg')">Upload Vegetation Image</button>
    <input type="file" accept="image/*" onchange="uploadImage(event, 'veg')" style="display:none;" />
  `;

  waterBox.innerHTML = `
    <h3>Water Stress</h3>
    <img class="demo-img" src="https://i.ibb.co/3mJhXhk/water-stress.jpg" alt="Water Stress">
    <button onclick="triggerFileInput('water')">Upload Water Image</button>
    <input type="file" accept="image/*" onchange="uploadImage(event, 'water')" style="display:none;" />
  `;

  healthBox.innerHTML = `
    <h3>Health Mapping</h3>
    <img class="demo-img" src="https://i.ibb.co/ZGSKQX4/health-map.jpg" alt="Health Mapping">
    <button onclick="triggerFileInput('health')">Upload Health Image</button>
    <input type="file" accept="image/*" onchange="uploadImage(event, 'health')" style="display:none;" />
  `;
}

function triggerFileInput(type) {
  if (type === "veg") vegBox.querySelector('input[type="file"]').click();
  if (type === "water") waterBox.querySelector('input[type="file"]').click();
  if (type === "health") healthBox.querySelector('input[type="file"]').click();
}

function uploadImage(event, type) {
  const file = event.target.files[0];
  if (!file) return;

  const reader = new FileReader();
  reader.onload = function (e) {
    let targetBox;

    if (type === "veg") targetBox = vegBox;
    if (type === "water") targetBox = waterBox;
    if (type === "health") targetBox = healthBox;

    targetBox.innerHTML = `
      <h3>${type === "veg" ? "Vegetation Stress" : type === "water" ? "Water Stress" : "Health Mapping"}</h3>
      <img class="demo-img" src="${e.target.result}" alt="${type} image">
      <button onclick="triggerFileInput('${type}')">Upload ${type} Image</button>
      <input type="file" accept="image/*" onchange="uploadImage(event, '${type}')" style="display:none;" />
    `;

    statusText.textContent =` Crop Health Status: ${type} image uploaded `;
  };

  reader.readAsDataURL(file);
}