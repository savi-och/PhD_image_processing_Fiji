// Prompt the user to select a folder
dir = getDirectory("Choose a Directory");

// Get a list of all TIFF images in the folder
list = getFileList(dir);

for (i = 0; i < list.length; i++) {
    if (endsWith(list[i], ".tif") || endsWith(list[i], ".tiff")) {
        open(dir + list[i]);

        

        // Apply Fire LUT
        run("Red");

        
          // Add scale bar with consistent dimensions
        run("Scale Bar...", "width=100 height=10 thickness=30 font=40 color=White background=None location=[Lower Right] bold overlay");

        // Save with 'F_' prefix in the same directory
        filename = File.getName(list[i]);
        saveAs("Tiff", dir + "R_" + filename);

        // Close everything to clean up for the next image
        close(); // Close original if needed
    }
}
