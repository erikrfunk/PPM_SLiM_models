#!/bin/bash

## SLiM configuration
## variable setting:

# General run paramters
decline_script="/home/centos/USS/erik/PPM/SLiMrescue/scripts/mtapopulation-decline.slim"
fin="/home/centos/USS/erik/PPM/SLiMrescue/metapopulation_preliminary/N800k1milGensQ10_MetapopulationQ3_adjN_simulationState_rescaledCoeffs.txt"
Q=1
winterMortality=0.33

# Population Sizes
K1=70
K2=435
K3=94
Kcb=250

# Dates
botgens=10
postbot=100

# Translocations
source=4
sink=1
trans_size=10
trans_freq=4

###################################################
# Run SLiM

echo "Slim invoked as:"
echo "slim -d fin=${fin} -d Q=${Q} -d source=${source} -d sink=${sink} \
-d trans_size=${trans_size} -d trans_freq=${trans_freq} -d winterMortality=${winterMortality} \
-d K1=${K1} -d K2=${K2} -d K3=${K3} -d Kcb=${Kcb} -d botgens=${botgens} -d postbot=${postbot} \
${decline_script}"

slim -d "fin='${fin}'" -d Q=${Q} -d source=${source} -d sink=${sink} \
-d trans_size=${trans_size} -d trans_freq=${trans_freq} -d winterMortality=${winterMortality} \
-d K1=${K1} -d K2=${K2} -d K3=${K3} -d Kcb=${Kcb} -d botgens=${botgens} -d postbot=${postbot} \
${decline_script}
