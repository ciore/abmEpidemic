#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import numpy as np
import random as rd
import matplotlib.pyplot as pl
import time

rd.seed(1)

# model and agent parameters
motionNoise = 0.05
typeNames=('healthy', 'sick', 'immune');
numPeople0=100 #number if people in the population at the start
numSick0=5 #number of sick at start
infectDistance2=0.05**2 #radius^2 under which infection occurs
timeToRecover=25 #number of iterations to recover
localised=True #if true then sick are localised within 0.4<xy<0.6
restrictMotion=True #if true then sick are stationary
quarantine=False #if true no motion across 0.4<xy<0.6
quarantineEffectiveness=0.9 #probability of no motion across quarantine

class person:
  def __init__(self,xy):
    self.type = 1
    self.xy = xy
    self.healthy = True
    self.immune = False
    self.timeSick = 0
    self.motionNoise = motionNoise
    
def draw(people,data):
  ax[0].set_title('iter: '+ str(t))
  for i in range(len(people)): 
    if people[i].type==0:
      ax[0].scatter(people[i].xy[0], people[i].xy[1], color = 'red')
    elif people[i].type==1:
      ax[0].scatter(people[i].xy[0], people[i].xy[1], color = 'green')
    elif people[i].type==2:
      ax[0].scatter(people[i].xy[0], people[i].xy[1], color = 'blue')
  ax[0].axis([0, 1, 0, 1])
  # ax[0].axis('scaled')
  ax[0].set_xlabel('x')
  ax[0].set_ylabel('y')
  ax[1].plot(list(range(t+1)),[data[i][0] for i in range(len(data))],'g')
  ax[1].plot(list(range(t+1)),[data[i][1] for i in range(len(data))],'r')
  ax[1].plot(list(range(t+1)),[data[i][2] for i in range(len(data))],'b')
  ax[1].set_xlabel('iter')
  ax[1].set_ylabel('number of people')
  ax[1].set_ylim(-5, 100)
  pl.subplots_adjust(hspace=0.5)
    
def randomMotion(people):
  for i in range(len(people)):
    radius = rd.gauss(0,1)*people[i].motionNoise;
    theta=rd.uniform(0,1)*np.pi;
    xy = [people[i].xy[0]+radius*np.cos(theta), people[i].xy[1]+radius*np.sin(theta)];
    if xy[0] < 0:
      xy[0] = 0
    if xy[1] < 0:
      xy[1] = 0
    if xy[0] > 1:
      xy[0] = 1
    if xy[1] > 1:
      xy[1] = 1
    people[i].xy = xy
    
  
# initialise population
global people 
people = []
for i in range(numPeople0):
    people.append(person([rd.uniform(0,1), rd.uniform(0,1)]))    
if localised:
  epicentre = list(np.where(np.array([[p.xy[0]>0.4 and p.xy[1]>0.4 and p.xy[0]<0.6 and p.xy[1]<0.6] for p in people]))[0])
else:
  epicentre = rd.sample(range(numPeople0),numSick0)
for i in epicentre:
  people[i].healthy = False
  people[i].type = 0
    
t = 0
numHealthy = numPeople0-numSick0
numSick = numSick0
numImmune = 0
data=[[numHealthy, numSick0, numImmune]]
pl.ion()
fig, ax = pl.subplots(2,1)
draw(people,data)

# simulate
timer0 = time.time()
while sum([not p.healthy for p in people]) > 0:
  t += 1
  
  randomMotion(people)
  
  for i in range(len(people)):

    #detect interaction and change state
    for j in range(i+1,len(people)):
      if (people[i].xy[0]-people[j].xy[0])**2+(people[i].xy[1]-people[j].xy[1])**2<infectDistance2: #in range
        if (not people[i].immune) and (not people[j].healthy):
          people[i].healthy = False
          people[i].type = people[i].healthy + people[i].immune
        if (not people[j].immune) and (not people[i].healthy):
          people[j].healthy = False
          people[j].type = people[j].healthy + people[i].immune

    # recover and become immune
    if not people[i].healthy:
      if people[i].timeSick > timeToRecover:
        people[i].healthy = 1
        people[i].immune = 1
        people[i].motionNoise = motionNoise
        people[i].type = people[i].healthy + people[i].immune
      else:
        if restrictMotion:
          people[i].motionNoise = 0
        people[i].timeSick += 1;
        people[i].type = people[i].healthy + people[i].immune;
  
  # save data    
  data.append([sum([p.healthy for p in people]), sum([not p.healthy for p in people]), sum([p.immune for p in people])])

  # plot 
  pl.ion()
  fig, ax = pl.subplots(2,1)
  draw(people,data)
  pl.show()
  pl.pause(0.001)
  pl.close(fig)  
elapsed = time.time() - timer0
print('Elapsed time is',elapsed,'seconds.')
