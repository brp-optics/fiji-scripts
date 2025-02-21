// ImageJ script to roughly measure the flatness of a microscope field
// by comparing the mean "inner" and "outer" intensities.
// Inner is defined by a 1/4-FOV central rectangle, outer by its inverse.
// Analysis is separate. 
// I found that the outer/inner average converges to 1 at higher zooms 
// on our well-calibrated laser scanning microscopes. 
// (Where zoom defines the FOV of the scanned area.)
// Analysis will be incorporated in a later python version
// of this script.

// The method here is primitive.
// A better method might look at the radial distribution outward 
// from the center-of-mass point.
// But this is good enough to compare our microscope systems, 
// and is much easier to implement in the ImageJ macro environment.

// BRP, 2025.02.20


inputDir = getDirectory("Input directory");
suffix = getString("File suffix", ".ome.tif");

function measureFlatness(imagePath) {
    open(imagePath);
    
    // Bookkeeping so we can close images and stack duplicates later
    opened = newArray(1);
    opened[0] = getImageID();
    
    if (nSlices>1){ // We have an image stack. Use the second image.
    	run("Duplicate...", "duplicate range=2 use");
		
		opened2 = newArray(1);
    	opened2[0] = getImageID();
    	opened = Array.concat(opened, opened2);
    	
    	run("Duplicate...", "use");
    	opened2[0] = getImageID();
    	opened = Array.concat(opened, opened2);
    };
    run("Set Measurements...", "area mean modal min center area_fraction display redirect=None decimal=3");
    w = getWidth();
    h = getHeight();
    
    // We scale the width of the blur with the pixel size
    // to keep the physical size of the blur constant.
    // sig=40 works well to remove dirt in my images,
    // which are 512 pix x 512 pix on a 20x Obj.
    
    // Get pixel dimensions and unit
	getPixelSize(scaleUnit, pixelWidth, pixelHeight);
	
	if (scaleUnit=="microns"){
        sig = 40*(1/2.1991)/pixelWidth; 
	} else {
		print("Unrecognized scale unit: " + scaleUnit + " at line 26 in measureCentration2.");
	};
	run("Gaussian Blur...", "sigma=" + sig);
	makeRectangle(w/4, h/4, w/2, h/2);

    imageTitle = getTitle();
    run("Measure");
    setResult("Label", nResults-1, imageTitle + " Inner");
    run("Invert");
    run("Measure");
    setResult("Label", nResults-1, imageTitle + " Outer");
    saveAs("Results", imagePath + "_results.csv");
    
    // Close all the opened image file (duplicates), and nothing else:
    for (i = 0; i < opened.length; i++) {
    	ID = opened[i];
    	selectImage(ID);
    	close();
    };
};

function processDirectory(directory, suffix) { 
    list = getFileList(directory);
	
    for (i = 0; i < list.length; i++) {
	    path = directory + list[i];
        if (File.isDirectory(path)) {
            processDirectory(path, suffix);  // Recursive call for subdirectory
        } else {
            // Limit processing to files of the user-specified suffix. 
            if (endsWith(list[i], suffix)) {
                measureFlatness(path);
            };
        };
    };
 };

setBatchMode("hide");

processDirectory(inputDir, suffix);

setBatchMode("show");