rwildcard = $(foreach d, $(wildcard $1*), $(filter $(subst *, %, $2), $d) $(call rwildcard, $d/, $2))

CC := arm-none-eabi-gcc
AS := arm-none-eabi-as
LD := arm-none-eabi-ld
OC := arm-none-eabi-objcopy

name := UnsafeA9LHInstaller
revision := $(shell git describe --tags --match v[0-9]* --abbrev=8 | sed 's/-[0-9]*-g/-/i')

dir_source := source
dir_mset := CakeHax
dir_ninjhax := CakeBrah
dir_2xrsa := 2xrsa
dir_build := build
dir_out := out

ASFLAGS := -mcpu=arm946e-s
CFLAGS := -Wall -Wextra -MMD -MP -marm $(ASFLAGS) -fno-builtin -fshort-wchar -std=c11 -Wno-main -O2 -flto -ffast-math
LDFLAGS := -nostartfiles
FLAGS := name=$(name).dat dir_out=$(abspath $(dir_out)) ICON=$(abspath icon.png) APP_DESCRIPTION="Unsafe ARM9LoaderHax installer." APP_AUTHOR="Aurora Wright/SciresM" --no-print-directory

objects= $(patsubst $(dir_source)/%.s, $(dir_build)/%.o, \
         $(patsubst $(dir_source)/%.c, $(dir_build)/%.o, \
	 $(call rwildcard, $(dir_source), *.s *.c)))

.PHONY: all
all: launcher a9lh ninjhax 2xrsa

.PHONY: launcher
launcher: $(dir_out)/$(name).dat 

.PHONY: a9lh
a9lh: $(dir_out)/arm9loaderhax.bin

.PHONY: 2xrsa
2xrsa: $(dir_out)/arm9.bin $(dir_out)/arm11.bin

.PHONY: ninjhax
ninjhax: $(dir_out)/3ds/$(name)

.PHONY: release
release: $(dir_out)/$(name)$(revision).7z

.PHONY: clean
clean:
	@$(MAKE) $(FLAGS) -C $(dir_mset) clean
	@$(MAKE) $(FLAGS) -C $(dir_ninjhax) clean
	@$(MAKE) -C $(dir_2xrsa) clean
	@rm -rf $(dir_out) $(dir_build)

$(dir_out):
	@mkdir -p "$(dir_out)"

$(dir_out)/$(name).dat: $(dir_build)/main.bin $(dir_out)
	@mkdir -p $(dir_out)
	@$(MAKE) $(FLAGS) -C $(dir_mset) launcher
	dd if=$(dir_build)/main.bin of=$@ bs=512 seek=144

$(dir_out)/arm9loaderhax.bin: $(dir_build)/main.bin $(dir_out)
	@cp -av $(dir_build)/main.bin $@

$(dir_out)/arm9.bin: $(dir_build)/main.bin $(dir_out)
	@cp -av $(dir_build)/main.bin $@

$(dir_out)/arm11.bin:
	@$(MAKE) -C $(dir_2xrsa)
	@cp -av $(dir_2xrsa)/bin/arm11.bin $@

$(dir_out)/3ds/$(name): $(dir_out)
	@mkdir -p $(dir_out)/3ds/$(name)
	@$(MAKE) $(FLAGS) -C $(dir_ninjhax)
	@mv $(dir_out)/$(name).3dsx $@
	@mv $(dir_out)/$(name).smdh $@

$(dir_out)/$(name)$(revision).7z: launcher a9lh ninjhax 2xrsa
	@7z a -mx $@ ./$(@D)/*

$(dir_build)/main.bin: $(dir_build)/main.elf
	$(OC) -S -O binary $< $@

$(dir_build)/main.elf: $(objects)
	$(LINK.o) -T linker.ld $(OUTPUT_OPTION) $^

$(dir_build)/memory.o:    CFLAGS += -O3
$(dir_build)/installer.o: CFLAGS += -DTITLE="\"$(name) $(revision)\""

$(dir_build)/%.o: $(dir_source)/%.c
	@mkdir -p "$(@D)"
	$(COMPILE.c) $(OUTPUT_OPTION) $<

$(dir_build)/%.o: $(dir_source)/%.s
	@mkdir -p "$(@D)"
	$(COMPILE.s) $(OUTPUT_OPTION) $<
include $(call rwildcard, $(dir_build), *.d)
