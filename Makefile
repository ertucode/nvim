.PHONY: create-karabiner setup-macos-dimmer setup-pc

create-karabiner:
	bun run ./ts/feat/mac/create-karabiner.ts

setup-macos-dimmer:
	bun run ./ts/feat/mac/setup-macos-dimmer.ts

setup-pc:
	bun run ./ts/setup-pc.ts
