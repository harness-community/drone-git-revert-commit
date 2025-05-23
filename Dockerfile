FROM alpine/git:latest

LABEL org.opencontainers.image.source="https://github.com/harness-community/drone-git-revert-commit-history"
LABEL org.opencontainers.image.description="Drone plugin to revert git commits"

# Copy the plugin script
COPY plugin.sh /bin/plugin.sh

# Make the script executable
RUN chmod +x /bin/plugin.sh

# Set the entrypoint
ENTRYPOINT ["/bin/plugin.sh"]
