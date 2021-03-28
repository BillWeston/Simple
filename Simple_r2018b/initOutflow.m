%% function initOutflow
% Initialises Simulink Outflow Block.
% Should be init callback of Outflow block mask
% By Bill Weston bill.weston@embeduk.com
% Copyright Embed Ltd 2017
function initOutflow

% If we are running return straight away - can't alter structure
if get_param(bdroot,'SimulationTime') > 0.0
    return
end

block = gcbh; %
blockPath = gcb;

outports = find_system(block ...open
    ,'SearchDepth',1 ...
    ,'FollowLinks','on' ...
    ,'LookUnderMasks','all' ...
    ,'BlockType','Outport' ...
    );

froms = find_system(block ...
    ,'SearchDepth',1 ...
    ,'FollowLinks','on' ...
    ,'LookUnderMasks','all' ...
    ,'FindAll', 'on' ...
    ,'BlockType', 'From' ...
    );

for from = froms'
    lh=get(from,'LineHandles');
    op = lh.Outport;
    try
        delete(op)
    end
    delete(from)
end

gains = find_system(block ...
    ,'SearchDepth',1 ...
    ,'FollowLinks','on' ...
    ,'LookUnderMasks','all' ...
    ,'FindAll', 'on' ...
    ,'BlockType', 'Gain' ...
    );

for gain = gains'
    lh=get(gain,'LineHandles');
    op = lh.Outport;
    try
        delete(op)
    end
    delete(gain)
end

portConnectivity = get(block,'PortConnectivity');
nPorts = length(portConnectivity);

try
nInports = 1;
iPort = 2;
iOutport = iPort - nInports;
portCon = portConnectivity(iPort);
dst = portCon.DstBlock;
catch
    return
end

outport = outports(iOutport);

disOrientation = 'right';
offsetFlow = [0, 100, 0, 100];
offsetConstantFlow = [-500, 50, -500, 50];
offsetFlowGain = [100, 0, 100, 0];
 
posOutport = get(outport,'Position');

indices = [];
sigNames = {};
[inflows, gains] = chase('initInflow', portCon, block, indices, sigNames, 1);
nInflows = length(inflows);

backBus = find_system(block ...
    ,'SearchDepth',1 ...
    ,'FollowLinks','on' ...
    ,'LookUnderMasks','all' ...
    ,'Name','BackBus' ...
    );
if strcmp('BusCreator',get(backBus,'BlockType'))
    set(backBus,'Inputs',num2str(max(1,nInflows)))
else
    set(backBus,'numInputs',num2str(max(1,nInflows)))
end

% Add a from for each Inflow found, connect each via a gain to the
% Concatenator
for iInflow = 1:nInflows

    try 
        %% Add From.
        flowName = inflows{iInflow};
        hFrom = add_block('built-in/From', [blockPath '/' flowName], 'MakeNameUnique','on');
        set(hFrom,'Name',flowName);
        set(hFrom,'TagVisibility','global');
        gotoTag = ['tag' flowName];
        gotoTag = gotoTag(1:min(63,length(gotoTag)));
        set(hFrom,'GotoTag',gotoTag);
        set(hFrom,'Orientation',disOrientation);
        posInflow = posOutport + offsetConstantFlow + iInflow*offsetFlow;
        set(hFrom, 'Position', posInflow);
        
        %% Add gain.
        gainName = strrep(flowName, 'Inflow_', 'Gain_');
        hGain = add_block('built-in/Gain', [blockPath '/' gainName]);

        
        gain = gains(iInflow);
        set(hGain, 'Gain', '666');
        set(hGain,'Name',gainName);
        set(hGain, 'Gain', num2str(gain));
        set(hGain,'Orientation',disOrientation);
        posGain = posInflow + offsetFlowGain;
        set(hGain, 'Position', posGain);
        
        %% Link up to Concaternator 'BackBus'
        src = [flowName '/1'];
        dst = [gainName '/1'];
        add_line(block, src, dst);
        
        src = dst;
        dst = ['BackBus/' num2str(iInflow)];
        add_line(block, src, dst);
    end
