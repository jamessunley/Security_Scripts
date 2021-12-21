# Introduction 
Automation script that pulls the latest scans for each project from Checkmarx and uploads the reports generated from these scans to the relevent teams channels based on a list of preset teams email addresses

# Getting Started

1.	Move the config.ini file to the correct location on the server.
2.  Add the correct Checkmarx authentication details to the config.ini file. Please ensure these are not checked in to TFS!!!
3.  The default script is set to pick up all scans within the last 30 days. This is not configurable at runtime at present and should be configured within the script.
4.  The default output is as a CSV file for the reports that are then zipped and emailed to teams, this can also be configured within the script but not currently at runtime.
5.  The Postman collection is available to learn more about the Checkmarx API but is not needed for the script to run.
6.  Python must be installed to run the script. 
7.  The script was developed using Python 3.9.0 on a windows machine - no testing has been done in a Linux environemnt yet

# Build and Test
The script can be run from the command line or terminal using: 
py CheckmarxAutomation.py

There are currently no formal tests in place. All testing has been manual up until this point.

# Contribute
There are a number of "TODO" comments within the script where small improvements can be made in the future to make the script better

# Notes
Gitignore ignores everything within the reports folder and anything with csv, pdf and zip extensions to avoid checking in reports to TFS. If the output type is updated make sure to update the gitignore to avoid mistakes in the future.