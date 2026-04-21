#!/bin/bash

# Deploy script using zenv to load .env.local
zenv -f .env.local -- kamal deploy
