# travisDrat

Deploy your package to a github drat repo from Travis-CI.

This R package is heavily inspired by Colin Gillespie and Dirk Eddelbuettel's blog post http://eddelbuettel.github.io/drat/CombiningDratAndTravis.html.

# Usage

## Step 0

### Generate a Personal Access Token

From Dirk's blog:

> To allow Travis CI to push to your GitHub repository, we need to generate a GitHub [API token](https://github.com/settings/tokens/new). After re-entering your password, just select `repo`, or if your repository is public, select `public_repo`. GitHub will create the token and give you a chance to copy it down.

I recommend making `public_repo` token only if your drat repo is public.


### Activate Repository on Travis

Visit [your profile on Travis](https://travis-ci.org/profile). Make sure your repository is active and ready to be checked on Travis.


## Step 1 - Encrypt Personal Access Token

Create a secure personal access token (PAT) that can be used in Travis safely.

```{r}
# Add the token to env.global automatically
travisDrat::secure_token()

# Display only
travisDrat::secure_token(add = FALSE)
```

The `.travis.yml` file should contain the fields:

```{yaml}
env:
  global:
    secure: "REALLYLONGENCRYPTEDKEYTHATISNOTHUMANREADABLE"
```


## Step 2 - Update `.travis.yml`

Add the following lines to your travis file:

```{yaml}
r_github_packages:
  - HBGDki/travisDrat

after_success:
  - Rscript -e "travisDrat::deploy_drat()"
```

## Step 3 - Deploy

Push commits to Github.  Travis will activate on the package web hook.  After a successful check of your R package, `travisDrat` will deploy to the drat repo provided.
