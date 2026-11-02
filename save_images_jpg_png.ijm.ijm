// Prompt user for output directory
outputDir = getDirectory("Choose output directory");

// Prompt user for file format (JPG or PNG)
Dialog.create("File Format");
Dialog.addMessage("Choose the file format for saving the images:");
Dialog.addChoice("Format:", newArray("JPG", "PNG"), "JPG");
Dialog.show();

fileFormat = "." + Dialog.getChoice();

// Get the list of open windows
ids = getList("image.titles");

// Iterate over each open image
for (i = 0; i < ids.length; i++) {
    selectWindow(ids[i]);
    // Save the image with its original title and the chosen file format
    saveAs(fileFormat, outputDir + File.separator + ids[i] + fileFormat);
}

print("All images saved successfully!");