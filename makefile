SHELL := /bin/bash

help:
	@grep -E '^[ a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
	awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

compile = ligo compile contract  --project-root ./src ./src/$(1) -o ./compiled/$(2) $(3) 
# ^ Compile contracts to Michelson or Micheline

test = ligo run test $(project_root) ./test/$(1) --no-warn
# ^ run given test file


.PHONY: test compile
compile: ## compile contracts to Michelson
	@mkdir -p compiled
	@$(call compile,fa2_single_asset.mligo,fa2_single_asset.tz, -m TOKEN)
	@$(call compile,fa2_single_asset.mligo,fa2_single_asset.mligo.json, --michelson-format json)
	@$(call compile,vesting.mligo,vesting.tz, -m VESTING)
	@$(call compile,vesting.mligo,vesting.mligo.json, --michelson-format json)

test: ## run tests (SUITE=asset_approve make test)
ifndef SUITE
	@$(call test,fa2_single_asset.test.mligo)

else
	@$(call test,$(SUITE).test.mligo)
endif


deploy.ts:
	@echo "Running deploy script\n"
	@cd deploy && yarn install && yarn deploy