# Kiwix Library Configuration
# ==============================================================================
# This file lists ZIM files to serve via Kiwix
# Place ZIM files in: /srv/homelab/data/ZIM/
#
# Download ZIM files from: https://wiki.kiwix.org/wiki/Content_in_all_languages
# ==============================================================================

## Popular ZIM Files (Legal, Free Content)

### Wikipedia
# - wikipedia_en_all_maxi (Full English Wikipedia, ~100 GB)
# - wikipedia_en_all_nopic (English Wikipedia without images, ~20 GB)
# - wikipedia_en_simple (Simple English Wikipedia, ~500 MB)

### Wikibooks
# - wikibooks_en_all (All English Wikibooks)

### Wikiversity
# - wikiversity_en_all (Educational resources)

### Stack Overflow
# - stackoverflow_en_all (Programming Q&A)

### Project Gutenberg
# - gutenberg_en_all (Public domain books)

### TED Talks
# - ted_en_global_issues (Talks on global issues)

### Khan Academy
# - khanacademy_en_all (Educational videos)

### Medicine
# - wikimed_en_all (Medical Wikipedia)

## Download Commands

# Using kiwix-tools:
# kiwix-download wikipedia_en_all_maxi

# Direct download (replace with actual URL):
# wget https://download.kiwix.org/zim/wikipedia/wikipedia_en_all_maxi_YYYY-MM.zim

## Kiwix Docker Commands

# Serve all ZIM files in directory:
# docker run -v /srv/homelab/data/ZIM:/data -p 8081:80 ghcr.io/kiwix/kiwix-serve /data/*.zim

# Create library file for multiple ZIMs:
# kiwix-manage library.xml add /zim/wikipedia_en_all.zim
# kiwix-manage library.xml add /zim/stackoverflow_en_all.zim
