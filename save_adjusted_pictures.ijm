// Prompt user to select the save directory
saveDir = getDirectory("Choose directory to save images");

// Loop through all open images and save them
for (i = 1; i <= nImages; i++) {
    selectImage(i);
    
    // Get the current image title
    title = getTitle();
    
    // Remove extension from title
    dotIndex = lastIndexOf(title, ".");
    if (dotIndex > 0) {
        title = substring(title, 0, dotIndex);
    }
    
    // Construct the save path
    savePath = saveDir + File.separator + title + "_adjusted.tif";
    
    // Save the image
    saveAs("Tiff", savePath);
    
    print("Saved image: " + savePath);
}

showMessage("All open images have been saved.");


// Close all images if any remain open
  //  while (nImages > 0) {
     //   selectImage(nImages);
     //   close();
    //}