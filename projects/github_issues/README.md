# Github issues tracking

Pull data from one or more github repositories and generate a knowledge graph from the data. Derive insights related to issues, pull requests, and user activity.

## Required steps to pull data

### 1. Install GhApi

To install, run either `pip install ghapi` or `conda install -c fastai ghapi`.

Repo: https://github.com/fastai/ghapi

### 2. Need GITHUB_TOKEN with repo access

You will need a github token for your account. Your account needs to have access to the repo you wish to pull. [How to generate a github token.](https://docs.github.com/en/github/authenticating-to-github/keeping-your-account-and-data-secure/creating-a-personal-access-token)

Set the environment variable `GITHUB_TOKEN` to your token. You can do this in your `.bashrc` file permanently, or via the command line for just the current session. To add the token string to an environment variable in `.bashrc`:

```bash
# Set Github token
export GITHUB_TOKEN="token string here"
```

Reload .bashrc file: 
```bash
$ source ~/.bashrc
```

### 3. Run a script to pull data via GhApi API

This script uses GhApi and the Github API to pull data from github. Pulls data to the same directory.

```bash
$ python3 pull_github_data.py
```

Set the owner, repository, and local data path with flags.

```bash
$ python3 pull_github_data.py --owner RelationalAI --repo raicode --path ../data
```

The path can be a relative or absolute path. The final data files should be placed in the project data folder, `./projects/github_issues/data`. You will have the following files:

1. {repo}-issues.json
2. {repo}-labels.json
3. {repo}-milestones.json
4. {repo}-repo.json
5. {repo}-user-details.json

where {repo} is the name of the repository set with the `--repo` flag.