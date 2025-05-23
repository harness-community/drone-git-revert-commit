#!/bin/sh
set -e

# Display error message and exit
error() {
  echo "ERROR: $1" >&2
  exit 1
}

# Display info message
info() {
  echo "INFO: $1"
}

# Validate required parameters
if [ -z "${PLUGIN_GIT_PAT}" ] && [ -z "${GIT_PAT}" ]; then
  error "Git Personal Access Token (git_pat) is required"
fi

if [ -z "${PLUGIN_COMMIT_SHA}" ] && [ -z "${COMMIT_SHA}" ]; then
  error "Commit SHA (commit_sha) is required"
fi

# Set parameters with fallbacks
GIT_PAT=${PLUGIN_GIT_PAT:-${GIT_PAT}}
COMMIT_SHA=${PLUGIN_COMMIT_SHA:-${COMMIT_SHA}}

# Optional parameters with defaults
GIT_USER_EMAIL=${PLUGIN_GIT_USER_EMAIL:-${DRONE_COMMIT_AUTHOR_EMAIL:-${CI_COMMIT_AUTHOR_EMAIL}}}
GIT_USER_NAME=${PLUGIN_GIT_USER_NAME:-${DRONE_COMMIT_AUTHOR:-${CI_COMMIT_AUTHOR:-${DRONE_COMMIT_AUTHOR_NAME:-${CI_COMMIT_AUTHOR_NAME}}}}}
BRANCH=${PLUGIN_BRANCH:-${BRANCH:-${DRONE_BRANCH:-"main"}}}
CREATE_REVERT_BRANCH=${PLUGIN_CREATE_REVERT_BRANCH:-${CREATE_REVERT_BRANCH:-"true"}}
REVERT_BRANCH_PREFIX=${PLUGIN_REVERT_BRANCH_PREFIX:-${REVERT_BRANCH_PREFIX:-"reverted-pr-"}}
REMOTE=${PLUGIN_REMOTE:-${REMOTE:-"origin"}}

# Configure git
info "Configuring git user"
git config --global user.email "${GIT_USER_EMAIL}"
git config --global user.name "${GIT_USER_NAME}"
git config --global --add safe.directory /drone/src
git config --global credential.helper 'cache --timeout 600'

# Configure git credentials
info "Setting up git credentials"
cat <<EOF | tr -d ' ' | git credential-cache store
protocol=https
host=github.com
username="${GIT_USER_NAME}"
password=${GIT_PAT}
EOF

# Pull latest changes from target branch
info "Pulling latest changes from ${BRANCH}"
git pull ${REMOTE} ${BRANCH}

# Display the current commit
info "Current commit"
git rev-parse HEAD

# Create and push revert branch if enabled
if [ "${CREATE_REVERT_BRANCH}" = "true" ]; then
  REVERT_BRANCH="${REVERT_BRANCH_PREFIX}${COMMIT_SHA}"
  info "Creating revert branch: ${REVERT_BRANCH}"
  git branch ${REVERT_BRANCH} ${BRANCH}
  info "Pushing revert branch to remote"
  git push --set-upstream ${REMOTE} ${REVERT_BRANCH}
  info "Revert branch created successfully"
fi

# Perform the revert
info "Reverting commit: ${COMMIT_SHA}"
git revert -m 1 ${COMMIT_SHA} || error "Failed to revert commit ${COMMIT_SHA}"

info "Restored commit"
git rev-parse HEAD

# Push the revert to target branch
info "Pushing revert to ${BRANCH}"
git push --set-upstream ${REMOTE} ${BRANCH} || error "Failed to push to ${BRANCH}"

info "Git revert completed successfully"
