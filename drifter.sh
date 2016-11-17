#!/bin/bash

## Configuration.  Change these as needed for your setup.
MACRODIRNAME=driftermacros

## Internal Commands.  Don't forget to add your new command to the help() function so people know about it.

#  Add any internal commands to this array, separated by spaces.  Create a function with the same name.
INTERNALCOMMANDS=("help" "macrohelp" "drifterhelp" "addmacro" "removemacro");

function addmacro() {
    if [[ -z $2 ]]; then
        echo "No macrofile specified.";
        exit 20;
    fi;

    if [[ ! -f $2 ]]; then
        echo "No macrofile located.  Are you sure $2 exists?";
         exit 21;
    fi;

    sudo -v

    if [[ $? -gt 0 ]]; then
        echo "Admin rights needed to install macros.";
        exit 22;
    fi;

    if [[ ! -d "/usr/local/bin/$MACRODIRNAME" ]]; then
        mkdir "/usr/local/bin/$MACRODIRNAME";
    fi;

    sudo cp $2 "/usr/local/bin/$MACRODIRNAME";
    sudo chmod +x "/usr/local/bin/$MACRODIRNAME/$2";

    sudo -k
}

function removemacro() {
  if [[ -z $2 ]]; then
      echo "No macro file name specified.";
      exit 30;
  fi;

  if [[ ! -f "/usr/local/bin/$MACRODIRNAME/$2" ]]; then
    echo "No macro file exists with that name. Are you sure $2 exists?";
    exit 31
  fi;

  sudo -v

  if [[ $? -gt 0 ]]; then
      echo "Admin rights needed to remove macros.";
      exit 32;
  fi;

  sudo rm -f "/usr/local/bin/$MACRODIRNAME/$2"

  sudo -k
}

function help() {
    drifterhelp
    echo "Available commands:"
    echo "-------------------------"
    echo " "
    echo "    drifterhelp      :  Displays drifter usage information"
    echo "    macrohelp        :  Displays information about writing drifter macros"
    echo "    help             :  Displays help information"
    echo "    addmacro         :  Installs a macro"
    echo "    removemacro      :  Removes a macro"
    echo " "
    echo " "
    echo "Macros:"
    echo "-------------------------"
    echo " "
    macrohelp
    exit 0
}

function macrohelp() {
    echo "Macros are shells scripts that are created to run vagrant functions."
    echo " "
    echo "Install a macro by running 'drifter addmacro {filename}' where filename is "
    echo "the macro to add.  Drifter will handle copying and provisioning it for you."
    echo " "
    echo "Macros have the following variables and functions available to them:"
    echo " "
    echo "Variables:"
    echo "\$VAGRANTFILEPATH    :  The location of the Vagrantfile detected in the"
    echo "                       parent tree"
    echo "\$RUNPATH            :  The vagrant executable including full path"
    echo "\$SCRIPTDIR          :  The location of the drifter script"
    echo "\$MACRODIR           :  The location of the macro files"
    echo "\$DEBUG              :  Debug mode flag -- use for macro debugging"
    echo " "
    echo "Functions:"
    echo "getVagrantStatus    :  Sets a variable called \$VAGRANTSTATUS containing"
    echo "                       the status of all defined vagrant machines"
    echo "runVagrantCommand   :  Runs vagrant using the selected executable and"
    echo "                       Vagrantfile.  Options passed to this function will"
    echo "                       be passed directly to vagrant"
    echo "debug_dump          :  Outputs text to the console, but only if DEBUG=0"
    echo " "
    echo "Overriding:"
    echo "If a macro and an internal command or vagrant function share a name, the macro takes priority."
    echo "This can be used to override an internal command or vagrant function."
    echo " "
    echo " "
    echo "Directives:"
    echo " "
    echo "The 2nd line of the macro, below the shebang line, is used for macro directives."
    echo "Create a comment in whatever way is appropriate for the interpreter, and place any number of the following"
    echo "on that line to apply the indicated flag to the macro."
    echo " "
    echo "@RequireVagrantFile     :  Informs drifter that the macro requires a VagrantFile.  This will initiate a"
    echo "                           search for the VagrantFile in the parent tree and set the associated variables."
    echo "                           Note that a macro marked @RequireVagrantFile will NOT run without a VagrantFile"
    echo "                           somewhere in the parent tree."
    echo "@RequireVagrantPath     :  Informs drifter that the macro requires access to the vagrant executable., "
    echo "                           Initiating a search for the vagrant executable."
    echo " "
}

