% Set up paths for simple plant model examples

% Get Project Path
thisFile = mfilename('fullpath') ;
here = fileparts(thisFile);

project_pos = findstr(here,'Simple_');
project = here(1:project_pos+12);
addpath(project)

embedlib_pos = findstr(here,'embedlib');
embedlib = here(1:embedlib_pos+8);
addpath([embedlib 'EmbedMbdToolbox\trunk\blocks\Test'])
addpath([embedlib 'EmbedMbdToolbox\trunk\blocks\Utilities'])
addpath([embedlib 'EmbedMbdToolbox\trunk\blocks\Document'])
addpath([embedlib 'EmbedMbdToolbox\trunk\blocks\Calibrate'])

clear embedlib embedlib_pos here project project_pos
