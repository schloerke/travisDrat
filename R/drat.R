
git_user <- function() {
  gsub(
    ".*[:/]([^/]*)/[^.]*\\.git",
    "\\1",
    system("git config --get remote.origin.url", intern = TRUE)
  )
}


exists_or_stop <- function(key, msg = paste("'", key, "' is not set", sep = "")) {
  char_count <- system(paste("echo ${#", key, "}", sep = ""), intern = TRUE)
  if (as.numeric(char_count) == 0) {
    stop(msg)
  }
  invisible()
}


check_for_travis_gem <- function() {
  bol <- length(suppressWarnings(system("which travis", intern = TRUE))) > 0
  if (!bol) {
    stop("travis gem is not installed. Please fix this!")
  }
}

install_travis <- function() {
  cat("Please execute this command in your terminal

    sudo gem install travis\n\n")
}

check_for_pat <- function() {
  if (is.null(devtools::github_pat())) {
    install_travis()
    stop("env variable GITHUB_PAT is not set. Please set this environment variable!")
  }
}


#' Secure personal access token
#'
#' Function to create or automatically add a secure key (GITHUB_PAT) for travis to be able to publish to the drat repo
#' @param add boolean to determine if the key should be automatically added.  Default is \code{TRUE}.  This will remove custom formatting as the file will be programatically generated
#' @export
#' @examples
#' \dontrun{
#'   secure_token(FALSE)
#' }
secure_token <- function(add = TRUE) {
  check_for_pat()
  check_for_travis_gem()

  if (isTRUE(add)) {
    system("travis encrypt GITHUB_PAT=$GITHUB_PAT --add env.global")
    cat("Added to .travis file\n")
  } else {
    system("travis encrypt GITHUB_PAT=$GITHUB_PAT")
  }
}




#' Deploy drat repo
#'
#' Publish the package to the drat repo with travis
#' @param drat_repo "USER/REPO" location of the drat repository
#' @param valid_branches character vector of branch names that are allowed to deploy
#' @param email email of the 'user' making the travis commit
#' @param name name of the 'user' making the travis commit
#' @param output_dir location to perform drat functions.  This folder should not exist beforehand
#' @export
#' @examples
#' \dontrun{
#'   secure_token(FALSE)
#' }
deploy_drat <- function(
  drat_repo = paste(git_user(), "/drat", sep = ""),
  valid_branches = c("master"),
  email = "travis@travis-ci.org",
  name = "Travis CI",
  output_dir = "drat"
) {
  check_for_pat()

  # check if travis build number is available
  exists_or_stop("TRAVIS_BUILD_NUMBER")
  exists_or_stop("TRAVIS_PULL_REQUEST")
  exists_or_stop("TRAVIS_BRANCH")

  travis_pull_request <- Sys.getenv("TRAVIS_PULL_REQUEST")
  travis_branch <- Sys.getenv("TRAVIS_BRANCH")

  if (! (travis_branch %in% valid_branches)) {
    cat("Branch not allowed to deploy. Exiting")
    return()
  }

  if (travis_pull_request != "false") {
    cat("Pull requests are not allowed to deploy. Exiting")
    return()
  }


  system(paste(
    "set -o errexit -o nounset
    addToDrat(){
      PKG_REPO=$PWD
      ls -R
      echo \"$PKG_REPO/$PKG_TARBALL\"

      cd ..; mkdir ", output_dir, "; cd ", output_dir, "

      ## Set up Repo parameters
      git init
      git config user.name \"", name, "\"
      git config user.email \"", email, "\"
      git config --global push.default simple

      ## Get drat repo
      git remote add upstream \"https://$GITHUB_PAT@github.com/", drat_repo, ".git\"  > /dev/null 2>&1
      git fetch --quiet upstream
      git checkout --quiet gh-pages

      Rscript -e \"drat::insertPackage('$PKG_REPO/$PKG_TARBALL', \
        repodir = '.', \
        commit='Travis update: build $TRAVIS_BUILD_NUMBER')\"
      git push

      git push --quiet \"https://$GITHUB_PAT@github.com/", drat_repo, ".git\" master:gh-pages > /dev/null 2>&1


    }
    addToDrat",
    sep = ""
  ))
}
