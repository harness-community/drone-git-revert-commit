# Drone Git Revert Plugin

A Drone plugin to revert Git commits and optionally create a revert branch for traceability. This plugin is designed to help with rolling back changes in Git repositories during CI/CD pipelines.

## Features

- Revert a specific Git commit
- Create a separate branch to track the revert (optional)
- Simple integration with Drone CI/Harness CI
- Lightweight image based on Alpine Git

## Usage

Below is an example of how to use this plugin in a Drone CI pipeline:

```yaml
steps:
  - name: revert-commit
    image: plugins/git-revert-commit:latest
    settings:
      git_pat:
        from_secret: git_token
      commit_sha: ${DRONE_COMMIT_SHA}
      git_user_email: "ci@example.com"
      git_user_name: "CI Bot"
      branch: main
```

## Parameters

### Required Parameters

| Parameter | Description |
|-----------|-------------|
| `git_pat` | Git Personal Access Token for authentication |
| `commit_sha` | The commit SHA to revert |

### Optional Parameters

| Parameter | Description | Default |
|-----------|-------------|--------|
| `git_user_email` | Git user email | Uses Drone/CI environment variables |
| `git_user_name` | Git user name | Uses Drone/CI environment variables |
| `branch` | Target branch to push to | `DRONE_BRANCH` or "main" |
| `create_revert_branch` | Whether to create a separate branch for the revert | `true` |
| `revert_branch_prefix` | Prefix for the revert branch name | "reverted-pr-" |
| `remote` | Git remote to use | "origin" |

## Environment Variables

The plugin will use the following environment variables for Git user information if they are available and no explicit settings are provided:

- For email: `DRONE_COMMIT_AUTHOR_EMAIL`, `CI_COMMIT_AUTHOR_EMAIL`
- For name: `DRONE_COMMIT_AUTHOR`, `CI_COMMIT_AUTHOR`, `DRONE_COMMIT_AUTHOR_NAME`, `CI_COMMIT_AUTHOR_NAME`

## How It Works

The plugin performs the following steps:

1. Configures Git with the provided user name and email
2. Sets up Git credentials using the provided Personal Access Token
3. Pulls the latest changes from the target branch
4. Creates a new branch for the revert (if `create_revert_branch` is true)
5. Pushes the new branch to the repository (if `create_revert_branch` is true)
6. Reverts the specified commit
7. Pushes the revert to the target branch

## Example Harness CI Integration

```yaml
pipeline:
  name: Git Revert Example
  identifier: git_revert_example
  projectIdentifier: your_project_id
  orgIdentifier: your_org_id
  tags: {}
  stages:
    - stage:
        name: Git Revert Stage
        identifier: git_revert_stage
        type: CI
        spec:
          cloneCodebase: true
          execution:
            steps:
              - step:
                  type: Plugin
                  name: Revert Commit
                  identifier: revert_commit
                  spec:
                    connectorRef: your_docker_connector_id
                    image: plugins/git-revert-commit:latest
                    settings:
                      git_pat: <+secrets.getValue("git_pat_secret")>
                      commit_sha: <+codebase.commitSha>
                      git_user_email: "ci-bot@example.com"
                      git_user_name: "Harness CI Bot"
                      branch: main
                      create_revert_branch: "true"
          platform:
            os: Linux
            arch: Amd64
          runtime:
            type: Cloud
            spec: {}
```

## Building

To build the Docker image locally:

```bash
docker build -t plugins/git-revert-commit:latest .
```

## License

Apache License 2.0