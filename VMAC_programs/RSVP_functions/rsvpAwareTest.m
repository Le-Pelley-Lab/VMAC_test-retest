function clickedCorrectResponse = rsvpAwareTest

global MainWindow
global DATA
global bColour white screenWidth screenHeight
global rewardString1 neutralString1
global awareTestPoints session cueBalance

yellow = [255, 255, 0];

instrWindow = Screen('OpenOffscreenWindow', MainWindow, bColour);
Screen('TextFont', instrWindow, 'Segoe UI');
Screen('TextStyle', instrWindow, 0);
Screen('TextSize', instrWindow, 40);

%%% SET INSTRUCTIONS
instrString = ['You''ve completed the main task - well done!\n\nNow we have one final test.'];
instrString2 = '\n\n\nWhat type of trial was it when one of the images was a ';
%instrString2 = '\n\n\nWhich type of picture was more likely to appear in the stream of images on REWARD TRIALS (i.e., trials on which you could win or lose points)?';
instrString3 = 'Please click on one of the options to make your response';
lineLength = 94;
textLeft = 140;

if strcmp(session, '1')
    switch cueBalance
        case {1, 3}
            distString(1,:) = 'BIRD     ';
            distString(2,:) = 'BICYCLE  ';
        case {2, 4}
            distString(1,:) = 'BICYCLE  ';
            distString(2,:) = 'BIRD     ';
    end
else
    switch cueBalance
        case {1, 2}
            distString(1,:) = 'CHAIR    ';
            distString(2,:) = 'CAR      ';
        case {3, 4}
            distString(1,:) = 'CAR      ';
            distString(2,:) = 'CHAIR    ';
    end
end


awareTrialOrder = randperm(2); %randomly decide whether rewarded or unrewarded trial goes first

%%% CREATE RESPONSE OPTIONS
responseRectHeight = 120;
responseRect = [0, 0, 500, responseRectHeight];
informFramePenWidth = 3;

responseGap = 270;
imageHeight = 620;
instrString3Top = 740;

for ii = 1 : 2
    responseWindow(ii) = Screen('OpenOffscreenWindow', MainWindow, bColour, responseRect); %#ok<AGROW>
    Screen('FrameRect', responseWindow(ii), yellow, responseRect, informFramePenWidth);
    Screen('TextFont', responseWindow(ii), 'Segoe UI');
    Screen('TextStyle', responseWindow(ii), 1);
    Screen('TextSize', responseWindow(ii), 48);
end

DrawFormattedText(responseWindow(1), 'REWARD trial', 'center', 'center', yellow);
DrawFormattedText(responseWindow(2), 'NO-REWARD trial', 'center', 'center', yellow);


%%% CREATE CONFIDENCE BUTTONS
confButtons = 5;
confButtonSide = 100;
confButtonGap = 100;

confCentreY = 920;
confButtonRect = [0, 0, confButtonSide, confButtonSide];

confCentreX = zeros(confButtons, 1);

for ii = 1 : confButtons
    confButtonWin(ii) = Screen('OpenOffscreenWindow', MainWindow, bColour, confButtonRect); %#ok<AGROW>
    Screen('FrameRect', confButtonWin(ii), white, confButtonRect, informFramePenWidth);
    Screen('TextFont', confButtonWin(ii), 'Segoe UI');
    Screen('TextStyle', confButtonWin(ii), 1);
    Screen('TextSize', confButtonWin(ii), 48);
    DrawFormattedText(confButtonWin(ii), num2str(ii), 'center', 'center', white);
    
    confCentreX(ii) = screenWidth/2 + (ii - (confButtons + 1) / 2) * (confButtonSide + confButtonGap);
    
end


%%%%%%% SET UP LABELS ON CONFIDENCE SCALE
confLabelMinString = 'not at all\nconfident';
confLabelMaxString = 'totally\nconfident';

cyan = [0, 255, 255];

confLabelHeight = 200;
confLabelRect = [0, 0, 300, confLabelHeight];

confLabelMinWindow = Screen('OpenOffscreenWindow', MainWindow, bColour, confLabelRect);
Screen('TextFont', confLabelMinWindow, 'Segoe UI');
Screen('TextStyle', confLabelMinWindow, 1);
Screen('TextSize', confLabelMinWindow, 26);
DrawFormattedText(confLabelMinWindow, confLabelMinString, 'center', 20, cyan);

confLabelMaxWindow = Screen('OpenOffscreenWindow', MainWindow, bColour, confLabelRect);
Screen('TextFont', confLabelMaxWindow, 'Segoe UI');
Screen('TextStyle', confLabelMaxWindow, 1);
Screen('TextSize', confLabelMaxWindow, 26);
DrawFormattedText(confLabelMaxWindow, confLabelMaxString, 'center', 20, cyan);



for t = 1 : 2
%%% DRAW INITIAL RESPONSE SCREEN

questionString = [instrString2, strtrim(distString(awareTrialOrder(t),:)), '?'];

