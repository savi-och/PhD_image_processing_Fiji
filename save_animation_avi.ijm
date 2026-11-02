// Prompt user for directory containing the original images
inputDir = getDirectory("Input: choose folder where images came from");

// Prompt user for output directory
outputDir = getDirectory("Output: choose where to save AVI files");

// Set animation options (frames per second)
frameRate = 10;
run("Animation Options...", "speed=" + frameRate + " loop");

// Get the list of open image titles
ids = getList("image.titles");

// Iterate over each open image
for (i = 0; i < ids.length; i++) {
    title = ids[i];
    selectWindow(title);

    // Save as AVI
    aviFile = outputDir + title + ".avi";
    saveAs("AVI", aviFile);

    // Save over original TIFF (assumes filename matches)
    tiffFile = inputDir + title;
    saveAs("Tiff", tiffFile);

    // Close image after saving
    close();
}

// Optional: Show a message when processing is complete
showMessage("Processing complete!");
