// Define the input and output directories
#@ File[] (label = "Choose Files to Analyze:", style = "open", extensions = {"txt", "img"}) inputFiles


#@ File (label = "Save Results To:", style = "directory") outputDir
#@ File (label = "Save Images To:", style = "directory") ImageOutputDir
#@ File (label = "Save ROIs To:", style = "directory") RoiOutputDir


Dialog.create("Channels in Chosen Images");
Dialog.addChoice("Do all chosen files contain the same channels?", newArray("Yes","No"));
Dialog.show();


//////////////////////////////////////////////

YesOrNo = Dialog.getChoice();
var gResultsTable = "Results.csv";
var gTableRow = 0;
var OrigChannels;
var isGal4Present = "False";
var customGal4Name;
var NumChannels;
var channelChoices = newArray();
var AllROIs;
var Gal4ChannelNumber;
var DapiChannelNumber;
var ChanneltoIgnoreNumber;
var channelChoicesFirstFile = newArray();
var isGal4PresentFirstFile;
var Gal4ChannelNumberFirstFile;
var DapiChannelNumberFirstFile;
var ChanneltoIgnoreNumberFirstFile;
var customGal4NameFirstFile;

setBackgroundColor(0, 0, 0);
//close("*");
run("Clear Results");
roiManager("reset");
run("Select None");
close("Results.csv");
Table.create(gResultsTable);

//CALLING FUNCTIONS

processFiles(inputFiles);

getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
ResTable = "Results_("+replace(d2s(year, 0),"20","")+d2s(month+1, 0)+d2s(dayOfMonth, 0)+"_"+hour+"-"+minute+").csv";

Table.rename(gResultsTable, ResTable);


selectWindow(ResTable);
Table.save(outputDir + File.separator + ResTable);

TempResPath = outputDir + File.separator + gResultsTable;

File.delete(TempResPath);
//close("*");

waitForUser("=========================DONE!======================");
////////////////////////////////////////////

// function to scan folders/subfolders/files to find files with correct suffix
// a function called "processFolder" and it takes 1 argument which is "InputDirectory". when it is called, it will use "inputDir"

function processFiles(InputDirectory) {
	// Initialize gTableRow outside the loop
    //Cont = true;
    
    			// If the user rejects the result, loop back to the thresholding step
   				//while(Cont) {
	for (i = 0; i < inputFiles.length; i++) {
		if (endsWith(inputFiles[i], ".ims")) {
			run("Close All");
			roiManager("reset");
			run("Clear Results");
			// Open the current file using Bio-Formats Importer and select series 1
			run("Bio-Formats Importer", "open=[" + inputFiles[i] + "] autoscale color_mode=Default view=Hyperstack stack_order=XYCZT series=1");
			
			ImageName = File.name ();
			ImageName = replace(ImageName,".ims","");
			rename(ImageName);
			
			SingleResultsTable = "Results_"+ImageName+".csv";
			Table.create(SingleResultsTable);
			SingleTableRow = 0;
			
			//save the path and file in table
			//Table.set("File Name",gTableRow,ImageName,gResultsTable);
			isGal4Present = "False";
			customGal4Name = "";
			OrigChannels = newArray();
			channelChoices = newArray();
			AllROIs = newArray();
			
			selectWindow(ImageName);
			
			if (((YesOrNo == "Yes") && (i == 0)) || (YesOrNo == "No")) {
			identifyChannel(ImageName);
			}
			else {
			identifyChannel2(ImageName);
			}
			
			defineWD(ImageName);
			
			processChannel();
			close("SideBySide");
			
			saveROI();
						
			comboROI();		
			
			finalROI(AllROIs, isGal4Present);
			
			
			selectWindow("MAX_"+ImageName);
  			saveAs("TIFF", ImageOutputDir + File.separator + "MAX_"+ImageName + ".tiff");
			roiManager("Select", newArray());
			run("Select All");
			roiManager("Save", RoiOutputDir + File.separator + ImageName +"_RoiSet" + ".zip");
			selectWindow(SingleResultsTable);
			Table.save(outputDir + File.separator + SingleResultsTable );
			
			
			selectWindow(gResultsTable);
			Table.save(outputDir + File.separator + gResultsTable);
			
			close(SingleResultsTable);
			close("Log");
			close("Results");
			close(SingleResultsTable);
			
		}
	}
}
/////////

