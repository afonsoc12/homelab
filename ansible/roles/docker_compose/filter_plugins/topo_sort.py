from __future__ import annotations

DOCUMENTATION = r"""
name: topo_sort_autostart
short_description: Order containers for Unraid's autostart list, respecting network_mode dependencies
description:
  - Unraid starts containers listed in /var/lib/docker/unraid-autostart strictly in file
    order, waiting for each `docker start` to return before the next. A container using
    `network_mode: service:<name>` (or `container:<name>`) must therefore appear *after*
    the container that owns that network namespace, or Docker fails to attach it
    (exit code 128) because the target container doesn't exist/isn't running yet.
  - A plain alphabetical sort ignores this entirely — this filter topologically sorts
    on those dependencies first, falling back to alphabetical order for anything with
    no dependency relationship (stable, deterministic output).
"""


def _network_mode_target(network_mode):
    if not network_mode:
        return None
    for prefix in ("service:", "container:"):
        if network_mode.startswith(prefix):
            return network_mode[len(prefix) :]
    return None


def topo_sort_autostart(services):
    """services: list of compose service dicts (container_name, network_mode)."""
    names = sorted(s["container_name"] for s in services)
    depends_on = {s["container_name"]: _network_mode_target(s.get("network_mode")) for s in services}

    ordered = []
    visited = set()
    visiting = set()

    def visit(name):
        if name in visited or name not in depends_on:
            return
        if name in visiting:
            # Cycle — bail out rather than infinite-loop; leave remaining order alphabetical.
            return
        visiting.add(name)
        target = depends_on.get(name)
        if target:
            visit(target)
        visiting.discard(name)
        visited.add(name)
        ordered.append(name)

    for name in names:
        visit(name)

    return ordered


class FilterModule:
    def filters(self):
        return {"topo_sort_autostart": topo_sort_autostart}