function drifterhelp() {
    echo "Usage: $0 {--debug} [command] {params}"
    echo " "
    echo "[command] can be any drifter internal command, correctly defined macro, or vagrant command"
    echo " "
    echo "Specifying -debug as the first param will output debugging information as drifter works out what you want"
    echo "it to do."
    echo " "
    echo "Any arguments after {command} will be passed to {command} in the same order as they appear on the command line."
    echo " "
}


########################################################################
###  Don't modify below this line unless you know what you're doing. ###
########################################################################

## Initialization

if [[ $1 == "--debug" ]]; then
    DEBUG=1;
    shift;
else
    DEBUG=0;
fi;


SCRIPTDIR=$(dirname $0);
MACRODIR=${SCRIPTDIR}/${MACRODIRNAME};
USEMACRO=0;



function debug_dump() {
    if [ "${DEBUG}" -gt 0 ]; then
        echo "$1";
    fi;
}

function enforceMacroFlags() {
# $1 = name of macro script
    FLAGSLINE=$(cat $1 | head -n2 | tail -n1);

    if [[ $FLAGSLINE == *"@vagrantFileRequired"* ]]; then
        debug_dump "Macro requires VagrantFile.  Locating"
        findVagrantFile
    fi;
}

function containsElement() {
## Ignore Bash error below.  It's a bug in PHPStorm's bash parser
    local needle=$1;
    shift
    local haystack=$@;
    local inArray;

    debug_dump "Analysing internal commands"
    debug_dump "  Needle  : $needle"
    debug_dump "  Haystack: $haystack"
    debug_dump "  Command Count: $(echo ${haystack} | grep "${needle}" | wc -l)"
    contains_element=$(echo ${haystack} | grep "${needle}" | wc -l)
}

function isMacro() {
    local COMMAND=$1;

    if [ ! "$COMMAND" = "" ]; then
        debug_dump "Command passed to drifter: $COMMAND";
        if [ -d "$MACRODIR" ]; then
            debug_dump "Macros Directory Exists";
            if [ -e "$MACRODIR/$COMMAND" ]; then
                is_macro=1;
                MACROPATH="$MACRODIR/$COMMAND";
                debug_dump "Macro Located $MACROPATH";
                return;
            fi;
        fi;
        is_macro=0
        return;
    fi;
}

function checkIfMacroRequiresVagrantFile() {
    local COMMAND=$1

    DIRECTIVES=$(cat $MACRODIR/$COMMAND | head -n2 | tail -n1);
    if [[ ${DIRECTIVES} == *"@RequireVagrantFile"* ]]; then
        REQUIRESVAGRANTFILE=1
    else
        REQUIRESVAGRANTFILE=0
    fi;
}

function checkIfMacroRequiresVagrant() {
    local COMMAND=$1

    DIRECTIVES=$(cat $MACRODIR/$COMMAND | head -n2 | tail -n1);
    if [[ ${DIRECTIVES} == *"@RequireVagrantPath"* ]]; then
        REQUIRESVAGRANT=1
    else
        REQUIRESVAGRANT=0
    fi;
}

function isCommandOrMacro() {
    local COMMAND=$1
    debug_dump "Checking if $COMMAND is an internal command or external macro"

    containsElement ${COMMAND} ${INTERNALCOMMANDS[@]}
    isMacro ${COMMAND}

    if [[ ${contains_element} -gt 0 ]]; then
        debug_dump "$COMMAND is an internal command"
        is_command_or_macro="command"
        return 1
    elif [[ ${is_macro} -gt 0 ]]; then
        debug_dump "$COMMAND is an external macro"
        USEMACRO=1;
        is_command_or_macro="macro"
        return 2
    else
        debug_dump "$COMMAND matches no internal command or macro"
        is_command_or_macro=
        return 0;
    fi;
}

