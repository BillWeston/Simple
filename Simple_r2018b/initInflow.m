%% function initInflow
% Useful as InitFcn for Inflow block mask.
% By Bill Weston bill.weston@embeduk.com
% Copyright Bill Weston 2017
function initInflow

% If we are running return straight away - can't alter structure
if get_param(bdroot,'SimulationTime') > 0.0
    return
end

block = gcbh;                     

% TODO better name!
gotoFlow = find_system(block ...
    ,'SearchDepth',1 ...
    ,'FollowLinks','on' ...
    ,'LookUnderMasks','all' ...
    ,'Name','GotoFlow' ...
    );
longName = getLongName(block);
% label the level and flow names
%underscoredName = getUnderscoredName(block);
gotoTag = getTagName(block);
set(gotoFlow,'GotoTag',gotoTag);
%levelVarName = get(block,'Level');
%flowVarName = get(block,'Flow');
%lvl_in = find_system(block, 'FollowLinks', 'on' ,'LookUnderMasks','all', 'FindAll', 'on', 'Name', 'Level','Type','line');
%%lvl_in = find_system(block, 'RegExp', 'on', 'FollowLinks', 'on' ,'LookUnderMasks','all', 'FindAll', 'on', 'Name', ['^' levelVarName],'Type','line');
%set(lvl_in,'DataLogging',1)
%set(lvl_in,'DataLoggingNameMode','Custom')
%levelName =  [levelVarName underscoredName];
%%set(lvl_in, 'Name', levelName)
%set(lvl_in, 'DataLoggingName', levelName)
%%flw_in = find_system(block, 'RegExp', 'on', 'FollowLinks', 'on' ,'LookUnderMasks','all', 'FindAll', 'on', 'Name', ['^' flowVarName],'Type','line');
%flw_in = find_system(block, 'FollowLinks', 'on' ,'LookUnderMasks','all', 'FindAll', 'on', 'Name', 'Flow','Type','line');
%flowName =  [flowVarName underscoredName];
%set(flw_in,'DataLogging',1)
%set(flw_in,'DataLoggingNameMode','Custom')
%set(flw_in, 'DataLoggingName', flowName)

% Label the dummy from
% TODO better name!
fromFlow = find_system(block ...
    ,'SearchDepth',1 ...
    ,'FollowLinks','on' ...
    ,'LookUnderMasks','all' ...
    ,'Name','Flow' ...
    );
set(fromFlow,'GotoTag',gotoTag);

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
while ~strcmp(pth,bdroot) 
    [pth,levelname] = fileparts(pth);
    longname = [longname levelname];
end

longname = strrep(longname,newline,'_');
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
longname = [name];
while ~strcmp(pth,bdroot) 
    [pth,levelname] = fileparts(pth);
    longname = [longname '_' levelname];
end

longname = strrep(longname,newline,'_');
longname = strrep(longname,' ','');
longname = strrep(longname,'&','');
longname = strrep(longname,'-','');
longname = strrep(longname,'''','');
len = length(longname);
longname=longname(1:min(63,len));

end
