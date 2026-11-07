# Rejected parser-budget epoch

The generic observer passes its parser check. The subsequent active-snapshot
check exhausts the shared5-second parser budget and is terminated, with no script
error printed. No native Main diagnostic runs in this epoch. All790 production
inputs and both ignored observers remain unchanged. This is a tooling timeout,
not a gameplay failure or acceptance packet.