end

end

%% function [inflows, gains] = chase(soughtInit, portCon, originator, indices, sigNames, gain)
% Chase along fan out from an Out block until we find In blocks.
% Returns cell array of long names of destination In blocks.
% Tries to deal appropriately with special blocks like
% subsystems and buses, muxes and gotos.
% There is a port connectivity for each port of a block.
% The outports can link on to multiple destinations (but no source)
% The inports can have at most one source, but no destination
function [inflows, gains] = chase(soughtInit, portCon, originator, indices, sigNames, gain)

%if nargin < 6
%    gain = 1;
%end

inflows = {};   % default to empty
gains = [];

try
    dstBlocks = portCon.DstBlock;
catch
    return
end

%% Loop over all the destination blocks
for iDstBlock = 1:length(dstBlocks)
    dstBlock = dstBlocks(iDstBlock);
    initFcn = get(dstBlock, 'MaskInitialization');
    %% Hurrah, recognised an inflow on the signal by its mask initialisation!
    if contains(initFcn, soughtInit)
        % If correct init function then must be an inflow, add to list and
        % continue with next destination block.
        inflowName = getLongName(dstBlock);
        % put physical type test here, and set up colouringx
        pc = get(dstBlock,'PortConnectivity');
        
        if ~isempty(sigNames)
            warning('Badly nested signal into %s\n',inflowName);
        end

        inflows{end+1} = inflowName;
        gains(end+1) = gain;
        continue;
    end
    
    %% Else deal with special cases (?switch, subsys, mux etc)
    % If subsys go in and start from appropriate inport
    blockType = get(dstBlock, 'BlockType');

    %% Deal with Commented blocks
    switch get(dstBlock,'Commented')
        case 'on'
            break  % Don't chase after full comments
        case 'through'
            pcs = get(dstBlock, 'PortCon');
            if length(pcs) > 1
                pc = pcs(2);  % commented through must mean one in portcon, one out.
                %inflows = [inflows chase(soughtInit, pc, originator, indices, sigNames)];
                [newInflows, newGains] = chase(soughtInit, pc, originator, indices, sigNames, gain);
                inflows = [inflows newInflows];
                gains = [gains, newGains];
            end
            break
        otherwise
            % Do all the other processing!            
    end
    
    %% TODO: Refactor the following to use a switch, and factor out recursion
    %% Deal with Sum
    if strcmp(blockType,'Sum')
        newPortCons = get(dstBlock,'PortConnectivity');
        inputs = get(dstBlock, 'inputs');
        signCharIndex = portCon.DstPort(iDstBlock)+1;
        if isempty(str2num(inputs))  % not an integer, need to parse signage
            gapless = strrep(inputs,'|','');
            assert(length(gapless)+1 == length(newPortCons),'Wrong number of signs')
            if gapless(signCharIndex) == '-'
                gain = -gain;
            end
        end
        for ipc = 1:length(newPortCons)
        % for pc = newPortCons'
            pc = newPortCons(ipc);
            if ~isempty(pc.DstBlock)
                [newInflows, newGains] = chase(soughtInit, pc, originator, indices, sigNames, gain);
                inflows = [inflows newInflows];
                gains = [gains newGains];
                break
            end
        end
        continue
    end
    
    %% Deal with actual Gain
    if strcmp(blockType,'Gain')
        actualGain = get(dstBlock,'Gain');
        actualGainAsNum = str2num(actualGain);
        newPortCons = get(dstBlock,'PortConnectivity');
        for pc = newPortCons'
            if ~isempty(pc.DstBlock)
                [newInflows, newGains] = chase(soughtInit, pc, originator, indices, sigNames, gain*actualGainAsNum);
                inflows = [inflows newInflows]; 
                gains = [gains newGains];
                break
            end
        end
        continue
    end
    
    %% Deal with Subsystem
    if strcmp(blockType,'SubSystem')
        inports = find_system(dstBlock...
            ,'SearchDepth',1 ...
            ,'LookUnderMasks', 'all'...
            ,'FollowLinks','on' ...
            ,'BlockType', 'Inport'...
            );
        dstPorts = portCon.DstPort;
        portIndex = 1+dstPorts(iDstBlock);
        portToChase = inports(portIndex);
        pc = get(portToChase, 'PortConnectivity');

        [newInflows, newGains] = chase(soughtInit, pc, originator, indices, sigNames, gain);
        inflows = [inflows newInflows];
        gains = [gains newGains];
        continue
    end
    
    %% Deal with Outport - not sure this is the best way to do it but it works!
    % If outport go out and start from appropriate outport.
    if strcmp(blockType,'Outport')
        number = str2double(get(dstBlock,'Port'));
        parent = get(dstBlock,'Parent');
        pc_parent = get_param(parent,'PortConnectivity');
        out_count = 0;
        for ipc_parent = 1:length(pc_parent)
            if isempty(pc_parent(ipc_parent).DstBlock)
                continue
            end
            out_count = out_count + 1;
            if out_count == number
                pc = pc_parent(ipc_parent);

                [newInflows, newGains] = chase(soughtInit, pc, originator, indices, sigNames, gain);
                inflows = [inflows newInflows]; 
                gains = [gains newGains];
            end
        end
        continue
    end
    
    %% Deal with BusSelector
    % If BusSelector choose the signal with name at top of stack.
    if strcmp(blockType,'BusSelector')
       % disp('BusSelector')
       ph = get(dstBlock,'PortHandles');
       outports = ph.Outport;
       for iOutport = 1:length(outports)
           outport = outports(iOutport);
           nameOut = get(outport,'Name');
           nameOut = strrep(nameOut,'<','');
           nameOut = strrep(nameOut,'>','');
           sigName = sigNames{end};
           sigName = strrep(sigName,'<','');
           sigName = strrep(sigName,'>','');
           try
               if strcmp(nameOut,sigName)
                   newSigNames = sigNames;
                   newSigNames(end) = [];
                   newPortCons = get(dstBlock,'PortConnectivity');
                   pc = newPortCons(1+iOutport);
                   [newInflows, newGains] = chase(soughtInit, pc, originator, indices, sigNames, gain);
                   inflows = [inflows newInflows];
                   gains = [gains newGains];
                   break
               end
           end
       end
       continue
    end 
    
    %% Deal with BusCreator
    % If BusCreator put signal name on stack and recurse.
    if strcmp(blockType,'BusCreator')
        % disp('BusCreator')
        phs = get(dstBlock,'Porthandles');
        ph = phs;%(iDstBlock);
        hh = ph.Inport(1+portCon.DstPort(iDstBlock));
        sigName = get(hh,'Name');
        newPortCons = get(dstBlock,'PortConnectivity');
        pc = newPortCons(end);
        newSigNames = sigNames;
        newSigNames{end+1} = sigName;
        [newInflows, newGains] = chase(soughtInit, pc, originator, indices, sigNames, gain);
        inflows = [inflows newInflows];
        gains = [gains newGains];
        continue
    end
    
    %% Deal with Goto
    % If Goto then start again at relevant From.  
    % There can be multiple Froms per Goto.
    if strcmp(blockType,'Goto')
        gotoTag = get(dstBlock,'GotoTag');
        hRoot = get_param(bdroot,'Handle');
        hFroms = find_system(hRoot,'BlockType','From','GotoTag',gotoTag);
        for iFrom = 1:length(hFroms)
            hFrom = hFroms(iFrom);
            pc = get(hFrom,'PortConnectivity');
            [newInflows, newGains] = chase(soughtInit, pc, originator, indices, sigNames, gain);
            inflows = [inflows newInflows];
            gains = [gains newGains];
        end
        continue
    end
    
    %% Deal with Mux
    % If mux then find the index of the inport.
    if strcmp(blockType,'Mux')
        portIndex=portCon.DstPort(iDstBlock)+1;
        newIndices = [indices portIndex];
        newPortCons = get(dstBlock,'PortConnectivity');
        pc = newPortCons(end);
        [newInflows, newGains] = chase(soughtInit, pc, originator, indices, sigNames, gain);
        inflows = [inflows newInflows];
        gains = [gains newGains];
        continue
    end
    
    %% Deal with Demux
    % If demux then get the index.
    if strcmp(blockType,'Demux')
        portIndex = indices(end);
        indices(end) = [];
        newPortCons = get(dstBlock,'PortConnectivity');
        pc = newPortCons(portIndex+1);
        [newInflows, newGains] = chase(soughtInit, pc, originator, indices, sigNames, gain);
        inflows = [inflows newInflows];
        gains = [gains newGains];
        continue
    end
    
