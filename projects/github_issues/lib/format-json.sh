#! /bin/sh

set -e

sed -i 's/"description": null/"description": ""/g' labels.json
sed -i 's/"description":null/"description":""/g' labels.json

sed -i 's/"closed_at": null/"closed_at": ""/g' milestones.json


sed -i 's/"body": null/"body": ""/g' issues.json
sed -i 's/"body":null/"body":""/g' issues.json

sed -i 's/"closed_at": null/"closed_at": ""/g' issues.json
sed -i 's/"closed_at":null/"closed_at": ""/g' issues.json

sed -i 's/"description": null/"description": ""/g' issues.json
sed -i 's/"description":null/"description": ""/g' issues.json

python3 -m json.tool milestones.json > $2/$1-milestones.json
python3 -m json.tool labels.json > $2/$1-labels.json
python3 -m json.tool issues.json > $2/$1-issues.json
python3 -m json.tool user-details.json > $2/$1-user-details.json
python3 -m json.tool repo.json > $2/$1-repo.json

rm milestones.json
rm labels.json
rm issues.json
rm users.json
rm user-details.json
rm repo.json