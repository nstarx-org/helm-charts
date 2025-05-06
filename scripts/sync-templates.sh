#!/bin/bash
# Script to synchronize templates from shared directory to individual charts

# Base directories
TEMPLATES_DIR="$(dirname "$(dirname "$0")")/templates"
CHARTS_DIR="$(dirname "$(dirname "$0")")/charts"

# Ensure the script works regardless of where it's called from
cd "$(dirname "$0")/.."

echo "Syncing templates from $TEMPLATES_DIR to chart directories..."

# For each chart directory
for CHART_DIR in "$CHARTS_DIR"/*; do
  if [ -d "$CHART_DIR" ]; then
    CHART_NAME=$(basename "$CHART_DIR")
    echo "Processing chart: $CHART_NAME"
    
    # Ensure templates directory exists
    mkdir -p "$CHART_DIR/templates"
    
    # Copy all templates to chart's templates directory
    cp -rf "$TEMPLATES_DIR"/* "$CHART_DIR/templates/"
    
    echo "Templates synchronized for $CHART_NAME"
  fi
done

echo "Template synchronization complete."