// a function called "identifyChannel" and it takes 1 argument which is derived from the previous function (processFile) which redirects to the initial function (processFolder).
// therefore, file == inputFilesList[i]
function identifyChannel(file) {
	
Gal4ChannelNumber = 0;
DapiChannelNumber = 0;
ChanneltoIgnoreNumber = 0;
	// Get stack dimentions and set the middle slice
	getDimensions(w, h, channels, slices, frames);
	Stack.setPosition(channels, 0.5*slices, frames);
	// Check if the image is a stack
	//channelChoices[0] = "WD";
	if (slices > 1) {
		// Get number of channels
		NumChannels = channels;
		//(NumChannels);
		// Create an array to store the choices for the channels
Table.set("File Name", gTableRow, ImageName, gResultsTable);


Table.set("Channels",gTableRow,"",gResultsTable);
Table.set("",gTableRow,"",gResultsTable);
                       
Table.set("ROI", gTableRow, "", gResultsTable);
            
Table.set("Area (um^2)", gTableRow, "", gResultsTable);
Table.set("Perimiter (um)", gTableRow, "", gResultsTable);
Table.set("*", gTableRow, "*", gResultsTable);
Table.set("Mean Gray Value", gTableRow, "", gResultsTable);
Table.set("StdDev", gTableRow, "", gResultsTable);
Table.set("Min", gTableRow, "", gResultsTable);
Table.set("Max", gTableRow, "", gResultsTable);
			gTableRow++;
			
			
Table.set("File Name", SingleTableRow, ImageName, SingleResultsTable);


Table.set("Channels",SingleTableRow,"",SingleResultsTable);
Table.set("",SingleTableRow,"",SingleResultsTable);
                       
Table.set("ROI", SingleTableRow, "", SingleResultsTable);
            
Table.set("Area (um^2)", SingleTableRow, "", SingleResultsTable);
Table.set("Perimiter (um)", SingleTableRow, "", SingleResultsTable);
Table.set("*", SingleTableRow, "*", SingleResultsTable);
Table.set("Mean Gray Value", SingleTableRow, "", SingleResultsTable);
Table.set("StdDev", SingleTableRow, "", SingleResultsTable);
Table.set("Min", SingleTableRow, "", SingleResultsTable);
Table.set("Max", SingleTableRow, "", SingleResultsTable);
			SingleTableRow++;
			
		for (c = 1; c <= NumChannels; c++) {
			selectWindow(ImageName);
			Stack.setChannel(c);
			run("Enhance Contrast", "saturated=0.35");
			Dialog.create("Choose Channel Identity");
			Dialog.addMessage("Choose what channel " + c + " represents:");
			Dialog.addChoice("Channel " + c + ":", newArray("Channel " + c,"Gal4", "cDCP1", "cPARP", "TUNEL", "LysoTracker", "Dapi/Hoechst/Phalloidin", "G-trace_Green", "G-Trace_Red", "DBS", "DBS_Green", "DBS_Red", "-Channel to Ignore-", "Other"));
			Dialog.show();
			
			Choice = Dialog.getChoice();
				if (Choice == "Other") {
					Dialog.create("Custom Channel");
					Dialog.addString("Enter Custom Channel Name:", "", 20); 
					Dialog.show();
					customChannelName = Dialog.getString();
					channelChoices[c-1] = customChannelName;
					
					}
				else if (Choice == "Dapi/Hoechst/Phalloidin") {
					channelChoices[c-1] = Choice;
					DapiChannelNumber = c;
					
					
					}
				else if (Choice == "-Channel to Ignore-") {
					channelChoices[c-1] = Choice;
					ChanneltoIgnoreNumber = c;
					
					
					}
				else if (Choice == "Gal4") {
					Dialog.create("Custom Gal4 Channel");
					Dialog.addString("Enter Custom Gal4 Driver Name:", "", 20); 
					Dialog.show();
					customGal4Name = Dialog.getString();
					channelChoices[c-1] = customGal4Name;
					isGal4Present = "True";
					Gal4ChannelNumber = c;
				
					}
				else {
					channelChoices[c-1] = Choice;
					}
			
			
			// Store the choice in the array
			print("Channel " + c + " Choice:", channelChoices[c-1]);
			
			

			run("Duplicate...", "duplicate channels="+c);
			rename(channelChoices[c-1]);
			Stack.getStatistics(voxelCount, mean, min, max, stdDev);
			setMinAndMax(1*min, 3*mean);
			run("8-bit");
			run("Z Project...", "projection=[Max Intensity]");
			rename(channelChoices[c-1]+"_8-bit");
			//run("Enhance Contrast", "saturated=0.35");
			close(channelChoices[c-1]);
			selectWindow(ImageName);
			Stack.setChannel(c);
			setMinAndMax(1*min, 3*mean);
			//run("Enhance Contrast", "saturated=0.35");	
			}
			selectWindow(ImageName);
			run("Z Project...", "projection=[Max Intensity]");
			rename("MAX_"+ImageName);
			}
OrigChannels = channelChoices;			


		if (isGal4Present == "True") {
			preChannels = newArray("WD", customGal4Name);
			channelChoices = Array.deleteValue(channelChoices, "Dapi/Hoechst/Phalloidin");
			channelChoices = Array.deleteValue(channelChoices, "-Channel to Ignore-");
			channelChoices = Array.deleteValue(channelChoices, customGal4Name);
			channelChoices = Array.concat(preChannels, channelChoices);
			}
		else {
			preChannels = newArray("WD");
			channelChoices = Array.deleteValue(channelChoices, "Dapi/Hoechst/Phalloidin");
			channelChoices = Array.deleteValue(channelChoices, "-Channel to Ignore-");
			channelChoices = Array.concat(preChannels, channelChoices);
		}
AllROIs = channelChoices;

channelChoicesFirstFile = OrigChannels;
isGal4PresentFirstFile = isGal4Present;
Gal4ChannelNumberFirstFile = Gal4ChannelNumber;
DapiChannelNumberFirstFile = DapiChannelNumber;
ChanneltoIgnoreNumberFirstFile = ChanneltoIgnoreNumber;
customGal4NameFirstFile = customGal4Name;
//print("3");
//waitForUser("===pause_3===");
			
return channelChoices;
}


//////////////////////////////////////////


