#!/bin/bash

## SLiM configuration
## variable setting:
# Pop1 = Dana Point
# Pop2 = Santa Margarita
# Pop3 = South San Mateo

# General run paramters
fin="/home/centos/USS/erik/PPM/SLiMrescue/Burnins/N800KGens800KQ10_simulationState.txt"
out="N800kGens29kQ10_MetapopulationQ4quarterMig"
metapop_script="/home/centos/USS/erik/PPM/SLiMrescue/scripts/FormMetapopulation.slim"
Q=4
setNewScale=T
oldQ=10
winterMortality=0.33

# Population Sizes
# Take the estimated size time 1.27 to approxiate harmonic mean between summer and winter given winter mortality of 0.35
K1hist=130085
K2hist=113981
K3hist=99489
K12anc=38666

# Dates
divdate=1235
postdiv=12000
P1P3iso=2500
P2P3iso=400

# Migration

m_Anc12_into_P2=3.5e-7
m_P2_into_Anc12=7.5e-9
m_P1_into_P3=1.5e-7
m_P3_into_P1=2.25e-5
m_P3_into_P2=1e-5
m_P2_into_P3=1.75e-5


###################################################
# Run SLiM
slim -d "fin='${fin}'" -d "out='${out}'" -d Q=${Q} -d setNewScale=${setNewScale} \
-d oldQ=${oldQ} -d winterMortality=${winterMortality} -d K1hist=${K1hist} \
-d K2hist=${K2hist} -d K3hist=${K3hist} -d K12anc=${K12anc} \
-d postdiv=${postdiv} -d divdate=${divdate} \
-d m_Anc12_into_P2=${m_Anc12_into_P2} -d m_P2_into_Anc12=${m_P2_into_Anc12} \
-d m_P1_into_P3=${m_P1_into_P3} -d m_P3_into_P1=${m_P3_into_P1} \
-d m_P3_into_P2=${m_P3_into_P2} -d m_P2_into_P3=${m_P2_into_P3} \
-d P1P3iso=${P1P3iso} -d P2P3iso=${P2P3iso} \
${metapop_script}