function detectVagrant {
    which vagrant 2>&1 > /dev/null;
    if [ "$?" = "1" ]; then
        if [ -z "${VAGRANTPATH}" ]; then
          echo "Can't find vagrant.";
          echo "Ensure vagrant is in your path or set environment variable VAGRANTPATH to its location";
          exit 10;
        else
          RUNPATH=${VAGRANTPATH}
        fi;
    else
      RUNPATH=$(which vagrant);
    fi;
}

function traverseBack() {
    DEPTH=$1;
    while [ ${DEPTH} -gt 0 ]; do
        debug_dump "Traversing back to $(pwd)"
        popd 2>&1 > /dev/null
        let DEPTH-=1;
    done;
    debug_dump "Back at $(pwd)";
}

function findVagrantfile () {

    VAGRANTFILEPATH=

    if [ -e "VagrantFile" ]; then
        VAGRANTFILEPATH='.';
    else
        DIRCOUNTER=0;
        debug_dump "Beginning VagrantFile search."
        debug_dump "Current Dir: $(pwd)"
        while [ ! -e "VagrantFile" ] && [ ! "$(pwd)" == "/" ]; do
            debug_dump "Checking $(pwd)"
            pushd .. 2>&1 > /dev/null
            let DIRCOUNTER+=1
        done;
        if [ -e "VagrantFile" ]; then
            VAGRANTFILEPATH="$(pwd)";
            debug_dump "VagrantFile located at $VAGRANTFILEPATH"
            traverseBack ${DIRCOUNTER}
        else
            debug_dump "No VagrantFile located before root"
            traverseBack ${DIRCOUNTER}

            echo "Cannot locate VagrantFile in parent tree.  Are you sure this project uses it?"
            exit 11;

        fi;
    fi;
}

function getVagrantStatus() {
   # MAGIC.  Trims the fat from the vagrant global status.
   export VAGRANTSTATUS=$(vagrant global-status | sed '1,2d' | sed -n -e :a -e '1,7!{P;N;D;};N;ba')
}


function runVagrantCommand () {
    pushd "$VAGRANTFILEPATH" 2>&1 > /dev/null

    debug_dump "Vagrantfile Path: $VAGRANTFILEPATH";
    debug_dump "Vagrant command : $RUNPATH $@";

    "$RUNPATH" $@
    popd 2>&1 > /dev/null
}

function executeMacro () {
    local COMMAND=$1
    if [ -n "$MACROPATH" ]; then
        debug_dump "Passing control to macro script at $MACRODIR/$COMMAND"
        debug_dump "Current dir: $(pwd)"
        "$MACROPATH" $@;
        exit 0;
    fi;
}

function trapNoCommandState() {
    if [[ -z "$1" ]]; then
        debug_dump "No command specified.  Displaying help."
        drifterhelp
        exit 0;
    fi;
}

## Making some stuff available to macros
export VAGRANTFILEPATH;
export RUNPATH;
export SCRIPTDIR;
export MACRODIR;
export DEBUG
export -f getVagrantStatus;
export -f runVagrantCommand;
export -f debug_dump;


# Let's get this train rolling.
trapNoCommandState $1
isCommandOrMacro $1

case ${is_command_or_macro} in
    'macro')
        debug_dump "Executing macro"
        checkIfMacroRequiresVagrantFile $1
        checkIfMacroRequiresVagrant $1
        if [[ ${REQUIRESVAGRANTFILE} -eq 1 ]]; then
            findVagrantfile
        fi;

        if [[ ${REQUIRESVAGRANT} -eq 1 ]]; then
            detectVagrant
        fi;
        executeMacro $@;
        exit 0
    ;;
    'command')
        debug_dump "Calling internal command"
        "$1" $@;
        exit 0;
    ;;
    *)
        debug_dump "Passing control to vagrant"
        detectVagrant
        findVagrantfile
        runVagrantCommand $@;
        exit 0
    ;;
esac;
