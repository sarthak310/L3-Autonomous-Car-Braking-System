%% Task 1

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

% Original Code

%{
Gain = 90000;
InitSpeed = 40; 
decelLim = -150;

[A,B,C,D,Kess, Kr, Ke, uD] = designControl(secureRand(),Gain);
open_system('LaneMaintainSystem.slx')

set_param('LaneMaintainSystem/VehicleKinematics/Saturation','LowerLimit',num2str(decelLim))
set_param('LaneMaintainSystem/VehicleKinematics/vx','InitialCondition',num2str(InitSpeed))

simModel = sim('LaneMaintainSystem.slx');

figure
plot(simModel.sx1.Time,simModel.sx1.Data)
title('Distance from the car')

figure
plot(simModel.vx1.Time,simModel.vx1.Data)
title('Velocity of the car')


figure
plot(simModel.ax1.Time,simModel.ax1.Data)
title('Deceleration of the car')
%}


%% Part 1 & 2

rng('default')

% 120 values for avg HR
HR_1 = normrnd(80, 14, [1, 20]);
HR_2 = normrnd(65, 15, [1, 20]);
HR_3 = normrnd(61, 14, [1, 20]);
HR_4 = normrnd(95, 26, [1, 20]);
HR_5 = normrnd(71, 21, [1, 20]);
HR_6 = normrnd(92, 23, [1, 20]);
HR = [HR_1, HR_2, HR_3, HR_4, HR_5, HR_6]; % displayed in Task1.1 in csv

% 120 values for avg RR
RR_1 = normrnd(16, 6, [1, 20]);
RR_2 = normrnd(13, 4, [1, 20]);
RR_3 = normrnd(17, 8, [1, 20]);
RR_4 = normrnd(21, 14, [1, 20]);
RR_5 = normrnd(14, 5, [1, 20]);
RR_6 = normrnd(26, 16, [1, 20]);
RR = [RR_1, RR_2, RR_3, RR_4, RR_5, RR_6]; % displayed in Task1.1 in csv

% Reaction Quotient
Rq = HR ./ RR;

% Reaction Time
tr = 0.01 .* Rq; % displayed in Task1.2 in csv

figure
plot(1:120, tr);
xlabel('User');
ylabel('Reaction Time (tr)');
title('Reaction Times of 120 Sample Users');


%% Part 3

decelLim = -150; % change for HCW (-150) & LCW (-200)

gainArray = 20000:5000:200000; % Gain values from 20,000 to 200,000 with a step of 5,000
speedArray = 20:1:40; % Initial speeds from 20 to 40 with a step of 1
collisions = zeros(1, length(gainArray)); % array of num of collisions for each gain for speeds 20 to 40

for i = 1:length(gainArray)
    Gain = gainArray(i);
    countCollisions = 0; % num of collisions for each gain for speeds 20 to 40

    for j = 1:length(speedArray) % speeds 20 to 40 for each gain
        InitSpeed = speedArray(j);

        [A,B,C,D,Kess, Kr, Ke, uD] = designControl(secureRand(),Gain);
        open_system('LaneMaintainSystem.slx')
        
        set_param('LaneMaintainSystem/VehicleKinematics/Saturation','LowerLimit',num2str(decelLim))
        set_param('LaneMaintainSystem/VehicleKinematics/vx','InitialCondition',num2str(InitSpeed))
        
        simModel = sim('LaneMaintainSystem.slx');

        if max(simModel.sx1.Data) > 0 % braking control unable to prevent collision
            countCollisions = countCollisions + 1;
        end

    end
    collisions(i) = countCollisions;
end

figure
plot(gainArray, collisions);
xlabel('Gain');
ylabel('Number of Collisions from 20 to 40 kmph');
title('Collisions for given speed interval for increasing gains');

% [HCW] for gain 20k to 200k (5k intervals) and 1 kmph speed intervals, result
% was: 2 collisions for gains upto 85k & 1 collision for gains 90k to 200k

% [LCW] 2 collisions till 30k, 1 for 35k to 90k, 0 for 95k to 200k

% [Result] Hence, the gain can be 90,000 for -150 decel (HCW) and 95,000 for -200
% decel (LCW) for minimum collisions (1 and 0 respectively)


%% Part 4

% we got 0 collisions for LCW. for HCW, there was 1 collision. obviously,
% that collision was when speed was max (i.e., 40 kmph)

% hence, for 90,000 gain, 40 kmph, -150 decel -> tc/tstop (stopping time =
% collision time) came out to be 1.60992 sec (output from the original code)

%now, let's check the num of switches for that scenario

InitSpeed = 40; 
decelLim = -165; % 1.1*(-150) = -165

open_system('HumanActionModel.slx')

set_param('HumanActionModel/VehicleKinematics/Saturation','LowerLimit',num2str(decelLim))
set_param('HumanActionModel/VehicleKinematics/vx','InitialCondition',num2str(InitSpeed))
set_param('HumanActionModel/Step', 'After', '-165'); % step func setting

ta = zeros(1, 120); % action times
hstop = zeros(1, 120); % human stop times
switches = blanks(120); % switch(1)/no switch(0) for diff tr; displayed in Task1.4 in csv

for i = 1:120 % diff tr
    set_param('HumanActionModel/Step', 'Time', num2str(tr(i))); % step func setting
    simModel2 = sim('HumanActionModel.slx');
    ta(i) = max(simModel2.ScopeData.time);
    hstop(i) = tr(i) + ta(i);
    if hstop(i) < 1.60992
        switches(i) = '1'; % human can stop in time
    else
        switches(i) = '0'; % even human cannot stop in time
    end        
end

figure
plot(1:120, ta);
xlabel('User');
ylabel('Action Time (ta)');
title('Action Times of 120 Sample Users');

figure
plot(1:120, hstop);
xlabel('User');
ylabel('Stopping Time (hstop = tr + ta)');
title('Stopping Times of 120 Sample Users');

disp(switches)

% [RESULT] got only 1 collision out of 120 sample users whose tr was ~0.52 and
% hstop = 1.716. Hence, our gain setting was near perfect

% [CONCLUSION]

% for LCW (-200), autonomous braking does its job and stops the car
% everytime when gain is set to 95,000.

% for HCW (-150), autonomus braking does not
% work when speed is 40 kmph for any gain, but works fine with gain 90,000
% for speeds 20 to 39 kmph. so for 40 kmph, control is switched to human
% where 1.1 times decel can be applied (-165). out of 120 sample users, 119
% users can stop the car in time. 1 user will collide eitherways, so the
% control is not switched to the user (see the highest peak in stopping
% time graph). 2 of the users come very close to colliding (see the 2
% second highest peaks).

% this result was based on just 120 users whose data was taken from
% gaussian distribution of just 6 users (3 users in hcw and lcw each). this can be redone with more samples and data,
% but would take a significant number of iterations and time. gain and speed intervals can also be reduced
% (like 1000 instead of 5000 and 0.1 instead of 1 respectively)