function VMAC_TR_DataAnalysis()
%% set up globals and other important variables
clearvars
clc

commandwindow;

global numBlocks distractTypes fid1 exptSessions 


RemoveInitial_N_trials = 2;
Remove_N_trialsAfterBreak = 2;

%Lower limit of proportion of good gaze samples required to be analysed. In
%line with previous papers.
requiredTrialPropGoodSamples = 0.25;

defaultMinSubNumber  = 1;
defaultMaxSubNumber = 150;

minSubNumber = input(['Lowest participant number (default = ', num2str(defaultMinSubNumber), ') ---> ']);
maxSubNumber = input(['Highest participant number (default = ', num2str(defaultMaxSubNumber), ') ---> ']);

if isempty(minSubNumber)
    minSubNumber = defaultMinSubNumber;
end
if isempty(maxSubNumber)
    maxSubNumber = defaultMaxSubNumber;
end

exptSessions = 2;
parentPath = cd(cd('..'));
dataFileFolder = [parentPath, '/raw_data/'];
infoFileFolder = [parentPath, '/participant_details/'];

%% Set up for basic participant info
subNumSummary = zeros(maxSubNumber, 1);
ageSummary = zeros(maxSubNumber, 1);
sexSummary = cell(maxSubNumber, 1);
handSummary = cell(maxSubNumber, 1);
counterbalSummary = zeros(maxSubNumber, 1);
startTimeSummary = cell(maxSubNumber, exptSessions);
finishTimeSummary = cell(maxSubNumber, exptSessions);
totalPayment = zeros(maxSubNumber,1);

%% Set up for spatial RT analysis
distractTypes = 3;
awareTestTrials = 2;
spatialTrials = 288;
numBlocks = zeros(1,exptSessions);
numBlocks(:) = 12;


maxBlocks = max(numBlocks(:));

% Data storage matrices - 1 added here to make outputting work smoothly
% across both spatial and rsvp tasks
rtStoreBlock = zeros(maxSubNumber, distractTypes, exptSessions, maxBlocks, 1);
rtStoreSession = zeros(maxSubNumber, distractTypes, exptSessions, 1);
rtStoreAll = zeros(maxSubNumber, distractTypes, 1);

rtStoreBlock_num = zeros(maxSubNumber, distractTypes, exptSessions, maxBlocks, 1);
rtStoreSession_num = zeros(maxSubNumber, distractTypes, exptSessions, 1);
rtStoreAll_num = zeros(maxSubNumber, distractTypes, 1);

accStoreBlock = zeros(maxSubNumber, distractTypes, exptSessions, maxBlocks, 1);
accStoreSession = zeros(maxSubNumber, distractTypes, exptSessions, 1);
accStoreAll = zeros(maxSubNumber, distractTypes, 1);

accStoreBlock_num = zeros(maxSubNumber, distractTypes, exptSessions, maxBlocks, 1);
accStoreSession_num = zeros(maxSubNumber, distractTypes, exptSessions, 1);
accStoreAll_num = zeros(maxSubNumber, distractTypes, 1);

missingTrials = zeros(maxSubNumber, exptSessions);
awareButtonSummary = zeros(maxSubNumber, awareTestTrials);
awareConfSummary = zeros(maxSubNumber, awareTestTrials);

trialTimeouts = zeros(maxSubNumber, exptSessions);
trialSoftTimeouts = zeros(maxSubNumber, exptSessions);
trialsSummary = zeros(maxSubNumber, exptSessions);

%% Set up for RSVP analysis
rsvpTrials = 280;
rsvpBlocks = zeros(1, exptSessions);
rsvpBlocks(:) = 7;
rsvpDistractTypes = 3;
rsvpLags = 2;


rsvpMaxBlocks = max(rsvpBlocks(:));

