function init_lump

block = gcbh;
underscoredName = getUnderscoredName(block);

conserve = find_system(block, 'FollowLinks', 'on' ,'LookUnderMasks','all', 'FindAll', 'on', 'Name', 'conserved_quantity','Type','line');
conserved_quantity_name = get(block,'conserved_quantity_name');
full_name =  [conserved_quantity_name '_' underscoredName];
set(conserve,'DataLogging',1)
set(conserve,'DataLoggingNameMode','Custom')
set(conserve, 'DataLoggingName', full_name)
set(conserve, 'DataLoggingDecimateData', true)
set(conserve, 'DataLoggingDecimation', '10')

energy = find_system(block, 'FollowLinks', 'on' ,'LookUnderMasks','all', 'FindAll', 'on', 'Name', 'energy','Type','line');
energy_name = get(block,'energy_name');
full_name =  [energy_name '_' underscoredName];
set(energy,'DataLogging',1)
set(energy,'DataLoggingNameMode','Custom')
set(energy, 'DataLoggingName', full_name)
set(energy, 'DataLoggingDecimateData', true)
set(energy, 'DataLoggingDecimation', '10')

end

% long unique (up to truncation) block name
function longname = getUnderscoredName(h)

name = get(h,'Name');
pth = get(h,'Path');
longname = [name];
while ~isempty(pth)
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