// a function called "identifyChannel" and it takes 1 argument which is derived from the previous function (processFile) which redirects to the initial function (processFolder).
// therefore, file == inputFilesList[i]
function identifyChannel2(file) {
	
channelChoices = channelChoicesFirstFile;
isGal4Present = isGal4PresentFirstFile;
Gal4ChannelNumber = Gal4ChannelNumberFirstFile;
DapiChannelNumber = DapiChannelNumberFirstFile;
ChanneltoIgnoreNumber = ChanneltoIgnoreNumberFirstFile;
customGal4Name = customGal4NameFirstFile;


	// Get stack dimentions and set the middle slice
	getDimensions(w, h, channels, slices, frames);
	Stack.setPosition(channels, 0.5*slices, frames);
	// Check if the image is a stack
	//channelChoices[0] = "WD";
	if (slices > 1) {
		// Get number of channels
		NumChannels = channels;
		//(NumChannels);
		// Create an array to store the choices for the channels
Table.set("File Name", gTableRow, ImageName, gResultsTable);


Table.set("Channels",gTableRow,"",gResultsTable);
Table.set("",gTableRow,"",gResultsTable);
                       
Table.set("ROI", gTableRow, "", gResultsTable);
            
Table.set("Area (um^2)", gTableRow, "", gResultsTable);
Table.set("Perimiter (um)", gTableRow, "", gResultsTable);
Table.set("*", gTableRow, "*", gResultsTable);
Table.set("Mean Gray Value", gTableRow, "", gResultsTable);
Table.set("StdDev", gTableRow, "", gResultsTable);
Table.set("Min", gTableRow, "", gResultsTable);
Table.set("Max", gTableRow, "", gResultsTable);
			gTableRow++;
			
			
Table.set("File Name", SingleTableRow, ImageName, SingleResultsTable);


Table.set("Channels",SingleTableRow,"",SingleResultsTable);
Table.set("",SingleTableRow,"",SingleResultsTable);
                       
Table.set("ROI", SingleTableRow, "", SingleResultsTable);
            
Table.set("Area (um^2)", SingleTableRow, "", SingleResultsTable);
Table.set("Perimiter (um)", SingleTableRow, "", SingleResultsTable);
Table.set("*", SingleTableRow, "*", SingleResultsTable);
Table.set("Mean Gray Value", SingleTableRow, "", SingleResultsTable);
Table.set("StdDev", SingleTableRow, "", SingleResultsTable);
Table.set("Min", SingleTableRow, "", SingleResultsTable);
Table.set("Max", SingleTableRow, "", SingleResultsTable);
			SingleTableRow++;
			
		for (c = 1; c <= NumChannels; c++) {
			selectWindow(ImageName);
			Stack.setChannel(c);
			run("Enhance Contrast", "saturated=0.35");
			
					
			// Store the choice in the array
			print("Channel " + c + " Choice:", channelChoices[c-1]);
			
			

			run("Duplicate...", "duplicate channels="+c);
			rename(channelChoices[c-1]);
			Stack.getStatistics(voxelCount, mean, min, max, stdDev);
			setMinAndMax(1*min, 3*mean);
			run("8-bit");
			run("Z Project...", "projection=[Max Intensity]");
			rename(channelChoices[c-1]+"_8-bit");
			//run("Enhance Contrast", "saturated=0.35");
			close(channelChoices[c-1]);
			selectWindow(ImageName);
			Stack.setChannel(c);
			setMinAndMax(1*min, 3*mean);
			//run("Enhance Contrast", "saturated=0.35");	
			}
			selectWindow(ImageName);
			run("Z Project...", "projection=[Max Intensity]");
			rename("MAX_"+ImageName);
			}
OrigChannels = channelChoices;			


		if (isGal4Present == "True") {
			preChannels = newArray("WD", customGal4Name);
			channelChoices = Array.deleteValue(channelChoices, "Dapi/Hoechst/Phalloidin");
			channelChoices = Array.deleteValue(channelChoices, "-Channel to Ignore-");
			channelChoices = Array.deleteValue(channelChoices, customGal4Name);
			channelChoices = Array.concat(preChannels, channelChoices);
			}
		else {
			preChannels = newArray("WD");
			channelChoices = Array.deleteValue(channelChoices, "Dapi/Hoechst/Phalloidin");
			channelChoices = Array.deleteValue(channelChoices, "-Channel to Ignore-");
			channelChoices = Array.concat(preChannels, channelChoices);
		}
AllROIs = channelChoices;

//print("3");
//waitForUser("===pause_3===");
			
return channelChoices;
}
//////////////////////////////////////////


//a function called "defineWD" which takes 1 argument which is "file" (and therefore, file == inputFilesList[i])
//This function makes a composite image of all channels, then asks the user to delete unnecessary parts, then thresholds the entire WD.

