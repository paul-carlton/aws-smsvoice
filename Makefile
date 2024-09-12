
include project-name.mk

# Makes a recipe passed to a single invocation of the shell.
.ONESHELL:

MAKE_SOURCES:=makefile.mk project-name.mk Makefile
PROJECT_SOURCES:=$(shell find ./pkg -regex '.*.\.\(go\|json\)$$')

BUILD_DIR:=build/
GOMOD_VENDOR_DIR:=vendor/
export VERSION?=latest

ALL_GO_PACKAGES:=$(shell find ${CURDIR}/pkg/ \
	-type f -name *.go -exec dirname {} \; | sort --uniq)
GO_CHECK_PACKAGES:=$(shell echo $(subst $() $(),\\n,$(ALL_GO_PACKAGES)) | \
	awk '$$0!~/pkg[\/]api/||/pkg[\/]api[\/]v[1-9][0-9]*[\/]restapi$$/{print $$0}')

CHECK_ARTIFACT:=${BUILD_DIR}${PROJECT}-check-${VERSION}-docker.tar
BUILD_ARTIFACT:=${BUILD_DIR}${PROJECT}-build-${VERSION}-docker.tar

GOMOD_CACHE_ARTIFACT:=${GOMOD_CACHE_DIR}._gomod
GOMOD_VENDOR_ARTIFACT:=${GOMOD_VENDOR_DIR}._gomod
GO_BIN_ARTIFACT:=$(shell echo "$${GOBIN:-$${GOPATH}/bin}/${PROJECT}")
GO_DOCS_ARTIFACTS:=$(shell echo $(subst $() $(),\\n,$(ALL_GO_PACKAGES)) | \
	sed 's:\(.*[/\]\)\(.*\):\1\2/\2.md:')

YELLOW:=\033[0;33m
GREEN:=\033[0;32m
NC:=\033[0m

# Targets that do not represent filenames need to be registered as phony or
# Make won't always rebuild them.
.PHONY: all clean ci-check ci-gate clean-godocs \
	_godocs-build godocs clean-gomod gomod gomod-update \
	clean-${PROJECT}-check ${PROJECT}-check clean-${PROJECT}-build \
	${PROJECT}-build ${GO_CHECK_PACKAGES} clean-check check \
	clean-build build
# Stop prints each line of the recipe.
.SILENT:

# Allow secondary expansion of explicit rules.
.SECONDEXPANSION: %.md %-docker.tar

all: ${PROJECT}-check godocs ${PROJECT}-build
build: gomod ${PROJECT}-check godocs ${PROJECT}-build
clean: clean-gomod clean-godocs clean-${PROJECT}-check \
	clean-${PROJECT}-build clean-check clean-build \
	clean-${BUILD_DIR}


# Specific CI targets.
# ci-check: Validated the 'check' target works for debug as it cache will be used
# by build.
ci-check: check build
	$(MAKE) -C build

clean-${BUILD_DIR}:
	rm -rf ${BUILD_DIR}

${BUILD_DIR}:
	mkdir -p $@

clean-godocs:
	rm -f ${GO_DOCS_ARTIFACTS}

_godocs-build: ${GO_DOCS_ARTIFACTS}
%.md: $$(wildcard $$(dir $$@)*.go)
	echo "${YELLOW}Running godocdown: $@${NC}" && \
	godocdown -output $@ $(shell dirname $@)


clean-gomod:
	rm -rf ${GOMOD_VENDOR_DIR}

go.mod:
	rm -rf ${GOMOD_VENDOR_DIR} && \
	go mod tidy

gomod: go.sum
go.sum:  ${GOMOD_VENDOR_ARTIFACT}
%._gomod: go.mod
	rm -rf ${GOMOD_VENDOR_DIR} && \
	go mod vendor && \
	touch  ${GOMOD_VENDOR_ARTIFACT}

gomod-update: go.mod ${PROJECT_SOURCES}
	rm -rf ${GOMOD_VENDOR_DIR}  && \
	go build ./... && \
	go mod vendor  && \
	touch ${GOMOD_VENDOR_ARTIFACT}

clean-${PROJECT}-check:
	$(foreach target,${GO_CHECK_PACKAGES},
		$(MAKE) -C ${target} --makefile=${CURDIR}/makefile.mk clean;)

${PROJECT}-check: ${GO_CHECK_PACKAGES}
${GO_CHECK_PACKAGES}: go.sum
	$(MAKE) -C $@ --makefile=${CURDIR}/makefile.mk


clean-${PROJECT}-build:
	rm -f ${GO_BIN_ARTIFACT}

${PROJECT}-build: ${GO_BIN_ARTIFACT}
${GO_BIN_ARTIFACT}: go.sum ${MAKE_SOURCES} ${PROJECT_SOURCES}
	echo "${YELLOW}Building executable: $@${NC}" && \
	EMBEDDED_VERSION="github.com/paul-carlton/example-prog/pkg/acctclient" && \
	CGO_ENABLED=0 go build \
		-ldflags="-s -w -X $${EMBEDDED_VERSION}.serverVersion=${VERSION}" \
		-o $@ pkg/main/main.go


clean-check:
	rm -f ${CHECK_ARTIFACT}

check: DOCKER_SOURCES=Dockerfile ${MAKE_SOURCES} ${PROJECT_SOURCES}
check: DOCKER_BUILD_OPTIONS=--target builder --build-arg VERSION
check: TAG=${ORG}/${PROJECT}-check:${VERSION}
check: ${BUILD_DIR} ${CHECK_ARTIFACT}

clean-build:
	rm -f ${BUILD_ARTIFACT}

build: DOCKER_SOURCES=Dockerfile ${MAKE_SOURCES} ${PROJECT_SOURCES}
build: DOCKER_BUILD_OPTIONS=--build-arg VERSION
build: TAG=${ORG}/${PROJECT}:${VERSION}
build: ${BUILD_DIR} ${BUILD_ARTIFACT}

%-docker.tar: $${DOCKER_SOURCES}
	docker build --rm --pull=true \
		${DOCKER_BUILD_OPTIONS} \
		--tag ${TAG} \
		--file $< \
		. && \
	docker save --output $@ ${TAG}
