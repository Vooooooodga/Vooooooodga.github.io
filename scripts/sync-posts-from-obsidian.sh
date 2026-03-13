#!/usr/bin/env bash
# 将 Obsidian 库中「博客」目录下的 .md 同步到本仓库的 _posts（Jekyll 格式）
# 用法: ./scripts/sync-posts-from-obsidian.sh /path/to/your/vault/blog
# 要求: 每篇 .md 有 YAML front matter，且含 title；可选 date（否则用文件修改日期）

set -e
OBSIDIAN_BLOG_DIR="${1:?用法: $0 /path/to/vault/blog}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
POSTS_DIR="$REPO_ROOT/_posts"
mkdir -p "$POSTS_DIR"

sync_file() {
  local src="$1"
  local base name title date_line date_val filename
  base=$(basename "$src" .md)
  [[ "$base" == *".md" ]] && return 0

  # 简单解析 YAML front matter（第一个 --- 与第二个 --- 之间）
  title=""
  date_val=""
  in_fm=0
  while IFS= read -r line; do
    if [[ "$line" == "---" ]]; then
      ((in_fm++)) || true
      [[ "$in_fm" -eq 2 ]] && break
      continue
    fi
    [[ "$in_fm" -ne 1 ]] && continue
    if [[ "$line" =~ ^title:[[:space:]]*(.+)$ ]]; then
      title="${BASH_REMATCH[1]}"
      title="${title#[\"\']}"
      title="${title%[\"\']}"
      title="${title// / }"
    fi
    if [[ "$line" =~ ^date:[[:space:]]*(.+)$ ]]; then
      date_val="${BASH_REMATCH[1]}"
      date_val="${date_val#[\"\']}"
      date_val="${date_val%[\"\']}"
      if [[ "$date_val" =~ ([0-9]{4}-[0-9]{2}-[0-9]{2}) ]]; then
        date_val="${BASH_REMATCH[1]}"
      fi
    fi
  done < "$src"

  # 若 front matter 里没有 date，用文件修改日期的 YYYY-MM-DD
  if [[ -z "$date_val" ]]; then
    if [[ "$(uname -s)" == "Darwin" ]]; then
      date_val=$(stat -f "%Sm" -t "%Y-%m-%d" "$src")
    else
      date_val=$(stat -c "%y" "$src" | cut -d' ' -f1)
    fi
  fi

  if [[ -z "$title" ]]; then
    title="$base"
  fi

  # Jekyll 文件名: YYYY-MM-DD-标题.md，标题中的空格和特殊字符替换为 -
  safe_title=$(echo "$title" | sed 's/[^a-zA-Z0-9\u4e00-\u9fff\u3040-\u309f\u30a0-\u30ff -]//g' | sed 's/[[:space:]]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')
  [[ -z "$safe_title" ]] && safe_title="untitled"
  filename="${date_val}-${safe_title}.md"
  dst="$POSTS_DIR/$filename"

  if [[ "$src" -nt "$dst" ]] || [[ ! -f "$dst" ]]; then
    cp "$src" "$dst"
    echo "Synced: $filename"
  fi
}

find "$OBSIDIAN_BLOG_DIR" -maxdepth 3 -name "*.md" -type f | while read -r f; do
  sync_file "$f"
done

echo "Done. Check $POSTS_DIR"