function defineWD(file) {
	selectWindow(file);
	run("Duplicate...", "duplicate");
	rename("Image");
	run("Z Project...", "projection=[Max Intensity]");
	close("Image");
	run("Make Composite");
	run("RGB Color");
	close("MAX_Image");
	run("8-bit");
	rename("MAX_Image");
	
	
	title = "Please Delete Non-relevant WD parts";
	msg = "Apply the Selection tool to delete unwanted regions in the WD then \n Press \"OK\" to begin analysis.";
	waitForUser(title, msg);
	run("Select None");
	// Prompt the user to review the images and accept or reject the result
	accepted = false;
    
    // If the user rejects the result, loop back to the thresholding step
    while(!accepted) {
		close("SideBySide");
		close("WD");

		roiManager("reset");
		setBackgroundColor(0, 0, 0);
		selectWindow("MAX_Image");
		run("Duplicate...", "duplicate");
		
		rename("WD");
		//Threshold whole WD
		run("Threshold...");
		title = "Threshold for the ENTIRE WD";
		msg = "Use the \"Threshold\" tool to adjust the threshold for the ENTIRE WD, then:\n 1. Press \"Apply\".\n 2. Click \"OK\" in this box to continue.";
		waitForUser(title, msg);
		run("Despeckle", "slice");
		run("Despeckle", "slice");
		run("Despeckle", "slice");
		run("Despeckle", "slice");
		run("Fill Holes", "slice");
		run("Analyze Particles...", "size=5000-Infinity show=Nothing add slice");
		//setBackgroundColor(255, 255, 255);
		roiManager("Select", 0);
		roiManager("Select", 0)
		run("Clear Outside"); 
		setBackgroundColor(0, 0, 0);
		
		makeSideBySide("MAX_Image", "WD");

		// Prompt the user to review the images and accept or reject the result
    	accepted = getBoolean("Is the thresholding result for the WD acceptable?");		
		
	}
	close("MAX_Image");}


////


//a function called "makeSideBySide" which takes 2 arguments, which are "MAX_Image" and "TH_Image"
//This function makes a side by side image of the thresholded area and the remaining area. 

function makeSideBySide(MAX_Image, TH_Image) {
	roiManager("Show None");
	roiManager("reset");
	run("Select None");
	selectWindow(TH_Image);
	run("Create Selection");
	roiManager("Add");
	roiManager("Select", 0)
	roiManager("Rename", TH_Image);
	// Get stack dimentions and set the middle slice
	getDimensions(w, h, channels, slices, frames);
	// Calculate the size of the new concatenated image
	newWidth = (w+w);
	newHeight = (h);
	selectWindow(MAX_Image);
	run("Duplicate...", "duplicate");
	run("Enhance Contrast", "saturated=0.35");
	rename("IN");
	run("Duplicate...", "duplicate");
	rename("OUT");
	
	selectWindow("IN");
	roiManager("Select", TH_Image);
	run("Clear Outside", "slice");
	
	
	selectWindow("OUT");
	roiManager("Select", TH_Image);
	run("Clear", "slice");
	// Create a new image that is twice the width of the original images
	newImage("SideBySide", "RGB white", newWidth, newHeight, 1);
	selectWindow("IN");
	run("Select All");
	run("Copy");
	selectWindow("SideBySide");
	makeRectangle(0, 0, w, h);
	run("Paste");
	close("IN");
	selectWindow("OUT");
	run("Select All");
	run("Copy");
	selectWindow("SideBySide");
	makeRectangle(newWidth/2, 0, w, h);
	run("Paste");
	close("OUT");
	selectWindow("SideBySide");
}

		
/////////


//a function called "processChannel" which takes ??? arguments, which are
//This function processes a single channel by thresholding it. 
function processChannel() {
  ListOpenImages = getList("image.titles");
     for (i=0; i<ListOpenImages.length; i++){
     	if (matches(ListOpenImages[i],".*Dapi.*") || matches(ListOpenImages[i],".*Hoechst.*") || matches(ListOpenImages[i],".*Phalloidin.*") || matches(ListOpenImages[i],".*-Channel to Ignore-.*")){
     		close(ListOpenImages[i]);
     	}}
  ListOpenImages = getList("image.titles");
     for (i=0; i<ListOpenImages.length; i++){
     	if (matches(ListOpenImages[i],".*_8-bit.*")){
				selectWindow(ListOpenImages[i]);
				roiManager("Select", "WD");
				run("Clear Outside", "slice");
				run("Select None");
     		}
     	}
     	
		
	for (i=0; i<ListOpenImages.length; i++){
     		if(matches(ListOpenImages[i],".*_8-bit.*")){
				// Prompt the user to review the images and accept or reject the result
				accepted = false;
    
    			// If the user rejects the result, loop back to the thresholding step
   				while(!accepted) {
					TH_Image = "TH_Image_"+ListOpenImages[i];
					close("SideBySide");
					close(TH_Image);
					roiManager("reset");
					setBackgroundColor(0, 0, 0);
				
					selectWindow(ListOpenImages[i]);
					run("Duplicate...", "duplicate");
					run("Cyan");
					rename(TH_Image);
			
					//Threshold the channel
					run("Threshold...");
					title = "Threshold for the "+ListOpenImages[i]+" channel";
					msg = "Use the \"Threshold\" tool to adjust the threshold, then:\n 1. Press \"Apply\".\n 2. Click \"OK\" in this box to continue.";
					waitForUser(title, msg);
					run("Despeckle", "slice");
					run("Despeckle", "slice");
					run("Despeckle", "slice");
					//run("Fill Holes", "slice");
					
					makeSideBySide(ListOpenImages[i], TH_Image);
		
					// Prompt the user to review the images and accept or reject the result
		    		accepted = getBoolean("Is the thresholding result for the "+ListOpenImages[i]+" channel acceptable?");	
					}}}
	for (i=0; i<ListOpenImages.length; i++){
     		if(matches(ListOpenImages[i],".*_8-bit.*")){
     			close(ListOpenImages[i]);     		}
     		}
     		
    ListOpenImages = getList("image.titles");
    for (i=0; i<ListOpenImages.length; i++){
     		if(matches(ListOpenImages[i],".*_8-bit.*")){
     			
     			name = ListOpenImages[i];
     			newname = name.replace("TH_Image_", "");
     			newname = newname.replace("_8-bit", "");
     			selectWindow(ListOpenImages[i]);
     			rename(newname);}	
				}
}
        

