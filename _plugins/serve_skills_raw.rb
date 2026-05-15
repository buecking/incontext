# Serves files under skills/ as raw markdown instead of Jekyll-rendered HTML.
#
# Jekyll always processes any file with YAML frontmatter, converting .md to HTML
# even when the permalink keeps the .md extension. For SKILL.md files that need
# to be installable verbatim by an AI coding agent, we want the served bytes to
# match the source bytes exactly.
#
# This post_write hook runs after Jekyll's normal build and copies each
# skills/**/*.md source file over the rendered output, restoring the raw text.

require "fileutils"

Jekyll::Hooks.register :site, :post_write do |site|
  Dir.glob(File.join(site.source, "skills/**/*.md")).each do |src|
    rel = src.sub("#{site.source}/", "")
    dst = File.join(site.dest, rel)
    FileUtils.mkdir_p(File.dirname(dst))
    FileUtils.cp(src, dst)
  end
end
