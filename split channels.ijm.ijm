// Macro: Process Images with ROI and Split Channels
macro "Process Images with ROI and Split Channels" {
    // Ask user to select the input directory
    inputDir = getDirectory("Choose Input Directory");
    if (inputDir == "null") exit("No input directory selected.");

    // Ask user to select the output directory
    outputDir = getDirectory("Choose Output Directory");
    if (outputDir == "null") exit("No output directory selected.");

    // Create subfolders for channels
    channel1Dir = outputDir + "Channel1/";
    File.makeDirectory(channel1Dir);

    // Get the list of all files in the input directory
    list = getFileList(inputDir);

    // Loop through all files in the directory
    for (i = 0; i < list.length; i++) {
        filePath = inputDir + list[i];
        if (File.isDirectory(filePath)) continue; // Skip subdirectories

        // Open the image
        open(filePath);

        // Ensure the image window is active
        selectWindow(list[i]); // Explicitly select the opened image window
 
 // Split channels
        run("Split Channels");

        // Save each channel in its corresponding folder
        selectWindow("C1-" + list[i]);
        saveAs("Tiff", channel1Dir + "C1-" + list[i]);
        close();
        
        selectWindow("C2-" + list[i]);
        saveAs("Tiff", channel1Dir + "C2-" + list[i]);
        close();
// or channel 4 for sytox
        selectWindow("C3-" + list[i]);
        saveAs("Tiff", channel1Dir + "C3-" + list[i]);
        close();
        
// or channel 5 for grays
       selectWindow("C4-" + list[i]);
       saveAs("Tiff", channel1Dir + "C4-" + list[i]);
       close();
        
        // Close original image if still open
        if (isOpen(list[i])) close();
    }

    // Print final message
    print("Processing complete. Channels saved to: " + outputDir);
}
