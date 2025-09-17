const statusText = document.getElementById("status-text");
const vegBox = document.getElementById("veg-box");
const waterBox = document.getElementById("water-box");
const healthBox = document.getElementById("health-box");
const API_BASE_URL = "http://127.0.0.1:5000";

/**
 * This is the function for the "Instant" button.
 * It calls the fast /api/latest-result endpoint.
 */
function showLatestResult() {
  fetchAndDisplayData(
    `${API_BASE_URL}/api/latest-result`,
    "Loading latest result from database..."
  );
}

/**
 * This is the function for the "Slow" button.
 * It calls the full /api/analyze endpoint.
 */
function runNewAnalysis() {
  // --- THIS IS THE CRITICAL FIX ---
  // The typo "API_-BASE_URL" has been corrected to "API_BASE_URL".
  fetchAndDisplayData(
    `${API_BASE_URL}/api/analyze/demofield1`,
    "Running new AI analysis... (This will be slow)"
  );
}

/**
 * This is a shared helper function that both buttons use.
 * It takes a URL and a loading message, calls the API, and updates the UI.
 */
async function fetchAndDisplayData(apiUrl, loadingMessage) {
  try {
    // 1. Set the UI to a "loading" state
    statusText.textContent = `Crop Health Status: ${loadingMessage}`;
    vegBox.innerHTML = `<h3>Vegetation Stress</h3><p>Loading...</p>`;
    waterBox.innerHTML = `<h3>Water Stress</h3><p>Loading...</p>`;
    healthBox.innerHTML = `<h3>Health Mapping</h3><p>Loading...</p>`;

    // 2. Call the specified backend API endpoint
    const response = await fetch(apiUrl);

    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(errorData.error || `API Error: ${response.statusText}`);
    }

    const data = await response.json();

    // 3. Update the UI with the successful result
    statusText.textContent = `Crop Health Status: ${data.overall_status}`;

    const vegStressImgUrl = `${API_BASE_URL}${data.image_urls.vegetation_stress}`;
    const waterStressImgUrl = `${API_BASE_URL}${data.image_urls.water_stress}`;
    const healthMapImgUrl = `${API_BASE_URL}${data.image_urls.health_map}`;

    vegBox.innerHTML = `<h3>Vegetation Stress (NDVI)</h3><img class="demo-img" src="${vegStressImgUrl}" alt="Vegetation Stress Map">`;
    waterBox.innerHTML = `<h3>Water Stress (NDWI)</h3><img class="demo-img" src="${waterStressImgUrl}" alt="Water Stress Map">`;
    healthBox.innerHTML = `<h3>Predicted Health Map</h3><img class="demo-img" src="${healthMapImgUrl}" alt="Predicted Health Map">`;
  } catch (error) {
    console.error("Failed to fetch analysis:", error);
    statusText.textContent = `Crop Health Status: Error - ${error.message}`;
    vegBox.innerHTML = `<h3>Vegetation Stress</h3><p>Error.</p>`;
    waterBox.innerHTML = `<h3>Water Stress</h3><p>Error.</p>`;
    healthBox.innerHTML = `<h3>Health Mapping</h3><p>Error.</p>`;
  }
}
