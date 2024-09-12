
# Test Developers Guide

## Setup

clone into $GOPATH/src/github.com/paul-carlton:

    cd $GOPATH/src/github.com/paul-carlton
    git clone git@github.com:paul-carlton/example-prog.git
    cd example-prog


This project requires the following software:

    golangci-lint --version = 1.19.1
    golang version = 1.13.1
    godocdown version = head

You can install these in the `$GOPATH/bin/<project name>` directory using the 'setup.sh' script:

    bin/setup.sh
    . bin/env.sh

The setup.sh script can safely be run at any time. It will only install tools if the required version is not
currently present in `$GOPATH/bin/<project name>`. Alternatively you can use the version of these tools from
elsewhere on your workstation.

Then build:

    make

## Development

The Makefile in the project's top level directory will compile, build and test all components.

    make build

To run the build and test in a docker container, type:

    make check

If changes are made to go source imports you may need to perform a go mod vendor update, type:

    make gomod-update

###  Testing program on Workstation

To run the program:

    cd $GOPATH/src/github.com/paul-carlton/example-prog
    . bin/env.sh
    make
    example-prog
