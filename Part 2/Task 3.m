%% Task 3

% IMP:
% "ScopeData" is the output of the upper scope in "HumanActionModel.slx".
% It is in the form of a structure which has a set of data values (y-axis) and a set of time values (x axis) in the Workspace
% For this code to work -
% 1. Open Configuration Properties of the upper scope ("Scope")
% 2. Go to Logging tab
% 3. Check "Log data to workspace"
% 4. Variable name: ScopeData; Save format: Structure with time

clc
clear all

%% reac time model for user 3

rng('default')

HR_LCW = normrnd(61, 14, [1, 50]); % taking 50 bcoz 20 to 60 will have 41 speeds with interval of 1 for each gain
HR_HCW = normrnd(92, 23, [1, 50]);

RR_LCW = normrnd(17, 8, [1, 50]);
RR_HCW = normrnd(26, 16, [1, 50]);

Rq_LCW = HR_LCW ./ RR_LCW;
Rq_HCW = HR_HCW ./ RR_HCW;

tr_LCW = 0.01 .* Rq_LCW;
tr_HCW = 0.01 .* Rq_HCW;


%% reduce collisions and switches

decelLim = -200; % change this for lcw and hcw

gainArray = 50000:5000:150000; % Gain values from 50,000 to 150,000 with a step of 5,000
speedArray = 20:1:60; % Initial speeds from 20 to 60 with a step of 1
collisions = zeros(1, length(gainArray));
switches = zeros(1, length(gainArray));

for i = 1:length(gainArray)
    Gain = gainArray(i);
    countCollisions = 0;
    countSwitches = 0;

    for j = 1:length(speedArray)
        InitSpeed = speedArray(j);
        tr = 0.95*tr_LCW(j); % set factor from task 2 and change LCW/HCW

        [A,B,C,D,Kess, Kr, Ke, uD] = designControl(secureRand(),Gain);
        open_system('LaneMaintainSystem.slx')
        
        set_param('LaneMaintainSystem/VehicleKinematics/Saturation','LowerLimit',num2str(decelLim))
        set_param('LaneMaintainSystem/VehicleKinematics/vx','InitialCondition',num2str(InitSpeed))
        
        simModel = sim('LaneMaintainSystem.slx');

        if max(simModel.sx1.Data) >= 0
            
            tc = max(simModel.sx1.Time);
            open_system('HumanActionModel.slx')
            
            set_param('HumanActionModel/VehicleKinematics/vx','InitialCondition',num2str(InitSpeed))
            set_param('HumanActionModel/VehicleKinematics/Saturation','LowerLimit',num2str(1.1*decelLim))
            set_param('HumanActionModel/Step', 'After', num2str(1.1*decelLim));
            set_param('HumanActionModel/Step', 'Time', num2str(tr));
            simModel2 = sim('HumanActionModel.slx');
            ta = max(simModel2.ScopeData.time);
            hstop = tr + ta;
    
            if hstop < tc
                countSwitches = countSwitches + 1;
            else
                countCollisions = countCollisions + 1;
            end
        end

    end
    collisions(i) = countCollisions;
    switches(i) = countSwitches;
end

figure
plot(gainArray, collisions, 'r-')
hold on
plot(gainArray, switches, 'b-')
title('Number of Collisions and Switches')
legend('collisions', 'switches')
xlabel('Gain')
ylabel('Collisions and Switches for each gain for user 3')
hold off

% [RESULT] we got 19 switches for gain = 100,000 and above for LCW and 21
% for gain = 95,000 and more for HCW