[~, ny, ~] = DrawFormattedText(instrWindow, instrString, textLeft, 100, white, lineLength, [], [], 1.3);
DrawFormattedText(instrWindow, questionString, textLeft, ny, yellow, lineLength, [], [], 1.3);

Screen('TextSize', instrWindow, 28);
DrawFormattedText(instrWindow, instrString3, 'center', instrString3Top, white);


%awarenessOrder = randi(2);  % 1 = correct response on left, 2 = correct response on right

% 
if awareTrialOrder(t) == 1
    correctResponseRect = CenterRectOnPoint(responseRect, screenWidth/2 - responseGap, imageHeight);
    incorrectResponseRect = CenterRectOnPoint(responseRect, screenWidth/2 + responseGap, imageHeight);
else
    correctResponseRect = CenterRectOnPoint(responseRect, screenWidth/2 + responseGap, imageHeight);
    incorrectResponseRect = CenterRectOnPoint(responseRect, screenWidth/2 - responseGap, imageHeight);
end

Screen('DrawTexture', instrWindow, responseWindow(1), [], CenterRectOnPoint(responseRect, screenWidth/2 - responseGap, imageHeight));
Screen('DrawTexture', instrWindow, responseWindow(2), [], CenterRectOnPoint(responseRect, screenWidth/2 + responseGap, imageHeight));

Screen('DrawTexture', MainWindow, instrWindow);

ShowCursor('Arrow');

Screen('Flip', MainWindow);


%%% GET INITIAL MOUSE RESPONSE

clickedCorrectResponse = 999;
while clickedCorrectResponse == 999
    [~, mouseX, mouseY, ~] = GetClicks(MainWindow, 0);
    if IsInRect(mouseX, mouseY, correctResponseRect)
        clickedCorrectResponse = 1;
        Screen('FillRect', instrWindow, bColour, incorrectResponseRect);    % Hide alternative response option
        %fbString = ['Your choice was: CORRECT.\n\n', num2str(awareTestPoints), ' points have been added to your total.'];
    elseif IsInRect(mouseX, mouseY, incorrectResponseRect)
        clickedCorrectResponse = 0;
        Screen('FillRect', instrWindow, bColour, correctResponseRect);    % Hide alternative response option
        %fbString = 'Your choice was: INCORRECT.\n\n0 points have been added to your total.';
    end
end
fbString = ['\n\n\nPlease press space to continue'];



%%%%%%%%%% REQUEST CONFIDENCE RATING

Screen('FillRect', instrWindow, bColour, [0, imageHeight + responseRectHeight/2 + 10, screenWidth, screenHeight]);

confResponseLocation = zeros(confButtons, 4);
DrawFormattedText(instrWindow, 'How confident are you of this choice?', 'center', confCentreY - confButtonSide/2 - 50, white);
for ii = 1 : confButtons
    confResponseLocation(ii, :) = CenterRectOnPoint(confButtonRect, confCentreX(ii), confCentreY);
    Screen('DrawTexture', instrWindow, confButtonWin(ii), [], confResponseLocation(ii, :));
end
Screen('DrawTexture', instrWindow, confLabelMinWindow, [], CenterRectOnPoint(confLabelRect, confCentreX(1), confCentreY + confButtonSide/2 + confLabelHeight/2 + 20));
Screen('DrawTexture', instrWindow, confLabelMaxWindow, [], CenterRectOnPoint(confLabelRect, confCentreX(confButtons), confCentreY + confButtonSide/2 + confLabelHeight/2 + 20));

Screen('DrawTexture', MainWindow, instrWindow);
Screen('Flip', MainWindow);

clickedConfButton = 0;
while clickedConfButton == 0
    [~, mouseX, mouseY, ~] = GetClicks(MainWindow, 0);
    for ii = 1 : confButtons
        if IsInRect(mouseX, mouseY, confResponseLocation(ii, :))
            clickedConfButton = ii;
        end
    end
end


DATA.awareTestInfo(t,:) = [awareTrialOrder(t), clickedCorrectResponse, clickedConfButton];
    



%%%% GIVE FEEDBACK

HideCursor;

Screen('TextSize', instrWindow, 40);

Screen('FillRect', instrWindow, bColour);
DrawFormattedText(instrWindow, fbString, 'center', 'center', white);
Screen('DrawTexture', MainWindow, instrWindow);
Screen('Flip', MainWindow);

RestrictKeysForKbCheck(KbName('Space'));   % Only accept spacebar
KbWait([], 2);

Screen('FillRect', instrWindow, bColour);

end

%%%% CLOSE WINDOWS AND RETURN TO MAIN FUNCTION

Screen('Close', instrWindow);
Screen('Close', confLabelMinWindow);
Screen('Close', confLabelMaxWindow);
for ii = 1 : 2
    Screen('Close', responseWindow(ii));
end
for ii = 1 : confButtons
    Screen('Close', confButtonWin(ii));
end

end