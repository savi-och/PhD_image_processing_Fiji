// ============================================================
// MACRO D_AREA — Source Cell Area Measurement
//
// Processes composite _merged_registered.tif images.
// For each ROI image:
//   1. Extracts source channel (ch2, frame 1)
//   2. Subtracts noise floor and floors negatives at 0
//   3. Thresholds to binary mask (Mean dark)
//   4. Removes particles < minParticleSize_px
//   5. Measures total source cell area in µm²
//      (sum of individual particle areas)
//
// Output:
//   source_cell_areas.csv — saved in the same folder as input images
//   Columns: Filename, N_Particles, Total_Area_um2
//   Rows with no signal or empty channel: area = 0, flagged in log
//
// Requires: Fiji (no additional plugins needed)
// ============================================================


// ============================================================
// USER SETTINGS — must match Macro D exactly
// ============================================================

sourceChannel      = 2;
imageSuffix        = "_merged_registered.tif";

noiseThreshold     = 110;  //ADJUST ACCORDINGLY TO BASE NOISE - USUALLY CLOSE TO 110
minParticleSize_um2 = 18;

// Scale calibration (1 µm = 1.8182 px)
scalePixelsPerUnit = 1.8182;
scaleKnownDist     = 1;
scaleUnit          = "µm";


// ============================================================
// FOLDER SELECTION
// ============================================================

imageFolder = getDirectory("Select folder containing _merged_registered.tif images");
outputCSV   = imageFolder + "source_cell_areas.csv";


// ============================================================
// ENUMERATE IMAGES
// ============================================================

imageList = getFileList(imageFolder);
roiCount  = 0;
for (i = 0; i < imageList.length; i++) {
    if (endsWith(imageList[i], imageSuffix)) roiCount++;
}

print("Found " + roiCount + " images  (suffix: " + imageSuffix + ")");

if (roiCount == 0) {
    print("ERROR: no images found — check imageSuffix");
    exit;
}


// ============================================================
// INITIALISE CSV
// Write header line first, then append one row per image.
// File.append() creates the file if it does not exist.
// ============================================================

// Overwrite any existing file by writing the header fresh
File.saveString("Filename,N_Particles,Total_Area_um2\n", outputCSV);

processedCount = 0;
errorCount     = 0;


// ============================================================
// MAIN LOOP
// ============================================================

