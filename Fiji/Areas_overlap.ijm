#@ File(label="Input file",value="?", persist=true) iInputFile
#@ File(label="Output directory",value="A:\\reinat\\Saar\\Images", style="directory", persist=true, description="dir") iOutDir
#@ Integer(label="C1 threshold",value="120", persist=true) iC1Threshold
#@ Integer(label="C2 threshold",value="150", persist=true) iC2Threshold
#@ Integer(label="C3 threshold",value="150", persist=true) iC3Threshold
#@ Integer(label="Min. Area size (pixel^2)",value="0", persist=true, description="smaller areas will be ignored") iMinAReaSize
#@ Boolean(label="Fill holes",value="False", persist=true, description="Weather or not to run tubeness before calculating directionality") iFillHoles
#@ Integer(label="From Slice",value="1", persist=true ) iFromSlice
#@ Integer(label="To Slice",value="-1", persist=true,  description="-1 for all slices until the end") iToSlice

var gResultsSubFolder = "Results";
var gResultTable = ""; gResultTable = File.getNameWithoutExtension(iInputFile)+"Results";
var gImsOpenParms = "autoscale color_mode=Default view=Hyperstack stack_order=XYCZT series_"; //bioImage importer auto-selection


setBatchMode(false);
Table.create(gResultTable);
ProcessFile(iInputFile);
waitForUser("------------------------------DONE!!!!!!!----------------");



function ProcessFile(fileFullPath) {
	print("File=",fileFullPath);
	directory = File.getDirectory(fileFullPath);
	resFolder = iOutDir + File.separator + gResultsSubFolder + File.separator; 
	File.makeDirectory(resFolder);
	run("Close All");
	openFile(fileFullPath);
	getDimensions(width, height, channels, slices, frames);
	getPixelSize(unit, pixelWidth, pixelHeight);

	//waitForUser("slices: "+slices);
	imageId = getImageID();
	//rename("image");
	roiManager("reset");
	while(roiManager("count") != 1){
		waitForUser("Please add an ROI around the disk (area in image that is of interest) - check that the ROI manager has that single ROI");
	}
	roiManager("select", 0);
	getStatistics(area, mean, min, max, std, histogram);
	print("Roi area ("+unit+"^2): "+area);
	if(iToSlice < 0){
		iToSlice = slices;
	}
	else{
		iToSlice = minOf(iToSlice+1,slices);
	}
	if(iFromSlice <= 0){
		iFromSlice = 1;
	}
	for(i=iFromSlice; i<iToSlice; i++){
		row = i-iFromSlice;
		Table.set("Slice number", row, i,gResultTable);
		c1Map = GetBinaryMask(imageId,i,1,iC1Threshold,iMinAReaSize,iFillHoles,0);
		countPixels(c1Map,gResultTable,row,"C1 area ("+unit+"^2)");
		c2Map = GetBinaryMask(imageId,i,2,iC2Threshold,iMinAReaSize,iFillHoles,0);
		countPixels(c2Map,gResultTable,row,"C2 area("+unit+"^2)");
		c3Map = GetBinaryMask(imageId,i,3,iC3Threshold,iMinAReaSize,iFillHoles,0);
		countPixels(c3Map,gResultTable,row,"C3 area("+unit+"^2)");

		c1c2Map = AND_ISCF(c1Map, GetTitle_ISCF(c1Map), GetTitle_ISCF(c2Map));
		countPixels(c1c2Map,gResultTable,row,"C1&C2 area("+unit+"^2)");

		c1c3Map = AND_ISCF(c1Map, GetTitle_ISCF(c1Map),GetTitle_ISCF(c3Map));
		countPixels(c1c3Map,gResultTable,row,"C1&C3 area("+unit+"^2)");
		
		c2c3Map = AND_ISCF(c1Map, GetTitle_ISCF(c2Map),GetTitle_ISCF(c3Map));
		countPixels(c2c3Map,gResultTable,row,"C2&C3 area("+unit+"^2)");
		
		c1c2c3Map = AND_ISCF(c1Map, GetTitle_ISCF(c1c2Map),GetTitle_ISCF(c3Map));
		countPixels(c1c2c3Map,gResultTable,row,"C1&C2&C3 area("+unit+"^2)");
	}
	Table.save(resFolder+gResultTable+".csv");
	run("Close All");
}
function AND_ISCF(imageId, t1, t2){
	imageCalculator("AND create",t1, t2);
	return getImageID();
}
function GetTitle_ISCF(imageId){
	selectImage(imageId);
	title = getTitle();
	return title;
}

function countPixels(imageId,table,rowIndex,columnName){
	getStatistics(area, mean, min, max, std, histogram);
	//waitForUser("area, mean, min, max, std, histogram"+area+","+mean+","+min+","+max+","+std+","+histogram[1]);
	Table.set(columnName, rowIndex, histogram[1]*pixelWidth*pixelHeight,table);
	Table.update(table);
	//waitForUser("check table");
}
function GetBinaryMask(imageId,slice,channel,threshold,minParticleSize,fillHolsInd,roiInd){
	selectImage(imageId);
	title = getTitle();
	run("Make Substack...", "channels="+channel+" slices="+slice);
	sliceImageId = getImageID();
	run("Select None");
	roiManager("deselect");
	if(roiInd >=0){
		roiManager("select", roiInd);
		run("Clear Outside");
		run("Select None");
		roiManager("deselect");
	}
	run("Manual Threshold...", "min="+threshold+" max=100000");
	analyzeParms = "size="+minParticleSize+"-Infinity show=Masks";
	if(fillHolsInd){
		analyzeParms += " include";
	}
	run("Analyze Particles...", analyzeParms);
	run("Divide...", "value=255");
	//waitForUser("check");
	rename("Mask of " + title + " channel_"+channel +" slice_"+ slice);
	return getImageID();
}
function openFile(fileFullPath)
{
	// ===== Open File ========================
	// later on, replace with a stack and do here Z-Project, change the message above
	if ( endsWith(fileFullPath, "h5") )
		run("Import HDF5", "select=["+fileFullPath+"] "+ gH5OpenParms);
	else if ( endsWith(fileFullPath, "ims") )
		run("Bio-Formats Importer", "open=["+fileFullPath+"] "+ gImsOpenParms);
	else if ( endsWith(fileFullPath, "nd2") )
		run("Bio-Formats Importer", "open=["+fileFullPath+"] autoscale color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
	else
		open(fileFullPath);
}
