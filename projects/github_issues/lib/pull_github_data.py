import os
import json
from ghapi.all import GhApi, paged
from fastcore.utils import obj2dict
import argparse
import copy

parser = argparse.ArgumentParser(description="Pull github issues data.")
parser.add_argument("--owner", type=str, default='RelationalAI', help="Owner of the repository")
parser.add_argument("--repo", type=str, default='raicode', help="Name of the respository")

args = parser.parse_args()

print(f"Pulling repository {args.repo} owned by {args.owner}...")

def write_paged_generator_to_file(gen, filename):
    result = []
    #printProgressBar(0, 10)
    print(f'\rPages pulled: 0', end='\r')
    for n,page in enumerate(gen):
        result.extend(page)
        #printProgressBar(n, n+1)
        print(f'\rPages pulled: {n+1}', end='\r')
    print()

    with open(filename, "w") as f:
        json.dump(obj2dict(result), f)
    print("...results written to "+filename)

def write_to_file(results, filename):
    # Write results to json-formatted file
    with open(filename, "w") as f:
        json.dump(obj2dict(results), f)
    print("...results written to "+filename)

def get_issues():
    print("Pulling issues...")
    api = GhApi()
    token = os.environ["GITHUB_TOKEN"]
    gen = paged(api.issues.list_for_repo, per_page=100, owner=args.owner, repo=args.repo, state='all', token=token)
    write_paged_generator_to_file(gen, 'issues.json')

def get_milestones():
    print("Pulling milestones...")
    api = GhApi()
    token = os.environ["GITHUB_TOKEN"]
    gen = paged(api.issues.list_milestones, per_page=100, owner=args.owner, repo=args.repo, state='all', token=token)
    write_paged_generator_to_file(gen, 'milestones.json')

def get_labels():
    print("Pulling labels...")
    api = GhApi()
    token = os.environ["GITHUB_TOKEN"]
    gen = paged(api.issues.list_labels_for_repo, per_page=100, owner=args.owner, repo=args.repo, token=token)
    write_paged_generator_to_file(gen, 'labels.json')

def get_repo():
    print("Pulling repo details...")
    api = GhApi()
    token = os.environ["GITHUB_TOKEN"]
    results = [ api.repos.get(owner=args.owner, repo=args.repo, token=token) ]
    # Write results to json-formatted file
    write_to_file(results, 'repo.json')

def get_users():
    print("Pulling users...")
    api = GhApi()
    token = os.environ["GITHUB_TOKEN"]
    gen = paged(api.repos.list_contributors, per_page=100, owner=args.owner, repo=args.repo, token=token)
    write_paged_generator_to_file(gen, 'users.json')

def get_user_details():
    print("Pulling user details...")
    api = GhApi()
    token = os.environ["GITHUB_TOKEN"]

    results = []
    with open('users.json', "r") as f:
        # List of users who contribute to repository
        users = json.load(f)
        total = len(users)
        print(f'\rUser details pulled: 0 / {total}', end='\r')
        for n,user in enumerate(users):
            # Get details for the user and extend to list results
            results.append( api.users.get_by_username(username=user['login'], token=token) )
            print(f'\rUser details pulled: {n+1} / {total}', end='\r')
        print()
    with open('repo.json', "r") as f:
        # Ownership of repository
        repos = json.load(f)
        cnt = 0
        print(f'\rUser details pulled: {cnt}', end='\r')
        for m,repo in enumerate(repos):
            # Get details for the user and extend to list results
            cnt +=1
            results.append( api.users.get_by_username(username=repo['owner']['login'], token=token) )
            if 'organization' in repo.keys():
                cnt += 1
                results.append( api.users.get_by_username(username=repo['organization']['login'], token=token) )
            print(f'\rRepo owner details pulled: {cnt}', end='\r')
        print()
    # Write results to json-formatted file
    write_to_file(results, 'user-details.json')

# Run these to pull data
get_repo()
get_milestones()
get_labels()
get_issues()
get_users()
get_user_details()