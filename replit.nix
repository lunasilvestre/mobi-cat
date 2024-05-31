{pkgs}: {
  deps = [
    pkgs.google-cloud-sdk-gce
    pkgs.python39
    pkgs.python39Packages.google-cloud-pubsub
    pkgs.terraform
    pkgs.docker
    pkgs.libxml2  # For XML parsing
  ];

  # Set up shell hooks to ensure docker can be used without sudo
  shellHook = ''
    if ! [ -e /var/run/docker.sock ]; then
      sudo dockerd &
      sleep 5
    fi
    sudo usermod -aG docker $USER
    echo "All dependencies installed successfully."
  '';
}
