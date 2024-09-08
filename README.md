# The Initiator Caspase Dronc Drives Compensatory Proliferation of Apoptosis-Resistant Cells During Epithelial Tissue Regeneration After Ionizing Radiation
We investigate compensatory proliferation in the Drosophila wing imaginal disc following ionizing radiation.
## Image Analysis
### Slice by slice image analysis
To quantify the results in the experiment presented in the blue bar in figure S2E we used a Fiji macro that:
1. In each channel and each slice it identifies the related cell total area using an intensity threshold. We used 170 as the minimal intensity for channel 1, 240 for channel 2, and 120 for channel 3. We did not fill holes in the identified areas. These thresholds were used for all analysed images. 
2. For each slice, the total area identified in each channel and the overlapping identified areas between channels were exported as .csv file for further statistical analysis.

The macro, Areas_Overlap.ijm, can be found under [Fiji folder](../../tree/main/Fiji)

### Z-Stack max intensity, image analysis
To quantify the results in the experiments presented in: figures 1B-C, 3E-F, 4C-D, 4F, 4I-J, 5E, 5H-I, 6F-G, 7D-E, 7H-I, S2E (except for the blue bar), S3D, S3E, S4D, S5B-C we used a Fiji macro that:
1. A 2D maximal intensity projection of the Z-stack for each imaged WID was generated.
2. Each fluorescent channel was then threshold and masked under careful supervision to prevent misclassification. Thresholding for the entire imaged WID was performed using a combination of all fluorescent channels.
3. The masked images were then used to define overlaying and divergent regions of interest for all relevant imaged channels.
4. Measurements of the mean intensity and area of the resulting regions of interest were conducted on the corresponding original 2D maximal intensity projection images for each fluorescent channel.
5. All regions of interest and processed images were documented and saved. The results were exported as .csv files for further statistical analysis.

The macro, 231213_Automation_Macro.ijm, can be found under [Fiji folder](../../tree/main/Fiji)
