.PHONY: create-karabiner setup-macos-dimmer setup-pc install-macos-utils

create-karabiner:
	bun run ./ts/feat/mac/create-karabiner.ts

setup-macos-dimmer:
	bun run ./ts/feat/mac/setup-macos-dimmer.ts

setup-pc:
	bun run ./ts/setup-pc.ts

install-macos-utils:
	cd apps/macosUtils && ./install.sh