for (fileIdx = 0; fileIdx < imageList.length; fileIdx++) {

    fileName = imageList[fileIdx];
    if (!endsWith(fileName, imageSuffix)) continue;

    print("\n[" + (processedCount + 1) + "/" + roiCount + "] " + fileName);
    
    // Derive base name and output paths for saved intermediates
	baseName        = substring(fileName, 0, lengthOf(fileName) - lengthOf(imageSuffix));
	channelSavePath = imageFolder + baseName + "_sourceChannel.tif";	
	maskSavePath    = imageFolder + baseName + "_sourceMask.tif";

    // Declare image IDs — safe to reference in cleanup block
    compositeID = -1;
    sourceID    = -1;
    maskRawID   = -1;
    channelSaveID = -1;
	maskSaveID    = -1;

    // ----------------------------------------------------------
    // STEP 1: Open composite, extract source channel at frame 1
    // ----------------------------------------------------------

    open(imageFolder + fileName);
    compositeID = getImageID();
    w = getWidth();
    h = getHeight();

    run("Duplicate...", "title=SourceRaw duplicate channels=" + sourceChannel + " frames=1");
    sourceID = getImageID();

    getStatistics(area, mean, srcMin, srcMax);

    // Empty channel check
    if (srcMax == 0) {
        print("  WARNING: source channel is empty — area set to 0");
        File.append("\"" + fileName + ",0,0", outputCSV);
        selectImage(compositeID); close();
        selectImage(sourceID);    close();
        errorCount++;
        processedCount++;
        continue;
    }

    selectImage(compositeID); close(); compositeID = -1;

    // ----------------------------------------------------------
    // STEP 3: Subtract noise floor, floor negatives at 0
    // ----------------------------------------------------------

    selectImage(sourceID);
    run("Subtract...", "value=" + noiseThreshold);
    run("Min...", "value=0");

    getStatistics(area, mean, flMin, flMax);

    // No signal above noise floor
    if (flMax == 0) {
        print("  WARNING: no signal above noise threshold — area set to 0");
        File.append("\"" + fileName + ",0,0", outputCSV);
        selectImage(sourceID); close(); sourceID = -1;
        errorCount++;
        processedCount++;
        continue;
    }
    
// ----------------------------------------------------------
// SAVE: Processed source channel (after noise subtraction)
// Duplicate before thresholding so the saved image retains
// the continuous intensity values, not the binary mask.
// ----------------------------------------------------------

selectImage(sourceID);
run("Duplicate...", "title=SourceChannel_save");
channelSaveID = getImageID();
run("Set Scale...",
    "distance=" + scalePixelsPerUnit +
    " known="   + scaleKnownDist +
    " unit="    + scaleUnit);
saveAs("Tiff", channelSavePath);
channelSaveID = getImageID();
selectImage(channelSaveID); close(); channelSaveID = -1;
print("  Source channel saved: " + channelSavePath);

    // ----------------------------------------------------------
    // STEP 4: Apply scale calibration BEFORE measuring
    // so that Analyze Particles reports area in µm² directly
    // ----------------------------------------------------------

    selectImage(sourceID);
    run("Set Scale...",
        "distance=" + scalePixelsPerUnit +
        " known="   + scaleKnownDist +
        " unit="    + scaleUnit);

    // ----------------------------------------------------------
    // STEP 4: Threshold to binary mask (Mean dark)
    // ----------------------------------------------------------

    // Compute Mean threshold automatically, then shift up by +10
	// to reduce overestimation from merging adjacent low-intensity pixels.
	// getThreshold() retrieves the lower and upper bounds Fiji computed.
	// setThreshold() applies the adjusted lower bound before converting.
	setAutoThreshold("Mean dark");
	getThreshold(lowerThresh, upperThresh);
	lowerThresh = lowerThresh + 10; // ADJUST THE +10 ACCORDING TO HOW CONSEVATIVE YOU WANT TO BE
	setThreshold(lowerThresh, upperThresh);
	print("  Threshold applied: " + lowerThresh + " (Mean + 10)");
	setOption("BlackBackground", true);
	run("Convert to Mask");
    maskRawID = sourceID;
    sourceID  = -1;

    // ----------------------------------------------------------
    // STEP 4b: Remove small particles AND measure remaining ones
    //
    // show=Nothing  — no output image needed (area only)
    // display       — populates Results table with area per particle
    // clear         — clears Results table before this run
    // include       — includes particles touching image edge
    //
    // Area in Results table is already in µm² because Set Scale
    // was applied to the image before thresholding.
    // ----------------------------------------------------------

    selectImage(maskRawID);
    run("Analyze Particles...",
    "size=" + minParticleSize_um2 + "-Infinity show=Masks display clear include");

	nParticles = nResults;

	// Only capture and save the mask window if particles were found.
	// When nParticles = 0, show=Masks may not create a new window,
	// so getImageID() is unreliable — we skip saving in that case.
	if (nParticles > 0) {
    	maskSaveID = getImageID();
    	saveAs("Tiff", maskSavePath);
    	maskSaveID = getImageID();
    	print("  Source mask saved: " + maskSavePath);
    	selectImage(maskSaveID); close(); maskSaveID = -1;
	} else {
    	print("  WARNING: no particles survived size filter — mask not saved");
	}
    	print("  Particles found (≥ " + minParticleSize_um2 + " px²): " + nParticles);

    // ----------------------------------------------------------
    // STEP 5: Sum individual particle areas from Results table
    // ----------------------------------------------------------

    totalArea = 0;
    for (r = 0; r < nResults; r++) {
        totalArea += getResult("Area", r);
    }

    totalArea = d2s(totalArea, 4);   // 4 decimal places in µm²
    print("  Total source cell area: " + totalArea + " µm²");

    // ----------------------------------------------------------
    // WRITE ROW TO CSV
    // ----------------------------------------------------------

    File.append("\"" + fileName + "," + nParticles + "," + totalArea, outputCSV);

    // ----------------------------------------------------------
    // Cleanup
    // ----------------------------------------------------------

    if (compositeID != -1) { selectImage(compositeID); close(); }
    if (sourceID    != -1) { selectImage(sourceID);    close(); }
    if (maskRawID   != -1) { selectImage(maskRawID);   close(); }
    if (channelSaveID != -1) { selectImage(channelSaveID); close(); }
	if (maskSaveID    != -1) { selectImage(maskSaveID);    close(); }

    // Clear Results table for next image
    run("Clear Results");

    processedCount++;
    print("  Done — " + processedCount + "/" + roiCount);
}


// ============================================================
// SUMMARY
// ============================================================

print("\n==========================================");
print("Macro D_AREA complete.");
print("Processed: " + processedCount + "/" + roiCount);
print("Warnings (area set to 0): " + errorCount);
print("Output CSV: " + outputCSV);
print("==========================================");