end

end

% long unique (up to truncation) block name
function longname = getLongName(h)

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
longname=longname(1:min(63,len));

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

%%%%%%%%%%%%%%%%%%%%%%%%%% junk %%%%%%%%%%%%%%%%%%%%%%%%%
%{
%% No need to check physical type now have bus wrappings
try
            dstColour = eval(get(dstBlock,'colour'));
            srcColour = eval(get(originator,'colour'));
            if any(dstColour~=srcColour)
                warning('Colour doesn''t match into %s\n',inflowName);
            end
        end
        try
            dstPotPrefix = get(dstBlock,'potPrefix');
            srcPotPrefix = get(originator,'potPrefix');
            if ~strcmp(dstPotPrefix,srcPotPrefix)
                %fprintf(2,'Connection to %s has potential (across) variable mismatch\n',inflowName);
                phd = get(dstBlock,'PortHandles');
                portIndex=portCon.DstPort(iDstBlock)+1;
                ph = phd.Inport(iDstBlock);
                line = get(ph,'Line');
                set(line,'HiliteAncestors','error')
                error('Connection to %s has potential (across) variable mismatch.\n',inflowName);
            end
            dstFlowPrefix = get(dstBlock,'flowPrefix');
            srcFlowPrefix = get(originator,'flowPrefix');
            if ~strcmp(dstFlowPrefix,srcFlowPrefix)
                %fprintf(2,'Connection to %s has flow (through) variable mismatch\n',inflowName);
                phd = get(dstBlock,'PortHandles');
                portIndex=portCon.DstPort(iDstBlock)+1;
                ph = phd.Inport(iDstBlock);
                line = get(ph,'Line');
                set(line,'HiliteAncestors','error')
                error('Connection to %s has flow (through) variable mismatch.\n',inflowName);
            end
        end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% label the level and flow names
longName = getLongName(block);
%levelVarName = get(block,'Level');
%flowVarName = get(block,'Flow');
%underscoredName = getUnderscoredName(block);
%lvl_out = find_system(block, 'RegExp', 'on', 'FollowLinks', 'on' ,'LookUnderMasks','all', 'FindAll', 'on', 'Name', levelVarName,'Type','line');

%lvl_out = find_system(block, 'FollowLinks', 'on' ,'LookUnderMasks','all', 'FindAll', 'on', 'Name', 'Level','Type','line');
%set(lvl_out,'DataLogging',1)
%levelName =  [levelVarName underscoredName];
%set(lvl_out,'DataLoggingNameMode','Custom')
%set(lvl_out, 'DataLoggingName', levelName)
%%flw_out = find_system(block, 'RegExp', 'on', 'FollowLinks', 'on' ,'LookUnderMasks','all', 'FindAll', 'on', 'Name', flowVarName,'Type','line');
%flw_out = find_system(block,  'FollowLinks', 'on' ,'LookUnderMasks','all', 'FindAll', 'on', 'Name', 'Flow','Type','line');
%flowName =  [flowVarName underscoredName];
%set(flw_out,'DataLogging',1)
%set(flw_out,'DataLoggingNameMode','Custom')
%set(flw_out, 'DataLoggingName', flowName)


%}

        
