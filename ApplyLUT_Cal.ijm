// Prompt the user to select a folder
dir = getDirectory("Choose a Directory");

// Get a list of all TIFF images in the folder
list = getFileList(dir);

for (i = 0; i < list.length; i++) {
    if (endsWith(list[i], ".tif") || endsWith(list[i], ".tiff")) {
        open(dir + list[i]);

        run("Duplicate...", "title=dup"); // Duplicate the projection
        
         // Set Brightness/Contrast range manually
        setMinAndMax(0, 255);
        
        //Stack.setChannel(c);
        run("Gaussian Blur...", "sigma=1");

        // Apply Fire LUT
        run("Fire");

        // Add Calibration Bar
        run("Calibration Bar...", "location=[Upper Right] fill=None label=White number=5 decimal=0 font=12 zoom=3 bold overlay");

        // Save with 'F_' prefix in the same directory
        filename = File.getName(list[i]);
        saveAs("Tiff", dir + "F_" + filename);

        // Close everything to clean up for the next image
        close(); // Close duplicate
        close(); // Close original if needed
    }
}
