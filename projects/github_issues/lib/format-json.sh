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

python3 -m json.tool milestones.json > milestones-formatted.json
python3 -m json.tool labels.json > labels-formatted.json
python3 -m json.tool issues.json > issues-formatted.json
python3 -m json.tool users.json > users-formatted.json
python3 -m json.tool user-details.json > user-details-formatted.json