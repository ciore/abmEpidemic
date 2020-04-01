% This file provides a simple agent-based modelling simulation
% of the spread of an epidemic in a 1x1 ecosystem
% 
% Copyright (C) 2020 Ciarán O'Reilly <ciaran@kth.se>
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>.

% rng('shuffle')
rng(0)

%% model parameters

%model
typeNames={'healthy','sick','immune'};
numPerson0=100; %number if people in the population at the start
numSick0=5; %number of sick at start
infectDistance2=0.05^2; %radius^2 under which infection occurs
timeToRecover=25; %number of iterations to recover
localised=true; %if true then sick are localised within 0.4<xy<0.6
restrictMotion=true; %if true then sick are stationary
quarantine=false; %if true no motion across 0.4<xy<0.6
quarantineEffectiveness=0.9; %probability of no motion across quarantine

%agents
params.healthy=1;
params.immune=0;
params.timeSick=0;
params.motionNoise=0.05;

%% initialise 
person=initAgents(numPerson0,params);
if localised
  epicentre=find(sum(reshape([person.xy]>0.4&[person.xy]<0.6,2,numel(person)),1)==2);
else
  epicentre=1:numPerson0;
end
for i=randi(numel(epicentre),1,numSick0)
  person(epicentre(i)).healthy=0;
end
person=categorize(person);
time=0;
data=[sum([person.healthy]) sum(not([person.healthy])) sum([person.immune])];
subplot(2,1,1), drawAgents(person)

%% step
tic
while sum(not([person.healthy]))
  
  time=time+1;
  
  %simulate random motion with quarantine zone for sick
  if quarantine
    personNew=randomMotion(person);
    for i=1:numel(person)
      if (person(i).xy>0.4)&(person(i).xy<0.6)
        if rand>quarantineEffectiveness
          person(i).xy=personNew(i).xy;
        end
      elseif (personNew(i).xy>0.4)&(personNew(i).xy<0.6)
        if rand>quarantineEffectiveness
          person(i).xy=personNew(i).xy;
        end
      else
        person(i).xy=personNew(i).xy;
      end
    end
  else
    person=randomMotion(person);
  end
  
  %detect interaction and change state
  for i=1:numel(person)
    for j=i+1:numel(person)
        if (person(i).xy(1)-person(j).xy(1))^2+(person(i).xy(2)-person(j).xy(2))^2<infectDistance2 %in range
          if not(person(i).immune)&not(person(j).healthy)
            person(i).healthy=0;
          end
          if not(person(j).immune)&not(person(i).healthy)
            person(j).healthy=0;
          end
        end
    end
  end
    
  % recover and become immune
  for i=1:numel(person)
    if not(person(i).healthy)
      if person(i).timeSick>timeToRecover
        person(i).healthy=1;
        person(i).immune=1;
        person(i).motionNoise=params.motionNoise;
        person(i).type=person(i).healthy+person(i).immune;
      else
        if restrictMotion
          person(i).motionNoise=0;
        end
        person(i).timeSick=person(i).timeSick+1;
        person(i).type=person(i).healthy+person(i).immune;
      end
    end
  end
  
  %plot
  subplot(2,1,1), drawAgents(person)
  drawnow

  %store data
  data=[data; sum([person.healthy]) sum(not([person.healthy])) sum([person.immune]==1)];
  subplot(2,1,2), drawData(data), legend(typeNames,'Location','northwest')
  
end
toc


%% FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
function agents=initAgents(num,params)
  for i=1:num
    agents(i).xy=rand(1,2);
    agents(i).type=1;
    fnames=fieldnames(params);
    for j=1:numel(fnames)
      eval(['agents(i).',fnames{j},'=params.',fnames{j},';']);
    end
  end
end

%%
function agents=categorize(agents)
  for i=1:numel(agents)
    agents(i).type=agents(i).healthy+agents(i).immune;
  end
end

%%
function agents=randomMotion(agents)
  for i=1:numel(agents)
    radius=randn(1)*agents(i).motionNoise;
    theta=rand(1)*pi;
    xy=agents(i).xy+[radius.*cos(theta) radius.*sin(theta)];
    xy(xy<0)=0;
    xy(xy>1)=1;
    agents(i).xy=xy;
  end
end

%%
function agents=reproAgents(agents,params)
  numAgents=numel(agents);
  for i=1:numAgents
    if rand(1)<params.reproRate*(1-numAgents/params.maxNum)
       agents=[agents agents(i)]; %add a copy of the parent
    end
  end
end

%%
function drawAgents(agents)
  cla
%   axis equal
  axis([0 1 0 1])
  hold on
  markers={'.r','.g','.b'};
  if iscell(agents)
    for i=1:numel(agents)
      xy=reshape([agents{i}.xy],2,numel(agents{i}));
      plot(xy(1,:),xy(2,:),markers{i})
    end
  else
    xy=reshape([agents.xy],2,numel(agents));
    type=[agents.type];
    for t=unique(type)
      plot(xy(1,type==t),xy(2,type==t),markers{t+1})
    end
  end
  xlabel('x'), ylabel('y'),
end

%%
function drawData(data)
  cla
  markers={'g','r','b'};
  h=plot(data);
  for i=1:numel(h)
    set(h(i),'color',markers{i});
  end
  xlabel('iteration')
end
