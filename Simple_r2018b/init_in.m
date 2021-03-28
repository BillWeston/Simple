% function init_in to initialise a domain-specific Simple inflow block
%% function init_in 
% Useful to initialise a domain-specific Simple inflow block.
% By Bill Weston bill.weston@embeduk.com
% Copyright Embed Ltd 2017
function init_in

block = gcbh;                     

longName = getLongName(block);
% label the level and flow names
underscoredName = getUnderscoredName(block);
levelVarName = get(block,'Level');
flowVarName = get(block,'Flow');
%lvl_in = find_system(block, 'FollowLinks', 'on' ,'LookUnderMasks','all', 'FindAll', 'on', 'Name', 'Level','Type','line');
lvl_in = find_system(block, 'FollowLinks', 'on' ,'LookUnderMasks','all', 'FindAll', 'on', 'Name', levelVarName,'Type','line');
if isempty(lvl_in)
    lvl_in = find_system(block, 'FollowLinks', 'on' ,'LookUnderMasks','all', 'FindAll', 'on', 'Name', ['<' levelVarName '>'],'Type','line');
end
set(lvl_in,'DataLogging',0)
% set(lvl_in,'DataLogging',1)
% set(lvl_in,'DataLoggingNameMode','Custom')
% levelName =  [levelVarName underscoredName];
% %%set(lvl_in, 'Name', levelName)
% set(lvl_in, 'DataLoggingName', levelName)
% set(lvl_in, 'DataLoggingDecimateData', true)
% set(lvl_in, 'DataLoggingDecimation', '10')
%%flw_in = find_system(block, 'RegExp', 'on', 'FollowLinks', 'on' ,'LookUnderMasks','all', 'FindAll', 'on', 'Name', ['^' flowVarName],'Type','line');
flw_in = find_system(block, 'FollowLinks', 'on' ,'LookUnderMasks','all', 'FindAll', 'on', 'Name', flowVarName,'Type','line');
if isempty(flw_in)
    flw_in = find_system(block, 'FollowLinks', 'on' ,'LookUnderMasks','all', 'FindAll', 'on', 'Name', ['<' flowVarName '>'],'Type','line');
end

flowName =  [flowVarName underscoredName];
set(flw_in,'DataLogging',1)
set(flw_in,'DataLoggingNameMode','Custom')
set(flw_in, 'DataLoggingName', flowName)
set(flw_in, 'DataLoggingDecimateData', true)
set(flw_in, 'DataLoggingDecimation', '10')
end

% long unique (up to truncation) block name
function tagname = getTagName(h)
    tagname = getLongName(h, 60);
    tagname = ['tag' tagname];
end

% long unique (up to truncation) block name
function longname = getLongName(h, max_len)

if nargin < 2
    max_len = 63;
end

name = get(h,'Name');
pth = get(h,'Path');
longname = [name];
while ~isempty(pth)
    [pth,levelname] = fileparts(pth);
    longname = [longname levelname];
end

longname = strrep(longname,char(10),'_');
longname = strrep(longname,' ','');
longname = strrep(longname,'&','');
longname = strrep(longname,'-','');
longname = strrep(longname,'''','');
len = length(longname);
longname=longname(1:min(max_len,len));

end
% long unique (up to truncation) block name
function longname = getUnderscoredName(h)

name = get(h,'Name');
pth = get(h,'Path');
longname = name;
%while ~isempty(pth)
while ~strcmp(pth,bdroot)  
    [pth,levelname] = fileparts(pth);
    longname = [longname '_' levelname];
end

longname = strrep(longname,char(10),'_');
longname = strrep(longname,' ','');
longname = strrep(longname,'&','');
longname = strrep(longname,'-','');
longname = strrep(longname,'''','');
len = length(longname);
longname=longname(1:min(63,len));

end
