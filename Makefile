LINUX_CXX := @clang++
LINUX_CC  := @clang

ifeq ($(OS),Windows_NT)
WINDOWS_CXX := @g++
WINDOWS_CC  := @gcc
else
WINDOWS_CXX := @x86_64-w64-mingw32-g++
WINDOWS_CC  := @x86_64-w64-mingw32-gcc
endif

# LSAN_OPTIONS=verbosity=1:log_threads=1 # Use this environment variable for more verbosity with address sanitizer
LINUX_DEBUG_FLAGS := -fsanitize=address -g -Wall -O0 -D NOSTALGIA_DEBUGGING
WINDOWS_DEBUG_FLAGS := -g -Wall -O0 -D NOSTALGIA_DEBUGGING
COMMON_FLAGS := -frtti -D COMPILER_FORWARD_DECLARATIONS
CXX_FLAGS := -std=c++20

LINUX_INCLUDE := -I src/system/linux/include
WINDOWS_INCLUDE := -I src/system/windows/include
COMMON_INCLUDE := -I src/ -I src/include/Nostalgia

LINUX_LIBRARIES := -L src/system/linux/lib -l glfw3 -l NostalgiaEngine
WINDOWS_LIBRARIES := -L src/system/windows/lib -l glfw-lib-mingw-w64/glfw3 -l gdi32 -l NostalgiaEngine


BUILD_ROOT         := build
BUILD_PATH_LINUX   := linux
BUILD_PATH_WINDOWS := windows
BUILD_PATH_RELEASE := release
BUILD_PATH_DEBUG   := debug

ifeq ($(OS),Windows_NT)
APP_NAME_LINUX   := Linux.x86_64
else
APP_NAME_LINUX   := $(shell uname -s)_$(subst .,_,$(shell uname -r)).$(shell uname -m)
endif
APP_NAME_WINDOWS := Win64.exe
APP_NAME_RELEASE := Nostalgia
APP_NAME_DEBUG   := DEBUG__Nostalgia

export BUILD_VERSION ?= $(BUILD_PATH_RELEASE)
export APP_VERSION   ?= $(APP_NAME_RELEASE)


export BUILD_ARCH  ?= $(BUILD_PATH_LINUX)
export APP_ARCH    ?= $(APP_NAME_LINUX)
export CXX         ?= $(LINUX_CXX)
export CC          ?= $(LINUX_CC)
export INCLUDE     ?= $(COMMON_INCLUDE) $(LINUX_INCLUDE)
export LDFLAGS     ?= $(LINUX_LIBRARIES)
export DEBUG_FLAGS ?= $(LINUX_DEBUG_FLAGS)
ifeq ($(OS),Windows_NT)
export BUILD_ARCH  ?= $(BUILD_PATH_WINDOWS)
export APP_ARCH    ?= $(APP_NAME_WINDOWS)
export CXX         ?= $(WINDOWS_CXX)
export CC          ?= $(WINDOWS_CC)
export INCLUDE     ?= $(COMMON_INCLUDE) $(WINDOWS_INCLUDE)
export LDFLAGS     ?= $(WINDOWS_LIBRARIES)
export DEBUG_FLAGS ?= $(WINDOWS_DEBUG_FLAGS)
endif

export CXXFLAGS    ?= $(COMMON_FLAGS) $(CXX_FLAGS)
export CCFLAGS     ?= $(COMMON_FLAGS)

export APP_NAME ?= $(APP_VERSION)_$(APP_ARCH)
export BUILD_DIR ?= $(BUILD_ROOT)/$(BUILD_ARCH)_$(BUILD_VERSION)

VPATH := $(SRC_DIRS) $(DIRTY_SRC_DIRS)

SRC_DIRS :=    \
	src/app    \
	src/system \
	src/ui     \

DIRTY_SRC_DIRS :=