///////////////////////////////////////////////////////////////////////////////////////////

//a function called "saveROI" which takes ??? arguments, which are
//This function uses the open images . 

function saveROI() {
	roiManager("reset");
	for (i = 0; i < lengthOf(channelChoices); i++) {
    // Get the current image based on its name
   

    
   	if (isOpen(channelChoices[i])) {
   		selectWindow(channelChoices[i]);
   		run("Create Selection");
		roiManager("Add");
		roiManager("Select", i);
		roiManager("Rename", channelChoices[i]);
		
		//print("Pause "+i+1);
		//waitForUser("===pause_"+i+1+"===");
		
		close(channelChoices[i]);}
	else {
		print(channelChoices[i]+" is not open");
		//print("Pause "+i+1);
		//waitForUser("===NOT OPEN pause_"+i+1+"===");
		
		}
		}		
}

///////////////////////////////////////////////////////////////////////////////////////////

// Function to generate ROI combinations
function generateROICombinations(values, roiNames) {
    n = lengthOf(values);

    for (i = 1; i < (1 << n); i++) {
        combination = newArray();
        combinedName = "";
        
        for (j = 0; j < n; j++) {
            if (((i >> j) & 1) == 1) {
                combination = Array.concat(combination, values[j]);
                combinedName += "+" + roiNames[values[j]];
                if (startsWith(combinedName, "+")) {
					combinedName = substring(combinedName, 1);
}
            }}
            
            if (lengthOf(combination) > 1) {
            	// Check if combination is not already in AllROIs
            	if (Array_Contains_LSCF(AllROIs, combinedName) == -1) {
        		roiManager("Select", combination);
        		roiManager("AND");
				roiManager("Add");
				SelectLastROI_LSCF();
				roiManager("Rename", combinedName);
				AllROIs = Array.concat(AllROIs, combinedName);
            	}}}}
				
///////////////////////////////////////////////////////////////////////////////////////////


