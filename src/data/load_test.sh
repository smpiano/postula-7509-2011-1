#!/bin/bash
target_dir=${2:-'../arribos'}
rm -f "$target_dir"/*
cp "${1:-001}"/* "$target_dir"
