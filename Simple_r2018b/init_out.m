% function to initialise a domain-specific Simple outflow block
function init_out

block = gcbh; 

levelVarName = get(block,'Level');
flowVarName = get(block,'Flow');
underscoredName = getUnderscoredName(block);
%%lvl_out = find_system(block, 'RegExp', 'on', 'FollowLinks', 'on' ,'LookUnderMasks','all', 'FindAll', 'on', 'Name', levelVarName,'Type','line');
lvl_out = find_system(block, 'FollowLinks', 'on' ,'LookUnderMasks','all', 'FindAll', 'on', 'Name', levelVarName,'Type','line');
set(lvl_out,'DataLogging',1)
levelName =  [levelVarName underscoredName];
set(lvl_out,'DataLoggingNameMode','Custom')
set(lvl_out, 'DataLoggingName', levelName)
set(lvl_out, 'DataLoggingDecimateData', true)
set(lvl_out, 'DataLoggingDecimation', '10')

%flw_out = find_system(block, 'RegExp', 'on', 'FollowLinks', 'on' ,'LookUnderMasks','all', 'FindAll', 'on', 'Name', flowVarName,'Type','line');
flw_out = find_system(block,  'FollowLinks', 'on' ,'LookUnderMasks','all', 'FindAll', 'on', 'Name', flowVarName,'Type','line');
flowName =  [flowVarName underscoredName];
set(flw_out,'DataLogging',0) % was 1 
% set(flw_out,'DataLoggingNameMode','Custom')
% set(flw_out, 'DataLoggingName', flowName)
% set(flw_out, 'DataLoggingDecimateData', true)
% set(flw_out, 'DataLoggingDecimation', '10')

end

% long unique (up to truncation) block name
function longname = getUnderscoredName(h)

name = get(h,'Name');
pth = get(h,'Path');
longname = [name];
% while ~isempty(pth)
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