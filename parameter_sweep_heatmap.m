function parameter_sweep_heatmap()
    % Sweep ranges for handover probability and number of channels
    p_handover_vals = 0.1:0.1:0.9;
    channel_vals = 5:5:30;

    % Fixed parameters for all simulations
    Tsim = 5000;         % Total simulation time
    lambda = 0.1;        % Call arrival rate
    mu = 1/180;          % Call duration rate (mean duration = 180s)

    % Initialize result matrices for heatmap values
    blocked_matrix = zeros(length(channel_vals), length(p_handover_vals));
    dropped_matrix = zeros(length(channel_vals), length(p_handover_vals));
    completed_matrix = zeros(length(channel_vals), length(p_handover_vals));

    % Sweep over all channel and handover combinations
    for i = 1:length(channel_vals)
        for j = 1:length(p_handover_vals)
            % Run one simulation with given parameters
            [comp, block, drop] = run_single_sim(Tsim, lambda, mu, channel_vals(i), p_handover_vals(j));

            % Store results
            completed_matrix(i,j) = comp;
            blocked_matrix(i,j) = block;
            dropped_matrix(i,j) = drop;
        end
    end

    %% Generate Heatmaps
    figure;

    % Blocked Calls Heatmap
    subplot(1,3,1);
    heatmap(p_handover_vals, channel_vals, blocked_matrix, 'Colormap', parula, ...
        'Title', 'Blocked Calls', 'XLabel', 'Handover Probability', 'YLabel', 'Channels per Cell');

    % Dropped Calls Heatmap
    subplot(1,3,2);
    heatmap(p_handover_vals, channel_vals, dropped_matrix, 'Colormap', autumn, ...
        'Title', 'Dropped Calls', 'XLabel', 'Handover Probability');

    % Completed Calls Heatmap
    subplot(1,3,3);
    heatmap(p_handover_vals, channel_vals, completed_matrix, 'Colormap', winter, ...
        'Title', 'Completed Calls', 'XLabel', 'Handover Probability');
end

% Function to simulate a single configuration and return call statistics
function [completed, blocked, dropped] = run_single_sim(Tsim, lambda, mu, channels, p_handover)
    % Initialize time and counters
    currentTime = 0;
    call_id_counter = 0;
    blocked = 0;
    dropped = 0;
    completed = 0;

    % Channel occupancy in each cell
    occupied = struct('A', 0, 'B', 0, 'C', 0);

    % Map to track ongoing calls
    activeCalls = containers.Map('KeyType', 'int32', 'ValueType', 'any');

    % Event queue: stores scheduled events
    events = struct('time', {}, 'type', {}, 'call_id', {});

    % Schedule first call arrival
    nextArrival = currentTime + exprnd(1/lambda);
    events(end+1) = struct('time', nextArrival, 'type', 'arrival', 'call_id', -1);

    % Simulation event loop
    while ~isempty(events)
        % Sort events by time
        [~, idx] = sort([events.time]);
        events = events(idx);

        % Pop the earliest event
        event = events(1);
        events(1) = [];

        % Advance simulation time
        currentTime = event.time;
        if currentTime > Tsim
            break;
        end

        switch event.type
            case 'arrival'
                % If Cell A has free channel, accept the call
                if occupied.A < channels
                    call_id_counter = call_id_counter + 1;
                    call.id = call_id_counter;
                    call.cell = 'A';
                    call.handed_over1 = false;
                    call.handed_over2 = false;

                    % Generate call duration and schedule departure
                    call_duration = exprnd(1/mu);
                    call.departure_time = currentTime + call_duration;

                    % Schedule handovers probabilistically
                    if rand < p_handover
                        offset1 = call_duration * (0.3 + 0.1*rand);
                        offset2 = call_duration * (0.6 + 0.1*rand);
                        call.handover_time1 = currentTime + offset1;
                        call.handover_time2 = currentTime + offset2;
                        events(end+1) = struct('time', call.handover_time1, 'type', 'handover1', 'call_id', call.id);
                        events(end+1) = struct('time', call.handover_time2, 'type', 'handover2', 'call_id', call.id);
                    end

                    % Accept call and mark resources
                    activeCalls(call.id) = call;
                    occupied.A = occupied.A + 1;
                    events(end+1) = struct('time', call.departure_time, 'type', 'departure', 'call_id', call.id);
                else
                    % No free channels → block call
                    blocked = blocked + 1;
                end

                % Schedule next call arrival
                nextArrival = currentTime + exprnd(1/lambda);
                events(end+1) = struct('time', nextArrival, 'type', 'arrival', 'call_id', -1);

            case 'handover1'
                % Attempt handover from A → B
                if isKey(activeCalls, event.call_id)
                    call = activeCalls(event.call_id);
                    if ~call.handed_over1 && occupied.B < channels
                        call.handed_over1 = true;
                        call.cell = 'B';
                        occupied.A = occupied.A - 1;
                        occupied.B = occupied.B + 1;
                        activeCalls(event.call_id) = call;
                    else
                        dropped = dropped + 1;
                        remove(activeCalls, call.id);
                    end
                end

            case 'handover2'
                % Attempt handover from B → C
                if isKey(activeCalls, event.call_id)
                    call = activeCalls(event.call_id);
                    if ~call.handed_over2 && call.handed_over1 && occupied.C < channels
                        call.handed_over2 = true;
                        call.cell = 'C';
                        occupied.B = occupied.B - 1;
                        occupied.C = occupied.C + 1;
                        activeCalls(event.call_id) = call;
                    else
                        dropped = dropped + 1;
                        remove(activeCalls, call.id);
                    end
                end

            case 'departure'
                % Final call completion
                if isKey(activeCalls, event.call_id)
                    call = activeCalls(event.call_id);
                    occupied.(call.cell) = max(0, occupied.(call.cell) - 1);
                    completed = completed + 1;
                    remove(activeCalls, call.id);
                end
        end
    end
end