% RSVP Data storage
rsvpRtStoreBlock = zeros(maxSubNumber, rsvpDistractTypes, exptSessions, rsvpMaxBlocks, rsvpLags);
rsvpRtStoreSession = zeros(maxSubNumber, rsvpDistractTypes, exptSessions, rsvpLags);
rsvpRtStoreAll = zeros(maxSubNumber, rsvpDistractTypes, rsvpLags);

rsvpRtStoreBlock_num = zeros(maxSubNumber, rsvpDistractTypes, exptSessions, rsvpMaxBlocks, rsvpLags);
rsvpRtStoreSession_num = zeros(maxSubNumber, rsvpDistractTypes, rsvpLags, exptSessions);
rsvpRtStoreAll_num = zeros(maxSubNumber, rsvpDistractTypes, rsvpLags);

rsvpAccStoreBlock = zeros(maxSubNumber, rsvpDistractTypes, exptSessions, rsvpMaxBlocks, rsvpLags);
rsvpAccStoreSession = zeros(maxSubNumber, rsvpDistractTypes, exptSessions, rsvpLags);
rsvpAccStoreAll = zeros(maxSubNumber, rsvpDistractTypes, rsvpLags);

rsvpAccStoreBlock_num = zeros(maxSubNumber, rsvpDistractTypes, exptSessions, rsvpMaxBlocks, rsvpLags);
rsvpAccStoreSession_num = zeros(maxSubNumber, rsvpDistractTypes, exptSessions, rsvpLags);
rsvpAccStoreAll_num = zeros(maxSubNumber, rsvpDistractTypes, rsvpLags);

rsvpMissingTrials = zeros(maxSubNumber, exptSessions);

%% Start running the analysis - initially participant info

