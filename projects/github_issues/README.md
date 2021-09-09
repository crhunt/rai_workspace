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

### 3. Run script to pull data via GhApi API

This script uses GhApi and the Github API to pull data from github. Pulls data to the same directory.

```bash
$ python3 pull_github_data.py
```

Set the owner and/or repository with flags.

```bash
$ python3 pull_github_data.py --owner RelationalAI --repo raicode
```

### 4. Post-process files to render compatible with Rel

Resolve null value compatibility issues with Rel, so we can insert the json data into our Rel program.

```bash
$ bash format-json.sh
```

### 5. Place final files in data directory

The files:

1. issues-formatted.json
2. labels-formatted.json
3. milestones-formatted.json

should be placed in the project data folder, `./projects/github_issues/data`.