CC_SRCS        := $(foreach directory,$(SRC_DIRS),$(wildcard $(directory)/*.c))
CXX_SRCS       := $(foreach directory,$(SRC_DIRS),$(wildcard $(directory)/*.cpp))
DIRTY_CC_SRCS  := $(foreach directory,$(DIRTY_SRC_DIRS),$(wildcard $(directory)/*.c))
DIRTY_CXX_SRCS := $(foreach directory,$(DIRTY_SRC_DIRS),$(wildcard $(directory)/*.cpp))

export CC_OBJS        ?= $(addprefix $(BUILD_DIR)/,$(subst .c,.o,$(CC_SRCS:src/%=%)))
export CXX_OBJS       ?= $(addprefix $(BUILD_DIR)/,$(subst .cpp,.obj,$(CXX_SRCS:src/%=%)))
export DIRTY_CC_OBJS  ?= $(addprefix $(BUILD_DIR)/,$(subst .c,.o,$(DIRTY_CC_SRCS:src/%=%)))
export DIRTY_CXX_OBJS ?= $(addprefix $(BUILD_DIR)/,$(subst .cpp,.obj,$(DIRTY_CXX_SRCS:src/%=%)))

EXTERNAL := src/external

GIT := git
# Nostalgia Library variables
NOSTALGIA_REPO_NAME := nostalgia-game-engine
NOSTALGIA_REPO_URL   := https://github.com/Electron7-7/$(NOSTALGIA_REPO_NAME)


# ANSI color code variables
export RESET   ?= \\033[0m
export BLACK   ?= \\033[30m
export RED     ?= \\033[31m
export GREEN   ?= \\033[32m
export YELLOW  ?= \\033[33m
export BLUE    ?= \\033[34m
export MAGENTA ?= \\033[35m
export CYAN    ?= \\033[36m
export WHITE   ?= \\033[37m
export DEFAULT ?= \\033[39m


.PHONY: build update_library sublime linux windows debug release resources build_dir clean clean_debug clean_release clean_linux clean_windows clean_dirty

build: update_library
	@ echo -e "$(DEFAULT)::Compiling application objects$(RESET)"
	@ echo -e "$(DEFAULT)::Compile command: ($(CXX:@%=%)/$(CC:@%=%)) $(YELLOW)(CXXFLAGS) (INCLUDE)$(DEFAULT) -c <source file> -o <object file>$(RESET)"
	@ echo -e "$(DEFAULT)::Variable Definitions:$(RESET)"
	@ echo -e "\t$(YELLOW)CXXFLAGS: $(DEFAULT)$(CXXFLAGS)$(RESET)"
	@ echo -e "\t$(YELLOW)INCLUDE: $(DEFAULT)$(INCLUDE)$(RESET)\n"

	@ $(MAKE) -s $(CC_OBJS) $(CXX_OBJS) $(DIRTY_CC_OBJS) $(DIRTY_CXX_OBJS)

	@ echo -e "$(DEFAULT)::Linking command: $(CXX:@%=%)$(YELLOW) (CXXFLAGS) (CC_OBJS) (CXX_OBJS) (DIRTY_CC_OBJS) (DIRTY_CXX_OBJS) $(DEFAULT)-o$(YELLOW) (BUILD_DIR)$(DEFAULT)/$(YELLOW)(APP_NAME) (LDFLAGS)$(RESET)"
	@ echo -e "$(DEFAULT)::Variables:$(RESET)"
	@ echo -e "\t$(YELLOW)LDFLAGS: $(DEFAULT)$(LDFLAGS)$(RESET)"
	@ echo -e "\t$(YELLOW)CC_OBJS CXX_OBJS DIRTY_CC_OBJS DIRTY_CXX_OBJS: $(DEFAULT)all the object files previously compiled$(RESET)"
	@ echo -e "\t$(YELLOW)BUILD_DIR: $(DEFAULT)$(BUILD_DIR)$(RESET)"
	@ echo -e "\t$(YELLOW)APP_NAME: $(DEFAULT)$(APP_NAME)$(RESET)\n"

	@ -rm -f $(BUILD_DIR)/$(APP_NAME) # in case it already exists
	@ $(MAKE) -s $(BUILD_DIR)/$(APP_NAME)

update_library: $(EXTERNAL)/$(NOSTALGIA_REPO_NAME) src/system/$(BUILD_ARCH)/lib/libNostalgiaEngine.a src/include/Nostalgia
	@ cp $(EXTERNAL)/$(NOSTALGIA_REPO_NAME)/build/$(BUILD_ARCH)_static_release/libNostalgiaEngine.a src/system/$(BUILD_ARCH)/lib/libNostalgiaEngine.a
	@ cp -r $(EXTERNAL)/$(NOSTALGIA_REPO_NAME)/build/$(BUILD_ARCH)_static_release/include/* src/include/Nostalgia

src/system/$(BUILD_ARCH)/lib/libNostalgiaEngine.a:
	@ cd $(EXTERNAL)/$(NOSTALGIA_REPO_NAME) && $(GIT) pull
	@ $(MAKE) -s $(BUILD_ARCH) static install -C $(EXTERNAL)/$(NOSTALGIA_REPO_NAME)

src/include/Nostalgia:
	@ -mkdir -p $@

$(EXTERNAL)/$(NOSTALGIA_REPO_NAME): $(EXTERNAL)
	$(GIT) clone -b indev $(NOSTALGIA_REPO_URL) $@

$(EXTERNAL):
	@ -mkdir -p $(EXTERNAL)

# This target is for disabling the ANSI colors. The reason it's called 'sublime' (and an example use-case) is because
# Sublime Text's output panel doesn't support ANSI colors natively, so I call this target in every build system that's
# in my Sublime Text project file for Nostalgia.
sublime:
	$(eval RESET   := "")
	$(eval BLACK   := "")
	$(eval RED     := "")
	$(eval GREEN   := "")
	$(eval YELLOW  := "")
	$(eval BLUE    := "")
	$(eval MAGENTA := "")
	$(eval CYAN    := "")
	$(eval WHITE   := "")
	$(eval DEFAULT := "")
	@ echo -e "Output colors disabled"

linux:
ifeq ($(OS),Windows_NT)
	$(eval APP_ARCH := $(APP_NAME_LINUX))
	$(eval BUILD_ARCH := $(BUILD_PATH_LINUX))
	$(eval INCLUDE := $(COMMON_INCLUDE) $(LINUX_INCLUDE))
	$(eval LDFLAGS := $(LINUX_LIBRARIES))
endif
	$(eval CXX := $(LINUX_CXX))
	$(eval CC := $(LINUX_CC))
	$(eval DEBUG_FLAGS := $(LINUX_DEBUG_FLAGS))
	$(eval CXXFLAGS += $(LINUX_FLAGS))
	@ echo -e "$(DEFAULT)::Architecture - Linux$(RESET)"

windows:
ifneq ($(OS),Windows_NT)
	$(eval APP_ARCH := $(APP_NAME_WINDOWS))
	$(eval BUILD_ARCH := $(BUILD_PATH_WINDOWS))
	$(eval INCLUDE := $(COMMON_INCLUDE) $(WINDOWS_INCLUDE))
	$(eval LDFLAGS := $(WINDOWS_LIBRARIES))
endif
	$(eval CXX := $(WINDOWS_CXX))
	$(eval CC := $(WINDOWS_CC))
	$(eval DEBUG_FLAGS := $(WINDOWS_DEBUG_FLAGS))
	$(eval CXXFLAGS := $(WINDOWS_FLAGS))
	@ echo -e "$(DEFAULT)::Architecture - Windows$(RESET)"

debug:
	$(eval APP_VERSION := $(APP_NAME_DEBUG))
	$(eval BUILD_VERSION := $(BUILD_PATH_DEBUG))
	$(eval CXXFLAGS += $(DEBUG_FLAGS))
	@ echo -e "$(DEFAULT)::Version - Debug$(RESET)"

release:
	@ echo -e "$(DEFAULT)::Building Release$(RESET)"
	$(eval APP_VERSION := $(APP_NAME_RELEASE))
	$(eval BUILD_VERSION := $(BUILD_PATH_RELEASE))
	@ echo -e "$(DEFAULT)::Version - Release$(RESET)"

build_dir:
	@ -mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/$(APP_NAME):
	@ echo -e "$(DEFAULT)Linking: $(CYAN)$@$(RESET)"
	$(CXX) $(CXXFLAGS) $(INCLUDE) $(CC_OBJS) $(CXX_OBJS) $(DIRTY_CC_OBJS) $(DIRTY_CXX_OBJS) -o $@ $(LDFLAGS)

$(BUILD_DIR)/%.o: src/%.c | build_dir
	@ echo -e "$(DEFAULT)Compiling: $(DEFAULT)$<$(RESET) -> $(CYAN)$@$(RESET)"
	@ -mkdir -p $(dir $@)
	$(CC) $(CCFLAGS) $(INCLUDE) -c $< -o $@

$(BUILD_DIR)/%.obj: src/%.cpp | build_dir
	@ echo -e "$(DEFAULT)Compiling: $(DEFAULT)$<$(RESET) -> $(CYAN)$@$(RESET)"
	@ -mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) $(INCLUDE) -c $< -o $@

#
# Clean Targets
#
define clean_with_message
	@ if [ -d $(1) ]; then echo -e "\n$(DEFAULT)Cleaned: $(RED)$(1)$(RESET)"; fi
	@ -rm -rf $(1)
endef

clean:
	$(call clean_with_message,$(BUILD_ROOT))
	$(call clean_with_message,$(EXTERNAL))
	$(call clean_with_message,src/include/Nostalgia)

clean_debug:
	$(call clean_with_message,$(BUILD_LINUX_DEBUG))
	$(call clean_with_message,$(BUILD_WINDOWS_DEBUG))

clean_release:
	$(call clean_with_message,$(BUILD_LINUX_RELEASE))
	$(call clean_with_message,$(BUILD_WINDOWS_RELEASE))

clean_linux:
	$(call clean_with_message,$(BUILD_ROOT)/$(BUILD_PATH_LINUX))

clean_windows:
	$(call clean_with_message,$(BUILD_ROOT)/$(BUILD_PATH_WINDOWS))

clean_dirty:
	@ echo -e $(foreach directory,$(wildcard $(BUILD_ROOT)/*),$(foreach clean_dir,$(SRC_DIRS:src/%=%),$(shell rm -rf $(directory)/$(clean_dir) && echo -e "$(DEFAULT)Cleaned: $(RED)$(directory)/$(clean_dir)$(RESET)")))
