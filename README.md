# SuStaIn Web App

This is a simplified version of the SuStaIn web application available on the neugrid.eu platform (https://www.neugrid2.eu/index.php/ml-tools/sustain/).

It is intended to serve as a basis for the development of other web-based applications implementing SuStaIn models. (The original SuStaIn paper is [here](https://doi.org/10.1038/s41467-018-05892-0).)

The webapp is designed to run on a local server.

In order to run and test it, copy the contents of this repository into the home folder of your local server (`/var/www/html/` for many linux systems) and open the file `index.html` in a browser (or enter http://localhost in your browser).               

The main files to manage the webapp backend are located in [scripts/](scripts):
- `sustain.php`: checks the input data from `index.html` and launches the computation;
- `sustain.sh`:  manages the computation. Specifically, it processes the uploaded scan with FreeSurfer 5.3, calculates the z-scores needed for SuStaIn model, subtypes and stages the individual (in this version subtyping and staging is poerformed using a sustain model based on mock data, you can use a different SuStaIn model by using a new .pickle file containing the model) and compiles a .pdf report containing the main outputs of subtyping and staging. If a mail server is configured on your server, the report is sent to the user.

REQUIREMENTS:
- a LAMP server: the easiest way to get it is to type `apt-get install lamp-server` in your terminal. You may have to change php settings so that large uploads are allowed.
- FSL: a free software package useful for MRI file management. Download it from https://fsl.fmrib.ox.ac.uk/fsldownloads_registration, and install it by typing `python fslinstaller.py` (requires python2 for installation)
- FreeSurfer 5.3: a free software for MRI segmentation. Download it at https://surfer.nmr.mgh.harvard.edu/fswiki/DownloadAndInstall5.3, then extract the files to your preferred location (default FreeSurfer location for the webapp is `/opt/FreeSurfer-5.3.0`)
- python3: required packages to run sustain in python3 are: `abc`, `csv`, `functools`, `matplotlib`, `multiprocessing`, `numpy`, `os`, `pandas`, `pathlib`, `pathos`, `pickle`, `scipy`, `sklearn`, `time`)
- blender
- pdflatex
