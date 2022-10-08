#!/bin/bash

vagrant destroy
rm -rf .vagrant
rm -rf nocloud.iso
make
vagrant up