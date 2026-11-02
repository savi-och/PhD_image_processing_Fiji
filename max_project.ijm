// Prompt user to select input directory
inputDir = getDirectory("Choose input directory");

// Prompt user to select output directory
saveDir = getDirectory("Choose output directory");

// Get the list of image files in the input directory
fileList = getFileList(inputDir);

// Process all images in the input directory and save to output directory
processImagesFromDirectory();

// Function to process images from the input directory
function processImagesFromDirectory() {
    setBatchMode(false);
    
    for (i = 0; i < fileList.length; i++) {
        // Open the image file
        open(inputDir + fileList[i]);
        
        // Get the image title without extension
        originalTitle = getTitle();
        dotIndex = lastIndexOf(originalTitle, ".");
        if (dotIndex > 0) {
            originalTitle = substring(originalTitle, 0, dotIndex);
        }
        
        // Perform maximum intensity projection
        run("Z Project...", "projection=[Max Intensity]");
        //run("Z Project...", "start=2 projection=[Max Intensity] all"); for timelapse starting from plane 2

        
        // Check if the projected image has multiple channels
        getDimensions(width, height, channels, slices, frames);
        nChannels = channels;  // Number of channels in the projected image

        // Enhance contrast for the projected image
        if (nChannels > 1) {
            // Loop through each channel
            for (c = 1; c <= nChannels; c++) {
                // Set the current channel
                Stack.setChannel(c);

                // Enhance contrast automatically
                run("Enhance Contrast", "saturated=0.35");

                
            }
        } else {
            // For single-channel projected images, just enhance contrast
            run("Enhance Contrast", "saturated=0.35");
           
        }
        
        // Save the processed image
        saveAs("Tiff", saveDir + originalTitle + "_MIP.tif");
        
        // Close the current image
        close();
    }

    setBatchMode(false);
    showMessage("Processing complete!");

    // Close all images if any remain open
    while (nImages > 0) {
        selectImage(nImages);
        close();
    }
}
