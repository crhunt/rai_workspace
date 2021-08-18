# Github issues tracking

## Required steps to pull data

### 1. Install GhApi

To install, run either `pip install ghapi` or `conda install -c fastai ghapi`.

Repo: https://github.com/fastai/ghapi

### 2. Need repo GITHUB_TOKEN

https://docs.github.com/en/github/authenticating-to-github/keeping-your-account-and-data-secure/creating-a-personal-access-token

Add token to an environment variable in .bashrc:

```bash
# Set Github token
export GITHUB_TOKEN="token string here"
```

Reload .bashrc file: 
```bash
source ~/.bashrc
```

### 3. Run script to pull data via GhApi API

Script just related to pulling data. Pulls data to same directory.

```bash
$ python3 pull_github_data.py
```

## 