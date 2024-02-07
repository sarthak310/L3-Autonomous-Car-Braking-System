% IMPORTANT:
% "VelocityAScopeData" is the output of the "Car A Velocity" scope in LaneMaintainSystem3Car/CARA/VehicleKinematics
% It is in the form of a structure which has a set of data values (y-axis) and a set of time values (x axis) in the Workspace 
% For this code to work -
% 1. Open Configuration Properties of the Car A Velocity scope
% 2. Go to Logging tab
% 3. Check "Log data to workspace"
% 4. Variable name: VelocityAScopeData; Save format: Structure with time


function [switch_or_no_switch, timeOfSwitch] = AdvisoryControl(v_A,s_AB)

load('MemberDecel200.mat')
    if length(v_A) ~= length(s_AB)
        error('Input vectors must have the same length.');
    end
    initSpeedA = v_A(1); % let the first speed in the vector v_A be the initial speed of car A
    
    speed_diff = -4.91; % from the app (task 1)
    % speed_diff = average speed - current speed
    open_system('LaneMaintainSystem3Car.slx')
    set_param('LaneMaintainSystem3Car/CARA/VehicleKinematics/vx','InitialCondition',num2str(initSpeedA))
    
    if speed_diff > 0 % means that average speed > current speed => traffic
        decelLim = -150; % HCW
    else % means current speed > average speed => no traffic
        decelLim = -200; % LCW
    end

    set_param('LaneMaintainSystem3Car/CARA/VehicleKinematics/Saturation','LowerLimit',num2str(decelLim))
    set_param('LaneMaintainSystem3Car/VehicleKinematics/Saturation','LowerLimit',num2str(decelLim))
    simModel = sim('LaneMaintainSystem3Car.slx');
    
    x = simModel.VelocityAScopeData.time; % time intervals from car A velocity scope 
    y = simModel.VelocityAScopeData.signals.values; % velocity values from car A velocity scope
    DecelA = diff(y) ./ diff(x); % calculating deceleration of A from its velocity vs time graph   
    
    % plot(x(2:end), DecelA)

    [yUnique, index] = unique(y);
    xUnique = x(index);
    
    meanVal = [mean(decelMax(1:13)) mean(decelMax(14:28)) mean(decelMax(29:41))]; % from membershipFunctionBrakingNA.m
    stdVal = [std(decelMax(1:10)) std(decelMax(11:30)) std(decelMax(31:41))]; % from membershipFunctionBrakingNA.m
    
    for i = 1:size(v_A) % to determine switch/no switch for each velocity and distance value from the input vectors   
        
        timestep = interp1(yUnique, xUnique, v_A(i)); % time at that velocity   
        
        Decel = interp1(x(2:end), DecelA, timestep); % decel of A at that time
        
        a = membershipFunctionBrakingNA(-Decel); % a(1)=low, a(2)=med, a(3)=high .... (-Decel) because we have to pass a positive value
        b = membershipFunctionDistance(s_AB(i)); % b(1)=far, b(2)=close
        c = membershipFunctionRoad(speed_diff); % c(1)=poor, c(2)=normal
        
        brakingB = zeros(1,3); % resulting vector after applying the rules

        % RULES: format -> car A braking (AND) distance bet A & B (AND) road condition

        % 1) Car B brakes LOW if -
                            
        % low, far, poor
        %       (OR)
        % low, far, normal
        %       (OR)
        % med, far, poor    
        brakingB(1) = max([min([a(1),b(1),c(1)]),min([a(1),b(1),c(2)]),min([a(2),b(1),c(1)])]); % (OR) = max, (AND) = min
    
        % 2) Car B brakes MEDIUM if -
                            
        % low, close, poor
        %       (OR)
        % low, close, normal
        %       (OR)
        % med, far, normal
        %       (OR)
        % high, far, normal
        %       (OR)
        % high, far, poor
        brakingB(2) = max([min([a(1),b(2),c(1)]),min([a(1),b(2),c(2)]),min([a(2),b(1),c(2)]),min([a(3),b(1),c(2)]),min([a(3),b(1),c(1)])]); % (OR) = max, (AND) = min
    
        % 3) Car B brakes HIGH if -
                            
        % med, close, poor
        %       (OR)
        % med, close, normal
        %       (OR)
        % high, close, poor
        %       (OR)
        % high, close, normal
        brakingB(3) = max([min([a(2),b(2),c(1)]),min([a(2),b(2),c(2)]),min([a(3),b(2),c(1)]),min([a(3),b(2),c(2)])]); % (OR) = max, (AND) = min
        
        % Calculate the weighted sum of the mean values for each category
        centroid = sum(meanVal .* brakingB); % using the same braking membership function for defuzzification
        
        % Normalize by the sum of membership degrees
        normalizedSum = sum(brakingB);
        
        % Calculate the defuzzified value
        decelB = centroid / normalizedSum;
        
        if decelB > 0.75*(-decelLim) % given condition
            switch_or_no_switch = "switch";
            timeOfSwitch = num2str(timestep);
            break; % don't have to calculate for remaining velocities because already decided to switch      
        end

        switch_or_no_switch = "no switch";
        timeOfSwitch = "NA";

    end
    
    % CONCLUSION:
    % decelLim is too high in comparison to the range in the provided braking membership function. hence, i am getting no switch for every case
    % because decelB is never crossing 0.75*decelLim mark
    % to fix this, we can modify the decelMax vector to include decel values upto 200 and not just till 104
            