for subNum = minSubNumber : maxSubNumber
    
    fileCounter = 0;
    
    infoFilename = [infoFileFolder, 'participant', num2str(subNum), '.mat'];
    dataFilenameBase = [dataFileFolder, 'participant', num2str(subNum), 'session'];
    
    if exist(infoFilename, 'file') == 2 && exist([dataFilenameBase, '2.mat'], 'file') == 2 %if the info file and second session data exists
        
        fileCounter = fileCounter + 1;
        
        load(infoFilename);
        
        subNumSummary(fileCounter) = str2double(participant('number'));
        ageSummary(fileCounter) = str2double(participant('age'));
        sexSummary{fileCounter} = participant('gender');
        handSummary{fileCounter} = participant('hand');
        counterbalSummary(fileCounter) = participant('counterbalance');
        
        for sessionNum = 1:2
            dataFilename = [dataFilenameBase, num2str(sessionNum), '.mat'];
            
            if exist(dataFilename, 'file') == 2
                
                load(dataFilename);
                
                startTimeSummary{fileCounter, sessionNum} = experiment('start');
                finishTimeSummary{fileCounter, sessionNum} = experiment('finish');
                
                if sessionNum == 2
                    totalPayment(fileCounter) = experiment('bonus_total');
                end
                
                %% Spatial VMAC RT analysis
                exptKey = 'spatial';
                
                spatialData = experiment(exptKey);
                
                spatialTrialData = spatialData.expttrialInfoSpatial;
                
                
                for t = 1 : spatialTrials
                    exptSession_data = spatialTrialData(t,1);
                    block_data = spatialTrialData(t,2);
                    trial_data = spatialTrialData(t,3);
                    trialCounter_data = spatialTrialData(t,4);
                    trials_since_break_data = spatialTrialData(t,5);
                    targetLoc_data = spatialTrialData(t,6);
                    targetType_data = spatialTrialData(t,7);
                    distractLoc_data = spatialTrialData(t,8);
                    distractType_data = spatialTrialData(t,9);
                    searchTimeout_data = spatialTrialData(t,10);
                    accuracy_data = spatialTrialData(t,11);
                    rt_data = spatialTrialData(t,12);
                    trialPay_data = spatialTrialData(t,13);
                    sessionPoints_data = spatialTrialData(t,14);
                    
                    if block_data == 0
                        
                        missingTrials(fileCounter, sessionNum) = missingTrials(fileCounter, sessionNum) + 1;
                        
                    else
                        
                        if trial_data > RemoveInitial_N_trials && trials_since_break_data > Remove_N_trialsAfterBreak
                            
                            if searchTimeout_data ~=1 %If not a timeout
                                
                                %Store RT data
                                rtStoreBlock(fileCounter, distractType_data, sessionNum, block_data, 1) = rtStoreBlock(fileCounter, distractType_data, sessionNum, block_data, 1) + rt_data;
                                rtStoreSession(fileCounter, distractType_data, sessionNum, 1) = rtStoreSession(fileCounter, distractType_data, sessionNum, 1) + rt_data;
                                rtStoreAll(fileCounter, distractType_data, 1) = rtStoreAll(fileCounter, distractType_data, 1) + rt_data;
                                
                                rtStoreBlock_num(fileCounter, distractType_data, sessionNum, block_data, 1) = rtStoreBlock_num(fileCounter, distractType_data, sessionNum, block_data, 1) + 1;
                                rtStoreSession_num(fileCounter, distractType_data, sessionNum, 1) = rtStoreSession_num(fileCounter, distractType_data, sessionNum, 1) + 1;
                                rtStoreAll_num(fileCounter, distractType_data, 1) = rtStoreAll_num(fileCounter, distractType_data, 1) + 1;
                                
                                %Store Accuracy data
                                accStoreBlock(fileCounter, distractType_data, sessionNum, block_data, 1) = accStoreBlock(fileCounter, distractType_data, sessionNum, block_data, 1) + accuracy_data;
                                accStoreSession(fileCounter, distractType_data, sessionNum, 1) = accStoreSession(fileCounter, distractType_data, sessionNum, 1) + accuracy_data;
                                accStoreAll(fileCounter, distractType_data, 1) = accStoreAll(fileCounter, distractType_data, 1) + accuracy_data;
                                
                                accStoreBlock_num(fileCounter, distractType_data, sessionNum, block_data, 1) = accStoreBlock_num(fileCounter, distractType_data, sessionNum, block_data, 1) + 1;
                                accStoreSession_num(fileCounter, distractType_data, sessionNum, 1) = accStoreSession_num(fileCounter, distractType_data, sessionNum, 1) + 1;
                                accStoreAll_num(fileCounter, distractType_data, 1) = accStoreAll_num(fileCounter, distractType_data, 1) + 1;
                                
                            end
                        end
                    end
                end
                
                %% Spatial awareness test analysis
                
                if isfield(spatialData, 'awareTestInfo')
                    
                    spatialAwareData = spatialData.awareTestInfo;
                    
                    for ii = 1 : awareTestTrials

                        awareButtonSummary(fileCounter, spatialAwareData(ii, 2)) = spatialAwareData(ii, 3);
                        awareConfSummary(fileCounter, spatialAwareData(ii, 2)) = spatialAwareData(ii, 4);

                    end
                    
                end
                
                %% RSVP accuracy/RT analysis
                
                exptKey = 'rsvp';
                
                rsvpData = experiment(exptKey);
                
                rsvpTrialData = rsvpData.trialInfo(2).trialData;
                
                for t = 1 : rsvpTrials
                    rsvpBlock_data = rsvpTrialData(t,1);
                    rsvpTrial_data = rsvpTrialData(t,2);
                    rsvpDistractType_data = rsvpTrialData(t,3);
                    rsvpRawLag_data = rsvpTrialData(t,4);
                    
                    if rsvpRawLag_data == 2
                        rsvpLag_data = 1;
                    elseif rsvpRawLag_data == 4
                        rsvpLag_data = 2;
                    else
                        error('Something has gone wrong to do with Lags')
                    end
                    
                    rsvpDistractPosition_data = rsvpTrialData(t,5);
                    rsvpTargetPosition_data = rsvpTrialData(t,6);
                    rsvpTargetRotation_data = rsvpTrialData(t,7);
                    rsvpDistractID_data = rsvpTrialData(t,8);
                    rsvpTargetID_data = rsvpTrialData(t,9);
                    rsvpAccuracy_data = rsvpTrialData(t,10);
                    rsvpRT_data = rsvpTrialData(t,11);
                    rsvpSessionPoints_data = rsvpTrialData(t,12);
                    rsvpStreamTime_data = rsvpTrialData(t,13);
                    
                    if rsvpBlock_data == 0
                        
                        rsvpMissingTrials(fileCounter, sessionNum) = rsvpMissingTrials(fileCounter, sessionNum) + 1;
                    
                    else
                        
                        rsvpRtStoreBlock(fileCounter, rsvpDistractType_data, sessionNum, rsvpBlock_data, rsvpLag_data) = rsvpRtStoreBlock(fileCounter, rsvpDistractType_data, sessionNum, rsvpBlock_data , rsvpLag_data) + rsvpRT_data;
                        rsvpRtStoreSession(fileCounter, rsvpDistractType_data, sessionNum, rsvpLag_data) = rsvpRtStoreSession(fileCounter, rsvpDistractType_data, sessionNum, rsvpLag_data) + rsvpRT_data;
                        rsvpRtStoreAll(fileCounter, rsvpDistractType_data, rsvpLag_data) = rsvpRtStoreAll(fileCounter, rsvpDistractType_data, rsvpLag_data) + rsvpRT_data;

                        rsvpRtStoreBlock_num(fileCounter, rsvpDistractType_data, sessionNum, rsvpBlock_data, rsvpLag_data) =  rsvpRtStoreBlock_num(fileCounter, rsvpDistractType_data, sessionNum, rsvpBlock_data, rsvpLag_data) + 1;
                        rsvpRtStoreSession_num(fileCounter, rsvpDistractType_data, sessionNum , rsvpLag_data) = rsvpRtStoreSession_num(fileCounter, rsvpDistractType_data, sessionNum, rsvpLag_data) + 1;
                        rsvpRtStoreAll_num(fileCounter, rsvpDistractType_data, rsvpLag_data) = rsvpRtStoreAll_num(fileCounter, rsvpDistractType_data, rsvpLag_data) + 1;

                        rsvpAccStoreBlock(fileCounter, rsvpDistractType_data, sessionNum, rsvpBlock_data, rsvpLag_data) = rsvpAccStoreBlock(fileCounter, rsvpDistractType_data, sessionNum, rsvpBlock_data, rsvpLag_data) + rsvpAccuracy_data;
                        rsvpAccStoreSession(fileCounter, rsvpDistractType_data, sessionNum, rsvpLag_data) = rsvpAccStoreSession(fileCounter, rsvpDistractType_data, sessionNum, rsvpLag_data) + rsvpAccuracy_data;
                        rsvpAccStoreAll(fileCounter, rsvpDistractType_data, rsvpLag_data) = rsvpAccStoreAll(fileCounter, rsvpDistractType_data, rsvpLag_data) + rsvpAccuracy_data;

                        rsvpAccStoreBlock_num(fileCounter, rsvpDistractType_data, sessionNum, rsvpBlock_data, rsvpLag_data) = rsvpAccStoreBlock_num(fileCounter, rsvpDistractType_data, sessionNum, rsvpBlock_data, rsvpLag_data) + 1;
                        rsvpAccStoreSession_num(fileCounter, rsvpDistractType_data, sessionNum, rsvpLag_data) = rsvpAccStoreSession_num(fileCounter, rsvpDistractType_data, sessionNum, rsvpLag_data) + 1;
                        rsvpAccStoreAll_num(fileCounter, rsvpDistractType_data, rsvpLag_data) = rsvpAccStoreAll_num(fileCounter, rsvpDistractType_data, rsvpLag_data) + 1;
                        
                    end
                end
                
                
                
            else
                
                disp(['File ', dataFilename, ' not found']);
                
            end
            
            clear spatialData rsvpData spatialTrialData rsvpTrialData experiment participant
            
        end
        
    
        
        %% Figure out the proportions
        
        rtStoreBlock(fileCounter, :, :, :, :) =  rtStoreBlock(fileCounter, :, :, :, :) ./ rtStoreBlock_num(fileCounter, :, :, :, :);
        rtStoreSession(fileCounter, :, :, :) = rtStoreSession(fileCounter, :, :, :) ./ rtStoreSession_num(fileCounter, :, :, :);
        rtStoreAll(fileCounter, :, :) = rtStoreAll(fileCounter, :, :) ./ rtStoreAll_num(fileCounter, :, :);
        
        accStoreBlock(fileCounter, :, :, :, :) = accStoreBlock(fileCounter, :, :, :, :) ./ accStoreBlock_num(fileCounter, :, :, :, :);
        accStoreSession(fileCounter, :, :, :) = accStoreSession(fileCounter, :, :, :) ./ accStoreSession_num(fileCounter, :, :, :);
        accStoreAll(fileCounter, :, :) = accStoreAll(fileCounter, :, :) ./ accStoreAll_num(fileCounter, :, :);
        
        rsvpRtStoreBlock(fileCounter, :, :, :, :) = rsvpRtStoreBlock(fileCounter, :, :, :, :) ./ rsvpRtStoreBlock_num(fileCounter, :, :, :, :);
        rsvpRtStoreSession(fileCounter, :, :, :) = rsvpRtStoreSession(fileCounter, :, :, :) ./ rsvpRtStoreSession_num(fileCounter, :, :, :);
        rsvpRtStoreAll(fileCounter, :, :) = rsvpRtStoreAll(fileCounter, :, :) ./ rsvpRtStoreAll_num(fileCounter, :, :);
        
        rsvpAccStoreBlock(fileCounter, :, :, :, :) = rsvpAccStoreBlock(fileCounter, :, :, :, :) ./ rsvpAccStoreBlock_num(fileCounter, :, :, :, :);
        rsvpAccStoreSession(fileCounter, :, :, :) = rsvpAccStoreSession(fileCounter, :, :, :) ./ rsvpAccStoreSession_num(fileCounter, :, :, :);
        rsvpAccStoreAll(fileCounter, :, :) = rsvpAccStoreAll(fileCounter, :, :) ./ rsvpAccStoreAll_num(fileCounter, :, :);
        
        end
        
