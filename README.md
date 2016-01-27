# update_arraymap

we divide the work to update the database Arraymap in 4 steps:
  1. download the samples ID that are not in Arraymap (findSamples.pl)
  2. download the .CEL file of the affimetrix platforms (CELdownload.pl)
  3. download the soft files
  4. metadata interpretation
  5. elaboration of the soft file

-----------------------------------------------------------
Files:
  • findSamples.pl: script to download the GEO samples ID that are not present in arraymap
  • geometa.pl: together with findSamples.pl to find and download the metadata files of the samples
  • test.pl: ?
  • n_cel_file.pl: script to calculate the multiplicity of the CEL files in the sample. Hence: how many samples have 1 CEL file, how many have 2 CEL files, etc.
  • celfile_review.pl: as n_cel_file.pl, but can be run only on samples that are not in arraymap
  • CELdownload.pl: download all the CEL files of a given platform id