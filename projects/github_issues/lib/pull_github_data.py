import os
import json
from ghapi.all import GhApi, paged
from fastcore.utils import obj2dict

def write_paged_generator_to_file(gen, filename):
    result = []
    for page in gen:
        result.extend(page)

    with open(filename, "w") as f:
        json.dump(obj2dict(result), f)

def get_issues():
    api = GhApi()
    token = os.environ["GITHUB_TOKEN"]
    gen = paged(api.issues.list_for_repo, per_page=100, owner='RelationalAI', repo='raicode', state='all', token=token)
    write_paged_generator_to_file(gen, 'issues.json')

def get_milestones():
    api = GhApi()
    token = os.environ["GITHUB_TOKEN"]
    gen = paged(api.issues.list_milestones, per_page=100, owner='RelationalAI', repo='raicode', state='all', token=token)
    write_paged_generator_to_file(gen, 'milestones.json')

def get_labels():
    api = GhApi()
    token = os.environ["GITHUB_TOKEN"]
    gen = paged(api.issues.list_labels_for_repo, per_page=100, owner='RelationalAI', repo='raicode', token=token)
    write_paged_generator_to_file(gen, 'labels.json')

# Run these to pull data
get_milestones()
get_labels()
get_issues()