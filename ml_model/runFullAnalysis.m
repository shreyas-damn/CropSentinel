function healthMapData = runFullAnalysis(outputDir)
    % ======================================================================
    %               FINAL DEFINITIVE ALL-IN-ONE SCRIPT
    % ======================================================================
    % This is a self-contained AI script that performs a complete crop
    % health analysis. It is designed to be called by an external application.
    %
    % Workflow:
    %   1. Loads and preprocesses the hyperspectral data.
    %   2. Creates ground truth labels using scientific indices.
    %   3. Solves class imbalance using a robust undersampling technique.
    %   4. Trains a 3D CNN on the balanced data.
    %   5. Runs a prediction on the full map.
    %   6. Saves all three final PNG visualizations to the specified directory.
    % ======================================================================

    fprintf('--- [AI Analysis] Starting the definitive all-in-one process... ---\n');

    % ===== Step 1: Load and Preprocess Data =====
    fprintf('[Step 1/6] Loading and preprocessing raw hyperspectral data cube...\n');
    load("Indian_pines_corrected.mat");
    rawHyperCube = double(indian_pines_corrected);
    [height, width, numBands] = size(rawHyperCube);
    wavelengths = linspace(400, 2500, numBands);

    normalizedHyperCube = rawHyperCube;
    for b = 1:numBands
        band = rawHyperCube(:,:,b);
        lo = prctile(band(:), 1);
        hi = prctile(band(:), 99);
        normalizedHyperCube(:,:,b) = min(max((band - lo) / (hi - lo + eps), 0), 1);
    end

    % ===== Step 2: Compute Indices for Labeling and Visualization =====
    fprintf('[Step 2/6] Calculating vegetation indices...\n');
    nearestband = @(target) find(abs(wavelengths - target) == min(abs(wavelengths - target)), 1);
    idx_red = nearestband(670);
    idx_NIR = nearestband(860);
    idx_SWIR = nearestband(1240);

    redBand = normalizedHyperCube(:,:,idx_red);
    nirBand = normalizedHyperCube(:,:,idx_NIR);
    swirBand = normalizedHyperCube(:,:,idx_SWIR);

    NDVI = (nirBand - redBand) ./ (nirBand + redBand + eps);
    NDWI = (nirBand - swirBand) ./ (nirBand + swirBand + eps);

    % ===== Step 3: Define Ground Truth Labels =====
    pixelLabels = zeros(height, width);
    unhealthy_mask = (NDVI < 0.3);
    moderate_mask = (NDVI >= 0.3 & NDVI < 0.6);
    healthy_mask = (NDVI >= 0.6);
    pixelLabels(unhealthy_mask) = 1; % Unhealthy
    pixelLabels(moderate_mask) = 2;  % Moderate
    pixelLabels(healthy_mask) = 3;   % Healthy

    % ===== Step 4: Extract Patches and Balance the Dataset =====
    fprintf('[Step 3/6] Extracting patches and balancing data...\n');
    patchSize = 7;
    pad = floor(patchSize / 2);
    paddedCube = padarray(normalizedHyperCube, [pad pad 0], 'symmetric');
    numPixels = height * width;
    xPatches = zeros(patchSize, patchSize, numBands, numPixels, 'single');
    yLabels = zeros(numPixels, 1);
    idx = 1;
    for i = 1:height
        for j = 1:width
            patch = paddedCube(i:i+patchSize-1, j:j+patchSize-1, :);
            xPatches(:,:,:,idx) = patch;
            yLabels(idx) = pixelLabels(i,j);
            idx = idx + 1;
        end
    end
    labeledIndices = find(yLabels > 0);
    xPatches = xPatches(:,:,:,labeledIndices);
    yLabels = yLabels(labeledIndices);
    yLabels = categorical(yLabels, [1 2 3], {'Unhealthy','Moderate','Healthy'});

    % Undersampling to create a perfectly balanced training set
    [yTrainTemp, trainInd] = datasample(yLabels, round(numel(yLabels)*0.8), 'Replace', false);
    xTrainTemp = xPatches(:,:,:,trainInd);
    
    idx_unhealthy = find(yTrainTemp == 'Unhealthy');
    idx_moderate = find(yTrainTemp == 'Moderate');
    idx_healthy = find(yTrainTemp == 'Healthy');
    numMinority = min([numel(idx_unhealthy), numel(idx_moderate), numel(idx_healthy)]);
    
    idx_unhealthy_sampled = randsample(idx_unhealthy, numMinority);
    idx_moderate_sampled = randsample(idx_moderate, numMinority);
    idx_healthy_sampled = randsample(idx_healthy, numMinority);
    
    balancedIndices = [idx_unhealthy_sampled; idx_moderate_sampled; idx_healthy_sampled];
    xTrainFinal = xTrainTemp(:,:,:,balancedIndices);
    yTrainFinal = yTrainTemp(balancedIndices);
    
    % Use the remaining data for testing
    testInd = setdiff(1:numel(yLabels), trainInd);
    xTestFinal = xPatches(:,:,:,testInd);
    yTestFinal = yLabels(testInd);

    % Reshape for CNN
    xTrainFinal = reshape(xTrainFinal, patchSize, patchSize, numBands, 1, []);
    xTestFinal  = reshape(xTestFinal,  patchSize, patchSize, numBands, 1, []);
    
    % ===== Step 5: Define, Train, and Predict =====
    fprintf('[Step 4/6] Defining and training the 3D CNN...\n');
    inputSize = [patchSize patchSize numBands 1];
    numClasses = numel(categories(yTrainFinal));
    layers = [ image3dInputLayer(inputSize,'Name','input'), convolution3dLayer([3 3 3],16,'Padding','same'), batchNormalizationLayer, reluLayer, maxPooling3dLayer(2,'Stride',2), convolution3dLayer([3 3 3],32,'Padding','same'), batchNormalizationLayer, reluLayer, maxPooling3dLayer(2,'Stride',2), fullyConnectedLayer(64), reluLayer, fullyConnectedLayer(numClasses), softmaxLayer, classificationLayer ];
    options = trainingOptions('adam', 'MaxEpochs',15, 'MiniBatchSize',64, 'Shuffle','every-epoch', 'ValidationData',{xTestFinal, yTestFinal}, 'Plots','none', 'ExecutionEnvironment','auto', 'Verbose',false);
    net = trainNetwork(xTrainFinal, yTrainFinal, layers, options);

    fprintf('[Step 5/6] Running full map prediction...\n');
    healthMapData = zeros(height, width);
    for i = 1:height
        for j = 1:width
            patch = paddedCube(i:i+patchSize-1, j:j+patchSize-1, :);
            patch = reshape(patch, patchSize, patchSize, numBands, 1, 1);
            prediction = classify(net, patch);
            healthMapData(i,j) = double(prediction);
        end
    end

    % ===== Step 6: Save All Visual Outputs =====
    fprintf('[Step 6/6] Saving all PNG output files...\n');
    
    fig1 = figure('visible','off'); imagesc(NDVI,[-1 1]); colormap(gca,jet); colorbar; axis image; title('NDVI Heatmap'); print(fig1, fullfile(outputDir, 'NDVI.png'), '-dpng'); close(fig1);
    fig2 = figure('visible','off'); imagesc(NDWI,[-1 1]); colormap(gca,jet); colorbar; axis image; title('NDWI Heatmap'); print(fig2, fullfile(outputDir, 'NDWI.png'), '-dpng'); close(fig2);
    
    fig3 = figure('visible','off');
    imagesc(healthMapData);
    customCmap = [1 0 0; 1 1 0; 0 1 0]; % Red, Yellow, Green
    colormap(customCmap);
    caxis([1 3]);
    colorbar('Ticks',[1.33, 2, 2.67], 'TickLabels',{'Unhealthy','Moderate','Healthy'});
    axis image;
    title('Predicted Health Map');
    print(fig3, fullfile(outputDir, 'Predicted_health_map.png'), '-dpng');
    close(fig3);
    
    fprintf('--- [AI Analysis] All files saved successfully to the specified directory. ---\n');
end

