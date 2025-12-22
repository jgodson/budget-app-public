#!/bin/bash

# Check if an argument is provided
if [ -z "$1" ]; then
  echo "Usage: ./seed-data.sh <duration>"
  echo "Example: ./seed-data.sh 2y"
  echo "Example: ./seed-data.sh 6m"
  exit 1
fi

DURATION=$1
MONTHS=0

# Parse the duration
if [[ $DURATION =~ ^([0-9]+)y$ ]]; then
  YEARS=${BASH_REMATCH[1]}
  MONTHS=$((YEARS * 12))
elif [[ $DURATION =~ ^([0-9]+)m$ ]]; then
  MONTHS=${BASH_REMATCH[1]}
else
  echo "Invalid format. Use 'y' for years or 'm' for months (e.g., 2y, 6m)."
  exit 1
fi

echo "Seeding data for $MONTHS months..."

# Run the rails seed command with the calculated months
MONTHS_TO_SEED=$MONTHS CLEAN=true rails db:seed

echo "Done."
