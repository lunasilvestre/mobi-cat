{pkgs}: {
  deps = [
    pkgs.tree
    pkgs.awscli2
    pkgs.zip
    pkgs.google-cloud-sdk-gce
    pkgs.python310Full                   # Updated to Python 3.10 Full
    pkgs.python310Packages.google-cloud-pubsub
    pkgs.libxml2  # For XML parsing
    # pkgs.terraform
    # pkgs.docker
  ];

  # Set up shell hooks to ensure docker can be used without sudo
  # shellHook = ''
  #   if ! [ -e /var/run/docker.sock ]; then
  #     sudo dockerd &
  #     sleep 5
  #   fi
  #   sudo usermod -aG docker $USER
  #   echo "All dependencies installed successfully."
  # '';
}
