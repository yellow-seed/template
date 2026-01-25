# Podman build validation (Codex environment)

## Commands executed

- `sudo podman compose build`
- `podman build --privileged -t template_shell-dev .`
- `sudo podman build --isolation=chroot -t template_shell-dev .`

## Results

- `sudo podman compose build` failed when the Dockerfile reached a `RUN apt-get ...` step, with an error opening `/proc/sys/net/ipv4/ping_group_range` as read-only. This still repro'd after commenting out the Go tooling and Prettier install steps.
- `podman build --privileged -t template_shell-dev .` failed immediately because `--privileged` is not a supported flag for `podman build`.
- `sudo podman build --isolation=chroot -t template_shell-dev .` now completes successfully after commenting out the Go tooling and Prettier install steps.
