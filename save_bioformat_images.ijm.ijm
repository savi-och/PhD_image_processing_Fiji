// Prompt user to select save directory
saveDir = getDirectory("Choose save directory");

// Save all open images with the second part of the name
saveAllImages();

// Function to save all open images
function saveAllImages() {
    for (i = 1; i <= nImages; i++) {
        selectImage(i);
        originalTitle = getTitle();
        secondPart = substring(originalTitle, indexOf(originalTitle, ".lif") + 7);
        saveAs("Tiff", saveDir + File.separator + secondPart + ".tif");
    }
}