// Function to generate ROI combinations
function comboROI() {
	if (isGal4Present == "True") {

	WD = Array_Contains_LSCF(channelChoices, "WD");
	Gal4 = Array_Contains_LSCF(channelChoices, customGal4Name);
	
	
	channelChoices_indexArray = newArray(lengthOf(channelChoices));
	for (i = 0; i < lengthOf(channelChoices); i++) {
	    channelChoices_indexArray[i] = i;
	}
	
	OtherChannels_index = Array.slice(channelChoices_indexArray, 2, lengthOf(channelChoices_indexArray));
	
	generateROICombinations(OtherChannels_index, channelChoices);
	
	roiManager("Select", WD);
	roiManager("Add");
	SelectLastROI_LSCF();
	roiManager("Rename", "in "+channelChoices[0]);
	AllROIs = Array.concat(AllROIs, "in "+channelChoices[0]);
	
	roiManager("Select", Gal4);
	roiManager("Add");
	SelectLastROI_LSCF();
	roiManager("Rename", "in "+channelChoices[1]);
	AllROIs = Array.concat(AllROIs, "in "+channelChoices[1]);
	
	roiManager("Select", newArray(WD,Gal4));
	roiManager("XOR");
	roiManager("Add");
	SelectLastROI_LSCF();
	roiManager("Rename", "out "+channelChoices[1]);
	AllROIs = Array.concat(AllROIs, "out "+channelChoices[1]);

	selectWindow("MAX_"+ImageName);
	roiManager("Select", WD);
	run("Measure");
	
	//FullTable
	Table.set("File Name", gTableRow, "", gResultsTable);
	Table.set("Channels",gTableRow,"",gResultsTable);
	Table.set("",gTableRow,"",gResultsTable);                 
	Table.set("ROI", gTableRow, "WD", gResultsTable);    
	Table.set("Area (um^2)", gTableRow, getResult("Area"), gResultsTable);
	Table.set("Perimiter (um)", gTableRow, getResult("Perim."), gResultsTable);
	Table.set("*", gTableRow, "*", gResultsTable);
	Table.set("Mean Gray Value", gTableRow, "", gResultsTable);
	Table.set("StdDev", gTableRow, "", gResultsTable);
	Table.set("Min", gTableRow, "", gResultsTable);
	Table.set("Max", gTableRow, "", gResultsTable);
				gTableRow++;
				
	//SingleTable				
	Table.set("File Name", SingleTableRow, "", SingleResultsTable);
	Table.set("Channels",SingleTableRow,"",SingleResultsTable);
	Table.set("",SingleTableRow,"",SingleResultsTable);                     
	Table.set("ROI", SingleTableRow, "WD", SingleResultsTable);         
	Table.set("Area (um^2)", SingleTableRow, getResult("Area"), SingleResultsTable);
	Table.set("Perimiter (um)", SingleTableRow, getResult("Perim."), SingleResultsTable);
	Table.set("*", SingleTableRow, "*", SingleResultsTable);
	Table.set("Mean Gray Value", SingleTableRow, "", SingleResultsTable);
	Table.set("StdDev", SingleTableRow, "", SingleResultsTable);
	Table.set("Min", SingleTableRow, "", SingleResultsTable);
	Table.set("Max", SingleTableRow, "", SingleResultsTable);
			SingleTableRow++;
	
	
	selectWindow("MAX_"+ImageName);
	roiManager("Select", Gal4);
	run("Measure");
	
	//FullTable
	Table.set("File Name", gTableRow, "", gResultsTable);
	Table.set("Channels",gTableRow,"",gResultsTable);
	Table.set("",gTableRow,"",gResultsTable);               
	Table.set("ROI", gTableRow, customGal4Name, gResultsTable);      
	Table.set("Area (um^2)", gTableRow, getResult("Area"), gResultsTable);
	Table.set("Perimiter (um)", gTableRow, getResult("Perim."), gResultsTable);
	Table.set("*", gTableRow, "*", gResultsTable);
	Table.set("Mean Gray Value", gTableRow, "", gResultsTable);
	Table.set("StdDev", gTableRow, "", gResultsTable);
	Table.set("Min", gTableRow, "", gResultsTable);
	Table.set("Max", gTableRow, "", gResultsTable);
				gTableRow++;
				
	//SingleTable			
	Table.set("File Name", SingleTableRow, "", SingleResultsTable);
	Table.set("Channels",SingleTableRow,"",SingleResultsTable);
	Table.set("",SingleTableRow,"",SingleResultsTable);                      
	Table.set("ROI", SingleTableRow, customGal4Name, SingleResultsTable);         
	Table.set("Area (um^2)", SingleTableRow, getResult("Area"), SingleResultsTable);
	Table.set("Perimiter (um)", SingleTableRow, getResult("Perim."), SingleResultsTable);
	Table.set("*", SingleTableRow, "*", SingleResultsTable);
	Table.set("Mean Gray Value", SingleTableRow, "", SingleResultsTable);
	Table.set("StdDev", SingleTableRow, "", SingleResultsTable);
	Table.set("Min", SingleTableRow, "", SingleResultsTable);
	Table.set("Max", SingleTableRow, "", SingleResultsTable);
			SingleTableRow++;
			
			
	selectWindow("MAX_"+ImageName);
	roiManager("Select", newArray(WD,Gal4));
	roiManager("XOR");
	run("Measure");
	
	//FullTable
	Table.set("File Name", gTableRow, "", gResultsTable);
	Table.set("Channels",gTableRow,"",gResultsTable);
	Table.set("",gTableRow,"",gResultsTable);                
	Table.set("ROI", gTableRow, "WD - "+customGal4Name, gResultsTable);     
	Table.set("Area (um^2)", gTableRow, getResult("Area"), gResultsTable);
	Table.set("Perimiter (um)", gTableRow, getResult("Perim."), gResultsTable);
	Table.set("*", gTableRow, "*", gResultsTable);
	Table.set("Mean Gray Value", gTableRow, "", gResultsTable);
	Table.set("StdDev", gTableRow, "", gResultsTable);
	Table.set("Min", gTableRow, "", gResultsTable);
	Table.set("Max", gTableRow, "", gResultsTable);
				gTableRow++;
				
	//SingleTable			
	Table.set("File Name", SingleTableRow, "", SingleResultsTable);
	Table.set("Channels",SingleTableRow,"",SingleResultsTable);
	Table.set("",SingleTableRow,"",SingleResultsTable);                   
	Table.set("ROI", SingleTableRow, "WD - "+customGal4Name, SingleResultsTable);          
	Table.set("Area (um^2)", SingleTableRow, getResult("Area"), SingleResultsTable);
	Table.set("Perimiter (um)", SingleTableRow, getResult("Perim."), SingleResultsTable);
	Table.set("*", SingleTableRow, "*", SingleResultsTable);
	Table.set("Mean Gray Value", SingleTableRow, "", SingleResultsTable);
	Table.set("StdDev", SingleTableRow, "", SingleResultsTable);
	Table.set("Min", SingleTableRow, "", SingleResultsTable);
	Table.set("Max", SingleTableRow, "", SingleResultsTable);
			SingleTableRow++;
	
	
	
	AllROIs = Array.deleteValue(AllROIs, channelChoices[0]);
	AllROIs = Array.deleteValue(AllROIs, channelChoices[1]);
	roiManager("Deselect");
	roiManager("Select", Gal4);
	roiManager("Delete");
	roiManager("Deselect");
	roiManager("Select", WD);
	roiManager("Delete");
	}
	
	else if (isGal4Present == "False") {
	
	WD = Array_Contains_LSCF(channelChoices, "WD");
	
	channelChoices_indexArray = newArray(lengthOf(channelChoices));
	for (i = 0; i < lengthOf(channelChoices); i++) {
	    channelChoices_indexArray[i] = i;
	}
	OtherChannels_index = Array.slice(channelChoices_indexArray, 1, lengthOf(channelChoices_indexArray));
	
	generateROICombinations(OtherChannels_index, channelChoices);
	
	roiManager("Select", WD);
	roiManager("Add");
	SelectLastROI_LSCF();
	roiManager("Rename", "in "+channelChoices[0]);
	AllROIs = Array.concat(AllROIs, "in "+channelChoices[0]);
	
	
	roiManager("Select", WD);
	run("Measure");
	
	//FullTable
	Table.set("File Name", gTableRow, "", gResultsTable);
	Table.set("Channels",gTableRow,"",gResultsTable);
	Table.set("",gTableRow,"",gResultsTable);                 
	Table.set("ROI", gTableRow, "WD", gResultsTable);      
	Table.set("Area (um^2)", gTableRow, getResult("Area"), gResultsTable);
	Table.set("Perimiter (um)", gTableRow, getResult("Perim."), gResultsTable);
	Table.set("*", gTableRow, "*", gResultsTable);
	Table.set("Mean Gray Value", gTableRow, "", gResultsTable);
	Table.set("StdDev", gTableRow, "", gResultsTable);
	Table.set("Min", gTableRow, "", gResultsTable);
	Table.set("Max", gTableRow, "", gResultsTable);
				gTableRow++;
				
	//SingleTable				
	Table.set("File Name", SingleTableRow, "", SingleResultsTable);
	Table.set("Channels",SingleTableRow,"",SingleResultsTable);
	Table.set("",SingleTableRow,"",SingleResultsTable);                 
	Table.set("ROI", SingleTableRow, "WD", SingleResultsTable);         
	Table.set("Area (um^2)", SingleTableRow, getResult("Area"), SingleResultsTable);
	Table.set("Perimiter (um)", SingleTableRow, getResult("Perim."), SingleResultsTable);
	Table.set("*", SingleTableRow, "*", SingleResultsTable);
	Table.set("Mean Gray Value", SingleTableRow, "", SingleResultsTable);
	Table.set("StdDev", SingleTableRow, "", SingleResultsTable);
	Table.set("Min", SingleTableRow, "", SingleResultsTable);
	Table.set("Max", SingleTableRow, "", SingleResultsTable);
			SingleTableRow++;
			
			
	roiManager("Select", WD);
	roiManager("Delete");
	AllROIs = Array.deleteValue(AllROIs, channelChoices[0]);
	}
}

