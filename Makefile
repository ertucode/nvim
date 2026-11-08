.PHONY: create-karabiner setup-macos-dimmer

create-karabiner:
	bun run ./ts/feat/mac/create-karabiner.ts

setup-macos-dimmer:
	bun run ./ts/feat/mac/setup-macos-dimmer.ts
