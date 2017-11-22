Contributing
===========

# Files:

The following files are contained in the root of this repo:

###drifter.1
This is the POSIX man page for drifter, written in Groff.

###drifter.sh
This is the main shell script for drifter.  This is where the magic happens.

###install.sh
The drifter installer.  This is responsible for copying the script and man page
 into place, setting the appropriate permissions, and creating the macro directory
 
###README.md
Basic drifter repo information

###CONTRIBUTING.md
Information on contributing to drifter.  You're reading it now.

# Shell Script Structure
Drifter is written in the BASH shell scripting language.  Please follow all modern conventions for writing
 BASH scripts.  Please not that drifter is designed to run on all POSIX compliant systems, so platform-dependent
 features of BASH should be avoided.
 
## Adding internal commands to drifter
Internal commands are written as functions with a name matching the name of the command.  When adding an internal command,
follow these steps:

1.  Create a BASH function with the name of your command.  For example, if your command will be 'test', then add ```function test()```.
2.  Add the name of your new function to the INTERNALCOMMANDS array at or around line 9.
3.  Add your internal command and description to the help function.
4.  Add your internal command and description/usage information to the man page in drifter.1

## Writing macros for drifter
Macros are external commands that extend drifter's capabilities. These are shell scripts located in the directory
named in the MACRODIR variable at the top of the drifter.sh file.  See ```drifter macrohelp``` or the man page for
information on writing drifter macros.

# License
Written by and for the use of Radio Systems Corporation only.  



