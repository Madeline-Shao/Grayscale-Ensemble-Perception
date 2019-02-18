%the grayscale version of the other ensemble perception experiment
try
	clear all;
    close all;
    
    %% List of variables
	% response: column 1 = participant response; column 2 = actual average race; column 3 = # of stimuli displayed
    % black = stored texture ids of black faces
    % white = stored texture ids of white faces
    % order = shuffled vector to choose whether to show six or one face(s)
	% normalDistribution = shuffled pairs of white/black; possible folder combinations
    % nameID = uppercase participant's intials 
    % current = current pathway
    % window = the window pointer
    % rect = coordinates of the screen
    % window_w = width of screen
    % window_h = height of screen
    % center_x = x coord of center of screen
    % center_y = y coord of center of screen
    % ntrials = number of trials
    % scale_texture = texture of the rating scale image
    % scale_size =  size of scale image
    % scale_height = height of scale image
    % scale_width = width of scale image
    % image_size =  size of stimuli
    % image_height = height of stimuli
    % image_width = width of stimuli
    % xy_rect6 = grid for 6 stimuli
    % xy_rect = grid to draw the rating scale image

    %% screen/participant info setup
    
    % input participant's name, gender, age, race in command window
    int = input('Participant Initial: ', 's');
    nameID = upper(int); %capitalize initials
    age = input('Participant Age: ', 's');
    gender = input('Participant Gender: ', 's');
    race = input('Participant Race: ', 's');
    ParticipantInfo = {nameID, age, gender, race}; %put participant's info into a matrix

    % get current pathway
	current = pwd();

	% if there is no result folder, create one
    % if multiple participants have the same initials, 
    % add "-2" or "-3" and so on to their folder name
    % ex: "MS-2"
	if ~isdir([current '/Participant_Data_Grayscale/' nameID]) %if no one has the same initials so far, creates the folder named with just the initials
    	mkdir([current '/Participant_Data_Grayscale/' nameID]);
    else
        s=1;
        name = nameID;
        while isdir([current '/Participant_Data_Grayscale/' nameID]) %while a folder with that name exists, increase the "number" by one
            s=s+1;
            nameID=strcat(name, '-', num2str(s));
            if ~isdir([current '/Participant_Data_Grayscale/' nameID]) %if no folder with that name exists, create the folder and break from the loop
                mkdir([current '/Participant_Data_Grayscale/' nameID]);
                break;
            end
        end
    end
    
    
	% screen setup
    Screen('Preference', 'SkipSyncTests', 1);
    RandStream.setGlobalStream(RandStream('mt19937ar','seed',sum(100*clock))); %seeds randomizer
    [window, rect] = Screen('OpenWindow', 0); % opening the screen %opens window
    Screen('BlendFunction', window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); % allowing transparency in the photos
    HideCursor(); %hides cursor
    KbName('UnifyKeyNames'); %unifies key names

	% defining size of screen
    window_w = rect(3); 
    window_h = rect(4);

	%x and y coord of center of screen
    center_x = window_w/2; 
    center_y = window_h/2;

	%% loading stimuli, creating variables, grid, randomization etc.
	%number of trials
    ntrials=98; 
    
    %randomization vector: this will be used to randomize whether the
    %participant sees 1 or 6 faces
    conditions = repmat([1, 6], 1, ntrials/2);  % create a vector using repmat where 1 represents one condition (single face). 6 represents the other condition (6 faces). 
	order = Shuffle(conditions); % shuffle the above vector. 

	%read in the normal distribution matrix to choose how many african american/caucasian in each group
	normal = xlsread('Possible_Folder_Combinations.xlsx');
    normal = normal(1:98, :);
    
    %randomizes the above matrix and calculates the real average race of
    %the faces
	Af = normal(:,1); %african american column of the distribution
    Ca = normal(:,2); %caucasian column of the distribution
    avg_race = ((Af + (Ca.*10))/6); %calculates real avg
    normal(:,3)=avg_race; %inputs real avg into the matrix
    normalDistribution = normal(randperm(size(normal, 1)), :); %randomizes matrix

    %load stimuli of caucasian
    cd('White_Males_Grayscale');
    for i = 1:50
        image=imread(sprintf('WM-%d.jpg',i));
        white(i) = Screen('MakeTexture', window, uint8(image)); %make images into a texture
    end
    
    %load stimuli of african american
    cd ..;
    cd('Black_Males_Grayscale');
    for i = 1:50
        image=imread(sprintf('BM-%d.jpg',i));
        black(i) = Screen('MakeTexture', window, uint8(image)); %make images into a texxture
    end
    
    %load the image of the scale to instruct participants what to do
    cd ..
  	scale_image = imread('Res_Crowd.jpeg');
	scale_texture = Screen('MakeTexture', window, scale_image); %makes scale into a texture
    
    %image sizes (of the stimuli and the scale)
    scale_size =  size(scale_image);
    scale_height = scale_size(1);
    scale_width = scale_size(2);
    image_size =  size(image);
    image_height = image_size(1);
    image_width = image_size(2);

	%grid of display points for 6 stimuli
    nrows=2; %number of rows
	ncols=3; %number of columns
	gridLocX = linspace(image_width, window_w - image_width, ncols); %creates a line of x and y coordinates that evenly divide it
    gridLocY = linspace(image_height, window_h - image_width, nrows); %into the number of rows and columns
    [x, y] = meshgrid(gridLocX, gridLocY); %creates a grid from the line of coordinates
	xy_rect6 = [x(:)'-image_width/2; y(:)'-image_height/2; x(:)'+image_width/2; y(:)'+image_height/2]; %creates destination rects from each point on the grid

	%columns 1 is marked with the participant's response
    %col 2 is actual avg, col 3 is whether it was a single face or 6 faces
    %col 4 is the difference between actual avg and the participant's
    %response
	response=zeros(ntrials,3);

	%% run trials
    for i=1:ntrials
        
        % creates a set of six faces; the number of african
        % american/caucasian faces is chosen by the normalDistribution
        % matrix
        response(i,2)=normalDistribution(i,3); %records what the actual avg is
        black_nums = black(randperm(50, normalDistribution(i, 1))); %picks the appropriate number of faces from black and white
        white_nums = white(randperm(50, normalDistribution(i, 2)));
        faces = Shuffle(horzcat(black_nums, white_nums)); %shuffles the six faces
        
        % if only showing one face, pick one randomly from the six
        if order(i) == 1
        	face = randsample(faces, 1); 
      	end
        
    	%display only 1 face
        if order(i)==1
            response(i,3)=1; %record that only one face was displayed
            Screen('DrawTexture',window,face);
            Screen('Flip', window);
        %display 6 faces
        elseif order(i)==6
            response(i,3)=6; %record that six faces were displayed
            Screen('DrawTextures',window,faces, [], xy_rect6);
            Screen('Flip', window);
        end
        
        WaitSecs(0.3); %display stimuli for 0.3 seconds
        Screen('Flip',window);          
        WaitSecs(0.5);
                        
        %instruct participants on how to respond             
        Screen('DrawText', window, 'Use the numbers on the keyboard to rate the average ethnicity of the face(s)', center_x/2,center_y/2); 
    	xy_rect=[20, center_y, 20+scale_width, center_y+scale_height];
    	Screen('DrawTexture',window, scale_texture, [], xy_rect );
    	Screen('Flip', window);
                        
        while  1
            % Check which key was pressed
            [keyIsDown,seconds,keyCode] = KbCheck(-1);
            
			%if number key was pressed, set response to that number and break out of while loop
            if keyCode(KbName('1!'))
                response(i,1) = 1;
                break   
            end
            if keyCode(KbName('2@'))
                response(i,1) = 2;
                break   
            end
			if keyCode(KbName('3#'))
                response(i,1) = 3;
                break   
            end
            if keyCode(KbName('4$'))
                response(i,1) = 4;
                break
            end
            if keyCode(KbName('5%'))
                response(i,1) = 5;
                break
            end
            if keyCode(KbName('6^'))
                response(i,1) = 6;
                break   
            end
            if keyCode(KbName('7&'))
                response(i,1) = 7;
                break   
            end
            if keyCode(KbName('8*'))
                response(i,1) = 8;
                break   
            end            
            if keyCode(KbName('9('))
                response(i,1) = 9;
                break   
            end
            
            if keyCode(KbName('0)'))
                response(i,1) = 10;
                break   
            end
            
        end
		
        %calculates the difference between the actual avg and participant's
        %response
        response(i,4)=response(i,2)-response(i,1);
        
        Screen('Flip',window);
        
        %wait for participant to release the key before continuing
        WaitSecs(0.5);
        while keyIsDown == 1
            [keyIsDown,seconds,keyCode] = KbCheck(-1);
        end
    end

    %% saving results
	% navigate into the result folder and save results and participant info
	cd([current '/Participant_Data_Grayscale/' nameID]);
	save Results.mat,response;
    save ParticipantInfo.mat, ParticipantInfo;
    
    Screen('CloseAll');
    
catch
	Screen('CloseAll');
    rethrow(lasterror)
end

