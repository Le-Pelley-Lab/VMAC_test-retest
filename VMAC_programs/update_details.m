%% update_details

% input arguments

    % experiment: Map container created by the get_details function
    
    % bonus_session: optional float for performance bonus. Default is 0.
    
% outputs

    % saves experiment Map to raw_data directory

%% code

function [] = update_details(experiment, bonus_session, phase)
    

    % variable declarations
    global testing crash exptSession;
    

    % set  missing inputs
    if nargin < 2
        bonus_session = 0;  % default, no bonus
    end
    
    
    % check input types
    if ~isa(bonus_session, 'double')
        error('bonus_session input must be a double')
    end
    
    if ~isa(experiment, 'containers.Map')
        error('experiment input must be containers.Map')
    end
    
    
    % finish
    experiment('finish') = datestr(now, 0);
    
    
    % bonus
    if isKey(experiment, 'bonus_session')
        experiment('bonus_session') = bonus_session;  % store session bonus
    end
    
    if phase == 1 %if spatial task
        experiment('spatial_bonus') = bonus_session;
    else %if rsvp task
        experiment('rsvp_bonus') = bonus_session;
        experiment('bonus_session') = experiment('spatial_bonus') + experiment('rsvp_bonus');
    end
        
    
    if isKey(experiment, 'bonus_total')
        if phase == 2
            if crash == 0
                experiment('bonus_total') = experiment('bonus_total') + experiment('bonus_session');  % add session bonus to total
            else % if after a crash
                if exptSession == 1
                    experiment('bonus_total') = experiment('bonus_session');
                else
                    experiment('bonus_total') = experiment('bonus_session1') + experiment('bonus_session');
                end
            end
        end
    end
    
    
    % save
    if exist('raw_data', 'dir') ~= 7  % check for raw_data directory
        mkdir('raw_data')  % make it if it doesn't exist
    end
    
    
    save(experiment('data_filename'), 'experiment');
    
    
end