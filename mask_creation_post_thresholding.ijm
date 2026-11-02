macro "Analyze Each Image, Save Results, and Save ROIs" {
    // Set threshold method: choose either "Default" or "MaxEntropy"
    thresholdMethod = "Otsu"; // Change to "MaxEntropy" if desired
  
    
    // Ask user to select the input directory
    inputDir = getDirectory("Choose Input Directory");
    if (inputDir == "null") exit("No input directory selected.");

    // Ask user to select the output directory
    outputDir = getDirectory("Choose Output Directory");
    if (outputDir == "null") exit("No output directory selected.");

    // Get the list of all files in the input directory
    list = getFileList(inputDir);

    // Clear Results table and ROI Manager to avoid mixing old data
    run("Clear Results");
    if (isOpen("ROI Manager")) {
        roiManager("Reset");
    } else {
        run("ROI Manager...");
        roiManager("Reset");
    }
    
    // Loop through all files in the directory
    for (i = 0; i < list.length; i++) {
        filePath = inputDir + list[i];
        if (File.isDirectory(filePath)) continue; // Skip subdirectories

        // Open the image
        open(filePath);

        // Check if the image is opened successfully
        if (nImages == 0) {
            print("Error: Unable to open image: " + filePath);
            continue; // Skip to the next file if no image is open
        }
        
        
        // Apply Gaussian Blur with sigma = 1
     run("Gaussian Blur...", "sigma=1");

        // Apply thresholding
        //setAutoThreshold("Default dark no-reset");
        //run("Threshold...");
        //setThreshold(30, 255, "raw");
        
        // Thresholding
        setAutoThreshold(thresholdMethod + " dark no-reset");
        getRawStatistics(nPixels, mean, min, max, std, histogram);
        getThreshold(lower, upper);
        setThreshold(lower, upper);

        imageTitle = getTitle();
// Convert to mask and analyze particles
        run("Convert to Mask");
        run("Analyze Particles...", "size=20-Infinity display clear add");
        
        //save mask
        title = getTitle();                                  
		dotIndex = lastIndexOf(title, ".");
		if (dotIndex > 0)
	    baseName = substring(title, 0, dotIndex);
		else
   		 baseName = title;
   		 maskPath = outputDir + baseName + "_mask.tif";
		saveAs("Tiff", maskPath);
// Clear Results table for the next image
        run("Clear Results");

        // Reset ROI Manager for the next image
        roiManager("Reset");

        // Close the image after processing
        close();
    }