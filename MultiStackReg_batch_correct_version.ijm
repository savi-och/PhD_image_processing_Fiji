// Macro: MultiStackReg Batch Processing with Channel Split and Registration
// This macro processes multi-channel time-lapse images one at a time
// with user confirmation between files

macro "MultiStackReg Batch Processing" {
    
    // ===== STEP 1: Select source images and setup directories =====
    sourceDir = getDirectory("Choose folder containing your multi-channel images");
    if (sourceDir == "") exit("No source directory selected.");
    
    // Get list of TIFF files from source
    sourceList = getFileList(sourceDir);
    sourceTiffFiles = newArray();
    
    // Filter for TIFF files only
    for (i = 0; i < sourceList.length; i++) {
        if (endsWith(sourceList[i], ".tif") || endsWith(sourceList[i], ".tiff")) {
            sourceTiffFiles = Array.concat(sourceTiffFiles, sourceList[i]);
        }
    }
    
    if (sourceTiffFiles.length == 0) {
        exit("No TIFF files found in the selected folder.\nPlease select a folder containing .tif or .tiff files.");
    }
    
    print("\\Clear");
    print("=== MultiStackReg Batch Processing ===");
    print("Source directory: " + sourceDir);
    print("Found " + sourceTiffFiles.length + " TIFF file(s)");
    print("");
    
    // Ask user where to create the project folder structure
    mainDir = getDirectory("Choose where to create the output project folder");
    if (mainDir == "") exit("No output directory selected.");
    
    // Create folder structure
    originalDir = mainDir + "01_Original/";
    splitDir = mainDir + "02_Split_Channels/";
    matrixDir = mainDir + "03_Matrices/";
    registeredDir = mainDir + "04_Registered/";
    mergedDir = mainDir + "05_Merged/";
    
    File.makeDirectory(originalDir);
    File.makeDirectory(splitDir);
    File.makeDirectory(matrixDir);
    File.makeDirectory(registeredDir);
    File.makeDirectory(mergedDir);
    
    print("Output folder structure created:");
    print("  01_Original: " + originalDir);
    print("  02_Split_Channels: " + splitDir);
    print("  03_Matrices: " + matrixDir);
    print("  04_Registered: " + registeredDir);
    print("  05_Merged: " + mergedDir);
    print("");
    
    // ===== STEP 2: Copy TIFF files to 01_Original =====
    print("Copying images to 01_Original/...");
    tiffFiles = newArray();
    
    for (i = 0; i < sourceTiffFiles.length; i++) {
        sourceFile = sourceDir + sourceTiffFiles[i];
        destFile = originalDir + sourceTiffFiles[i];
        
        // Copy file
        File.copy(sourceFile, destFile);
        
        if (File.exists(destFile)) {
            tiffFiles = Array.concat(tiffFiles, sourceTiffFiles[i]);
            print("  Copied: " + sourceTiffFiles[i]);
        } else {
            print("  WARNING: Failed to copy " + sourceTiffFiles[i]);
        }
    }
    
    print("");
    print(tiffFiles.length + " file(s) ready for processing.");
    print("");
    
    // ===== STEP 3: Process each file with user confirmation =====
    for (fileIdx = 0; fileIdx < tiffFiles.length; fileIdx++) {
        
        currentFile = tiffFiles[fileIdx];
        print("--- Processing file " + (fileIdx + 1) + " of " + tiffFiles.length + " ---");
        print("File: " + currentFile);
        
        // Ask user if they want to process this file
        //Dialog.create("Process File?");
       //Dialog.addMessage("Ready to process:\n" + currentFile);
        //Dialog.addMessage("File " + (fileIdx + 1) + " of " + tiffFiles.length);
        //Dialog.addChoice("Action:", newArray("Process this file", "Skip this file", "Stop processing"));
        //Dialog.show();
        
        //action = Dialog.getChoice();
        
        //if (action == "Stop processing") {
            //print("Processing stopped by user.");
           // break;
      //  }
        
        //if (action == "Skip this file") {
           // print("Skipped by user.");
           // print("");
           // continue;
        //}
        
        // Get base filename without extension
        baseName = replace(currentFile, ".tif", "");
        baseName = replace(baseName, ".tiff", "");
        
        // ===== STEP 4: Open and detect number of channels =====
        print("Opening image...");
        open(originalDir + currentFile);
        
        // Detect number of channels
        getDimensions(width, height, channels, slices, frames);
        print("Detected " + channels + " channel(s)");
        
        // Determine reference channel based on number of channels
        if (channels == 3) {
            refChannel = 2; // C2 for 3-channel images
            print("Using C2 as reference channel (3-channel image)");
        } else if (channels >= 4) {
            refChannel = 3; // C3 for 4+ channel images
            print("Using C3 as reference channel (4-channel image)");
        } else {
            print("ERROR: Image has fewer than 3 channels. Skipping.");
            close("*");
            continue;
        }
        
        // Check if image is open
        if (nImages == 0) {
            print("ERROR: Could not open " + currentFile);
            continue;
        }
        
        print("Splitting channels...");
        run("Split Channels");
        
        // Save split channels - only save channels that exist
        availableChannels = newArray();
        
        for (c = 1; c <= channels; c++) {
            channelWindow = "C" + c + "-" + currentFile;
            
            if (isOpen(channelWindow)) {
                selectWindow(channelWindow);
                saveAs("Tiff", splitDir + "C" + c + "-" + baseName + ".tif");
                print("  Saved: C" + c + "-" + baseName + ".tif");
                availableChannels = Array.concat(availableChannels, c);
            }
        }
        
        // Close all to prepare for registration
        close("*");
        
        
// ===== STEP 5: Run MultiStackReg on reference channel =====
        print("Running MultiStackReg on C" + refChannel + " (reference channel)...");
        
        refChannelFile = "C" + refChannel + "-" + baseName + ".tif";
        open(splitDir + refChannelFile);
        
        // Define matrix filename
        matrixFile = matrixDir + "matrix-" + baseName + ".txt";
        
        // Run MultiStackReg with Affine transformation
        run("MultiStackReg", 
            "stack_1=[" + refChannelFile + "]" +
            " action_1=Align" +
            " file_1=[" + matrixFile + "]" +
            " stack_2=None" +
            " action_2=Ignore" +
            " file_2=[]" +
            " transformation=Affine" +
            " save");
        
        print("  Transformation matrix saved: matrix-" + baseName + ".txt");
        
        // Save registered reference channel
        saveAs("Tiff", registeredDir + "C" + refChannel + "-" + baseName + "_registered.tif");
        close();
        
        
        // ===== STEP 6: Apply transformation to other channels =====
        print("Applying transformation to other channels...");
        
        for (c = 0; c < availableChannels.length; c++) {
            channelNum = availableChannels[c];
            
            // Skip the reference channel (already registered)
            if (channelNum == refChannel) continue;
            
            channelFile = "C" + channelNum + "-" + baseName + ".tif";
            channelPath = splitDir + channelFile;
            
            if (File.exists(channelPath)) {
                open(channelPath);
                
                run("MultiStackReg", 
                    "stack_1=[" + channelFile + "]" +
                    " action_1=[Load Transformation File]" +
                    " file_1=[" + matrixFile + "]" +
                    " stack_2=None" +
                    " action_2=Ignore" +
                    " file_2=[]" +
                    " transformation=Affine");
                
                // Save registered channel
                saveAs("Tiff", registeredDir + "C" + channelNum + "-" + baseName + "_registered.tif");
                print("  Registered: C" + channelNum + "-" + baseName);
                close();
            } else {
                print("  WARNING: " + channelFile + " not found, skipping.");
            }
        }
        
        // ===== STEP 7: Merge registered channels =====
        print("Merging registered channels...");
        
        // Build list of registered channels that exist
        registeredChannels = newArray();
        
        for (c = 0; c < availableChannels.length; c++) {
            channelNum = availableChannels[c];
            regFile = registeredDir + "C" + channelNum + "-" + baseName + "_registered.tif";
            
            if (File.exists(regFile)) {
                open(regFile);
                registeredChannels = Array.concat(registeredChannels, channelNum);
            } else {
                print("  WARNING: Registered C" + channelNum + " not found, skipping from merge.");
            }
        }
        
        if (registeredChannels.length == 0) {
            print("  ERROR: No registered channels found to merge!");
        } else {
            // Build merge command with proper color assignments
            // For 4-channel: C1=blue, C2=green, C3=red, C4=gray
            // For 3-channel: C1=green, C2=red, C3=gray
            
            mergeCommand = "";
            
            if (channels == 4) {
                // 4-channel color mapping: C1→blue, C2→green, C3→red, C4→gray
                for (c = 0; c < registeredChannels.length; c++) {
                    channelNum = registeredChannels[c];
                    if (channelNum == 1) {
                        mergeCommand += "c3=[C1-" + baseName + "_registered.tif] "; // C1 → blue (c3)
                    } else if (channelNum == 2) {
                        mergeCommand += "c2=[C2-" + baseName + "_registered.tif] "; // C2 → green (c2)
                    } else if (channelNum == 3) {
                        mergeCommand += "c1=[C3-" + baseName + "_registered.tif] "; // C3 → red (c1)
                    } else if (channelNum == 4) {
                        mergeCommand += "c4=[C4-" + baseName + "_registered.tif] "; // C4 → gray (c4)
                    }
                }
            } else if (channels == 3) {
                // 3-channel color mapping: C1→green, C2→red, C3→gray
                for (c = 0; c < registeredChannels.length; c++) {
                    channelNum = registeredChannels[c];
                    if (channelNum == 1) {
                        mergeCommand += "c2=[C1-" + baseName + "_registered.tif] "; // C1 → green (c2)
                    } else if (channelNum == 2) {
                        mergeCommand += "c1=[C2-" + baseName + "_registered.tif] "; // C2 → red (c1)
                    } else if (channelNum == 3) {
                        mergeCommand += "c4=[C3-" + baseName + "_registered.tif] "; // C3 → gray (c4)
                    }
                }
            }
            
            mergeCommand += "create";
            
            print("  Merging " + registeredChannels.length + " channel(s) with color mapping...");
            run("Merge Channels...", mergeCommand);
            
            // Save merged image
            saveAs("Tiff", mergedDir + baseName + "_merged_registered.tif");
            print("  Merged image saved: " + baseName + "_merged_registered.tif");
            close();
        }
        
        print("Successfully processed: " + currentFile);
        print("");
    }
    
    print("=== Processing Complete ===");
    print("Total files processed: " + tiffFiles.length);
    print("Check output folders for results.");
}