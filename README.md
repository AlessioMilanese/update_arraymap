# update_arraymap

we divide the work to update the database Arraymap in 4 steps:
  1. download the samples ID that are not in Arraymap (findSamples.pl)
  2.1 download the .CEL file of the affimetrix platforms (CELdownload.pl)
  2.2 download the soft files
  3. metadata interpretation
  4. elaboration of the soft file