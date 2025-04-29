// Duplicate all image files. Select and work with duplicates directory to perserve raw data
// When performing the experiments, make sure 488 is the vglut3 positive control
// Make sure split channels on the initial pop up (import configuration window) is not checked
// URL to add adaptiveThr to plugins: https://sites.imagej.net/adaptiveThreshold/

//to count number of images in original folder and set folders directories
OrigDir=getDirectory("Select folder with deconvolved images to quantify.");
print("Working folder is: ", OrigDir);
vglut3SaveDir=getDirectory("Select folder for saved channel 1 images.");
print("channel 1 folder is: ", vglut3SaveDir);
chrna9SaveDir=getDirectory("Select folder for saved channel 2 images.");
print("channel 2 folder is: ", chrna9SaveDir);
ResultsDir=getDirectory("Select folder to store results.");
print("Results folder is: ", ResultsDir);
olist=getFileList(OrigDir);
m=lengthOf(olist);
print("The number of images to define ROI is: "+m);

// from here to end: to loop through analyzing
for(i = 0; i < m; i++){
    open(OrigDir+olist[i]);
    close("\\Others");
Name = getTitle();
// CleanName = replace(Name, "\ -\ Deconvolved\ 20\ iterations,\ Type\ Blind.nd2", "");
run("Duplicate...", "title=NM duplicate hyperstack"); 
    
// process vglut3 channel
run("Split Channels");
selectWindow("C1-NM");
vglut3 = getTitle();
run("Z Project...", "projection=[Max Intensity]");
run("Subtract Background...", "rolling=75 stack"); // 75 rolling ball manually selected so background pixels become roughly 0
saveAs("tiff", vglut3SaveDir + File.separator + "channel1_puncta_" + Name + ".tif");

// use ROI manager to collect NM shape based on vglut3 image
	if (i >= 1){
	open(ResultsDir + File.separator + "NMRoiSet.zip");
	roiManager("Show None"); // to prevent roiManager from applying all ROI in list at start of every loop
	}else {
		run("ROI Manager...");
	}
setTool("freehand");
waitForUser("Draw ROI around NM");
roiManager("Add");
roiName = call("ij.plugin.frame.RoiManager.getName", i); // gets the name of the last drawn NM roi
roiManager("Select", i);
roiManager("rename", Name); // names the ROI with the image title
roiNewName = call("ij.plugin.frame.RoiManager.getName", i);
print("ROI name changed from " + roiName + " to " + roiNewName);
roiManager("Save", ResultsDir + File.separator + "NMRoiSet.zip");
close("ROI Manager");

// process chrna9 channel
selectWindow("C2-NM");
chrna9 = getTitle();
run("Z Project...", "projection=[Max Intensity]");
run("Subtract Background...", "rolling=75 stack");
saveAs("tiff", chrna9SaveDir + File.separator + "channel2_puncta_" + Name + ".tif");

close( Name );
close( chrna9 );
close( vglut3 );

/*

close("*");

// alt idea for processing where all roi are collected and subsequently applied to images we sequentially open
// applies the previously drawn roi onto open images (vlgut3 and chrna9)
slist=getFileList(SaveDir);
p=lengthOf(slist);
print("The number of images to quantify is: "+p);
for (j = 0; j < p; j++) {
	open(SaveDir+slist[j]);
	close("\\Others");
	openimage=getTitle();
	openimage.matches(s2)
	if (matches(title, ".*40x.*")) {
	roiManager.selectByName(name); 
	roiManager("Select", j);
	for (i = 0; i < Fpoints.length; i++) {
    print(Fpoints[i]);
}
	index(CleanNameArray) //not real code lol
}

*/

// applies ROI drawn earlier onto both vglut3 and chrna9 images sequentially and quantifies puncta counts to csv
imgs = getList("image.titles");
print("Number of images open:" + imgs.length);
for (j = 0; j < imgs.length; j++) {
print("Open image: "+imgs[j]);
selectImage( imgs[j] );
imgsjname = getTitle();
imgsjname2 = replace(imgsjname, ".tif", "");
open(ResultsDir + File.separator + "NMRoiSet.zip");
roiManager("Show None"); // important to have otherwise imagej will ask if you want to save an overlay of all the roi's on top of the image
roicount  = roiManager("count");
	if (roicount == 1) {
		roiManager("select", 0);
	}else {
		roiManager("select", roicount -1); // selects the last roi in list because total length of list minus 1. 0 is first image
		}
	close("ROI Manager");
	run("Clear Outside");
	run("8-bit");
	run("adaptiveThr ", "using=[Weighted mean] from=3 then=-4"); // chosen based on manual testing of vglut3
	run("Watershed");
	run("Analyze Particles...", "size=0.025 circularity=0.1-1 display clear summarize overlay add"); // chosen based on Kindt publications
	// setResult("Fish", i, CleanName);
	// setResult("HC", i+1, part);
	// saveAs("results", ResultsDir + File.separator + imgsjname2 + "_intensity_results.xls");
	// run("Clear Results");
	roiManager("reset");
	
	}
close("*");
}
Table.rename("Summary", "Results");
saveAs("results", ResultsDir + File.separator + "_puncta_results.csv");

// getValue("results.count")
// Returns the number of lines in the current results table. Unlike nResults, works with tables that are not named "Results".
// look at print(string) function in imagej ref
// look at setResults function


// all done! now just save log and close everything
waitForUser("Save the Log file to maintain record of image processing/quantification.");
run("Close All");