end
        

    
%% Output the Data

exptName = 'VMAC_TR';
    for outputType = 1 : 4
        
        if outputType == 1
            
            outDataBlock = rtStoreBlock;
            outDataSession = rtStoreSession;
            outDataAll = rtStoreAll;
            dTypes = distractTypes;
            nBlocks = numBlocks;
            numVariants = 1;
            
            outString = 'spatialRT';
            
        elseif outputType == 2
            
            outDataBlock = accStoreBlock;
            outDataSession = accStoreSession;
            outDataAll = accStoreAll;
            dTypes = distractTypes;
            nBlocks = numBlocks;
            numVariants = 1;
            
            outString = 'spatialACC';
            
        elseif outputType == 3
            
            outDataBlock = rsvpRtStoreBlock;
            outDataSession = rsvpRtStoreSession;
            outDataAll = rsvpRtStoreAll;
            dTypes = rsvpDistractTypes;
            nBlocks = rsvpBlocks;
            numVariants = 2;
            
            outString = 'rsvpRT';
            
        elseif outputType == 4
            
            outDataBlock = rsvpAccStoreBlock;
            outDataSession = rsvpAccStoreSession;
            outDataAll = rsvpAccStoreAll;
            dTypes = rsvpDistractTypes;
            nBlocks = rsvpBlocks;
            numVariants = 2;
            
            outString = 'rsvpACC';
        end
        
        fid1 = fopen([exptName, '_', outString, '.csv'], 'w');
        
        for outRow = 0 : fileCounter
            
            headerRow = false;
            if outRow == 0
                headerRow = true;
            end
            
            if headerRow
                fprintf(fid1, 'subNum,');
                fprintf(fid1, 'age,');
                fprintf(fid1, 'sex,');
                fprintf(fid1, 'hand,');
                fprintf(fid1, 'counterbal,');
                fprintf(fid1, 'bonus,');
                fprintf(fid1, 'session1time,');
                fprintf(fid1, 'session2time,');
                fprintf(fid1, 'spatialMissing1,');
                fprintf(fid1, 'spatialMissing2,');
                fprintf(fid1, 'spatialTrialTimeouts1,');
                fprintf(fid1, 'spatialTrialTimeouts2,');
            else
                
                fprintf(fid1, '%d,', subNumSummary(outRow));
                fprintf(fid1, '%d,', ageSummary(outRow));
                fprintf(fid1, [char(sexSummary(outRow)), ',']);
                fprintf(fid1, [char(handSummary(outRow)), ',']); 
                fprintf(fid1, '%d,', counterbalSummary(outRow));
                fprintf(fid1, '%f,', totalPayment(outRow,:));
                fprintf(fid1, [char(startTimeSummary(outRow,1)), ',']);
                fprintf(fid1, [char(startTimeSummary(outRow,2)), ',']);
                fprintf(fid1, '%d,', missingTrials(outRow, :));
                fprintf(fid1, '%d,', trialTimeouts(outRow, :));
                
            end
            
