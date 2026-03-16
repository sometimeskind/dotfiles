DOTFILES := $(shell pwd)
TARGET   := $(HOME)
STOW     := stow --dir=$(DOTFILES) --target=$(TARGET)

# All top-level dirs are stow packages, except scripts/
PACKAGES := $(filter-out scripts,$(patsubst %/,%,$(wildcard */)))

.PHONY: stow unstow restow help

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*##"}; {printf "  %-10s %s\n", $$1, $$2}'

stow: ## Stow all packages, or one: make stow PKG=music
ifdef PKG
	$(STOW) $(PKG)
else
	$(STOW) $(PACKAGES)
endif

unstow: ## Unstow all packages, or one: make unstow PKG=music
ifdef PKG
	$(STOW) -D $(PKG)
else
	$(STOW) -D $(PACKAGES)
endif

restow: ## Restow all packages, or one: make restow PKG=music
ifdef PKG
	$(STOW) -R $(PKG)
else
	$(STOW) -R $(PACKAGES)
endif