///////////////////////////////////////////////////////////////////////////////////////////


// A function to generate and measure ROIs from the list of ROI combinations (AllROIs)
function finalROI(AllROIs, isGal4Present) {
	selectWindow("MAX_"+ImageName);
	run("Select All");
	run("Measure");
	WindowArea = getResult("Area");
	
	//print("10");
	//waitForUser("===pause_10===");
	
	nROI = roiManager("count");
	if (isGal4Present == "True") {
		in_WD = Array_Contains_LSCF(AllROIs, "in "+channelChoices[0]);
		in_Gal4 = Array_Contains_LSCF(AllROIs, "in "+customGal4Name);
		out_Gal4 = Array_Contains_LSCF(AllROIs, "out "+customGal4Name);
		
		for (i = 0; i < in_WD; i++) {
			roiManager("Select", newArray(i,in_WD));
			roiManager("AND");
			run("Measure");
			ROIarea = getResult("Area");
			if (ROIarea != WindowArea) {
				roiManager("Add");
				SelectLastROI_LSCF();
				roiManager("Rename", AllROIs[i]+" "+AllROIs[in_WD]);
				AllROIs = Array.concat(AllROIs,AllROIs[i]+" "+AllROIs[in_WD]);
			}
			
			roiManager("Select", newArray(i,in_Gal4));
			roiManager("AND");
			run("Measure");
			ROIarea = getResult("Area");
			if (ROIarea != WindowArea) {
			roiManager("Add");
			SelectLastROI_LSCF();
			roiManager("Rename", AllROIs[i]+" "+AllROIs[in_Gal4]);
			AllROIs = Array.concat(AllROIs,AllROIs[i]+" "+AllROIs[in_Gal4]);
			}
			
			//
			roiManager("Select", newArray(i,out_Gal4));
			roiManager("AND");
			run("Measure");
			ROIarea = getResult("Area");
			if (ROIarea != WindowArea) {
			roiManager("Add");
			SelectLastROI_LSCF();
			roiManager("Rename", AllROIs[i]+" "+AllROIs[out_Gal4]);
			AllROIs = Array.concat(AllROIs,AllROIs[i]+" "+AllROIs[out_Gal4]);
			}}
			
		//waitForUser("===pause_14!!===");	
		nROI = roiManager("count");
		run("Set Measurements...", "area mean standard min perimeter display redirect=None decimal=4");
		
		for (i = out_Gal4+1; i < nROI; i++) {
			for (c = 1; c <= NumChannels; c++) {
				if ((c != Gal4ChannelNumber) && (c != DapiChannelNumber) && (c != ChanneltoIgnoreNumber)) {
					substringToFind = OrigChannels[c-1];
					indexOfSubstring = indexOf(AllROIs[i], substringToFind);
					if (indexOfSubstring != -1) {
						selectWindow("MAX_"+ImageName);
						Stack.setChannel(c);
						roiManager("Select",i);
						run("Measure");
						
			
			//FullTable
			Table.set("File Name", gTableRow, "", gResultsTable);
			Table.set("Channels",gTableRow,"Channel "+c,gResultsTable);
            Table.set("",gTableRow,OrigChannels[c-1],gResultsTable);
            Table.set("ROI", gTableRow, AllROIs[i], gResultsTable);
            Table.set("Area (um^2)", gTableRow, getResult("Area"), gResultsTable);
			Table.set("Perimiter (um)", gTableRow, getResult("Perim."), gResultsTable);
			Table.set("*", gTableRow, "*", gResultsTable);
			Table.set("Mean Gray Value", gTableRow, getResult("Mean"), gResultsTable);
			Table.set("StdDev", gTableRow, getResult("StdDev"), gResultsTable);
			Table.set("Min", gTableRow, getResult("Min"), gResultsTable);
			Table.set("Max", gTableRow, getResult("Max"), gResultsTable);
			gTableRow++;
			
			
			//SingleTable
			Table.set("File Name", SingleTableRow, "", SingleResultsTable);
			Table.set("Channels",SingleTableRow,"Channel "+c,SingleResultsTable);
            Table.set("",SingleTableRow,OrigChannels[c-1],SingleResultsTable);
            Table.set("ROI", SingleTableRow, AllROIs[i], SingleResultsTable);
            Table.set("Area (um^2)", SingleTableRow, getResult("Area"), SingleResultsTable);
			Table.set("Perimiter (um)", SingleTableRow, getResult("Perim."), SingleResultsTable);
			Table.set("*", SingleTableRow, "*", SingleResultsTable);
			Table.set("Mean Gray Value", SingleTableRow, getResult("Mean"), SingleResultsTable);
			Table.set("StdDev", SingleTableRow, getResult("StdDev"), SingleResultsTable);
			Table.set("Min", SingleTableRow, getResult("Min"), SingleResultsTable);
			Table.set("Max", SingleTableRow, getResult("Max"), SingleResultsTable);
			SingleTableRow++;
			}}}}}
				
	else if (isGal4Present == "False") {
		in_WD = Array_Contains_LSCF(AllROIs, "in "+channelChoices[0]);
		
		for (i = 0; i < in_WD; i++) {
			
			roiManager("Select", newArray(i,in_WD));
			roiManager("AND");
			run("Measure");
			ROIarea = getResult("Area");
			if (ROIarea != WindowArea) {
			roiManager("Add");
			SelectLastROI_LSCF();
			roiManager("Rename", AllROIs[i]+" "+AllROIs[in_WD]);
			AllROIs = Array.concat(AllROIs,AllROIs[i]+" "+AllROIs[in_WD]);
			}}
		nROI = roiManager("count");
		
		for (i = in_WD+1; i < nROI; i++) {
			for (c = 1; c <= NumChannels; c++) {
				if ((c != Gal4ChannelNumber) && (c != DapiChannelNumber) && (c != ChanneltoIgnoreNumber)) {
					substringToFind = OrigChannels[c-1];
					indexOfSubstring = indexOf(AllROIs[i], substringToFind);
					if (indexOfSubstring != -1) {
						selectWindow("MAX_"+ImageName);
						Stack.setChannel(c);
						roiManager("Select",i);
						run("Measure");
			
			//FullTable
			Table.set("File Name", gTableRow, "", gResultsTable);
			Table.set("Channels",gTableRow,"Channel "+c,gResultsTable);
            Table.set("",gTableRow,OrigChannels[c-1],gResultsTable);
            Table.set("ROI", gTableRow, AllROIs[i], gResultsTable);
            Table.set("Area (um^2)", gTableRow, getResult("Area"), gResultsTable);
			Table.set("Perimiter (um)", gTableRow, getResult("Perim."), gResultsTable);
			Table.set("*", gTableRow, "*", gResultsTable);
			Table.set("Mean Gray Value", gTableRow, getResult("Mean"), gResultsTable);
			Table.set("StdDev", gTableRow, getResult("StdDev"), gResultsTable);
			Table.set("Min", gTableRow, getResult("Min"), gResultsTable);
			Table.set("Max", gTableRow, getResult("Max"), gResultsTable);
			gTableRow++;
			
			
			//SingleTable
			Table.set("File Name", SingleTableRow, "", SingleResultsTable);
			Table.set("Channels",SingleTableRow,"Channel "+c,SingleResultsTable);
           	Table.set("",SingleTableRow,OrigChannels[c-1],SingleResultsTable);
            Table.set("ROI", SingleTableRow, AllROIs[i], SingleResultsTable);
            Table.set("Area (um^2)", SingleTableRow, getResult("Area"), SingleResultsTable);
			Table.set("Perimiter (um)", SingleTableRow, getResult("Perim."), SingleResultsTable);
			Table.set("*", SingleTableRow, "*", SingleResultsTable);
			Table.set("Mean Gray Value", SingleTableRow, getResult("Mean"), SingleResultsTable);
			Table.set("StdDev", SingleTableRow, getResult("StdDev"), SingleResultsTable);
			Table.set("Min", SingleTableRow, getResult("Min"), SingleResultsTable);
			Table.set("Max", SingleTableRow, getResult("Max"), SingleResultsTable);
			SingleTableRow++;
			
			}}}}}
}
///////////////////////////////////////////////////////////////////////////////////////////
function Array_Contains_LSCF(array, value){
	n = array.length;
	for(i=0;i<n;i++){
		if(array[i] == value){
			return i;
		}
	}
	return -1;
}


function SelectLastROI_LSCF()
{
	n = roiManager("count");
	if(n > 0){
		roiManager("Select", n-1);
		return n-1;
	}
	return -1;
}


print("hey there");
	