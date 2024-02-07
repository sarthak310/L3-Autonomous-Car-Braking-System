%% Task 2

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

rng('default')

% markov chain

numSteps = 100;
P = [0.6 0.4; 0.85 0.15]; % transition probabilities

mc = dtmc(P); % mcmc model

scenario = simulate(mc,numSteps); % 2 is HCW, 1 is LCW; displayed in Task2.1 in csv
% scenario is a vector of 100 values of 1s and 2s

% sequence of initial speeds (gaussian from 20 to 60 kmph)
speed = normrnd(40, 20, [1, 100]); % displayed in Task2.2 in csv

% seq of reac times for avg user

% taking 90 values bcoz we dont know how many 1s and 2s will be there
HR_1_LCW = normrnd(80, 14, [1, 30]);
HR_2_LCW = normrnd(65, 15, [1, 30]);
HR_3_LCW = normrnd(61, 14, [1, 30]);

HR_1_HCW = normrnd(95, 26, [1, 30]);
HR_2_HCW = normrnd(71, 21, [1, 30]);
HR_3_HCW = normrnd(92, 23, [1, 30]);

avg_HR_LCW = [HR_1_LCW, HR_2_LCW, HR_3_LCW];
avg_HR_HCW = [HR_1_HCW, HR_2_HCW, HR_3_HCW];

RR_1_LCW = normrnd(16, 6, [1, 30]);
RR_2_LCW = normrnd(13, 4, [1, 30]);
RR_3_LCW = normrnd(17, 8, [1, 30]);

RR_1_HCW = normrnd(21, 14, [1, 30]);
RR_2_HCW = normrnd(14, 5, [1, 30]);
RR_3_HCW = normrnd(26, 16, [1, 30]);

avg_RR_LCW = [RR_1_LCW, RR_2_LCW, RR_3_LCW];
avg_RR_HCW = [RR_1_HCW, RR_2_HCW, RR_3_HCW];

avg_Rq_LCW = avg_HR_LCW ./ avg_RR_LCW;
avg_Rq_HCW = avg_HR_HCW ./ avg_RR_HCW;

avg_tr_LCW = 0.01 .* avg_Rq_LCW;
avg_tr_HCW = 0.01 .* avg_Rq_HCW;

% seq of reac times for user 3

HR_LCW = normrnd(61, 14, [1, 100]);
HR_HCW = normrnd(92, 23, [1, 100]);

RR_LCW = normrnd(17, 8, [1, 100]);
RR_HCW = normrnd(26, 16, [1, 100]);

Rq_LCW = HR_LCW ./ RR_LCW;
Rq_HCW = HR_HCW ./ RR_HCW;

tr_LCW = 0.01 .* Rq_LCW; % displayed in Task2.3 in csv
tr_HCW = 0.01 .* Rq_HCW; % displayed in Task2.3 in csv


% collision status and switches for user 3 BEFORE reac time setting

collisions = blanks(100); % displayed in Task2.4 in csv
switches = blanks(100); % displayed in Task2.5 in csv
j = 1; % for taking values from tr_LCW
k = 1; % for taking values from tr_HCW
for i = 1:100 % diff tr acc to seq of scenario
    if scenario(i) == 1 % LCW
        Gain = 95000; % fixed from task 1
        decelLim = -200;
        tr = tr_LCW(j);
        j = j + 1;
    else % HCW
        Gain = 90000; % fixed from task 1
        decelLim = -150;
        tr = tr_HCW(k);
        k = k + 1;
    end
    InitSpeed = speed(i);
    [A,B,C,D,Kess, Kr, Ke, uD] = designControl(secureRand(),Gain);
    open_system('LaneMaintainSystem.slx')
        
    set_param('LaneMaintainSystem/VehicleKinematics/Saturation','LowerLimit',num2str(decelLim))
    set_param('LaneMaintainSystem/VehicleKinematics/vx','InitialCondition',num2str(InitSpeed))
        
    simModel = sim('LaneMaintainSystem.slx');
    if max(simModel.sx1.Data) >= 0 % system cannot stop        
            
        tc = max(simModel.sx1.Time); % for calculating switches
        open_system('HumanActionModel.slx')        
        set_param('HumanActionModel/VehicleKinematics/vx','InitialCondition',num2str(InitSpeed))        
        set_param('HumanActionModel/VehicleKinematics/Saturation','LowerLimit',num2str(1.1*decelLim))
        set_param('HumanActionModel/Step', 'After', num2str(1.1*decelLim)); % step func
        set_param('HumanActionModel/Step', 'Time', num2str(tr)); % step func
        simModel2 = sim('HumanActionModel.slx');
        ta = max(simModel2.ScopeData.time);
        hstop = tr + ta;              
        if hstop < tc % human can stop
            collisions(i) = 'N'; % no collision
            switches(i) = '1'; % but switching, yes
        else % human cannot stop
            collisions(i) = 'Y'; % collision
            switches(i) = '0'; % no need for switching
        end
    else % system can stop
        collisions(i) = 'N'; % no collision
        switches(i) = '0'; % no switching needed
    end
end
disp(collisions)
disp(switches)
        
% [RESULT] we just got 1 collision and 45 switches for user 3, which we
% will try to reduce by changing the factor in the reac time setting

% reac time setting for avg user

collisionsArray = zeros(1,10); % array of collisions for each factor
switchesArray = zeros(1,10); % array of switches for rach factor
f = 1; % factor
for i = 1:10 % running scenario 10 times with increasing factor
    
    countCollisions = 0; % collisions for each factor
    countSwitches = 0; % switches for rach factor
    n = 1; % for changing tr_LCW for avg user
    m = 1; % % for changing tr_HCW for avg user
    for j = 1:100        
        
        if scenario(j) == 1 % LCW
            Gain = 95000; 
            decelLim = -200;
            tr = f*avg_tr_LCW(n);
            n = n + 1;
        else % HCW
            Gain = 90000; 
            decelLim = -150;
            tr = f*avg_tr_HCW(m);
            m = m + 1;
        end
        InitSpeed = speed(j);
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
    
    collisionsArray(i) = countCollisions;
    switchesArray(i) = countSwitches;
    f = f + 0.1; % interval for increasing factor
    
end    

figure
x = linspace(1.1,2,10);
plot(x, collisionsArray, 'r-')
hold on
plot(x, switchesArray, 'b-')
title('Number of Collisions and Switches')
legend('collisions', 'switches')
xlabel('Factor (tr=f*0.01*Rq)')
ylabel('Collisions and Switches')
hold off

% [RESULT] we are getting 0 collisions for avg user between f = 0.1 and 2.
% hence by changing the factor, collisions for user 3 can be reduced.

% collision status and switches for user 3 AFTER reac time setting

finalCollisions = 0;
finalSwitches = 0;
j = 1;
k = 1;
% decide factor from reac time setting of the advisory control
factor = 0.95;
for i = 1:100
    if scenario(i) == 1 % LCW
        Gain = 95000; 
        decelLim = -200;
        tr = factor*tr_LCW(j);
        j = j + 1;
    else % HCW
        Gain = 90000; 
        decelLim = -150;
        tr = factor*tr_HCW(k);
        k = k + 1;
    end
    InitSpeed = speed(i);
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
            finalSwitches = finalSwitches + 1;
        else
            finalCollisions = finalCollisions + 1;
        end
    end
end
disp(finalCollisions)
disp(finalSwitches)

% [RESULT] for factor = 0.95 (i.e., tr = f*0.01*Rq), we got 0 collisions
% and 46 switches for user 3. hence, it was a successful reac time setting trial

