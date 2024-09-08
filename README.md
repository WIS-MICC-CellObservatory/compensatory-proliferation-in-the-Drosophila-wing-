# The Initiator Caspase Dronc Drives Compensatory Proliferation of Apoptosis-Resistant Cells During Epithelial Tissue Regeneration After Ionizing Radiation
We investigate compensatory proliferation in the Drosophila wing imaginal disc following ionizing radiation.
## Overview
For the processing and analysis of the ?? we used Fiji macro that:
1. In each channel and each slice we identifies the related cell total area using an intensity threshold. We used 170 as the minimal intensity for channel 1, 240 for channel 2 and 120 for channels one. We did not fill holes in the identified areas and ignore areas smaller than 72864.24448 µm<sup>2</sup> These thresholds where used for all analyzed images. We used 
1. Given an intensity threshold, it identifies the location of each of the cell types in each of the channels 
2. It calculates the area of each cell type and the area of their intersections in each of the slices

The macro can be found under Fiji macro
