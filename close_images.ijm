  // Close all images if any remain open
    while (nImages > 0) {
        selectImage(nImages);
        close();
    }
