# ==============================================================================
# 📦 Checksums for ZIM Files
# ==============================================================================
# Format: SHA256HASH  filename
# 
# Note: These are example checksums. Real checksums should be obtained from
# the Kiwix download page: https://download.kiwix.org/zim/
# 
# To generate checksums for downloaded files:
#   sha256sum /path/to/file.zim > file.zim.sha256
# ==============================================================================

# These are PLACEHOLDER checksums - update with real values after download
# Run: sha256sum yourfile.zim | tee yourfile.zim.sha256

# Wikipedia (Simple English)
# PLACEHOLDER_HASH_SIMPLE_WIKI  wikipedia_en_simple_all_nopic_2024-06.zim

# Wikipedia (English, no pics)
# PLACEHOLDER_HASH_EN_NOPIC  wikipedia_en_all_nopic_2024-06.zim

# Wikipedia (English, full)
# PLACEHOLDER_HASH_EN_FULL  wikipedia_en_all_maxi_2024-06.zim

# Stack Overflow
# PLACEHOLDER_HASH_SO  stackoverflow.com_en_all_2024-05.zim

# Wikibooks
# PLACEHOLDER_HASH_WIKIBOOKS  wikibooks_en_all_nopic_2024-06.zim

# Project Gutenberg
# PLACEHOLDER_HASH_GUTENBERG  gutenberg_en_all_2024-05.zim

# ==============================================================================
# HOW TO UPDATE
# ==============================================================================
# 1. Download the ZIM file
# 2. Run: sha256sum filename.zim > checksums/filename.zim.sha256
# 3. The download-all.sh script will automatically verify
# ==============================================================================
