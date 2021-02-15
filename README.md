# Sustain_webapp

This is a simplified version of the SuStaIn web appilcation available on the neugrid.eu platform (https://www.neugrid2.eu/index.php/ml-tools/sustain/).

It is intended to serve as a basis fo r the development of other applications implementig SuStaIn models.  

The webapp is designed to run on a local server 

In order to run and test it copy the contents of the repository in the home folder of your local server (/var/www/html/ for linux systems) and open the file "index.html in a browser (or enter http://localhost in your browser).               

The main files to manage the web app backend are located in scripts/, specifically they are:

-sustain.php: checks the data inputed in "index.html" and launches the computation;

-sustain.sh: manages the computation, specifically it processes the uploaded scan with freesurfer 5.3, calculates the z-scores to use needed for the SuStaIn model, subtypes and stages the individual (in this version subtyping and staging is poerformed using a sustain model based on mock data, you can use a different SuStaIn model by using a new .pickle file containing the model) and compiles a .pdf report containing the main outputs of subtyping and staging. If a mail server is configured on your server, the report is sent to the user.


REQUIREMENTS:

- a LAMP server: the easiest way to get it is to type "apt-get install lamp-server^" in your terminal. You may have to change php settings so that large uploads are allowed.

- FSL: a software that is useful for MRI scans management. You can download it at https://fsl.fmrib.ox.ac.uk/fsldownloads_registration, and install it typing "python fslinstaller.py" (requires python2 for installation)

- FreeSurfer 5.3: fresurfer is a free software for MRI segmentation, you can dowload it at https://surfer.nmr.mgh.harvard.edu/fswiki/DownloadAndInstall5.3., then just extract files from the zip to your preferred location (default Freesurfer location for the webapp is /opt/FreeSurfer-5.3.0)

- python3: required packages to run sustain in python3 are: abc ,csv , functools, kdeebm, matplotlib, multiprocessing, numpy, os, pandas, pathlib, pathos, pickle, scipy, sklearn, time)

- blender

- pdflatex
