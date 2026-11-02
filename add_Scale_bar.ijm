  // Loop through all open images and save them
for (i = 1; i <= nImages; i++) {
    selectImage(i);
  
  // Add scale bar with consistent dimensions
        run("Scale Bar...", "width=1000 height=10 thickness=30 font=80 color=White background=None location=[Lower Right] bold overlay");
}