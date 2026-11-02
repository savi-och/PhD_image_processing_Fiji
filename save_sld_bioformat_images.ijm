// Prompt user to select save directory
saveDir = getDirectory("Choose save directory");

// Save all open images with the second part of the name
saveAllImages();

// Function to save all open images
function saveAllImages() {
    for (i = 1; i <= nImages; i++) {
        selectImage(i);
        originalTitle = getTitle();

        // --- Extract text after .lif/.sld and before " - Position" ---
        extIndex = indexOf(originalTitle, ".lif");
        if (extIndex == -1)
            extIndex = indexOf(originalTitle, ".sld");

        startIndex = extIndex + 7; // move past extension
        if (substring(originalTitle, startIndex, startIndex + 3) == " - ")
            startIndex += 3;

        endIndex = indexOf(originalTitle, " - Position");
        if (endIndex == -1)
            endIndex = lengthOf(originalTitle);

        secondPart = substring(originalTitle, startIndex, endIndex);
        secondPart = trim(secondPart);
        // ------------------------------------------------------------

        saveAs("Tiff", saveDir + File.separator + secondPart + ".tif");
    }
}
