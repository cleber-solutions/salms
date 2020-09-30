#!/bin/bash

docker run --rm \
    -v $PWD:/app \
    love /app