%             for exptSession = 1 : exptSessions
%                     if headerRow
%                         fprintf(fid1, ['trials_S', num2str(exptSession), ',']);
%                     else
%                         fprintf(fid1,'%d,', trialsSummary(outRow, exptSession));
%                     end
%             end
%             
            if outputType == 1 || outputType == 2
                fprintf(fid1,',');
                for ii = 1 : awareTestTrials

                    if headerRow

                        fprintf(fid1, ['awareButtonD', num2str(ii), ',']);
                        fprintf(fid1, ['awareConfD', num2str(ii), ',']);

                    else

                        fprintf(fid1, '%d,', awareButtonSummary(outRow, ii));
                        fprintf(fid1, '%d,', awareConfSummary(outRow, ii));

                    end
                end
            end

            
            fprintf(fid1,',');
            for distractType = 1 : dTypes
                for variant = 1 : numVariants

                    if headerRow
                        fprintf(fid1, ['ALL_', outString, '_D', num2str(distractType), 'V', num2str(variant), ',']);
                    else
                        fprintf(fid1,'%8.6f,', outDataAll(outRow, distractType, variant));
                    end

                end
            end
            fprintf(fid1,',');

            
            fprintf(fid1,',');

            for exptSession = 1 : exptSessions
                for distractType = 1 : distractTypes
                    for variant = 1 : numVariants

                        if headerRow
                            fprintf(fid1, ['SES_', outString, '_S', num2str(exptSession), 'D', num2str(distractType), 'V', num2str(variant), ',']);
                        else
                            fprintf(fid1,'%8.6f,', outDataSession(outRow, distractType, exptSession, variant));
                        end

                    end
                end
            end
            fprintf(fid1,',');
            
            fprintf(fid1,',');
            
            for exptSession = 1 : exptSessions
                for distractType = 1 : distractTypes
                    for variant = 1 : numVariants
                        for block = 1 : nBlocks

                            if headerRow
                                fprintf(fid1, ['SES_', outString, '_S', num2str(exptSession), 'D', num2str(distractType), 'V', num2str(variant), 'B', num2str(block), ',']);
                            else
                                fprintf(fid1,'%8.6f,', outDataBlock(outRow, distractType, exptSession, block, variant));
                            end

                        end
                        fprintf(fid1,',');
                    end
                end
            end

            
            fprintf(fid1, '\n');
            
        end
        
        fclose(fid1);
        
    end
    
    disp(' ');
    disp(['Finished: ', num2str(fileCounter), ' files processed']);
    
    
    clear all
    
end




