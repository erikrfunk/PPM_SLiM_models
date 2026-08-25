start=$1
stop=$2

for i in $(seq $start $stop); do
  mkdir Rep${i}
  cd Rep${i}
  # First amend the .json to reflect the rep path
  cat <<EOF > ExSituParameters.json
  {
  "Kcap": 250,
  "Kwild": 300,
  "gen": 100,

  "winterMortality": 0.33,
  "release_delay": 9,
  "track_reintro": "F",
  "trans_size": 0,
  "trans_freq": 4000,
  "Z": 72679016,
  "I": 1e3,
  "ROHlen":1e6,
  "vcf_freq":8,
  "outdir":"${PWD}/",

  "founderVariants": "/home/centos/USS/erik/PPM/SLiMrescue/vcf_files/SMoriginalFounders.recode.vcf",
  "sampleMap": 
  "founderPops": ["SMoriginalFounders","SSMoriginalFounders","DPoriginalFounder"],
  "founderSizes": 41,
  "Supplemental_founders": ["SupplementalFounders2014",
    "SupplementalFounders2016",
    "SupplementalFounders2019",
    "SupplementalFounders2020"],
  "Supplemental_times": [5, 9, 15, 17],
  "recycle_supplements": "T"
  }
EOF

cd ../

done
