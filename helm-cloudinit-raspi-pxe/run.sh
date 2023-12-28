#!/usr/bin/env bash

helm template -s templates/network-config.yaml .
helm template -s templates/user-data.yaml .
helm template -s templates/metadata.yaml .