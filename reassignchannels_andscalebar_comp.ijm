// Prompt user to select input directory
inputDir = getDirectory("Choose input directory");

// Prompt user to select save directory
saveDir = getDirectory("Choose save directory");

// Get the list of image files in the input directory
fileList = getFileList(inputDir);

// Process images from the input directory
processImagesFromFolder(fileList);

// Function to process images from the input directory
function processImagesFromFolder(fileList) {
    setBatchMode(true);
    
    for (i = 0; i < fileList.length; i++) {
        // Open the image file
        open(inputDir + fileList[i]);
        
        // Get the image title without extension
        originalTitle = getTitle();
        dotIndex = originalTitle.lastIndexOf(".");
        if (dotIndex > 0) {
            originalTitle = originalTitle.substring(0, dotIndex);
        }
        
        // Process the image
        //run("Make Composite");
        //Stack.setChannel(1);
       // run("Blue");
       // Stack.setChannel(2);
        //run("Red");
        //Stack.setChannel(3);
        //run("Grays");
        //Stack.setChannel(4);
       // run("Green");
      
        
         // Process the image
        //run("Make Composite");
        //Stack.setChannel(1);
        //run("Blue");
        //Stack.setChannel(2);
        //run("Magenta");
        //Stack.setChannel(3);
        //run("Green");
        //Stack.setChannel(4);
        //run("Red");
        //Stack.setChannel(5);
        //run("Grays");
        
        run("Make Composite");
        Stack.setChannel(1);
        run("Blue");
        Stack.setChannel(2);
        run("Green");
        Stack.setChannel(3);
        run("Red");
        Stack.setChannel(4);
        run("Grays");
        
        
        //This is for live imaging of slices
        //run("Make Composite");
       // Stack.setChannel(1);
        //run("Blue");
       // Stack.setChannel(2);
       // run("Yellow");
		//Stack.setChannel(3);
        //run("Red");

           // Add scale bar with consistent dimensions
        run("Scale Bar...", "width=1000 height=10 thickness=10 font=30 color=White background=None location=[Lower Right] bold overlay");

        // Save the processed image with the original title
        saveAs("Tiff", saveDir + File.separator + originalTitle + ".tif");
        close();
    }
    
    setBatchMode(false);
    showMessage("Processing complete!");
}
